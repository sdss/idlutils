;+
; NAME:
;   grow_object
;
; PURPOSE:
;   Identify objects as the contiguous non-zero pixels in an image.
;
; CALLING SEQUENCE:
;   grow_object, image, [ mask, xstart=, ystart=, putval=, /diagonal, nadd= ]
;
; INPUTS:
;   image      - Integer-valued image vector or array, where non-zero pixel
;                values indicate that an object touches that pixel.
;
; OPTIONAL INPUTS:
;   mask       - Mask with object IDs; zeros indicate that there is no object
;                in that pixel, and positive values are used as object IDs.
;                Negative values are not allowed.
;   xstart     - Starting X position(s) for assembling the object; default to
;                settting all pixels where IMAGE != 0.
;   ystart     - Starting Y position(s) for assembling the object; default to
;                settting all pixels where IMAGE != 0.
;   putval     - Object ID(s) to put in MASK as positive-valued long integer;
;                default to a unique integer (starting at 1) for each object.
;                This can either be a scalar, or a vector with one element
;                per XSTART,YSTART position.
;   diagonal   - If set, then consider diagonally-offset pixels as contigous
;                as well as pixels simply to the left, right, down, or up.
;
; OUTPUTS:
;   mask       - (Modified)
;
; OPTIONAL OUTPUTS:
;   nadd       - Number of pixels added to all objects
;
; COMMENTS:
;   Find the pixels that make up an "object" as the contiguous non-zero
;   pixels in IMAGE that touch the pixel XSTART,YSTART.  All such pixels
;   have MASK set to PUTVAL.
;
;   If XSTART,YSTART,PUTVAL are not specified, then all objects are found
;   in the image and assigned unique object IDs in MASK starting at 1.
;   Note that in this case, max(MASK) is the number of objects.
;
; EXAMPLES:
;   Create a random image of 0s and 1s, and identify all contiguous pixels
;   as objects:
;   IDL> image=smooth(randomu(123,100,100),5) GT 0.55 & mask = 0
;   IDL> grow_object, image, mask
;
; BUGS:
;
; PROCEDURES CALLED:
;   Dynamic link to grow_obj.c
;
; REVISION HISTORY:
;   20-May-2003  Written by D. Schlegel, Princeton
;-
;------------------------------------------------------------------------------
pro grow_object, image, mask, xstart=xstart1, ystart=ystart1, putval=putval1, $
 diagonal=diagonal, nadd=nadd

   ndim = size(image, /n_dimen)
   dims = size(image, /dimens)
   nx = dims[0]
   if (ndim EQ 1) then ny = 1L $
    else ny = dims[1]
   if (NOT keyword_set(mask)) then begin
      mask = long(0 * image)
   endif else begin
      if (min(mask) LT 0) then $
       message, 'MASK cannot have negative values!'
      if (n_elements(mask) NE n_elements(image)) then $
       message, 'Dimensions of IMAGE and MASK must agree'
   endelse
   nxcen = n_elements(xstart1)
   nycen = n_elements(ystart1)
   if (nxcen NE nycen) then $
    message, 'Number of elements in XSTART,YSTART must agree'

   ; Set default return values
   nadd = 0L

   if (nxcen EQ 1) then begin
      xstart = long(xstart1[0])
      ystart = long(ystart1[0])
   endif else if (nxcen GT 1) then begin
      if (keyword_set(putval1)) then $
       objid = putval1[i<(n_elements(putval1)-1)] $
      else $
       objid = 1L
      for i=0L, nxcen-1 do begin
         grow_object, image, mask, $
          xstart=long(xstart1[i]), ystart=long(ystart1[i]), $
          putval=objid, nadd=nadd1, diagonal=diagonal
         if (nadd1 GT 0) then begin
            nadd = nadd + nadd1
            if (NOT keyword_set(putval1)) then objid = objid + 1L
         endif
      endfor
      return
   endif else begin
      indx = where(image NE 0, ct)
      if (ct EQ 0) then return
      ystart = indx / nx
      xstart = indx - ystart * nx
      if (keyword_set(putval1)) then objid = putval1 $
       else objid = 1L
      for i=0L, ct-1 do begin
         grow_object, image, mask, xstart=xstart[i], ystart=ystart[i], $
          putval=objid, nadd=nadd1, diagonal=diagonal
         if (nadd1 GT 0) then begin
            nadd = nadd + nadd1
            if (NOT keyword_set(putval1)) then objid = objid + 1L
         endif
      endfor
      return
   endelse

   if (xstart LT 0 OR xstart GE nx OR ystart LT 0 OR ystart GE ny) then return

   ; Don't bother calling the C code if we know it won't do anything
   if (image[xstart,ystart] EQ 0) then return

   if (keyword_set(putval1)) then begin
      if (putval1 LT 0) then message, 'PUTVAL cannot be negative'
      putval = long(putval1)
   endif else begin
      putval = 1L
   endelse

   soname = filepath('libimage.so', $
    root_dir=getenv('IDLUTILS_DIR'), subdirectory='lib')

   qdiag = long(keyword_set(diagonal))
   if size(image, /tname) EQ 'LONG' then begin 
      nadd = call_external(soname, 'grow_obj', $
       nx, ny, image, mask, xstart, ystart, putval, qdiag)
   endif else begin  
      nadd = call_external(soname, 'grow_obj', $
       nx, ny, long(image), mask, xstart, ystart, putval, qdiag)
   endelse

end
;------------------------------------------------------------------------------
