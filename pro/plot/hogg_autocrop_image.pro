;+
; NAME:
;   hogg_autocrop_image
; PURPOSE:
;   remove whitespace border on image read by read_image
; REVISION HISTORY:
;   2003-01-31  written - Hogg
;-
function hogg_autocrop_image,image
dims= size(image,/dimensions)
if n_elements(dims) EQ 3 then timage= total(float(255-image),1) $
else timage=float(255-image)
ximage= total(timage,2)
nx= n_elements(ximage)
yimage= total(timage,1)
ny= n_elements(yimage)
xl= 0L
while ximage[xl] EQ 0.0 do xl= xl+1L
xh= nx-1
while ximage[xh] EQ 0.0 do xh= xh-1L
yl= 0L
while yimage[yl] EQ 0.0 do yl= yl+1L
yh= ny-1
while yimage[yh] EQ 0.0 do yh= yh-1L
if n_elements(dims) EQ 3 then outimage= image[*,xl:xh,yl:yh] $
else outimage= image[xl:xh,yl:yh]
return, outimage
end
