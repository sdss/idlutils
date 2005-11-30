;+
; NAME:
;   find_sb
; PURPOSE:
;   Find objects in a 2-d image with a gaussian filter
; CALLING SEQUENCE
;   find_sb, sub, wt, x=x, y=y, flux=flux, $
;       [sigma=, hpix=, hmin=]
; INPUTS:
;   sub         - skysubtracted image 
;   wt          - inverse variance weight (0 or 1 for CR mask is OK)
; OPTIONAL INPUTS:
;   sigma       - sigma of gaussian filter in pixels
;   hpix        - half-pixel width of convolution filter  (2 is default)
;   hmin        - minimum flux threshold
; KEYWORDS:
; OUTPUTS:
;   x           - column pixel position of flux peak (sorted be decreasing flux)
;   y           - row pixel position                  "
;   flux        - gaussian filtered flux estimate
; COMMENTS:
; DEPENDENCIES:
;   idlutils
; BUGS:
;   No checks on neighboring peaks
;   Not tested yet with real inverse variance weighting
; REVISION HISTORY:
;   2005-11-30  Written - Burles
;-
pro find_sb, sub, wt, x=x, y=y, flux=flux, sigma=sigma, hpix=hpix, hmin=hmin
 
  if NOT keyword_set(sigma) then sigma = 1.0
  if NOT keyword_set(hpix ) then hpix = 2L

  npix = 2*hpix + 1L
  k = gauss_kernel(sigma, hpix=2) 
  k2 = k # k

  denom = convol(wt, k2^2)
  f = convol(sub*wt, k2) / (denom + (denom EQ 0))

  mask = smooth(1.0*(wt LE 0),3) EQ 0   ; grow the wt EQ 0 mask

  h = f*mask
  if max(h) LE 0 then return

  if NOT keyword_set(hmin) then $
     hmin = 20. * mean(abs(h - median(h)))

  index = where(h GE hmin, nfound)
  
  n_x = (size(sub))[1]
  r = sqrt((findgen(npix)-hpix)^2 # replicate(1,npix) + $
      (findgen(npix)-hpix)^2 ## replicate(1,npix))
  good = where(r LE 1.5*sigma AND r GT 0, npixels)
  offset = (good mod npix) - hpix + ((good /npix) - hpix) * n_x

  for i=0, n_elements(offset)-1L do begin & $
     stars = where( f[index] GE  f[index+offset[i]], nfound) & $
     if nfound LE 0 then break & $
     index = index[stars] & $
  endfor

  print, 'Checking ', nfound, ' peaks'

  xcurv = 1.0 - 0.5*(f[index-1] + f[index+1])/f[index] 
  ycurv = 1.0 - 0.5*(f[index-n_x] + f[index+n_x])/f[index] 

  keep = where( xcurv LT 0.4 AND ycurv LT 0.4 AND xcurv GT 0 AND ycurv GT 0 $
                  AND abs(xcurv-ycurv) LT 0.2, nkeep)

  if nkeep EQ 0 then return

  really_keep = where(abs(alog(xcurv[keep]/ycurv[keep])) LT 1.0, nkeep)
  if nkeep EQ 0 then return
  keep = keep[really_keep]

  print, 'Keeping ', nkeep, ' peaks'

  ik = index[keep]

  xs = (f[ik+1] - f[ik-1]) / xcurv[keep] / f[ik] / 4.
  ys = (f[ik+n_x] - f[ik-n_x]) / ycurv[keep] / f[ik] / 4.
  x = (ik mod n_x) + xs
  y = (ik / n_x) + ys
  flux = f[ik] * ( 1.0 + xcurv[keep] * xs^2 + ycurv[keep] * ys^2 )

  s_f = reverse(sort(flux))

  x = x[s_f]
  y = y[s_f]
  flux = flux[s_f]

  return
end
