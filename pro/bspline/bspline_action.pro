;+
; NAME:
;   bspline_action
;
; PURPOSE:
;      1) Construct banded bspline matrix, with dimensions [ndata, bandwidth]
;
; CALLING SEQUENCE:
;   
;   action = bspline_action( x, sset, x2=x2, lower=lower, upper=upper)
;
; INPUTS:
;   x          - independent variable
;   sset       - Structure to be returned with all fit parameters
;
; RETURNS:
;   action     - b-spline action matrix
;
; OPTIONAL KEYWORDS:
;   x2         - Orthogonal dependent variable for 2d fits
;
; OPTIONAL OUTPUTS:
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
function bspline_action, x, sset, x2=x2, lower=lower, upper=upper

      if size(sset,/tname) NE 'STRUCT' then begin
         print, 'Please send in a proper B-spline structure'
         return, -1
      endif
 
      npoly = 1L
      nx = n_elements(x)

;
;	Check for the existence of x2 
;
      if keyword_set(x2) then begin
        if n_elements(x2) NE nx then begin
          print, 'dimensions do not match between x and x2'
          return, -1
        endif

        if ((where(tag_names(sset) EQ 'NPOLY'))[0] NE -1) then npoly=sset.npoly
      endif
 

      nord = sset.nord
      goodbk = where(sset.bkmask NE 0, nbkpt)
      if nbkpt LT 2*nord then return, -2L
      n = nbkpt - nord
      nfull = n*npoly

      gb = sset.fullbkpt[goodbk]

      bw = npoly * nord   
      action = x # replicate(0,bw) 
      right = -1L

      lower = lonarr(n-nord+1)
      upper = lonarr(n-nord+1)

      for i= 0L, n - nord do begin
  
         bspline_indx, x, gb[i+nord-1], gb[i+nord], left, right
         lower[i] = left
         upper[i] = right
         numel = upper[i] - lower[i] + 1


         if (upper[i] GT -1 AND numel GT 0) then begin  
            bf1 = bsplvn(gb, nord, x[lower[i]:upper[i]], i+nord-1)
            action[lower[i]:upper[i],*] = $
        transpose(reform((transpose(bf1))[*] ## replicate(1,npoly), bw, numel))
         endif
      endfor

      if keyword_set(x2) then begin

         x2norm = 2.0 * (x2[*] - sset.xmin) / (sset.xmax - sset.xmin) - 1.0

         CASE sset.funcname OF
           'poly' : begin
                   temppoly = (x2norm*0.0 + 1.0) # replicate(1,npoly)
                   for i=1,npoly-1 do temppoly[*,i] = temppoly[*,i-1] * x2norm
                  end
           'chebyshev' : temppoly = fchebyshev(x2norm, npoly)
           'legendre'  : temppoly = flegendre(x2norm, npoly)
           else :        temppoly = flegendre(x2norm, npoly)
         ENDCASE

         action = action * reform((temppoly[*] # replicate(1,nord))[*],nx,bw)
      endif

      return, action
end

