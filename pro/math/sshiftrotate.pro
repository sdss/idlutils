;+
; NAME:
;   sshiftrotate
;
; PURPOSE:
;   Routine to reject points when doing an iterative fit to data.
;
; CALLING SEQUENCE:
;   newimg =  sshiftrotate( image, [ theta, xshift=, yshift=, xcen=, ycen=, $
;    /bigger, xoffset=, yoffset= ]
;
; INPUTS:
;   image      - Image (2-dimensional)
;
; OPTIONAL KEYWORDS:
;   theta      - Rotate image clockwise this angle [degrees] about
;                the 0-indexed point XCEN,YCEN; default to 0 degrees
;   xshift    - Shift in X direction
;   yshift    - Shift in Y direction
;   xcen       - Center X position for rotation; default to the center of
;                the image
;   ycen       - Center Y position for rotation; default to the center of
;                the image
;   bigger     - If set, then keep the bigger image necessary for containing
;                the shifted + rotated image.
;
; OUTPUTS:
;   newimg     - Rotated and shifted image
;
; OPTIONAL OUTPUTS:
;   xoffset    - If /BIGGER is set, then this contains the integer pixel
;                offset in the X direction of the enlarged image.
;   yoffset    - If /BIGGER is set, then this contains the integer pixel
;                offset in the Y direction of the enlarged image.
;
; COMMENTS:
;   When both a shifT (XSHIFT,YSHIFT) and a rotation (THETA) are specified,
;   the resulting image is as if the shift is performed first, and the
;   rotation second.
;
; EXAMPLES:
;   Generate a random image and rotate by 30 degrees:
;     IDL> image = smooth(randomu(1234,200,200),5)
;     IDL> newimg = sshiftrotate(image,30)
;
; BUGS:
;   Currently only good for rotations +/- 45 deg --> Need to transpose first
;     for other angles!???
;   The sinc shifts need not do all pixels in each row each time, only
;     the "active" area!???  This will just be for a speed improvement.
;   Special-case rotations of 0,90,180,270 !???
;   Optionally return a mask of the illuminated region???
;
; PROCEDURES CALLED:
;   sshift()
;
; REVISION HISTORY:
;   18-Sep-2002  Written by D. Schlegel, Princeton
;------------------------------------------------------------------------------
function sshiftrotate, image, theta1, xshift=xshift, yshift=yshift, $
 xcen=xcen, ycen=ycen, bigger=bigger, xoffset=xoffset, yoffset=yoffset

   if (n_params() LT 2) then $
    message, 'Incorrect number of arguments'
   if (NOT keyword_set(xshift)) then xshift = 0
   if (NOT keyword_set(yshift)) then yshift = 0
   dims = size(image, /dimens)
   nx = dims[0]
   ny = dims[1]
   if (NOT keyword_set(xcen)) then xcen = 0.5 * nx + 0.5
   if (NOT keyword_set(ycen)) then ycen = 0.5 * ny + 0.5
   if (keyword_set(theta1)) then theta = theta1 $
    else theta = 0

   t0 = systime(1)

   ; Compute the offset functions for each of the 3 sinc shifts

   sint = sin(-theta/!radeg)
   aslope = (-2. + sqrt(4. - 2.*sint^2)) / (2. * sint)
   bslope = -2. * aslope / (1. + aslope^2)
   cslope = aslope
   ssx = xshift - cslope * yshift
   ssy = -bslope * xshift + (1+bslope*cslope) * yshift

   ;----------
   ; Compute the size of the super-image for containing the shifts

   ypad1 = -min( bslope * ([0,(nx-1.)] - xcen), max=ypad2)
   xpad1 = -min( aslope * ([0,(ny-1.)] - ycen) $
               + aslope * ([-ypad1,(ny-1.)+ypad2] - ycen), max=xpad2)

   xpad1 = xpad1 + ((-xshift)>0)
   xpad2 = xpad2 + ((xshift)>0)
   ypad1 = ypad1 + ((-yshift)>0)
   ypad2 = ypad2 + ((yshift)>0)

   xpad1 = ceil(xpad1) > 0L
   xpad2 = ceil(xpad2) > 0L
   ypad1 = ceil(ypad1) > 0L
   ypad2 = ceil(ypad2) > 0L

   ;----------
   ; Construct the output image, padding by the necessary amount in
   ; each dimension

   nbigx = nx + xpad1 + xpad2
   nbigy = ny + ypad1 + ypad2
   print, 'Resize image from ', nx, ny, ' to ', nbigx, nbigy

   newimg = fltarr(nbigx, nbigy) ; What if this is double???
   newimg[xpad1:xpad1+nx-1,ypad1:ypad1+ny-1] = image

   xvec = findgen(nbigx) - xcen - xpad1
   yvec = findgen(nbigy) - ycen - ypad1

   ;----------
   ; Do the sinc shifts

   for iy=0,nbigy-1 do $
    if (abs(yvec[iy]*aslope+ssx) LT 0.95*nbigx) then $
     newimg[*,iy] = sshift(newimg[*,iy],yvec[iy]*aslope+ssx)

   for ix=0,nbigx-1 do $
    if (abs(xvec[ix]*bslope+ssy) LT 0.95*nbigy) then $
     newimg[ix,*] = sshift(newimg[ix,*],xvec[ix]*bslope+ssy)

   for iy=0,nbigy-1 do $
    if (abs(yvec[iy]*cslope) LT 0.95*nbigx) then $
     newimg[*,iy] = sshift(newimg[*,iy],yvec[iy]*cslope)

   ;----------
   ; Trim the output image

   if (keyword_set(bigger)) then begin
      xoffset = xpad1
      yoffset = ypad1
   endif else begin
      xoffset = 0
      yoffset = 0
      newimg = newimg[xpad1:xpad1+nx-1,ypad1:ypad1+ny-1]
   endelse

   print, 'Time to rotate = ', systime(1)-t0

   return, newimg
end
;------------------------------------------------------------------------------
