;-----------------------------------------------------------------------
;+
; NAME:
;   djs_unlockfile
;
; PURPOSE:
;   Unlock a file if locked with DJS_LOCKFILE().
;
; CALLING SEQUENCE:
;   djs_unlockfile, filename, [lun= ]
;
; INPUT:
;   filename:   File name
;
; OPTIONAL INPUTS:
;   lun:        If this argument exists, then close the file associated
;               with this LUN number.  This is useful if FILENAME has
;               been opened with DJS_LOCKFILE().
;
; OUTPUTS:
;
; COMMENTS:
;   We use a lock file, which has a single byte written to it, to indicate
;   that FILENAME has been locked by DJS_LOCKFILE().  This routine deletes
;   that file.
;
; BUGS:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   30-Apr-2000  Written by D. Schlegel, APO
;-
;-----------------------------------------------------------------------
pro djs_unlockfile, filename, lun=lun

   lockfile = filename + '.lock'
   openw, olun, lockfile, /get_lun, /delete
   close, olun
   free_lun, olun

   if (arg_present(lun)) then begin
      close, lun
      free_lun, lun
   endif

   return
end
;-----------------------------------------------------------------------
