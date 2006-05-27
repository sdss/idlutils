;+
; NAME:
;   psf_stamp_center_iter
;
; PURPOSE:
;   Find sinc shift (dx,dy) such that central pixels are symmetric
;
; CALLING SEQUENCE:
;   shifted_image = psf_stamp_center_iter(image, rad, maxiter=, dx=, dy=, $
;                                         center= )
; INPUTS:
;   image       - postage stamp to shift
;   rad         - radius of box for flux-weighted center
; 
; OPTIONAL INPUTS:
;   maxiter     - number of iterations (Default 5)
;   center      - optional input (x,y) position of center.  
;                  Otherwise, assume center of stamp.
;
; OUTPUTS:
;   d{x,y}      - sub-pixel offsets. 
;
; EXAMPLES:
;   see psf_stamps.pro
;
; RESTRICTIONS:
;   rad=0 should mean center on sinc-interpolated peak, but this is
;    not implemented yet.
;
; COMMENTS:
;   One could also use the sinc-interpolated peak as the center. 
;    This is thought to be slightly more robust.  
;
; REVISION HISTORY:
;   2006-May-25   Written by Douglas Finkbeiner, Princeton
;
;----------------------------------------------------------------------
function psf_stamp_center_iter, image, rad, maxiter=maxiter, dx=dx, dy=dy, $
              center=center

; -------- defaults
  if NOT keyword_set(rad) then message, 'must set rad'
  if NOT keyword_set(maxiter) then maxiter = 5

; -------- check inputs
  sz = size(image, /dimen)
  if NOT keyword_set(center) then begin 
     cen = (sz-1)/2
     if array_equal(cen, (sz-1)/2.) eq 0 then message, 'pass arrays of odd dimension'
     if rad GT min(cen) then message, 'rad too big'
     center = cen
  endif

  dx = 0
  dy = 0
; -------- check center not too close to edge
  if min(center) LT 2 or max(center) GT (sz[0]-3) then begin 
     print, 'center near edge of box'
     return, image
  endif 

  shifted_image = image

; -------- find flux-weighted center, sinc shift, iterate
  xwt = transpose(findgen(2*rad+1)-rad) ; column vector

  for i=1L, maxiter do begin 
     subimg = shifted_image[center[0]-rad:center[0]+rad, center[1]-rad:center[1]+rad]
     subtot = total(subimg)
     dx0 = (xwt # total(subimg,2) / subtot)[0]*1.1
     dy0 = (xwt # total(subimg,1) / subtot)[0]*1.1
     dx = dx+dx0
     dy = dy+dy0
;     print, i, dx, dy, dx0, dy0
     if (abs(dx) > abs(dy)) lt 1 then shifted_image = sshift2d(image, -[dx, dy])
  endfor 

  return, shifted_image
end
