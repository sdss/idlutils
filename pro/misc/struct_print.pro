;+
; NAME:
;   struct_print
;
; PURPOSE:
;   Formatted print of a structure to either standard out or to a file.
;
; CALLING SEQUENCE:
;   struct_print, struct, [ lun=, filename= ]
;
; INPUTS:
;   struct     - Structure
;
; OPTIONAL INPUTS:
;   filename   - Output file name; open and close this file
;   lun        - LUN number for an output file if one is already open
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   If neither FILENAME or LUN is set, then write to the standard output.
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   01-Nov-2000  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------
pro struct_print, struct, filename=filename, lun=lun

   if (keyword_set(filename)) then $
    openw, lun, filename, /get_lun

   if (NOT keyword_set(lun)) then lun = -1

   fdigit = 5
   ddigit = 7

   if (size(struct,/tname) NE 'STRUCT') then return
   nrow = n_elements(struct)
   if (nrow EQ 0) then return

   tags = tag_names(struct)
   ntag = n_elements(tags)

   ;----------
   ; Construct the header lines and format string

   for itag=0L, ntag-1 do begin
      narr = n_elements(struct[0].(itag))
      for iarr=0L, narr-1 do begin

         if (itag EQ 0 AND iarr EQ 0) then begin
            hdr1 = ''
            hdr2 = ''
            format = '('
         endif else begin
            hdr1 = hdr1 + ' '
            hdr2 = hdr2 + ' '
            format = format + ',1x,'
         endelse

         thisname = tags[itag]
         if (narr GT 1) then thisname = thisname + strtrim(string(iarr),2)

         tname = size(struct[0].(itag),/tname)
         if (tname EQ 'BYTE' OR tname EQ 'INT' OR tname EQ 'LONG' $
          OR tname EQ 'LONG64' OR tname EQ 'UINT' OR tname EQ 'ULONG' $
          OR tname EQ 'ULONG64') then begin
            minval = min( struct.(itag)[iarr] )
            maxval = max( struct.(itag)[iarr] )

            nchar = strlen(strtrim(string(minval),2)) $
             > strlen(strtrim(string(maxval),2))
            nchar = nchar > strlen(thisname)
            thiscode = 'I' + strtrim(string(nchar),2)
         endif else if (tname EQ 'FLOAT') then begin
            minval = min( struct.(itag)[iarr] )
            if (minval LT 0) then nchar = fdigit + 7 $
             else nchar = fdigit + 6
            nchar = nchar > strlen(thisname)
            thiscode = 'G' + strtrim(string(nchar),2) + '.' $
             + strtrim(string(fdigit),2)
         endif else if (tname EQ 'DOUBLE') then begin
            minval = min( struct.(itag)[iarr] )
            if (minval LT 0) then nchar = ddigit + 7 $
             else nchar = ddigit + 6
            nchar = nchar > strlen(thisname)
            thiscode = 'G' + strtrim(string(nchar),2) + '.' $
             + strtrim(string(ddigit),2)
         endif else if (tname EQ 'STRING') then begin
            nchar = max(strlen( struct.(itag)[iarr] )) > strlen(thisname)
            thiscode = 'A' + strtrim(string(nchar),2)
         endif else begin
            message, 'Unsupported type code: ' + tname
         endelse

         schar = strtrim(string(nchar),2)
         hdr1 = hdr1 + string(thisname, format='(a' + schar + ')')
         hdr2 = hdr2 + string(replicate('-',nchar), $
          format='(' + schar + 'a)')
         format = format + thiscode

      endfor
   endfor

   format = format + ')'

   ;----------
   ; Now print one row at a time

   printf, lun, hdr1
   printf, lun, hdr2
   for irow=0L, nrow-1 do begin
      printf, lun, struct[irow], format=format
   endfor

   if (keyword_set(filename)) then $
    close, lun

   return
end
;------------------------------------------------------------------------------
