;+
;NAME:
;  djs_rgb_make
;
; PURPOSE:
;   Creates JPEG from three images or FITS files
;
; CALLING SEQUENCE:
;   djs_rgb_make, rimage, gimage, bimage, [ name=, origin=, scales=, $
;    nonlinearity=, rebinfactor=, overlay=, quality= ]
;
; INPUTS:
;   rimage,gimage,bimage - Input 2-dimensional images or names of FITS files;
;                 the dimensions of all images must agree
;
; OPTIONAL KEYWORDS:
;   name        - Name of the output JPEG file; default to 'test.jpg'
;   origin      - Subtract these zero-point values from the input images
;                 before any other scalings; default to [0,0,0]
;   scales      - Multiplicative scaling for each image; default to [1,1,1]
;   nonlinearity- 'b'
;               - b=0 for linear fit, b=Inf for logarithmic
;               - default is 3
;   rebinfactor - integer by which to rebin pixels in the x and y
;                 directions; eg, a rebinfactor of 2 halves the number
;                 of pixels in each direction and quarters the total
;                 number of pixels in the image.
;   overlay     - Optional overlay image, which must be dimensionsed as
;                 [NX/REBINFACTOR,NY/REBINFACTOR,3]
;   quality     - Quality for WRITE_JPEG; default to 75 per cent
;
; OUTPUTS:
;
; COMMENTS:
;   This routine is based upon Nick Wherry's code NW_RGB_MAKE.
;   The main difference is that saturated pixels are grouped into
;   contiguous "objects", which are then assigned a color based upon
;   the sum of all the pixels in that object.
;
;   The nonlinearity function applied is
;     RIMAGE = RIMAGE * asinh(b*r)/(b*r)
;     GIMAGE = GIMAGE * asinh(b*r)/(b*r)
;     BIMAGE = BIMAGE * asinh(b*r)/(b*r)
;   where "b" is the input NONLINEARITY parameter and we define at each pixel
;     r = (RIMAGE + GIMAGE + BIMAGE)
;
; EXAMPLES:
;
; BUGS:
;
; REVISION HISTORY:
;   10-May-2004 - Written by D. Schlegel, Princeton;
;                 based upon Nick Wherry's code NW_RGB_MAKE
;-
;------------------------------------------------------------------------------
pro djs_rgb_make, rimage, gimage, bimage, name=name, $
 origin=origin1, scales=scales1, nonlinearity=nonlinearity1, $
 rebinfactor=rebinfactor1, overlay=overlay, quality=quality

   t0 = systime(1)
   thismem = float(ulong(memory()))

   ;----------
   ; Set defaults

   if (NOT keyword_set(name)) THEN name = 'test.jpg'
   if (n_elements(origin1) EQ 0) THEN origin = [0,0,0] $
    else origin = float(origin1)
   if (n_elements(scales1) EQ 0) THEN scales = [1,1,1] $
    else scales = float(scales1)
   if (n_elements(rebinfactor1) EQ 0) THEN rebinfactor = 1 $
    else rebinfactor = float(rebinfactor1)
   if (NOT keyword_set(quality)) then quality = 75
   if (n_elements(nonlinearity1) EQ 0) then nonlinearity = 3. $
    else nonlinearity = float(nonlinearity1)

   ;----------
   ; Read the 3 images, and sanity-check that they are the same dimensions

   if (size(rimage,/tname) EQ 'STRING') then begin
      rimg = mrdfits(rimage, /silent)
      gimg = mrdfits(gimage, /silent)
      bimg = mrdfits(bimage, /silent)
   endif else begin
      rimg = float(rimage)
      gimg = float(gimage)
      bimg = float(bimage)
   endelse

   dims = size(rimg, /dimens)
   if (size(rimg, /n_dimen) NE 2) then begin
      print, 'Images must be 2-dimensional arrays!'
      return
   endif
   if (total(size(gimg, /dimens) NE dims) NE 0 $
    OR total(size(bimg, /dimens) NE dims) NE 0) then begin
      print, 'Dimensions of all 3 images must agree!'
      return
   endif

   ;----------
   ; Optionally rebin the images

   if (rebinfactor NE 1) then begin
      dims = round(dims / rebinfactor)
      if (rebinfactor EQ round(rebinfactor)) then begin
         rimg = rebin(rimg, dims[0], dims[1], /sample)
         gimg = rebin(gimg, dims[0], dims[1], /sample)
         bimg = rebin(bimg, dims[0], dims[1], /sample)
      endif else begin
         rimg = congrid(rimg, dims[0], dims[1], /interp)
         gimg = congrid(gimg, dims[0], dims[1], /interp)
         bimg = congrid(bimg, dims[0], dims[1], /interp)
      endelse
   endif

   ;----------
   ; Apply optional zero-point offsets or rescalings

   if (scales[0] NE 1 OR origin[0] NE 0) then $
    rimg = (scales[0] * (rimg - origin[0])) > 0 $
   else $
    rimg = rimg > 0
   if (scales[1] NE 1 OR origin[1] NE 0) then $
    gimg = (scales[1] * (gimg - origin[1])) > 0 $
   else $
    gimg = gimg > 0
   if (scales[2] NE 1 OR origin[2] NE 0) then $
    bimg = (scales[2] * (bimg - origin[2])) > 0 $
   else $
    bimg = bimg > 0

   ;----------
   ; Compute the nonlinear mapping, but do not apply it yet
   ; (until after we deal with saturated stars)

   radius = rimg + gimg + bimg
   radius = nonlinearity * radius
   radius = radius + (radius LE 0)
   nonlinfac = asinh(radius) / radius
   radius = 0 ; clear memory

   ;----------
   ; Determine where in the image we are saturating any of the 3 colors

   satmask = (rimg * nonlinfac GT 1) $
    OR (gimg * nonlinfac GT 1) $
    OR (bimg * nonlinfac GT 1)

   ;----------
   ; Apply the nonlinearity corrections, **except** for saturated pixels

   isat = where(satmask, nsat)
   if (nsat GT 0) then nonlinfac[isat] = 1

   rimg = rimg * nonlinfac
   gimg = gimg * nonlinfac
   bimg = bimg * nonlinfac
   nonlinfac = 0 ; clear memory

   ;----------
   ; Loop through each saturated object, and replace all pixels in each object
   ; with the mean color of that object

   ; This function groups all contiguous saturated pixels into one object.
   ; (This uses quite a bit of memory, though)
   objmask = grow_object(satmask)

   if (nsat GT 0) then begin
      nobj = max(objmask[isat])

      ; Produce the list of all saturated object pixels, sorted by object ID
      if (nobj EQ 1) then begin
         i1 = 0L
         i2 = nsat - 1
      endif else begin
         sortmask = objmask[isat]
         isort = sort(sortmask)
         isat = isat[isort]
         sortmask = sortmask[isort]
         isort = 0 ; clear memory
         i1 = where(sortmask NE shift(sortmask,1))
         sortmask = 0 ; clear memory
         i2 = [i1[1:nobj-1]-1, nsat-1]
      endelse
      for iobj=0L, nobj-1 do begin
         indx = isat[i1[iobj]:i2[iobj]]
         rtmp = total(rimg[indx]) > 0
         gtmp = total(gimg[indx]) > 0
         btmp = total(bimg[indx]) > 0
         maxval = max([rtmp,gtmp,btmp])
         rimg[indx] = rtmp / maxval
         gimg[indx] = gtmp / maxval
         bimg[indx] = btmp / maxval
      endfor
   endif
   objmask = 0 ; clear memory
   isat = 0
   i1 = 0
   i2 = 0

   ;----------
   ; Optionally add the overlay images

   if (keyword_set(overlay)) then begin
      if (total(size(overlay, /dimens) NE [dims[0],dims[1],3]) NE 0) then begin
         splog, 'Ignoring overlay since dimensions disagree!'
      endif else begin
         rimg = rimg + overlay[*,*,0]
         gimg = gimg + overlay[*,*,1]
         bimg = bimg + overlay[*,*,2]
      endelse
   endif

   ;----------
   ; Convert from a floating-point to byte-scaled image

   byteimg = bytarr(dims[0], dims[1], 3)
   byteimg[*,*,0] = byte((floor(temporary(rimg) * 256) > 0) < 255)
   byteimg[*,*,1] = byte((floor(temporary(gimg) * 256) > 0) < 255)
   byteimg[*,*,2] = byte((floor(temporary(bimg) * 256) > 0) < 255)

   ;----------
   ; Generate the JPEG image

   write_jpeg, name, byteimg, true=3, quality=quality

   thismem = float(ulong(memory()))
   splog, 'Max memory usage = ', thismem[3]/1.d6, ' MB'
   splog, 'Elapsed time = ', systime(1)-t0, ' sec'

   return
end
;------------------------------------------------------------------------------
