;+
; NAME:
;   slatec_splinefit
;
; PURPOSE:
;   Calculate a B-spline in the least squares sense with rejection
;
; CALLING SEQUENCE:
;   
;    fullbkpt = slatec_splinefit(x, y, coeff, invvar=invvar, $
;                  maxIter=maxIter, upper=upper, lower=lower, bkpt=bkpt,$
;                  secondkludge=secondkludge, _EXTRA = slatec_efc extras)
;
; INPUTS:
;   x          - data x values
;   y          - data y values
;   bkpt       - Breakpoint vector returned by efc
;
; RETURNS:
;   fullbkpt   - The fullbkpt vector required by evaluations with bvalu
;
; OUTPUTS:
;   coeff      - B-spline coefficients calculated by efc
;
; OPTIONAL KEYWORDS:
;   maxIter    - maximum number of iterations (default 5)
;   lower      - rejection threshold for negative deviations 
;                        (default 5 sigma)
;   upper      - rejection threshold for positive deviations 
;                        (default 5 sigma)
;   invvar     - inverse variance of y
;   EXTRA      - goodies passed to slatec_efc:
;   nord       - Order of b-splines (default 4: cubic)
;   bkpsace    - Spacing of breakpoints in units of x
;   nbkpts     - Number of breakpoints to span x range
;                 minimum is 2 (the endpoints)
;
; OPTIONAL OUTPUTS:
;   bkpt       - breakpoints without padding
;  
;
; COMMENTS:
;	If both bkspace and nbkpts are passed, bkspace is used
;
; EXAMPLES:
;
;	x = findgen(100)
;       y = randomu(100,100)
;       fullbkpt = slatec_splinefit(x, y, coeff, invvar=invvar, nbkpts=10)
;
;	xfit = findgen(10)*10.0
;       yfit = bvalu(xfit, fullbkpt, coeff)
;
;
; PROCEDURES CALLED:
;   efc_idl in slatec/src/idlwrapper.c
;         which wraps to efc.o in libslatecidl.so
;
; REVISION HISTORY:
;   15-Oct-1999  Written by Scott Burles, Chicago
;-
;------------------------------------------------------------------------------
function slatec_splinefit, x, y, coeff, invvar=invvar, upper=upper, $
         lower=lower, maxIter=maxIter, bkpt=bkpt, fullbkpt=fullbkpt, $
         secondkludge=secondkludge, _EXTRA=KeywordsForEfc

    if N_PARAMS() LT 3 then begin
        print, ' Syntax - fullbkpt = slatec_splinefit(x, y, coeff, '
        print, '         invvar=invvar, maxIter=maxIter, upper=upper, '
        print, '         lower=lower, bkpt=bkpt, secondkludge=secondkludge,'
        print, '          _EXTRA = slatec_efc extras)'
    endif

    if n_elements(maxIter) EQ 0 then maxIter = 5
    if (NOT keyword_set(upper)) then upper = 5.0
    if (NOT keyword_set(lower)) then lower = 5.0
    if (NOT keyword_set(invvar)) then begin
	; cheesey invvariance
        invvar = y - y + 1.0/(moment(y))[1]	
    endif

    invsig = sqrt(invvar)

    nx = n_elements(x)
    good = bytarr(nx) + 1

    for iiter=0, maxiter do begin
       oldgood = good
       these = where(good)
       fullbkpt = slatec_efc(x[these], y[these], fullbkpt=fullbkpt, $
              coeff, bkpt=bkpt, invsig=invsig[these], $
                 _EXTRA=KeywordsForEfc)
       yfit = slatec_bvalu(x, fullbkpt, coeff)
 
       diff = (y - yfit)*invsig
       bad = where(diff LT -lower OR diff GT upper)

	if (bad[0] EQ -1) then iiter = maxiter $
        else begin
            good = bytarr(nx) + 1	
	    good[bad]  = 0
            if total(abs(good - oldgood)) EQ 0 then iiter=maxiter
        endelse
    endfor

    if keyword_set(secondkludge) then begin
	nfullbkpt = n_elements(fullbkpt) 
	ncoeff = n_elements(coeff) 
	nordtemp = nfullbkpt - ncoeff
	nbkptfix = nfullbkpt - 2*nordtemp + 1

	xbkpt = fullbkpt[nordtemp:nordtemp+nbkptfix-1]
	deriv2 = sqrt(abs(slatec_bvalu(x, fullbkpt, coeff)))
	deriv2total = deriv2
	for i=1L,nx-1 do $
	  deriv2total[i] = deriv2total[i] + deriv2total[i-1]
	total2 = total(deriv2)
	deriv2x = (findgen(nbkptfix)+1.0)*total2/float(nbkptfix)
	invspl = spl_init(deriv2total,x)
	newbkpt = spl_interp(deriv2total,x,invspl,deriv2x)

	fullbkpt[nordtemp:nordtemp+nbkptfix-1] = newbkpt

       these = where(good)
       fullbkpt = slatec_efc(x[these], y[these], fullbkpt=fullbkpt, $
              coeff, invsig=invsig[these], $
                 _EXTRA=KeywordsForEfc)
      endif

    return, fullbkpt
end
