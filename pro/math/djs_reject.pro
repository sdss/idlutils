;+
; NAME:
;   djs_reject
;
; PURPOSE:
;   Routine to reject points when doing an iterative fit to data.
;
; CALLING SEQUENCE:
;   qdone = djs_reject(ydata, ymodel, outmask=, [ inmask=, $
;    sigma=, invvar=, upper=, lower=, maxdev=, $
;    maxrej=, groupsize=, groupdim=, /sticky ] )
;
; INPUTS:
;   ydata      - Data values
;   ymodel     - Fit values
;
; REQUIRED KEYWORDS:
;   outmask    - Output mask, usually from previous calls to DJS_REJECT(),
;                set =1 for good points, =0 for bad points.
;                If /STICKY is set, then bad pixels accumulate in this mask
;                between calls.  Otherwise, this mask is only used to determine
;                if the rejection iterations are complete (e.g., to set QDONE).
;                This keyword is required to be present, though need not be set.
;
; OPTIONAL KEYWORDS:
;   inmask     - Input mask, set =1 for good points, =0 for bad points;
;                bad points always have OUTMASK=0 also.
;   sigma      - Errors in YDATA, used to reject based upon UPPER and LOWER.
;   invvar     - Inverse variance in YDATA, used to reject based upon UPPER
;                and LOWER; cannot specify both SIGMA and INVVAR.
;   upper      - Reject points with YDATA > YMODEL + UPPER * SIGMA.
;   lower      - Reject points with YDATA < YMODEL - LOWER * SIGMA.
;   maxdev     - Reject points with abs(YDATA - YMODEL) > MAXDEV.
;   maxrej     - Maximum number of points to reject this iteration.  If /STICKY
;                is set, then this number of points can be rejected per
;                iteration.  If either GROUPDIM or GROUPSIZE is a vector,
;                then this quantity should be as well.
;   groupdim   - Dimension along which to group the data; set to 1 to group
;                along the 1st dimension, 2 for the 2nd dimension, etc.
;                If YDATA has dimensions [100,200], then setting GROUPDIM=2
;                is equivalent to grouping the data with GROUPSIZE=100.
;                In either case, there are 200 groups, specified by [*,i].
;   groupsize  - If this and MAXREJ are set, then reject a maximum of MAXREJ
;                points per group of GROUPSIZE points.  If GROUPDIM is also
;                set, then this specifies sub-groups within that.
;   sticky     - If set, then points rejected in OUTMASK are kept rejected.
;                Otherwise, if a fit (YMODEL) changes between iterations,
;                points can alternate from being rejected to not rejected.
;
; OUTPUTS:
;   qdone      - Set to 0 if YMODEL is not set (usually the first call to
;                this routine), or if the points marked as rejected in OUTMASK
;                changes; set to 1 when the same points are rejected as from
;                a previous call.
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   If neither SIGMA nor INVVAR are set, then a scalar value of SIGMA is
;   determined from the data points, excluding those points masked either
;   with INMASK or OUTMASK.
;
;   If the number of points rejected is limited with MAXREJ, then only the
;   worst points are rejected.  The worst points are those with the largest
;   deviation in terms of sigma (if UPPER or LOWER are set), or the largest
;   number of multiples of MAXDEV from YMODEL (if MAXDEV is set).
;
;   For example, if this is a 2-D array with GROUPDIM=1, then loop over each
;   column of the data.  If GROUPDIM=2, then loop over each row.
;
;   Note that UPPER, LOWER and MAXDEV can all be set.
;
; EXAMPLES:
;   Construct an array of random numbers.  Reject high outliers, rejecting
;   at most 1 point per iteration, for a maximum of 3 iterations:
;     ydata = randomn(123,1000)
;     ymodel = 0 * ydata
;     sigma = 0 * ydata + 1
;     outmask = 0
;     maxiter = 3
;     for iiter=0, maxiter do $
;      if djs_reject(ydata, ymodel, outmask=outmask, upper=3, $
;       maxrej=1, /sticky) then iiter = maxiter
;
;   Usually, one would want to re-fit YMODEL between rejection iterations.
;   The following does a weighted cubic fit to the data, but rejecting all
;   points that deviate by more than 2-sigma from the fit.
;     xdata = findgen(1000)
;     ydata = randomn(123,1000)
;     sigma = 0 * ydata + 1
;     iiter = 0
;     maxiter = 10
;     outmask = 0 * ydata + 1 ; Begin with all points good
;     while (NOT keyword_set(qdone) AND iiter LE maxiter) do begin
;        qdone = djs_reject(ydata, ymodel, outmask=outmask, upper=2, lower=2)
;        res = polyfitw(xdata, ydata, outmask/sigma^2, 2, ymodel)
;        iiter = iiter + 1
;     endwhile
;
; BUGS:
;   Check case of no good points, or only 1 point with a value of 0
;   (which might confuse keyword_set()). ???
;
; PROCEDURES CALLED:
;   djs_laxisnum()
;
; REVISION HISTORY:
;   30-Aug-2000  Written by D. Schlegel, Princeton
;------------------------------------------------------------------------------
function djs_reject, ydata, ymodel, outmask=outmask, inmask=inmask, $
 sigma=sigma, invvar=invvar, upper=upper, lower=lower, maxdev=maxdev, $
 maxrej=maxrej, groupsize=groupsize, groupdim=groupdim, sticky=sticky

   if (n_params() LT 2 OR NOT arg_present(outmask)) then begin
      print, 'Syntax: qdone = djs_reject(ydata, ymodel, outmask=, [ inmask=, $
      print, ' sigma=, invvar=, upper=, lower=, maxdev=, $'
      print, ' maxrej=, groupsize=, groupdim=, /sticky ] )'
      return, 1
   endif

   ndata = n_elements(ydata)
   if (ndata EQ 0) then $
    message, 'No data points'
   if (ndata NE n_elements(ydata)) then $
    message, 'Dimensions of YDATA and YMODEL do not agree'

   if (keyword_set(inmask)) then begin
      if (ndata NE n_elements(inmask)) then $
       message, 'Dimensions of YDATA and INMASK do not agree'
   endif

   if (keyword_set(maxrej)) then begin
      if (keyword_set(groupdim)) then begin
         if (n_elements(maxrej) NE n_elements(groupdim)) then $
          message, 'MAXREJ and GROUPDIM must have same number of elements!'
      endif
      if (keyword_set(groupsize)) then begin
         if (n_elements(maxrej) NE n_elements(groupsize)) then $
          message, 'MAXREJ and GROUPSIZE must have same number of elements!'
      endif
   endif

   ;----------
   ; Create OUTMASK, setting =1 for good data

   if (keyword_set(outmask)) then begin
      if (ndata NE n_elements(outmask)) then $
       message, 'Dimensions of YDATA and OUTMASK do not agree'
   endif else begin
      outmask = make_array(size=size(ydata), /byte) + 1
   endelse

   if (NOT keyword_set(ymodel)) then begin
      if (keyword_set(inmask)) then outmask[*] = inmask
      return, 0
   endif

   if (keyword_set(sigma) AND keyword_set(invvar)) then $
    message, 'Cannot set both SIGMA and INVVAR'

   if ((NOT keyword_set(sigma)) AND (NOT keyword_set(invvar))) then begin
      if (keyword_set(inmask)) then igood = where(inmask AND outmask, ngood) $
       else igood = where(outmask, ngood)
      if (ngood GT 1) then $
       sigma = stddev(ydata[igood] - ymodel[igood]) $ ; scalar value
      else $
       sigma = 0
   endif

;   if (n_elements(sigma) NE 1 AND n_elements(sigma) NE ndata) then $
;    message, 'Invalid number of elements for SIGMA'

   ydiff = ydata - ymodel

   ;----------
   ; The working array is BADNESS, which is set to zero for good points
   ; (or points already rejected), and positive values for bad points.
   ; The values determine just how bad a point is, either corresponding
   ; to the number of SIGMA above or below the fit, or to the number of
   ; multiples of MAXDEV away from the fit.

   badness = 0.0 * outmask

   ;----------
   ; Decide how bad a point is according to LOWER

   if (keyword_set(lower)) then begin
      if keyword_set(sigma) then begin
          qbad = ydiff LT (- lower * sigma) 
          badness = (((-ydiff / (sigma + (sigma EQ 0))) > 0) * qbad) + badness
      endif else begin
          qbad = ydiff  * sqrt(invvar) LT (- lower)
          badness = (((-ydiff * sqrt(invvar)) > 0) * qbad) + badness
      endelse
   endif

   ;----------
   ; Decide how bad a point is according to UPPER

   if (keyword_set(upper)) then begin
      if keyword_set(sigma) then begin
        qbad = ydiff GT (upper * sigma) 
        badness = (((ydiff / (sigma + (sigma EQ 0))) > 0) * qbad) + badness
      endif else begin
        qbad = ydiff  * sqrt(invvar) GT upper
        badness = (((ydiff * sqrt(invvar)) > 0) * qbad) + badness
      endelse
   endif

   ;----------
   ; Decide how bad a point is according to MAXDEV

   if (keyword_set(maxdev)) then begin
      qbad = abs(ydiff) GT maxdev
      badness = (abs(ydiff) / maxdev * qbad) + badness
   endif

   ;----------
   ; Do not consider rejecting points that are already rejected by INMASK.
   ; Do not consider rejecting points that are already rejected by OUTMASK
   ;   if /STICKY is set.

   if (keyword_set(inmask)) then badness = badness * inmask
   if (keyword_set(sticky)) then badness = badness * outmask

   ;----------
   ; Reject a maximum of MAXREJ (additional) points in all the data,
   ; or in each group as specified by GROUPSIZE, and optionally along
   ; each dimension specified by GROUPDIM.

   if (keyword_set(maxrej)) then begin
      ; Loop over each dimension of GROUPDIM (or loop once if not set)
      for iloop=0, (n_elements(groupdim)>1)-1 do begin
         ; Assign an index number in this dimension to each data point
         if (n_elements(groupdim) GT 0) then begin
            yndim = size(ydata, /n_dimen)
            if (groupdim[iloop] GT yndim) then $
             message, 'GROUPDIM is larger than number of dimensions for YDATA'
            dimnum = djs_laxisnum(size(ydata,/dimens), iaxis=groupdim[iloop]-1)
         endif else begin
            dimnum = 0
         endelse

         ; Loop over each vector specified by GROUPDIM.  For ex, if
         ; this is a 2-D array with GROUPDIM=1, then loop over each
         ; column of the data.  If GROUPDIM=2, then loop over each row.
         ; If GROUPDIM is not set, then use all whole image.
         for ivec=0, max(dimnum) do begin
            if (keyword_set(dimnum)) then indx = where(dimnum EQ ivec) $
             else indx = lindgen(ndata)

            ; Within this group of points, break it down into groups
            ; of points specified by GROUPSIZE (if set).
            nin = n_elements(indx)
            if (NOT keyword_set(groupsize)) then groupsize = nin
            i1 = 0L
            while (i1 LT nin) do begin
               i2 = (i1 + groupsize[iloop] - 1) < (nin - 1)
               nii = i2 - i1 + 1
               jj = indx[i1:i2]
               ; Test if too many points rejected in this group...
               if (total(badness[jj] NE 0) GT maxrej[iloop]) then begin
                  isort = sort(badness[jj])
                  ; Make the following points good again...
                  badness[jj[isort[0:nii-maxrej[iloop]-1]]] = 0
               endif
               i1 = i1 + groupsize[iloop]
            endwhile
         endfor
      endfor
   endif

   ;----------
   ; Now modify OUTMASK, rejecting points specified by INMASK=0,
   ; OUTMASK=0 (if /STICKY is set), or BADNESS>0.

   newmask = (badness EQ 0)
   if (keyword_set(inmask)) then newmask = newmask AND inmask
   if (keyword_set(sticky)) then newmask = newmask AND outmask

   ; Set QDONE if the input OUTMASK is identical to the output OUTMASK
   qdone = total(newmask NE outmask) EQ 0
   outmask = newmask

   return, qdone
end
;------------------------------------------------------------------------------
