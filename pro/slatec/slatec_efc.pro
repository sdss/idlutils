;+
; NAME:
;   slatec_efc
;
; PURPOSE:
;   Calculate a B-spline in the least-squares sense
;
; CALLING SEQUENCE:
;   
;   fullbkpt = slatec_efc(x, y, coeff, bkpt=bkpt, nord=nord, $
;    invsig=invsig, bkspace=bkspace, nbkpts=nbkpts, everyn=everyn, /silent)
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
;   invsig     - Inverse of sigma for weighted fit
;   bkspace    - Spacing of breakpoints in units of x
;   everyn     - Spacing of breakpoints in good pixels
;   nbkpts     - Number of breakpoints to span x range
;                 minimum is 2 (the endpoints)
;   silent     - Do not produce non-critical messages
;
; OPTIONAL OUTPUTS:
;   bkpt       - breakpoints without padding
;
; COMMENTS:
;   If both bkspace and nbkpts are passed, bkspace is used.
;   X values must be sorted.
;
; EXAMPLES:
;
;   x = findgen(100)
;   y = randomu(100,100)
;   fullbkpt = slatec_efc(x, y, coeff, bkspace = 10.0)
;
;   xfit = findgen(10)*10.0
;   yfit = bvalu(xfit, fullbkpt, coeff)
;
;
; PROCEDURES CALLED:
;   efc_idl in src/slatec/idlwrapper.c
;         which wraps to efc.o in libslatecidl.so
;
; REVISION HISTORY:
;   15-Oct-1999  Written by Scott Burles, Chicago
;-
;------------------------------------------------------------------------------
function slatec_efc, x, y, coeff, bkpt=bkpt, nord=nord, fullbkpt=fullbkpt, $
 invsig=invsig, bkspace=bkspace, nbkpts=nbkpts, everyn=everyn, silent=silent

   if (NOT keyword_set(nord)) then nord = 4L $
    else if (nord LT 1 or nord GT 20) then $
    message, 'efc only accepts nord between 1 and 20'

   ndata = n_elements(x)
   if (ndata LT 2) then $
    message, 'Too few data points'

   if (NOT keyword_set(invsig)) then $
    invsig = fltarr(ndata) + 1.0 $
   else if (n_elements(invsig) NE ndata) then $
    message, 'Number of INVSIG elements does not equal NDATA'

   good = where(invsig GT 0.0, ngood)

   if (ngood EQ 0) then begin
      print, 'No good points'
      coeff = 0
      fullbkpt = 0
      return, fullbkpt
   endif

   if (NOT keyword_set(fullbkpt)) then begin

      if (NOT keyword_set(bkpt)) then begin
 
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
          print, 'Lowest breakpoint does not cover lowest x value: changing'
         bkpt[spot] = min(x)
      endif

      if (max(x) GT max(bkpt,spot)) then begin
         if (NOT keyword_set(silent)) then $
          print, 'highest breakpoint does not cover highest x value, changing'
         bkpt[spot] = max(x)
      endif

      nshortbkpt = n_elements(bkpt)
      fullbkpt = bkpt
      bkptspace = (bkpt[1] - bkpt[0]) / 10.0
      for i=1, nord-1 do $
       fullbkpt = [bkpt[0]-bkptspace*i, fullbkpt, $
        bkpt[nshortbkpt - 1] + bkptspace*i]
  
   endif else begin

      fullbkpt = FLOAT(fullbkpt)

   endelse

   nbkpt = n_elements(fullbkpt)

   if (nbkpt LT 2*nord) then $
    message, 'Too few breakpoints: must have at least 2*NORD'

   qeval = 1
   while (qeval) do begin

      coeff = fltarr(nbkpt-nord)
      mdein = 1L
      mdeout = 0L
      lw = 10*nbkpt*nord + 2*max([ndata,nbkpt])
      w = fltarr(lw)

      test = call_external(getenv('IDLUTILS_DIR')+'/lib/libslatec.so', $
       'efc_idl', $
       ndata, FLOAT(x), FLOAT(y), FLOAT(invsig), LONG(nord), $
       LONG(nbkpt), fullbkpt, mdein, mdeout, coeff, lw, w)

      qeval = 0 ; Do not re-evaluate spline unless break points are removed
                ; below

      ; Test if the call to Slatec failed
     
      inff = where(finite(coeff) EQ 0,ninff) 
      if ((total(coeff) EQ 0 AND total(y) NE 0) OR ninff GT 0) then begin

         ; Assume that there are two break points without any data in between.
         ; Find them, and remove the second break point in those cases.
         i = nord + 0L ; Don't remove the first NORD or last NORD break points
print,'remove begin ',nbkpt
         while (i LE nbkpt-nord) do begin
            ; Test to see if there is data between break points #i and #(i-1)
            indx = where(x LT fullbkpt[i] AND x GE fullbkpt[i-1], ct)

            ; Or if all data points in that range have zero weight
            if (ct GT 0) then wsum = total(invsig[indx]) $
             else wsum = 1

            if (ct EQ 0 OR wsum EQ 0) then begin
               ; Remove break point #i
	       ; print, 'removing... ', i
               fullbkpt = fullbkpt[[lindgen(i),lindgen(nbkpt-i-1)+i+1]]
               nbkpt = n_elements(fullbkpt) ; Should decrement by 1
               qeval = 1 ; Set to re-evaluate the spline
            endif else begin
               i = i + 1
            endelse

         endwhile
print,'remove end ',nbkpt

      endif

   endwhile

   inff = where(finite(coeff) EQ 0,ninff) 
   if (inff[0] NE -1) then begin
     print, 'Replacing infinities in coeff!', ninff
     coeff[inff] = 0.0
   endif

   return, fullbkpt
end
