;+
; NAME:
;   slatec_efc
;
; PURPOSE:
;   Calculate a B-spline in the least squares sense
;
; CALLING SEQUENCE:
;   
;    fullbkpt = slatec_efc(x, y, coeff, bkpt=bkpt, nord=nord, $
;               invvar=invvar, bkspace = bkspace, nbkpts=nbkpts)
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
;   invvar     - Inverse variance for weighted fit
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
;       fullbkpt = slatec_efc(x, y, coeff, bkspace = 10.0)
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
function slatec_efc, x, y, coeff, bkpt=bkpt, nord=nord, $
        invvar=invvar, bkspace = bkspace, nbkpts=nbkpts, everyn=everyn

        sortx = sort(x)
	tempx = x[sortx]
	tempy = y[sortx]

	if (NOT keyword_set(nord)) then nord = 4L
        ndata = n_elements(tempx)

	if (NOT keyword_set(bkpt)) then begin $
	   range = (max(x) - min(x)) 	
           startx = min(x) 
	   if (keyword_set(bkspace)) then begin
	     nbkpts = long(range/float(bkspace)) + 1
	     if (nbkpts LT 2) then nbkpts = 2
           endif else if keyword_set(nbkpts) then begin
	     nbkpts = long(nbkpts)
	     if (nbkpts LT 2) then nbkpts = 2
	   endif else message, 'No information for bkpts'

	   if keyword_set(everyn) then begin
	     xspot = lindgen(nbkpts)*ndata/(nbkpts-1) 
             bkpt = tempx[xspot]
           endif else begin
	     tempbkspace = double(range/(float(nbkpts-1)))
	     bkpt = (findgen(nbkpts))*tempbkspace + startx
	   endelse
        endif

        if (NOT keyword_set(invvar)) then begin
            sigma = fltarr(ndata) + 1.0 
            good = lindgen(ndata)
        endif else begin
            good = where(invvar GT 0.0)
	    if (good[0] EQ -1) then $
               message, 'All points have zero inverse variance'
            sigma = 1.0/sqrt(invvar[sortx[good]])
        endelse
	
	nord = LONG(nord)
	bkpt = float(bkpt)


	if (min(x) LT min(bkpt,spot)) then begin
	     print, 'lowest breakpoint does not cover lowest x value, changing'
	    bkpt[spot] = min(x)
	endif 

	if (max(x) GT max(bkpt,spot)) then begin
            print, 'highest breakpoint does not cover highest x value'
	    bkpt[spot] = max(x)
	endif
	 
	nshortbkpt = n_elements(bkpt) 
	tempbkpt = bkpt
	bkptspace = (bkpt[1] - bkpt[0])/100.0
        for i=1,nord-1 do $
           tempbkpt = [bkpt[0]-bkptspace*i, tempbkpt, $
                bkpt[nshortbkpt - 1] + bkptspace*i]

	nbkpt = n_elements(tempbkpt)

	coeff = fltarr(nbkpt-nord)
	mdein = 1L
	mdeout = 0L
	lw = 10*nbkpt*nord + 2*max([ndata,nbkpt])
	w = fltarr(lw)

	test = call_external(getenv('IDL_EVIL')+'libslatecidl.so','efc_idl', $
	         ndata, tempx[good], tempy[good], sigma, $
                 nord, nbkpt, tempbkpt, mdein, mdeout, coeff, lw, w)

	return, tempbkpt
end
