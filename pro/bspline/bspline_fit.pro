;+
; NAME:
;   bspline_fit
;
; PURPOSE:
;   Calculate a B-spline in the least-squares sense 
;     based on two variables: x which is sorted and spans a large range
;				  where bkpts are required
;  		and 	      y which can be described with a low order
;				  polynomial	
;
; CALLING SEQUENCE:
;   
;   coeff = bspline_fit(xdata, ydata, invsig, fullbkpt, nord=, bkmask=, $
;                                    x2=, npoly=, poly=)
;
; INPUTS:
;   x          - independent variable
;   y          - dependent variable
;   invsig     - inverse error array of y
;   fullbkpt   - Breakpoint vector 
;
; RETURNS:
;   coeff      - B-spline coefficients calculated by efc
;
; OUTPUTS:
;
; OPTIONAL KEYWORDS:
;   nord       - Order of b-splines (4 is cubic, default)
;   x2         - Orthogonal dependent variable
;   npoly      - Order of x2 polynomial fit
;   bkmask     - mask for unused bkpts
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   please sort x for this routine?  This might not be necessary
;   replacement for efcmn and efc2d which calls slatec library
;
; EXAMPLES:
;
;
; PROCEDURES CALLED:
;
;   efc_idl in src/slatec/idlwrapper.c
;         which wraps to efc.o in libslatecidl.so
;
; REVISION HISTORY:
;   20-Aug-2000 Written by Scott Burles, FNAL
;-
;------------------------------------------------------------------------------

function bspline_fit, xdata, ydata, invsig, fullbkpt, bkmask=bkmask, $
       x2=x2, npoly=npoly, nord=nord, poly=poly

      if NOT keyword_set(nord) then nord=4L
      if NOT keyword_set(npoly) then npoly=1L
    
      nx = n_elements(xdata)
      nbkpt= n_elements(fullbkpt)
      n = (nbkpt - nord)
      nfull = n*npoly

      coeff = fltarr(nfull)

      xmin = min([fullbkpt[nord-1],xdata])
      xmax = max([fullbkpt[n],xdata])

;
;	Make sure nord bkpts on each side lie outside [xmin,xmax]
;
	for i=0,nord-1 do fullbkpt[i] = min([fullbkpt[i],xmin])
	for i=n,nbkpt-1 do fullbkpt[i] = max([fullbkpt[i],xmax]) 

;
;     Loop through data points, and process at every once each breakpoint
;     is crossed.
;
      bw = npoly * nord   ; this is the bandwidth

      indx = intrv(xdata, fullbkpt, nord)

      bf1 = bsplvn(fullbkpt, nord, xdata, indx)
      bf = reform(bf1[*] #replicate(1,npoly),nx, bw)

      if keyword_set(x2) then begin
         stuff = (x2 # replicate(1,nord))[*]
         if keyword_set(poly) then begin
           temppoly = (stuff*0.0 + 1.0) # replicate(1,npoly)
           for i=1,npoly-1 do temppoly[*,i] = temppoly[*,i-1] * x2
           ypoly = reform(temppoly,nx,bw)
         endif else ypoly = reform(flegendre(stuff, npoly),nx,bw)
      endif 

     
      if keyword_set(x2) then $
        a = bf * ypoly * (invsig # replicate(1,bw)) $
      else a = bf * (invsig # replicate(1,bw))

      b = ydata * invsig

      alpha = dblarr(bw,nfull+bw)
      beta = dblarr(nfull+bw)

      bi = lindgen(bw)
      bo = lindgen(bw)
      for i=1,bw-1 do bi = [bi,lindgen(bw-i)+(bw+1)*i]
      for i=1,bw-1 do bo = [bo,lindgen(bw-i)+bw*i]

      ilist = indx[uniq(indx)]
      for i=0, n_elements(ilist) - 1 do begin

        itop = i*npoly
        ibottom = (itop + bw < nfull) - 1
        inside = where(indx EQ ilist[i], ict)

        if (ict NE 0) then begin

          work = a[inside,*] ## transpose(a[inside,*])
          wb =  b[inside] # a[inside,*] 

          alpha[bo+itop*bw] = alpha[bo+itop*bw] + work[bi]
          beta[itop:ibottom] = beta[itop:ibottom] + wb
        endif
      endfor

; this changes alpha
    errb = cholesky_band(alpha)   

; this changes beta to contain the solution
    errs = cholesky_solve(alpha, beta)   

    return, reform(beta[lindgen(nfull)],npoly,n)
end 
