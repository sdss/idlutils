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
;               invsig=invsig, bkspace = bkspace, nbkpts=nbkpts)
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
;   invsig     - Inverse sigma for weighted fit
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
;	x values must be sorted
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
function slatec_efc, x, y, coeff, bkpt=bkpt, nord=nord, fullbkpt=fullbkpt, $
        invsig = invsig, bkspace = bkspace, nbkpts=nbkpts, everyn=everyn


	if (NOT keyword_set(nord)) then nord = 4L $
 	else if (nord LT 1 or nord GT 20) then $
          message, 'efc only accepts nord between 1 and 20'

        ndata = n_elements(x)
	if ndata LT 2 then message, 'need more data points'

        if (NOT keyword_set(invsig)) then begin
            invsig = fltarr(ndata) + 1.0 
            good = lindgen(ndata)
        endif else if n_elements(invsig) NE ndata then $
            message, 'number of invsig elements does not equal ndata'

	if (NOT keyword_set(fullbkpt)) then begin $

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
             bkpt = x[xspot]
           endif else begin
	     tempbkspace = double(range/(float(nbkpts-1)))
	     bkpt = (findgen(nbkpts))*tempbkspace + startx
	   endelse
        endif

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
	fullbkpt = bkpt
	bkptspace = (bkpt[1] - bkpt[0])/100.0
        for i=1,nord-1 do $
           fullbkpt = [bkpt[0]-bkptspace*i, fullbkpt, $
                bkpt[nshortbkpt - 1] + bkptspace*i]
     endif
	nord = LONG(nord)

	nbkpt = n_elements(fullbkpt)

	if (nbkpt LT 2*nord) then $
           message, 'not enough breakpoints?, must have at least 2*nord'



	coeff = fltarr(nbkpt-nord)
	mdein = 1L
	mdeout = 0L
	lw = 10*nbkpt*nord + 2*max([ndata,nbkpt])
	w = fltarr(lw)

	test = call_external(getenv('IDL_EVIL')+'libslatecidl.so','efc_idl', $
	         ndata, x, y, invsig, nord, nbkpt, fullbkpt, $
                 mdein, mdeout, coeff, lw, w)

	return, fullbkpt
end
