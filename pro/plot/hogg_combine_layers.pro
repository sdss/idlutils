;+
; NAME:
;   hogg_combine_layers
; PURPOSE:
;   Combine bitmapped figures into one bitmapped figure
; COMMENTS:
;   To make an image black, use r=g=b=0.
;   To make an image red, use r=1, g=b=0.
;   To make an image cyan, use r=0, g=b=1.
; INPUTS:
;   image    - [nx,ny,N] set of N float image layers (scaled from 0 to 1)
;   r,g,b    - [N] float vectors of r g and b values to use for each image
;              (scaled from 0 to 1)
;   filename - filename for output PPM file
; KEYWORDS:
; REVISION HISTORY:
;   2002-12-23  written - Hogg
;-
pro hogg_combine_layers, image,r,g,b,filename

splog, minmax(image)
splog, r
splog, g
splog, b
splog, filename

; get dimensions
dims= size(image,/dimensions)
nx= dims[0]
ny= dims[1]
if n_elements(dims) EQ 3 then nim= dims[2] else nim= 1
image= reform(image,nx,ny,nim)

; make output 3-layer image
oimage= fltarr(3,nx,ny)+1.0

; loop over input layers
for im=0,nim-1 do begin

; compute factors
    oimage[0,*,*]= oimage[0,*,*]*(r[im]+(1.0-r[im])*image[*,*,im])
    oimage[1,*,*]= oimage[1,*,*]*(g[im]+(1.0-g[im])*image[*,*,im])
    oimage[2,*,*]= oimage[2,*,*]*(b[im]+(1.0-b[im])*image[*,*,im])
endfor

; output rgb image
oimage= floor(oimage*255.0) < 255
splog, minmax(oimage)

write_ppm, filename,oimage

end
