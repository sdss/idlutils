;+
; NAME:
;   ishealpix
;
; PURPOSE:
;   Determine if array represents a healpix image
;
; CALLING SEQUENCE:
;   type = ishealpix(image)
;
; INPUTS:
;   image   - input array to be tested
;
; KEYWORDS:
;   silent  - suppress messages. 
;   true    - test for true color (not implemented)
;
; OUTPUTS:
;   type    - image type; 1=healpix, 0=not healpix
;
; COMMENTS:
;   Define healpix as an array of 12*2^(2*N) pixels for pos. integer N.
;   A looser definition is possible for ring ordering, but not for
;    nested ordering. 
;   
; REVISION HISTORY:
;   2003-Dec-05   Written by Douglas Finkbeiner, Princeton
;
;----------------------------------------------------------------------
function ishealpix, image, silent=silent

; -------- criterion for image being healpix
  
  npix = n_elements(image)
  nside = round(sqrt(npix/12))
  nlevel = round(alog(nside)/alog(2))

  if npix eq (12*2L^(2*nlevel)) then begin 
     if NOT keyword_set(silent) then $
       print, 'Assuming image is HEALPix, Nside:', nside
     return, 1B
  endif else begin 
     return, 0B
  endelse 

end
