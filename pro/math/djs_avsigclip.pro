;+
; NAME:
;   djs_avsigclip
;
; PURPOSE:
;   Average multiple images with sigma-rejection.
;
; CALLING SEQUENCE:
;   result = djs_avsigclip( array, [ dimension, sigrej=, maxiter= ] )
;
; INPUTS:
;   array      - N-dimensional array
;
; OPTIONAL INPUTS:
;   dimension  - The dimension over which to collapse the data.  If ommitted,
;                assume that the last dimension is the one to collapse.
;   sigrej     - Sigma for rejection; default to 3.0.
;   maxiter    - Maximum number of sigma rejection iterations.  One iteration
;                does no sigma rejection; default to 10 iterations.
;
; OUTPUTS:
;   result     - The output array.
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   The DIMENSION input is analogous to that used by the IDL built-in
;   function TOTAL.
;
; EXAMPLES:
;   Create a data cube of 10 random-valued 100x200 images.  At each pixel in
;   the image, compute the average of the 10 values, but rejecting 3-sigma
;   outliers:
;   > array = randomu(123,100,200,10)
;   > ave = djs_avsigclip(array,sigrej=3)
;
; PROCEDURES CALLED:
;   Dynamic link to arravsigclip.c
;
; REVISION HISTORY:
;   07-Jul-1999  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------
function djs_avsigclip, array, dim, sigrej=sigrej, maxiter=maxiter

   ; Need at least 1 parameter
   if (N_params() LT 1) then begin
      print, 'Syntax - result = djs_avsigclip( array, [ dimension, sigrej=, maxiter= ] )'
      return, -1
   endif

   if (NOT keyword_set(dim)) then dim = size(array, /n_dim)
   if (NOT keyword_set(sigrej)) then sigrej = 3.0
   if (NOT keyword_set(maxiter)) then maxiter = 10

   dimvec = size(array, /dimensions)
   ndim = N_elements(dimvec)

   if (dim GT ndim OR dim LT 1) then begin
      message, 'DIM must be between 1 and '+string(ndim)+' inclusive'
   endif

   ; Allocate memory for the output array
   newdimvec = dimvec[ where(lindgen(ndim)+1 NE dim) ]
   newsize = N_elements(array) / dimvec[dim-1]
   avearr = reform(fltarr(newsize), newdimvec)

   retval = call_external(getenv('IDL_EVIL')+'libmath.so', 'arravsigclip', $
    ndim, dimvec, float(array), long(dim), float(sigrej), float(sigrej), $
    long(maxiter), avearr)

   return, avearr
end
;------------------------------------------------------------------------------
