;+
; NAME:
;   bspline_iterfit
;
; PURPOSE:
;   Calculate a B-spline in the least squares sense with rejection
;
; CALLING SEQUENCE:
;   sset = bspline_iterfit( )
;
; INPUTS:
;   xdata      - Data x values
;   ydata      - Data y values
;
; OPTIONAL KEYWORDS:
;   invvar     - Inverse variance of y; if not set, then set to be
;                consistent with the standard deviation.  This only matters
;                if rejection is being done.
;   nord       - Order for spline fit; default to 3 (cubic).
;   x2         - 2nd dependent variable for 2-D spline fitting.
;   npoly      - Polynomial order to fit over 2nd variable (X2); default to 2.
;   xmin       - Normalization minimum for X2; default to MIN(XDATA).
;   xmax       - Normalization maximum for X2; default to MAX(XDATA).
;   oldset     - If set, then use values of FULLBKPT, NORD, XMIN, XMAX, NPOLY
;                from this structure.
;   maxiter    - Maximum number of rejection iterations; default to 0.
;   EXTRA      - Keywords for BSPLINE_BKPTS() and/or DJS_REJECT().
;
; OUTPUTS:
;   sset       - Structure describing spline fit.
;
; OPTIONAL OUTPUTS:
;   outmask    - Output mask, set =1 for good points, =0 for bad points.
;
; COMMENTS:
;   Data points can be masked either by setting their weights to zero
;   (INVVAR[]=0), or by using INMASK and setting bad elements to zero.
;   INMASK is passed to DJS_REJECT().
;
;   If OLDSET is used, then the output structure SSET will be a structure
;   with the same name as OLDSET.  This will allow the two structures to
;   be concatented, i.e.
;     > junk = [oldset, sset]
;
; EXAMPLES:
;
; PROCEDURES CALLED:
;   bspline_bkpts()
;   bspline_fit()
;   djs_reject()
;
; REVISION HISTORY:
;   05-Sep-2000  Written by D. Schlegel & S. Burles
;-
;------------------------------------------------------------------------------
function bspline_iterfit, xdata, ydata, invvar=invvar, nord=nord, $
 x2=x2, npoly=npoly, xmin=xmin, xmax=xmax, $
 oldset=oldset, maxiter=maxiter, outmask=outmask, _EXTRA=EXTRA

   if (n_params() LT 2) then begin
      print, 'Syntax -  sset = bspline_iterfit( )'
      return, -1
   endif

   ;----------
   ; Check dimensions of inputs

   nx = n_elements(xdata)
   if (n_elements(ydata) NE nx) then $
    message, 'Dimensions of XDATA and YDATA do not agree'

   if (NOT keyword_set(nord)) then nord = 4L

   if (keyword_set(invvar)) then begin
      if (n_elements(invvar) NE nx) then $
       message, 'Dimensions of XDATA and INVVAR do not agree'
   endif 

   if (keyword_set(x2)) then begin
      if (n_elements(x2) NE nx) then $
       message, 'Dimensions of X and X2 do not agree'
      if (NOT keyword_set(npoly)) then npoly = 2L
   endif
   if (NOT keyword_set(maxiter)) then maxiter = 10

   ;----------
   ; Determine the break points and create output structure

   if (keyword_set(oldset)) then begin
      sset = oldset
      sset.bkmask = 0
      sset.coeff = 0
      tags = tag_names(oldset)
      if ((where(tags EQ 'XMIN'))[0] NE -1 AND NOT keyword_set(x2)) then $
       message, 'X2 must be set to be consistent with OLDSET'
   endif else begin
      fullbkpt = bspline_bkpts(xdata, nord=nord, _EXTRA=EXTRA) ; ???
      sset = create_bsplineset(fullbkpt, nord, npoly=npoly) 

      if keyword_set(x2) then begin
         if (NOT keyword_set(xmin)) then xmin = min(x2)
         if (NOT keyword_set(xmax)) then xmax = max(x2)
         if (xmin EQ xmax) then xmax = xmin + 1
         sset.xmin = xmin
         sset.xmax = xmax
      endif

   endelse

   ;----------
   ; Test that the input data falls within the bounds set by the break points.
   ; This would only fail if OLDSET is used, and the break points do not
   ; bound the data.

   junk = where(xdata LT min(sset.fullbkpt) OR xdata GT max(sset.fullbkpt), $
    nbad)
   if (nbad GT 0) then $
    message, 'Break points do not bound XDATA'

   ;----------
   ; Condition the X2 dependent variable by the XMIN, XMAX values.
   ; This will typically put X2NORM in the domain [-1,1].

   if NOT keyword_set(invvar) then begin
       var = variance(ydata)
       if var EQ 0 then return, -1
       invvar = 0.0 * ydata + 1.0/var
   endif

   ;----------
   ; Iterate spline fit

   outmask = make_array(size=size(xdata), /byte) + 1
   iiter = 0
   error = -1L
   while (((error[0] NE -1) OR (keyword_set(qdone) EQ 0)) $
           AND iiter LE maxiter) do begin

      if (iiter GT 0) then begin
        print, error
        if (error[0] NE -1) then sset.bkmask[error+nord-1L] = 0 $
        else qdone = djs_reject(ydata, yfit, invvar=invvar, $
                           outmask=outmask, _EXTRA=EXTRA)
      endif

      qgood = outmask EQ 1
      igood = where(qgood, ngood)
      ibad = where(qgood NE 1, nbad)

      goodbk = where(sset.bkmask NE 0)

      if (ngood LE 1 OR goodbk[0] EQ -1) then begin
         coeff = 0
         iiter = maxiter + 1 ; End iterations
      endif else begin

;         DO THE FIT ???
;            INPUTS: xdata, ydata, x2, invvar, sset.fullbkpt, sset.bkmask,
;                    sset.nord, sset.xmin, sset.xmax, sset.npoly
;            OUTPUTS: updated bkmask, yfit, coeff
;
;	Let's demand invvar, fullbkpt, and coeff to be passed
;       ill constrained entries are returned
;       yfit is keyword
;       Full bkpt is required, not sure how to implement bkptmask yet
;


        error = bspline_fit(xdata, ydata, invvar*qgood, sset, $
               x2=x2, yfit=yfit)

      endelse

      iiter = iiter + 1
   endwhile

   return, sset
end
;------------------------------------------------------------------------------
