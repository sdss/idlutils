;------------------------------------------------------------------------------
;+
; NAME:
;   djs_iterstat
;
; PURPOSE:
;   Compute the mean, median and/or sigma of data with iterative sigma clipping.
;
; CALLING SEQUENCE:
;   djs_iterstat, image, [sigrej=, maxiter=, mean=, median=, sigma=, mask=]
;
; INPUTS:
;   image:      Input data
;
; OPTIONAL INPUTS:
;   sigrej:     Sigma for rejection; default to 3.0
;   maxiter:    Maximum number of sigma rejection iterations; default to 10
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;   mean:       Computed mean
;   median:     Computed median
;   sigma:      Computed sigma
;   mask:       Mask set to 0 for good points, and 1 for rejected points
;
; PROCEDURES CALLED:
;
; COMMENTS:
;   This routine is based upon Mark Dickinson's IRAF (!) script ITERSTAT.
;   It iteratively rejects outliers as determined by SIGREJ.  It stops
;   when one of the following conditions is met:
;   (1) The maximum number of iterations, as set by MAXITER, is reached.
;   (2) No new pixels are rejected, as compared to the previous iteration.
;   (3) At least 2 pixels remain from which to compute statistics.  If not,
;       then the returned values are based upon the previous iteration.
;
;   Note that this routine calls the IDL procedure MOMENT, which is stupidly
;   slow.  I compound upon this sluggishness by calling MEDIAN in each
;   iteration.
;
; REVISION HISTORY:
;   16-Jun-1999  Written by David Schlegel, Princeton
;-
;------------------------------------------------------------------------------
pro djs_iterstat, image, sigrej=sigrej, maxiter=maxiter, $
 mean=fmean, median=fmedian, sigma=fsig, mask=mask
 
   ; Need 1 parameter
   if N_params() LT 1 then begin
      print, 'Syntax - djs_iterstat, image, [sigrej=, maxiter=, mean=, median=, sigma=,'
      print, ' mask= ]'
      return
   endif

   if (NOT keyword_set(sigrej)) then sigrej = 3.0
   if (NOT keyword_set(maxiter)) then maxiter = 10

   ;----------
   ; Special cases of 0 or 1 data points

   ngood = N_elements(image)
   if (ngood EQ 0) then begin
      print, 'No data points'
      fmean = 0.0
      fmedian = 0.0
      fsig = 0.0
      mask = 0B
      return
   endif
   if (ngood EQ 1) then begin
      print, 'Only 1 data point'
      fmean = image[0]
      fmedian = fmean
      fsig = 0.0
      mask = 0B
      return
   endif

   ;----------
   ; Compute the mean + stdev of the entire image.
   ; These values will be returned if there are fewer than 2 good points.

   fmean = (moment(image, sdev=fsig))[0]
   fmedian = fmean
   iiter = 1
   mask = bytarr(ngood)

   ;----------
   ; Iteratively compute the mean + stdev, updating the sigma-rejection
   ; thresholds each iteration.

   nlast = -1
   while (iiter LT maxiter AND nlast NE ngood AND ngood GE 2) do begin
      loval = fmean - sigrej * fsig
      hival = fmean + sigrej * fsig
      nlast = ngood
      mask = image LT loval OR image GT hival
      igood = where(mask EQ 0, ngood)
      if (ngood GE 2) then begin
         fmean = (moment(image[igood], sdev=fsig))[0]
         fmedian = median(image[igood])
      endif
      iiter = iiter + 1
   endwhile

   return
end
;------------------------------------------------------------------------------
