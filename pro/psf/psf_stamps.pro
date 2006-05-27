;+
; NAME:
;   psf_stamps
;
; PURPOSE:
;   Cut out postage stamps around stars of interest
;
; CALLING SEQUENCE:
;   stamps = psf_stamps(image, ivar, px, py, par, shift=, dx=, dy=, $
;                                       stampivar=stampivar
; INPUTS:
;   image      - image to locate stars in
;   ivar       - inverse variance image -- must be correctly
;                calibrated, or some of the algorithms will NOT WORK!
;   p{x,y}     - integer (X,Y) positions from psf_findstars
;   par        - parameter structure (see psf_par.pro)
;
; OPTIONAL INPUTS:
;   
; KEYWORDS:
;   shift      - do a sub-pixel shift with psf_stamp_center_iter
;
; OUTPUTS:
;   stamps     - array of stamps [par.boxrad*2+1, par.boxrad*2+1, nstar]
;   stampivar  - ivar stamps corresponding to stamps
;   d{x,y}     - sub-pixel shift (add to px,py for 0-indexed location)
;   p{x,y}     - may be modified to include only stars where the
;                center pixel is the brightest.
;
; RESTRICTIONS:
;   
; EXAMPLES:
;   
; COMMENTS:
;   This code handles image edges correctly, even though you probably
;    do not want those stars.
;   calls stamp_center_iter()
;
; REVISION HISTORY:
;   2006-May-25  Written by Douglas Finkbeiner, Princeton
;
;----------------------------------------------------------------------
function psf_stamps, image, ivar, px, py, par, shift=shift, dx=dx, dy=dy, $
                         stampivar=stampivar

  rad    = par.cenrad           ; box rad. used for center and norm
  sz     = size(image, /dim)
  boxrad = par.boxrad           ; postage stamp size is boxrad*2+1
  box    = boxrad*2+1
  nstar  = n_elements(px)       ; number of stars
  
  arr       = fltarr(box, box, nstar)
  stampivar = fltarr(box, box, nstar)

  x0 = (px-boxrad) > 0
  x1 = (px+boxrad) < (sz[0]-1)
  y0 = (py-boxrad) > 0
  y1 = (py+boxrad) < (sz[1]-1)
  
  sx0 = x0-px+boxrad
  sx1 = x1-px+boxrad
  sy0 = y0-py+boxrad
  sy1 = y1-py+boxrad

  dx = fltarr(nstar)            ; sub-pixel offsets
  dy = fltarr(nstar)

  for i=0L, nstar-1 do begin 
     stamp = fltarr(box, box)
     sivar = fltarr(box, box)
     stamp[sx0[i]:sx1[i], sy0[i]:sy1[i]] = image[x0[i]:x1[i], y0[i]:y1[i]]
     sivar[sx0[i]:sx1[i], sy0[i]:sy1[i]] = ivar[x0[i]:x1[i], y0[i]:y1[i]]

     if keyword_set(shift) then begin 
        stampcen = stamp_center_iter(stamp, rad, maxiter=10, $
                                  dx=dx0, dy=dy0)
        subtot = psf_norm(stampcen, par.cenrad)
        dx[i]=dx0 & dy[i]=dy0
        stamp = temporary(stampcen)

     endif else begin 
        subtot = psf_norm(stamp, par.cenrad)
     endelse

     arr[*, *, i] = stamp/subtot
     stampivar[*, *, i] = sivar*subtot^2

  endfor

; -------- reject those where central pixel is not the highest.

  cenbrt = bytarr(nstar)
  for i=0L, nstar-1 do cenbrt[i] = max(arr[*, *, i]) EQ arr[boxrad, boxrad, i]
  wbrt = where(cenbrt, nbrt)

  if nbrt EQ 0 then message, 'no stars are bright - this is BAD.'
  arr = arr[*, *, wbrt]
  stampivar = stampivar[*, *, wbrt]
  px = px[wbrt]
  py = py[wbrt]
  dx = dx[wbrt]
  dy = dy[wbrt]

  return, arr
end
