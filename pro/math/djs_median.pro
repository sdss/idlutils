;+
; NAME:
;   djs_median
;
; PURPOSE:
;   Return the median of an image either with a filtering box or by collapsing
;   the image along one of its dimensions.
;
; CALLING SEQUENCE:
;   result = djs_median( array, [ dimension, width= ] )
;
; INPUTS:
;   array      - N-dimensional array
;
; OPTIONAL INPUTS:
;   dimension  - The dimension over which to compute the median, starting
;                at one.  If this argument is not set, the median of all array
;                elements (or all elements within the median window described
;                by WIDTH) are medianed.
;   width      - Width of median window; scalar value.
;                It is invalid to specify both DIMENSION and WIDTH.
;
; OUTPUTS:
;   result     - The output array.  If neither DIMENSION nor WIDTH are set,
;                then RESULT is a scalar.  If DIMENSION is not set and WIDTH
;                is set, then RESULT has the same dimensions as ARRAY.
;                If DIMENSION is set and WIDTH is not
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   The DIMENSION input is analogous to that used by the IDL built-in
;   function TOTAL.
;
;   I should like to add the functionality of having WIDTH be an N-dimensional
;   smoothing box.  For example, one should be able to median a 2-D image
;   with a 3x5 filtering box.
;
; EXAMPLES:
;   Create a 2-D image and compute the median of the entire image:
;   > array = findgen(100,200)
;   > print, djs_median(array)
;
;   Create a data cube of 3 random-valued 100x200 images.  At each pixel in
;   the image, compute the median of the 3:
;   > array = randomu(123,100,200,3)
;   > medarr = djs_median(array,3)
;
;   Create a random-valued 2-D image and median-filter with a 9x9 filtering box:
;   > array = randomu(123,100,200)
;   > medarr = djs_median(array,9)
;
; PROCEDURES CALLED:
;   Dynamic link to arrmedian.c
;
; REVISION HISTORY:
;   06-Jul-1999  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------
function djs_median, array, dim, width=width

   ; Need at least 1 parameter
   if (N_params() LT 1) then begin
      print, 'Syntax - result = djs_median( array, [ dimension, width= ] )'
      return, -1
   endif

   if (NOT keyword_set(dim) AND NOT keyword_set(width)) then begin

      medarr = median(array, /even)

   endif else if (NOT keyword_set(dim)) then begin

      medarr = median(array, width, /even)

   endif else if (NOT keyword_set(width)) then begin

      dimvec = size(array, /dimensions)
      ndim = N_elements(dimvec)

      if (dim GT ndim OR dim LT 1) then begin
         message, 'DIM must be between 1 and '+string(ndim)+' inclusive'
      endif

      ; Allocate memory for the output array
      newdimvec = dimvec[ where(lindgen(ndim)+1 NE dim) ]
      newsize = N_elements(array) / dimvec[dim-1]
      medarr = reform(fltarr(newsize), newdimvec)

      retval = call_external(getenv('IDL_EVIL')+'libmath.so', 'arrmedian', $
       ndim, dimvec, float(array), long(dim), medarr)

   endif else begin
      message, 'Invalid to specify both DIMENSION and WIDTH'
   endelse

   return, medarr
end
;------------------------------------------------------------------------------
