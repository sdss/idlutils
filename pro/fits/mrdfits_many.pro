;-----------------------------------------------------------------------
;+
; NAME:
;   mrdfits_many
;
; PURPOSE:
;   Read in and append many FITS binary tables to a single structure.
;
; CALLING SEQUENCE:
;   res = mrdfits_many(files, [ exten, _EXTRA= ])
;
; INPUTS:
;   files     - File names, or expression for matching file names
;
; OPTIONAL INPUTS:
;   exten     - Extension number; default to 1
;   _EXTRA    - Keywords for MRDFITS
;
; OUTPUTS:
;   res       - Output structure
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   This will only work if all of the structure types are identical.
;
; EXAMPLES:
;
; BUGS:
;   This could be made to be robust to data structures that are not
;   identical format.
;
; PROCEDURES CALLED:
;   mrdfits()
;
; REVISION HISTORY:
;   14-Jun-2017  Written by David Schlegel, Berkeley Lab
;-
;------------------------------------------------------------------------------
function mrdfits_many, files, exten1, _EXTRA=EXTRA

   ; Need at least 1 parameter
   if (N_params() LT 1) then begin
      print, 'Syntax - res = mrdfits_many(files)'
      return, 0
   endif
   if (n_elements(exten1) GT 0) then exten = exten1[0] $
    else exten = 1

   ;----------
   ; Find the file names

   if (n_elements(files) EQ 1) then $
    allfiles = file_search(files, count=nfile) $
   else $
    allfiles = files
   nfile = n_elements(allfiles)

   ; Count the total number of elements in all files
   nper = lonarr(nfile)
   for i=0L, nfile-1L do begin
print,i,string(13b),format='(i6,a,$)'
      hdr1 = headfits(allfiles[i], exten=exten)
      if (size(hdr1,/tname) EQ 'STRING') then $
       nper[i] = sxpar(hdr1, 'NAXIS2')
      if (nper[i] GT 0 AND keyword_set(res1) EQ 0) then $
       res1 = mrdfits(allfiles[i], exten, range=[0,0], _EXTRA=EXTRA, /silent)
   endfor
print
   ntot = total(nper)

   ; Create the blank output structure
   if (keyword_set(res1) EQ 0) then return, 0
   struct_assign, {junk:0}, res1
   res = replicate(res1, ntot)

   ; Now loop over and read the data
   ntot = 0L
   for i=0L, nfile-1L do begin
print,i,string(13b),format='(i6,a,$)'
      if (nper[i] GT 0) then begin
         res1 = mrdfits(allfiles[i], exten, _EXTRA=EXTRA, /silent)
         if (n_elements(res1) NE nper[i]) then $
          message, 'File length changed between access times '+allfiles[i]
         res[ntot:ntot+nper[i]-1] = res1
         ntot += nper[i]
      endif
   endfor
print

   return, res
end 
;------------------------------------------------------------------------------
