;+
; NAME:
;   yanny_read
;
; PURPOSE:
;   Write a Yanny parameter file.
;
; CALLING SEQUENCE:
;   yanny_write, filename, [ pdata, comments=comments ]
;
; INPUTS:
;   filename   - Output file name for Yanny parameter file
;
; OPTIONAL INPUTS:
;   pdata      - Array of pointers to all strucutures read.  The i-th data
;                structure is then referenced with "*pdata[i]"
;   comments   - All non-data lines.
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
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   05-Sep-1999  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------
pro yanny_write, filename, pdata, comments=comments

   if (N_params() LT 1) then begin
      print, 'Syntax - yanny_write, filename, [ pdata, comments=comments ]'
      return
   endif

   get_lun, olun
   openw, olun, filename

   ; Write the header of the Yanny file
   if (keyword_set(comments)) then begin
      for i=0, N_elements(comments)-1 do begin
         printf, olun, comments[i]
      endfor
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
