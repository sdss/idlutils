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
;   Need to write STRUCTS that is consistent with PDATA, even if not passed.
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
   endif

   ; Write the data in the Yanny file
   if (keyword_set(pdata)) then begin
      for idat=0, N_elements(pdata)-1 do begin
         ntag = N_tags( *pdata[idat] )
         stname = tag_names( *pdata[idat], /structure_name)

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

   return
end
;------------------------------------------------------------------------------
