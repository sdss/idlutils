;+
; NAME:
;   rmfile
;
; PURPOSE:
;   Delete file from disk.
;
; CALLING SEQUENCE:
;   rmfile, filename
;
; INPUTS:
;   filename   - File to delete.
;
; OUTPUTS:
;
; COMMENTS:
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   14-Oct-1999  Written by D. Schlegel, APO
;-
;------------------------------------------------------------------------------

pro rmfile, filename

   get_lun, ilun
   openr, ilun, filename, /delete, error=err
   if (err NE 0) then message, !err_string, /informational
   close, ilun
   free_lun, ilun

   return
end
