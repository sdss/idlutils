;+
; NAME:
;   hogg_weighted_mean_surface
; PURPOSE:
;   make an image of the weighted mean for a 2-d set of measurements
; CALLING SEQUENCE:
;   images = weighted_mean_surface(x,y,weight,quantity,xbin,ybin,dx,dy)
; INPUTS:
;   x,y       - [N] values of measurements
;   quantity  - [N] measurements themselves
;   weight    - [N] weights for measurements
;   xbin,ybin - [nx],[ny] vectors of coordinates of image pixel centers
;   dx,dy     - size of sliding box in which means are taken
; OUTPUTS:
;   images    - [nx,ny,4] output images of number of contributing
;               points (image 0), total weight used (image 1), total
;               square weight used (image 2), and weighted mean (image 3)
; COMMENTS:
; BUGS:
; REVISION HISTORY:
;   2003-01-08  written - Hogg
;-
function hogg_weighted_mean_surface, x,y,quantity,weight,xbin,ybin,dx,dy

; set dimensions, defaults, arrays, etc
npt= n_elements(x)
nx= n_elements(xbin)
ny= n_elements(ybin)
image= dblarr(nx,ny,4)

; loop over x,y subsamples
for xi= 0L,nx-1 do for yi= 0L,ny-1 do begin
    isub= where(abs(x-xbin[xi]) LE abs(0.5*dx) AND $
                abs(y-ybin[yi]) LE abs(0.5*dy),nsub)
    image[xi,yi,0]= double(nsub)
    if nsub GT 0 then begin
        image[xi,yi,1]= total(weight[isub],/double)
        image[xi,yi,2]= total((weight[isub])^2,/double)
        image[xi,yi,3]= total(weight[isub]*quantity[isub],/double) $
          /image[xi,yi,1]
    endif
endfor

; return
return, image
end
