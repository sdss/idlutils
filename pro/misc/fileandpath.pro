;+
; NAME:
;   fileandpath
;
; PURPOSE:
;   Split a file name into the path and the file name.
;
; CALLING SEQUENCE:
;   filename = fileandpath(fullname, [path= ])
;
; INPUTS:
;   fullname   - File name which may include disk and/or directory
;                specifications.
;
; OUTPUT:
;   filename   - File name without any disk or directory specifications.
;
; OPTIONAL OUTPUT:
;   path       - Disk and directory specification.
;
; COMMENTS:
;   This routine is meant to absorb any operating system dependencies.
;
; EXAMPLES:
;   For Unix:
;   IDL> print, fileandpath('data/all/one.dat', path=path)
;        one.dat
;   IDL> print, path
;        data/all
;
; BUGS:
;
; PROCEDURES CALLED:
;   fdecomp
;
; REVISION HISTORY:
;   30-May-2000  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------

function fileandpath, fullname, path=path

   ; If FULLNAME is an array, then call this routine recursively
   nname = n_elements(fullname)
   if (nname GT 1) then begin
      filename = strarr(nname)
      path = strarr(nname)
      for i=0, nname-1 do begin
         filename[i] = fileandpath(fullname[i], path=tmp_path)
         path[i] = tmp_path
      endfor
      return, filename
   endif

   fdecomp, fullname, disk, dir, name, qual, vers
   filename = name
   if (keyword_set(qual)) then filename = filename + '.' + qual
   if (keyword_set(vers)) then filename = filename + ';' + vers

   if (arg_present(path)) then begin
      path = disk + dir
   endif

   return, filename
end
;------------------------------------------------------------------------------
