;+
; NAME:
;   bspline_valu
;
; PURPOSE:
;   This routine has TWO purposes.  
;      1) Evaluate a bspline set (see create_bsplineset) at specified
;            x and x2 arrays
;      2) Construct banded bspline matrix, with dimensions [ndata, bandwidth]
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
;
; OPTIONAL OUTPUTS:
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
 

      goodbk = where(sset.bkmask NE 0, nbkpt)
      nord = sset.nord
      if nbkpt LT 2*nord then return, -2L
      n = (nbkpt - nord)
      nfull = n*npoly

      gb = sset.fullbkpt[goodbk]

      bw = npoly * nord   
      indx = intrv(x, gb, nord)

      largex = (x # replicate(1,npoly))[*]
      largeindx = (indx # replicate(1,npoly))[*]
      bf = reform(bsplvn(gb, nord, largex, largeindx), nx, bw)
      action = bf


      if keyword_set(x2) then begin

         x2norm = 2.0 * (x2 - sset.xmin) / (sset.xmax - sset.xmin) - 1.0

         CASE sset.funcname OF
           'poly' : begin
                   temppoly = (x2norm*0.0 + 1.0) # replicate(1,npoly)
                   for i=1,npoly-1 do temppoly[*,i] = temppoly[*,i-1] * x2norm
                  end
           'chebyshev' : temppoly = fchebyshev(x2norm, npoly)
           'legendre'  : temppoly = flegendre(x2norm, npoly)
           else :        temppoly = flegendre(x2norm, npoly)
         ENDCASE

         ypoly = reform((temppoly[*] # replicate(1,nord))[*],nx,bw)
         action = bf * ypoly

      endif

      yfit = x * 0.0
      spot = lindgen(bw)
      slist = indx[sort(indx)]
      ilist = slist[uniq(slist)]

      goodbk = where(sset.bkmask[nord:*] NE 0) 

      sc = size(sset.coeff)
      if sc[0] EQ 2 then goodcoeff = sset.coeff[0:npoly-1,goodbk] $
      else goodcoeff = sset.coeff[goodbk]

      for i=0, n_elements(ilist) - 1 do begin
         inside = where(indx EQ ilist[i], ict)
         if inside[0] NE -1 then yfit[inside] = action[inside,*] # $
                  goodcoeff[i*npoly+spot]
      endfor

      return, yfit
end

