;+
; NAME:
;   yanny_read
;
; PURPOSE:
;   Read a Yanny parameter file.
;
; CALLING SEQUENCE:
;   yanny_read, filename, [ pdata, hdr=hdr, enums=enums, structs=structs, $
;    /quick ]
;
; INPUTS:
;   filename   - Input file name for Yanny parameter file
;
; OPTIONAL INPUTS:
;
; OUTPUT:
;
; OPTIONAL OUTPUTS:
;   pdata      - Array of pointers to all strucutures read.  The i-th data
;                structure is then referenced with "*pdata[i]".  If you want
;                to pass a single structure (eg, FOOBAR), then pass
;                ptr_new(FOOBAR).
;   hdr        - Header lines in Yanny file, which are usually keyword pairs.
;   enums      - All "typedef enum" structures.
;   structs    - All "typedef struct" structures, which define the form
;                for all the PDATA structures.
;   quick      - Quicker read using READF, but fails if continuation lines
;                are present.
;
; COMMENTS:
;
; EXAMPLES:
;
; BUGS:
;   The IDL procedure READF will fail if the last non-whitespace character
;   is a backslash.  One can use such backslashes in Yanny files to indicate
;   a continuation of that line onto the next.  For this reason, I wrote
;   yanny_readstring as a replacement, though this will only work if all
;   lines are <= 255 characters.
;
;   The reading could probably be sped up by setting a format string for
;   each structure to use in the read.
;
;   Not set up yet to deal with multi-dimensional arrays.
;
; PROCEDURES CALLED:
;   mrd_struct
;
; INTERNAL SUPPORT ROUTINES:
;   yanny_add_comment
;   yanny_strip_brackets()
;   yanny_strip_commas()
;   yanny_readstring
;   yanny_nextline()
;
; REVISION HISTORY:
;   05-Sep-1999  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------
pro yanny_add_comment, rawline, comments

   if (size(comments,/tname) EQ 'INT') then $
    comments = rawline $
   else $
    comments = [comments, rawline]

   return
end
;------------------------------------------------------------------------------
; Replace left or right curly brackets with spaces.

function yanny_strip_brackets, sline

   i = strpos(sline, '}')
   while (i NE -1) do begin
      strput, sline, ' ', i
      i = strpos(sline, '}')
   endwhile

   i = strpos(sline, '{')
   while (i NE -1) do begin
      strput, sline, ' ', i
      i = strpos(sline, '{')
   endwhile

   return, sline
end
;------------------------------------------------------------------------------
; Replace ";" or "," with spaces.  Also get rid of extra whitespace.
; Also get rid of anything after a hash mark.

function yanny_strip_commas, rawline

   sline = rawline

   i = strpos(sline, '#')
   if (i EQ 0) then sline = '' $
    else if (i GE 0) then sline = strmid(sline, 0, i-1)

   i = strpos(sline, ',')
   while (i NE -1) do begin
      strput, sline, ' ', i
      i = strpos(sline, ',')
   endwhile

   i = strpos(sline, ';')
   while (i NE -1) do begin
      strput, sline, ' ', i
      i = strpos(sline, ';')
   endwhile

   sline = strtrim(strcompress(sline),2)

   return, sline
end
;------------------------------------------------------------------------------
; Procedure to read the next line from a file into a string, but work even
; if the last non-whitespace character is a backslash (READF will fail on
; that).  Note that the line cannot be more than 255 characters long.

pro yanny_readstring, ilun, sline

   sarray = strarr(255)
   readf, ilun, sarray, format='(255a1)'

   sline = string(' ', format='(a255)')
   for i=0, 254 do strput, sline, sarray[i], i

end
;------------------------------------------------------------------------------
; Read the next line from the input file, appending several lines if there
; are continuation characters (backslashes) at the end of lines.

function yanny_nextline, ilun
   sline = ''
   yanny_readstring, ilun, sline
   sline = strtrim(sline) ; Remove only trailing whitespace
   nchar = strlen(sline)
   while (strmid(sline, nchar-1) EQ '\') do begin
      strput, sline, ' ', nchar-1 ; Replace the '\' with a space
      yanny_readstring, ilun, stemp
      stemp = strtrim(stemp) ; Remove only trailing whitespace
      sline = sline + stemp
      nchar = strlen(sline)
   endwhile

   return, sline
end
;------------------------------------------------------------------------------
; Append another pointer NEWPTR to the array of pointers PDATA.
; Also add its name to PNAME.

pro add_pointer, stname, newptr, pcount, pname, pdata, pnumel

   if (pcount EQ 0) then begin
      pname = stname
      pdata = newptr
      pnumel = 0L
   endif else begin
      pname = [pname, stname]
      pdata = [pdata, newptr]
      pnumel = [pnumel, 0L]
   endelse

   pcount = pcount + 1

   return
end
;------------------------------------------------------------------------------
pro yanny_read, filename, pdata, hdr=hdr, enums=enums, structs=structs, $
 quick=quick

   if (N_params() LT 1) then begin
      print, 'Syntax - yanny_read, filename, [ pdata, hdr=hdr, enums=enums, $
      print, ' structs=structs, /quick ]'
      return
   endif

   tname = ['char', 'short', 'int', 'long', 'float', 'double']
   tvals = ['""'  , '0'    , '0'  , '0L'  , '0.0'  , '0.0D'  ]
   tarrs = ['strarr(' , $
            'intarr(' , $
            'intarr(' , $
            'lonarr(' , $
            'fltarr(' , $
            'dblarr(' ]

   hdr = 0
   enums = 0
   structs = 0

   ; List of all possible structures
   pcount = 0       ; Count of structure types defined
   pname = 0        ; Name of each structure
   pdata = 0        ; Pointer to each structure
   pnumel = 0       ; Number of elements in each structure

   nline = numlines(filename)
   get_lun, ilun
   openr, ilun, filename
   rawline = ''

   ; Read the very first line
   if (keyword_set(quick)) then readf, ilun, rawline $
    else rawline = yanny_nextline(ilun)

   while (NOT eof(ilun)) do begin
      qdone = 0 ; Set to 1 when this line is anything other than a hdr line
      sline = yanny_strip_commas(rawline)
      words = str_sep(sline, ' ') ; Divide into words based upon whitespace
      nword = N_elements(words)
      if (nword GE 2) then begin

         ; LOOK FOR "typedef enum" lines and add to structs
         if (words[0] EQ 'typedef' AND words[1] EQ 'enum') then begin

            while (strmid(sline,0,1) NE '}') do begin
               yanny_add_comment, rawline, enums
               if (keyword_set(quick)) then readf, ilun, rawline $
                else rawline = yanny_nextline(ilun)
               sline = yanny_strip_commas(rawline)
            endwhile

            yanny_add_comment, rawline, enums

            if (keyword_set(quick)) then readf, ilun, rawline $
             else rawline = yanny_nextline(ilun)
            qdone = 1

         ; LOOK FOR STRUCTURES TO BUILD with "typedef struct"
         endif else if (words[0] EQ 'typedef' AND words[1] EQ 'struct') $
          then begin

            ntag = 0
            yanny_add_comment, rawline, structs
            if (keyword_set(quick)) then readf, ilun, rawline $
             else rawline = yanny_nextline(ilun)
            sline = yanny_strip_commas(rawline)

            while (strmid(sline,0,1) NE '}') do begin
               sline = strcompress(sline)
               ww = str_sep(sline, ' ')

               if (N_elements(ww) GE 2) then begin
                  i = where(ww[0] EQ tname, ct)
                  i = i[0]

                  ; If the type is "char", then remove the string length
                  ; from the defintion, since IDL does not need a string
                  ; length.  For example, change "char foo[20]" to "char foo",
                  ; or change "char foo[10][20]" to "char foo[10]".
                  if (i EQ 0) then begin
                     j1 = rstrpos(ww[1], '[')
                     if (j1 NE -1) then ww[1] = strmid(ww[1], 0, j1)
                  endif

                  ; Force an unknown type to be a "char"
                  if (i[0] EQ -1) then i = 0

                  ; Test to see if this should be an array
                  ; (Only 1-dimensional arrays supported here.)
                  j1 = strpos(ww[1], '[')
                  if (j1 NE -1) then begin
                     addname = strmid(ww[1], 0, j1)
                     j2 = strpos(ww[1], ']')
                     addval = tarrs[i] + strmid(ww[1], j1+1, j2-j1-1) + ')'
                  endif else begin
                     addname = ww[1]
                     addval = tvals[i]
                  endelse

                  if (ntag EQ 0) then begin
                     names = addname
                     values = addval
                  endif else begin
                     names = [names, addname]
                     values = [values, addval]
                  endelse

                  ntag = ntag + 1
               endif

               yanny_add_comment, rawline, structs
               if (keyword_set(quick)) then readf, ilun, rawline $
                else rawline = yanny_nextline(ilun)
               sline = yanny_strip_commas(rawline)
            endwhile

            yanny_add_comment, rawline, structs

            ; Now for the structure name - get from the last line read
            ; Force this to uppercase
            stname = strupcase( strtrim(strmid(sline,1), 2) )

            ; Create the actual structure
            add_pointer, stname, $
             ptr_new( mrd_struct(names, values, 1, structyp=stname) ), $
             pcount, pname, pdata, pnumel

            if (keyword_set(quick)) then readf, ilun, rawline $
             else rawline = yanny_nextline(ilun)

            qdone = 1

         ; LOOK FOR A STRUCTURE ELEMENT
         ; Only look if some structures already defined
         ; Note that the structure names should be forced to uppercase
         ; such that they are not case-sensitive.
         endif else if (pcount GT 0) then begin
            idat = where(strupcase(words[0]) EQ pname[0:pcount-1], ct)
            if (ct EQ 1) then begin
               idat = idat[0]
               ; Add an element to the idat-th structure
               ; Note that if this is the first element encountered,
               ; then we already have an empty element defined.
               if (pnumel[idat] GT 0) then $
                *pdata[idat] = [*pdata[idat], (*pdata[idat])[0]]

               ; Split this text line into words
               sline = strcompress( yanny_strip_brackets(sline) )
               ww = str_sep(sline, ' ')
               i = 1 ; Counter for which word we're currently reading
                     ; Skip the 0-th word since it's the structure name.

               ; Now fill in this structure from the line of text
               ntag = N_tags( *pdata[idat] )
               for itag=0, ntag-1 do begin
                  ; This tag could be an array - see how big it is
                  sz = N_elements( (*pdata[idat])[0].(itag) )
                  for j=0, sz-1 do begin
                     (*pdata[idat])[pnumel[idat]].(itag)[j] = ww[i]
                     i = i + 1
                  endfor
               endfor

               pnumel[idat] = pnumel[idat] + 1
               qdone = 1
               if (keyword_set(quick)) then readf, ilun, rawline $
                else rawline = yanny_nextline(ilun)
            endif
         endif

      endif

      if (qdone EQ 0) then begin
         yanny_add_comment, rawline, hdr
         if (keyword_set(quick)) then readf, ilun, rawline $
          else rawline = yanny_nextline(ilun)
      endif
   endwhile

   close, ilun

   ; Trim the pointers to only those that exist

   return
end
;------------------------------------------------------------------------------
