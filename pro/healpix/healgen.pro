; Generate theta, phi for an nside HEALPIX projection
; DPF 27 Feb 1999

; input nside (usually a power of 2)
; output theta, phi in radians.  theta=0 is north pole

; D. Finkbeiner 8 Mar 1999 modified to do loop
; 17 Sep 2002 added nest keyword - DPF
; 19 Feb 2003 double keyword added - DPF
; 12 Nov 2003 cache outputs - DPF
PRO healgen, nside, theta, phi, nest=nest, double=double

  common healgen_common, nside_save, theta_save, phi_save, nest_save, $
    double_save

  IF keyword_set(nside) EQ 0 THEN BEGIN 
      print, '  CALL with nside:   healgen, nside, theta, phi'
      return
  ENDIF 

; Is nside too big?
  IF nside GT 8192 THEN BEGIN 
      print, '---> ERROR: NSIDE too large.'
      print, '     Routine not implemented with type long64 yet'
      return
  ENDIF 

  if keyword_set(nside_save) then begin 
     if (nside eq nside_save) AND (keyword_set(nest) eq nest_save) $
       AND (keyword_set(double) eq double_save) then begin 
        theta = theta_save
        phi = phi_save
        return
     endif 
  endif 

  npix = 12*long(nside)^2
  ipix = lindgen(npix)

; Do a loop to avoid allocating too much RAM
  chunk  = npix/12
  nchunk = long(12)
  if keyword_set(double) then begin 
     theta  = dblarr(npix)
     phi    = dblarr(npix)
  endif else begin 
     theta  = fltarr(npix)
     phi    = fltarr(npix)
  endelse

  FOR i=long(0), long(nchunk-1) DO BEGIN 
      lo = i*chunk
      hi = (i+1)*chunk
      if keyword_set(nest) then begin 
         pix2ang_nest, nside, ipix[lo:hi-1], theta1, phi1
      endif else begin 
         pix2ang_ring, nside, ipix[lo:hi-1], theta1, phi1
      endelse 
      phi[lo:hi-1] = phi1
      theta[lo:hi-1] = theta1
  ENDFOR 

; -------- cache outputs
  nside_save  = nside
  nest_save   = keyword_set(nest)
  double_save = keyword_set(double)
  phi_save    = phi
  theta_save  = theta


  return
END
