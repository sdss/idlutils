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
;                  maxIter=maxIter, upper=upper, lower=lower,
;                 _EXTRA = slatec_efc extras)
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
;   nord       - Order of b-splines (default 4: cubic)
;   sigma      - sigma array for weighted fit
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
         lower=lower, maxIter=maxIter, _EXTRA=KeywordsForEfc

    if N_PARAMS() LT 3 then begin
        print, ' Syntax - fullbkpt = slatec_splinefit(x, y, coeff, '
        print, '         invvar=invvar, maxIter=maxIter, upper=upper, '
        print, '         lower=lower, _EXTRA = slatec_efc extras)'
    endif

    if (NOT keyword_set(maxIter)) then maxIter = 5
    if (NOT keyword_set(upper)) then upper = 5.0
    if (NOT keyword_set(lower)) then lower = 5.0
    if (NOT keyword_set(invvar)) then begin
	; cheesey invvariance
        invvar = y - y + 1.0/(moment(y))[1]	
    endif

    nx = n_elements(x)
    good = bytarr(nx) + 1

    for iiter=0, maxiter do begin
       oldgood = good
       these = where(good)
       fullbkpt = slatec_efc(x[these], y[these], $
              coeff, invvar=invvar[where(good)], $
                 _EXTRA=KeywordsForEfc)
       yfit = slatec_bvalu(x[these], fullbkpt, coeff)
 
       diff = (y[these] - yfit)*sqrt(invvar)
       bad = where(diff LT -lower OR diff GT upper)

	stop
	if (bad[0] EQ -1) then iiter = maxiter $
        else begin
            good = bytarr(nx) + 1	
	    good[bad]  = 0
            if total(abs(good - oldgood)) EQ 0 then iiter=maxiter
        endelse
    endfor

    return, fullbkpt
end
