;+
; NAME:
;   yanny_read
;
; PURPOSE:
;   Write a Yanny parameter file.
;
; CALLING SEQUENCE:
;   yanny_write, filename, [ pdata, hdr=hdr, enums=enums, structs=structs ]
;
; INPUTS:
;   filename   - Output file name for Yanny parameter file
;
; OPTIONAL INPUTS:
;   pdata      - Array of pointers to all strucutures read.  The i-th data
;                structure is then referenced with "*pdata[i]"
;   hdr        - Header lines in Yanny file, which are usually keyword pairs.
;   enums      - All "typedef enum" structures.
;   structs    - All "typedef struct" structures, which define the form
;                for all the PDATA structures.
;   quick      - Quicker read using READF, but fails if continuation lines
;                are present.
;
; OUTPUT:
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;
; EXAMPLES:
;   Read a Yanny parameter file, then re-write as a different file with:
;     yanny_read, 'testin.par', pdata, comments=comments
;     yanny_write, 'testout.par', pdata, comments=comments
;
; BUGS:
;   There is no testing that STRUCTS is consistent with PDATA.
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   05-Sep-1999  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------
pro yanny_write, filename, pdata, hdr=hdr, enums=enums, structs=structs

   if (N_params() LT 1) then begin
      print, 'Syntax - yanny_write, filename, [ pdata, hdr=hdr, enums=enums, structs=structs]'
      return
   endif

   tname = ['char', 'short', 'int', 'long', 'float', 'double']
   idlname = ['STRING', 'BYTE', 'INT', 'LONG', 'FLOAT', 'DOUBLE']

   get_lun, olun
   openw, olun, filename

   ; Write the header of the Yanny file
   if (keyword_set(hdr)) then begin
      for i=0, N_elements(hdr)-1 do begin
         if (hdr[i] NE '') then printf, olun, hdr[i]
      endfor
      printf, olun, ''
   endif

   ; Write the "typedef enum" lines of the Yanny file
   if (keyword_set(enums)) then begin
      for i=0, N_elements(enums)-1 do begin
         if (enums[i] NE '') then printf, olun, enums[i]
      endfor
      printf, olun, ''
   endif

   ; Write the "typedef struct" lines of the Yanny file
   if (keyword_set(structs)) then begin
      for i=0, N_elements(structs)-1 do begin
         if (structs[i] NE '') then printf, olun, structs[i]
      endfor
      printf, olun, ''
   endif else begin
      ; The "typedef struct" lines were not passed to this routine,
      ; so generate those lines consistent with the data structures passed.
      if (keyword_set(pdata)) then begin
         for idat=0, N_elements(pdata)-1 do begin
            ntag = N_tags( *pdata[idat] )
            tags = tag_names( *pdata[idat] )
            stname = tag_names( *pdata[idat], /structure_name)
            if (stname EQ '') then stname = 'STRUCT' + strtrim(string(idat+1),2)

            printf, olun, 'typedef struct {'

            for itag=0, ntag-1 do begin          ; Loop through each variable
               tt = size( (*pdata[idat])[0].(itag), /tname )
               dims = size( (*pdata[idat])[0].(itag), /dimens )
               ndim = size( (*pdata[idat])[0].(itag), /n_dimen )
               tagname = tname[(where(idlname EQ tt))[0]]

               sline = ' ' + tagname + ' ' + tags[itag]
               for j=0, ndim-1 do begin
                  sline = sline + '[' + strtrim(string(dims[j]),2) + ']'
               endfor
               if (tagname EQ 'char') then $
                sline = sline + '[' $
                + strtrim(string(max(strlen((*pdata[idat]).(itag)))+1),2) + ']'
               sline = sline + ';'

               printf, olun, sline
            endfor

            printf, olun, '} ' + stname + ';'
            printf, olun, ''

         endfor
      endif
   endelse

   ; Write the data in the Yanny file
   if (keyword_set(pdata)) then begin
      for idat=0, N_elements(pdata)-1 do begin
         printf, olun, ''

         ntag = N_tags( *pdata[idat] )
         stname = tag_names( *pdata[idat], /structure_name)
         if (stname EQ '') then stname = 'STRUCT' + strtrim(string(idat+1),2)

         for iel=0, N_elements( *pdata[idat] )-1 do begin ; Loop thru each row

            sline = stname

            for itag=0, ntag-1 do begin          ; Loop through each variable
               sz = N_elements( (*pdata[idat])[iel].(itag) )
               if (sz EQ 1) then begin
                  sline = sline + ' ' + string( (*pdata[idat])[iel].(itag) )
               endif else begin
                  sline = sline + ' {'
                  for i=0, N_elements( (*pdata[idat])[iel].(itag) )-1 do $
                   sline = sline + ' ' + string( (*pdata[idat])[iel].(itag)[i] )
                  sline = sline + ' }'
               endelse
            endfor
            sline = strcompress(sline)
            printf, olun, sline
         endfor

      endfor
   endif

   close, olun
   free_lun, olun

   return
end
;------------------------------------------------------------------------------
