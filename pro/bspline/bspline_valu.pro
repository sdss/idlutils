;+
; NAME:
;   bspline_valu
;
; PURPOSE:
;      1) Evaluate a bspline set (see create_bsplineset) at specified
;            x and x2 arrays
;
; CALLING SEQUENCE:
;   
;   yfit  = bspline_valu( x, sset, x2=x2, action=action, indx=indx)
;
; INPUTS:
;   x          - independent variable
;   sset       - Structure to be returned with all fit parameters
;
; RETURNS:
;   yfit       - Evaluated b-spline fit
;
; OPTIONAL KEYWORDS:
;   x2         - Orthogonal dependent variable for 2d fits
;   action     - This keyword is overwritten with b-spline action matrix
;   indx       - The index of bkpt which is just left of x[i], needed to
;                  complete banded algebra
;
; COMMENTS:
;
; EXAMPLES:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   11-Sep-2000 Written by Scott Burles, FNAL
;-
;------------------------------------------------------------------------------
function bspline_valu, x, sset, x2=x2, action=action, indx=indx

      if size(sset,/tname) NE 'STRUCT' then begin
         print, 'Please send in a proper B-spline structure'
         return, -1
      endif

      xsort = sort(x)
      npoly = 1L
      xwork = x[xsort]

      if keyword_set(x2) then begin
        if ((where(tag_names(sset) EQ 'NPOLY'))[0] NE -1) then $
           npoly=sset.npoly
        x2work = x2[xsort]
      endif else x2work = 0

      if NOT keyword_set(action) then $
           action = bspline_action(xwork, sset, x2=x2work)
 
      nx = n_elements(x)
      yfit = x * 0.0
      nord = sset.nord
      bw = npoly * nord


      spot = lindgen(bw)
      goodbk = where(sset.bkmask NE 0, nbkpt) 
      coeffbk = where(sset.bkmask[nord:*] NE 0) 
      n = nbkpt - nord

      
      sc = size(sset.coeff)
      if sc[0] EQ 2 then goodcoeff = sset.coeff[0:npoly-1,coeffbk] $
      else goodcoeff = sset.coeff[coeffbk]
      gb = sset.fullbkpt[goodbk]

      upper = -1L
      for i= 0L, n - nord do begin

         bspline_indx, xwork, gb[i+nord-1], gb[i+nord], lower, upper
         ict = upper - lower + 1

          if (ict GT 0) then begin
             yfit[lower:upper] = action[lower:upper,*] # $
                  goodcoeff[i*npoly+spot]
          endif

      endfor

      yy = yfit
      yy[xsort] = yfit

      return, yy
end

