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
   if (NOT keyword_set(maxiter)) then maxiter = 0

   ;----------
   ; Determine the break points and create output structure

   if (keyword_set(oldset)) then begin
      sset = oldset
      sset.bkmask = 0
      sset.coeff = 0
      tags = tag_names(oldset)
      if (where(tags EQ 'XMIN') NE -1 AND NOT keyword_set(x2)) then $
       message, 'X2 must be set to be consistent with OLDSET'
   endif else begin
      fullbkpt = bspline_bkpts(xdata, nord=nord, _EXTRA=EXTRA) ; ???
      numbkpt = n_elements(fullbkpt)
      numcoeff = numbkpt - nord

      if (NOT keyword_set(x2)) then begin
         sset = $
         { fullbkpt: fullbkpt         , $
           bkmask  : bytarr(numbkpt)  , $
           nord    : long(nord)       , $
           coeff   : fltarr(numcoeff) }
      endif else begin
         if (NOT keyword_set(xmin)) then xmin = min(x2)
         if (NOT keyword_set(xmax)) then xmax = max(x2)
         if (xmin EQ xmax) then xmax = xmin + 1

         sset = $
         { fullbkpt: fullbkpt         , $
           bkmask  : bytarr(numbkpt)  , $
           nord    : long(nord)       , $
           xmin    : xmin             , $
           xmax    : xmax             , $
           npoly   : long(npoly)      , $
           coeff   : fltarr(npoly,numcoeff) }
      endelse
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

   if keyword_set(x2) then $
     x2norm = 2.0 * (x2 - sset.xmin) / (sset.xmax - sset.xmin) - 1.0


   ;----------
   ; Iterate spline fit

   outmask = make_array(size=size(xdata), /byte) + 1
   bkmask = bytarr(n_elements(fullbkpt)) + 1
   iiter = 0
   while (NOT keyword_set(qdone) AND iiter LE maxiter) do begin

      if (iiter GT 0) then begin
        qdone = djs_reject(ydata, yfit, invvar=invvar, $
                           outmask=outmask, _EXTRA=EXTRA)
      endif


      qgood = outmask EQ 1
      igood = where(qgood, ngood)
      ibad = where(qgood NE 1, nbad)

      if (ngood LE 1) then begin
         coeff = 0
         iiter = maxiter + 1 ; End iterations
      endif else begin
         if (keyword_set(invvar)) then invsig = sqrt(invvar) $
          else invsig = 0.0 * ydata + stddev(ydata[igood])
         if (nbad GT 0) then invsig[ibad] = 0

;         DO THE FIT ???
;            INPUTS: xdata, ydata, x2, invsig, sset.fullbkpt, sset.bkmask,
;                    sset.nord, sset.xmin, sset.xmax, sset.npoly
;            OUTPUTS: updated bkmask, yfit, coeff
;
;	Let's demand invsig to be passed
;       Coeff is output 
;       yfit is keyword
;       Full bkpt is required, not sure how to implement bkptmask yet
;

          if (NOT keyword_set(x2)) then $
           coeff = bspline_fit(xdata, ydata, invsig, sset.fullbkpt, $
            bkmask=bkmask, nord=sset.nord) $
          else $
           coeff = bspline_fit(xdata, ydata, invsig, sset.fullbkpt, $
            bkmask=bkmask, nord=sset.nord, x2=x2norm, npoly=sset.npoly)
      endelse

      iiter = iiter + 1
   endwhile

   ;----------
   ; Assign data in output structure

   sset.bkmask = bkmask
   sset.coeff = coeff

   return, sset
end
;------------------------------------------------------------------------------
