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
;               invsig=invsig, bkspace = bkspace, nbkpts=nbkpts, $
;               everyn = everyn, /silent)
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
;   bkspace    - Spacing of breakpoints in units of x
;   everyn     - Spacing of breakpoints in good pixels
;   nbkpts     - Number of breakpoints to span x range
;                 minimum is 2 (the endpoints)
;   silent     - Do not produce non-critical messages
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
        invsig = invsig, bkspace = bkspace, nbkpts=nbkpts, everyn=everyn, $
        silent=silent


	if (NOT keyword_set(nord)) then nord = 4L $
 	else if (nord LT 1 or nord GT 20) then $
          message, 'efc only accepts nord between 1 and 20'

        ndata = n_elements(x)
	if ndata LT 2 then message, 'need more data points'

        if (NOT keyword_set(invsig)) then begin
            invsig = fltarr(ndata) + 1.0 
        endif else if n_elements(invsig) NE ndata then $
            message, 'number of invsig elements does not equal ndata'

        good = where(invsig GT 0.0, ngood)

        if (ngood EQ 0) then begin
          print, 'no good points'
          return, -1
        endif

	if (NOT keyword_set(fullbkpt)) then begin $

	  if (NOT keyword_set(bkpt)) then begin $
 
	   range = (max(x) - min(x)) 	
           startx = min(x) 
	   if (keyword_set(bkspace)) then begin
	     nbkpts = long(range/float(bkspace)) + 1
	     if (nbkpts LT 2) then nbkpts = 2
	     tempbkspace = double(range/(float(nbkpts-1)))
	     bkpt = (findgen(nbkpts))*tempbkspace + startx
           endif else if keyword_set(nbkpts) then begin
	     nbkpts = long(nbkpts)
	     if (nbkpts LT 2) then nbkpts = 2
	     tempbkspace = double(range/(float(nbkpts-1)))
	     bkpt = (findgen(nbkpts))*tempbkspace + startx
	   endif else if keyword_set(everyn) then begin
             nbkpts = ngood / everyn
	     xspot = lindgen(nbkpts)*ngood/(nbkpts-1) 
             bkpt = x[good[xspot]]
	   endif else message, 'No information for bkpts'
        endif

	bkpt = float(bkpt)

	if (min(x) LT min(bkpt,spot)) then begin
	  if (NOT keyword_set(silent)) then $
            print, 'lowest breakpoint does not cover lowest x value, changing'
	  bkpt[spot] = min(x)
	endif 

	if (max(x) GT max(bkpt,spot)) then begin
	  if (NOT keyword_set(silent)) then $
            print, 'highest breakpoint does not cover highest x value, changing'
	  bkpt[spot] = max(x)
	endif
	 
	nshortbkpt = n_elements(bkpt) 
	fullbkpt = bkpt
	bkptspace = (bkpt[1] - bkpt[0])/10.0
        for i=1,nord-1 do $
           fullbkpt = [bkpt[0]-bkptspace*i, fullbkpt, $
                bkpt[nshortbkpt - 1] + bkptspace*i]
  
     endif
	nord = LONG(nord)

	nbkpt = n_elements(fullbkpt)

	if (nbkpt LT 2*nord) then $
           message, 'not enough breakpoints?, must have at least 2*nord'



   qeval = 1
   while (qeval) do begin

      coeff = fltarr(nbkpt-nord)
      mdein = 1L
      mdeout = 0L
      lw = 10*nbkpt*nord + 2*max([ndata,nbkpt])
      w = fltarr(lw)

      test = call_external(getenv('IDL_EVIL')+'libslatecidl.so','efc_idl', $
       ndata, float(x), float(y), float(invsig), nord, $
       nbkpt,fullbkpt, mdein, mdeout, coeff, lw, w)

      qeval = 0 ; Do not re-evaluate spline unless break points are removed
                ; below

      ; Test if the call to Slatec failed
      if (total(coeff) EQ 0 AND total(y) NE 0) then begin

         ; Assume that there are two break points without any data in between.
         ; Find them, and remove the first break point in those cases.
         wsum = 1
         i = 1 ; Don't remove the first point (i=0)
print,'remove begin ',nbkpt
         while (i LT nbkpt-2) do begin
            ; Test to see if there is data between break points #i and #(i+1)
            indx = where(x GE fullbkpt[i] AND x LT fullbkpt[i+1], ct)

            ; Or if all data points in that range have zero weight
            if (ct GT 0) then wsum = total(invsig[indx])

            if (ct EQ 0 OR wsum EQ 0) then begin
               ; Remove break point #i
               if (i EQ 0) then fullbkpt = fullbkpt[1:nbkpt-1] $
                else if (i EQ nbkpt-2) then fullbkpt = fullbkpt[0:nbkpt-2] $
                else fullbkpt = fullbkpt[[lindgen(i),lindgen(nbkpt-i-1)+i+1]]
               nbkpt = n_elements(fullbkpt) ; Should decrement by 1
               qeval = 1 ; Re-evaluate the spline
            endif
            i = i + 1
         endwhile
print,'remove end ',nbkpt

      endif

   endwhile

   return, fullbkpt
end
