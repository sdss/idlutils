;+
;NAME:
;  nw_rebin_image
;PURPOSE:
;  Factors the dimensions of the image by specified value
;CALLING SEQUENCE:
;  nw_rebin_image(colors,rebinfactor)
;INPUTS:
;  colors      - [NX,NY,3] array containing the R, G, and B images
;OPTIONAL INPUTS:
;  rebinfactor - factor by which to multiply NX and NY
;KEYWORDS:
;  none
;OUTPUTS:
;  The resized image 
;BUGS:
;  
;DEPENDENCIES:
;
;REVISION HISTORY:
;  11/14/03 written - wherry
;-
FUNCTION nw_rebin_image,colors,rebinfactor

dim = size(colors,/dimensions)
NX_new = round(dim[0]*rebinfactor)
NY_new = round(dim[1]*rebinfactor)
rebinned_colors = fltarr(NX_new,NY_new,3)

if (rebinfactor GT 1) AND (round(rebinfactor) EQ rebinfactor) then begin
    FOR k=0,2 DO $
      rebinned_colors[*,*,k] = rebin(colors[*,*,k],NX_new,NY_new,/sample)
endif else begin
    FOR k=0,2 DO $
      rebinned_colors[*,*,k] = congrid(colors[*,*,k],NX_new,NY_new)
endelse

RETURN,rebinned_colors
END
