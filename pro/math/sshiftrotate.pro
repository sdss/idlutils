;+
; NAME:
;   sshiftrotate
;
; PURPOSE:
;   Routine to reject points when doing an iterative fit to data.
;
; CALLING SEQUENCE:
;   newimg =  sshiftrotate( image, theta, [ xoffset=, yoffset=, xcen=, ycen= ]
;
; INPUTS:
;   image      - Image (2-dimensional)
;   theta      - Rotate image clockwise this angle [degrees] about
;                the 0-indexed point XCEN,YCEN
;
; OPTIONAL KEYWORDS:
;   xoffset    - Shift in X direction
;   yoffset    - Shift in Y direction
;   xcen       - Center X position for rotation; default to the center of
;                the image
;   ycen       - Center Y position for rotation; default to the center of
;                the image
;
; OUTPUTS:
;   newimg     - Rotated and shifted image
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;
; EXAMPLES:
;   Generate a random image and rotate by 30 degrees:
;     IDL> image = smooth(randomu(1234,200,200),5)
;     IDL> newimg = sshiftrotate(image,30)
;
; BUGS:
;
; PROCEDURES CALLED:
;   sshift()
;
; REVISION HISTORY:
;   30-Aug-2000  Written by D. Schlegel, Princeton
;------------------------------------------------------------------------------
function sshiftrotate, image, theta, xoffset=xoffset, yoffset=yoffset, $
 xcen=xcen, ycen=ycen

   if (n_params() LT 2) then $
    message, 'Incorrect number of arguments'
   if (NOT keyword_set(xoffset)) then xoffset = 0
   if (NOT keyword_set(yoffset)) then yoffset = 0
   dims = size(image, /dimens)
   nx = dims[0]
   ny = dims[1]
   if (NOT keyword_set(xcen)) then xcen = 0.5 * nx + 0.5
   if (NOT keyword_set(ycen)) then ycen = 0.5 * ny + 0.5

   xvec = findgen(nx) - xcen
   yvec = findgen(ny) - ycen

   sint = sin(-theta/!radeg)
   a = (-2. + sqrt(4. - 2.*sint^2)) / (2. * sint)
   b = -2. * a / (1. + a^2)
   c = a
   ssx = xoffset - c * yoffset
   ssy = -b * xoffset + (1+b*c) * yoffset


   newimg = image
   for iy=0,ny-1 do $
    if (abs(yvec[iy]*a+ssx) LT 0.95*nx) then $
     newimg[*,iy] = sshift(newimg[*,iy],yvec[iy]*a+ssx)
   for ix=0,nx-1 do $
    if (abs(xvec[ix]*a+ssy) LT 0.95*ny) then $
     newimg[ix,*] = sshift(newimg[ix,*],xvec[ix]*b+ssy)
   for iy=0,ny-1 do $
    if (abs(yvec[iy]*a) LT 0.95*nx) then $
     newimg[*,iy] = sshift(newimg[*,iy],yvec[iy]*c)

   return, newimg
end
;------------------------------------------------------------------------------
