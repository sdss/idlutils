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
;                  maxiter=maxiter, upper=upper, lower=lower, bkpt=bkpt,$
;                  secondkludge=secondkludge, mask=mask, rejper=rejper, $
;                 _EXTRA=KeywordsForEfc)
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
;   maxiter    - maximum number of iterations (default 5)
;   lower      - rejection threshold for negative deviations 
;                        (default 5 sigma)
;   upper      - rejection threshold for positive deviations 
;                        (default 5 sigma)
;   invvar     - inverse variance of y
;   rejper     - Different rejection algorithm, throwing out worst (rejper)
;                each iteration
;   secondkludge - ???
;   eachgroup  - ???
;
; KEYWORDS FOR SLATEC_EFC:
;   nord
;   bkspace
;   nbkpts
;   everyn
;
; OPTIONAL OUTPUTS:
;   bkpt       - breakpoints without padding
;   mask       - mask array
;
; COMMENTS:
;   If both bkspace and nbkpts are passed, bkspace is used
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
;   slatec_efc()
;
; REVISION HISTORY:
;   15-Oct-1999  Written by Scott Burles, Chicago
;-
;------------------------------------------------------------------------------
function slatec_splinefit, x, y, coeff, invvar=invvar, upper=upper, $
         lower=lower, maxiter=maxiter, bkpt=bkpt, fullbkpt=fullbkpt, $
         secondkludge=secondkludge, mask=mask, rejper=rejper, $
         eachgroup=eachgroup, _EXTRA=KeywordsForEfc

    if N_PARAMS() LT 3 then begin
        print, ' Syntax - fullbkpt = slatec_splinefit(x, y, coeff, '
        print, '         invvar=invvar, maxiter=maxiter, upper=upper, '
        print, '         lower=lower, bkpt=bkpt, secondkludge=secondkludge,'
        print, '         mask=mask, rejper=rejper, _EXTRA=KeywordsForEfc)'
    endif

    if (n_elements(maxiter) EQ 0) then maxiter = 5
    if (NOT keyword_set(upper)) then upper = 5.0
    if (NOT keyword_set(lower)) then lower = 5.0
    if (NOT keyword_set(invvar)) then begin
	; cheesey inverse variance
        invvar = y - y + 1.0 / (stddev(y))^2
    endif

    invsig = sqrt(invvar > 0)

    nx = n_elements(x)
    mask = bytarr(nx) + 1
    bad = where(invvar LE 0.0)
    good = where(invvar GT 0.0)
    if (bad[0] NE -1) then mask[bad] = 0

;    ; Note that we don't set any value to the masked elements of VARARR,
;    ; but that's OK since they are never passed to the routine slatec_efc().
;    vararr = float(0 * invvar)
;    if (good[0] NE -1) then vararr[good] = 1. / invvar[good]

    for iiter=0, maxiter do begin
       oldmask = mask
       these = where(mask, nthese)

       if (nthese LT 2) then begin
;          splog, 'Lost all points'
          return, fullbkpt
       endif

       fullbkpt = slatec_efc(x[these], y[these], fullbkpt=fullbkpt, $
              coeff, bkpt=bkpt, invsig=invsig[these], $
                 _EXTRA=KeywordsForEfc)
       yfit = slatec_bvalu(x, fullbkpt, coeff)

       if (keyword_set(rejper)) then begin
          diff = (y[these] - yfit[these])*invsig[these]
          bad = where(diff LE -lower OR diff GE upper,nbad)
	  if (nbad EQ 0) then iiter = maxiter $
          else begin
	    negs = where(diff LT 0)
	    tempdiff = abs(diff)/upper
            if (negs[0] NE -1) then tempdiff[negs] = abs(diff[negs])/lower

	    worst = reverse(sort(tempdiff))
	    rejectspot = long(n_elements(bad)*rejper) 
	    mask[these[worst[0:rejectspot]]] = 0

	    good = where(diff GT -lower AND diff LT upper AND $
                        invsig[these] GT 0.0)
	    if (good[0] NE -1) then mask[these[good]] = 1
          endelse
       endif else if (keyword_set(eachgroup)) then begin
	  diff = (y[these] - yfit[these])*invsig[these]
          bad = where(diff LE -lower OR diff GE upper, nbad)
	  if (nbad EQ 0) then iiter = maxiter $
          else begin
	    negs = where(diff[bad] LT 0)
	    tempdiff = abs(diff[bad])/upper
            if (negs[0] NE -1) then tempdiff[negs] = abs(diff[bad[negs]])/lower
	    if (nbad EQ 1) then mask[these[bad]] = 0 $
            else begin
 	      groups = where(bad[1:nbad-1] - bad[0:nbad-2] NE 1, ngroups)
	      if (ngroups EQ 0) then groups = [-1,nbad-1] $
	      else groups = [-1,groups,nbad-1]
	      for i=0L, ngroups do begin
	        groupmax = max(tempdiff[groups[i]+1:groups[i+1]], place)
	        mask[these[bad[place+groups[i]+1]]] = 0
	      endfor
            endelse 

	    good = where(diff GT -lower AND diff LT upper AND $
                        invsig[these] GT 0.0)
	    if (good[0] NE -1) then mask[these[good]] = 1
	  endelse
       endif else begin
          diff = (y - yfit)*invsig
          bad = where(diff LT -lower OR diff GT upper OR invsig LE 0.0)
	  if (bad[0] EQ -1) then iiter = maxiter $
          else begin
             mask = bytarr(nx) + 1	
	     mask[bad]  = 0
             if total(abs(mask - oldmask)) EQ 0 then iiter=maxiter
          endelse
        endelse
    endfor

    mask = oldmask ; Return the mask that was actually used in the last
                   ; call to SLATEC_EFC()

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

       these = where(mask)
       fullbkpt = slatec_efc(x[these], y[these], fullbkpt=fullbkpt, $
              coeff, invsig=invsig[these], $
                 _EXTRA=KeywordsForEfc)
      endif

    return, fullbkpt
end
