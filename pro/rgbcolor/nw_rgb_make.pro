;+
;NAME:
;  nw_rgb_make
;PURPOSE:
;  Creates JPEG (or TIFF) from images
;CALLING SEQUENCE:
;  nw_rgb_make, Rim, Gim, Bim, [name=, scales=, nonlinearity=, $
;      origin=, rebinfactor=, /saturatetowhite]
;INPUTS:
;  Rim,Gim,Bim - R, G, and B fits file names, or data arrays
;OPTIONAL INPUTS:
;  name        - name of the output jpeg file
;  scales      - (3x1) array to scale the R/G/B
;              - defaults are [1.,1.,1.]
;  nonlinearity- 'b'
;              - b=0 for linear fit, b=Inf for logarithmic
;              - default is 3
;  origin      - (3x1) array containing R0/G0/B0
;              - default is [0,0,0]
;  rebinfactor - integer by which to rebin pixels in the x and y
;                directions; eg, a rebinfactor of 2 halves the number
;                of pixels in each direction and quarters the total
;                number of pixels in the image.
;  quality     - quality input for WRITE_JPEG
;  overlay     - [nx/rebinfactor,ny/rebinfactor,3] image to overlay on
;                the input images
;OPTIONAL KEYWORDS:
;  saturatetowhite
;              - choose whether to saturate high-value pixels to white
;                or to color
;  tiff        - make tiff instead of jpeg
;OPTIONAL OUTPUTS:
;  
;EXAMPLE:
;  
;KEYWORDS:
;  none
;OUTPUTS:
;  JPEG (or TIFF)
;DEPENDENCIES:
;  
;BUGS:
;  If the code congridded before making the initial colors matrix, it
;  would use less memory and be faster.
;  
;REVISION HISTORY:
; 12/03/03 written - wherry
;-
PRO nw_rgb_make,Rim,Gim,Bim,name=name,scales=scales,nonlinearity= $
                nonlinearity,origin=origin,rebinfactor=rebinfactor, $
                saturatetowhite=saturatetowhite,quality=quality, $
                overlay=overlay,colors=colors,tiff=tiff

;set defaults
IF (keyword_set(tiff)) THEN suffix='tif' ELSE suffix='jpg'
IF (NOT keyword_set(name)) THEN name = 'nw_rgb_make.'+suffix
IF (NOT keyword_set(quality)) THEN quality = 75

;assume Rim,Gim,Bim same type, same size
IF size(rim,/tname) eq 'STRING' THEN BEGIN
    R = mrdfits(Rim)
    dim = size(R,/dimensions)
    NX = LONG(dim[0])
    NY = LONG(dim[1])
    colors = fltarr(NX,NY,3)
    colors[*,*,0] = temporary(R)
    colors[*,*,1] = mrdfits(Gim)
    colors[*,*,2] = mrdfits(Bim)
ENDIF ELSE BEGIN
    dim = size(Rim,/dimensions)
    NX = LONG(dim[0])
    NY = LONG(dim[1])
    colors = fltarr(NX,NY,3)
    colors[*,*,0] = Rim
    colors[*,*,1] = Gim
    colors[*,*,2] = Bim
ENDELSE
IF n_elements(rebinfactor) THEN BEGIN
    colors = nw_rebin_image(colors,rebinfactor)
ENDIF

print, 'nw_scale_rgb'
colors = nw_scale_rgb(colors,scales=scales)
print, 'nw_arcsinh'
colors = nw_arcsinh(colors,nonlinearity=nonlinearity, /inplace)
print, 'nw_cut_to_box'
IF (NOT keyword_set(saturatetowhite)) THEN $
  colors = nw_cut_to_box(colors,origin=origin)
IF keyword_set(overlay) THEN colors= (colors > overlay) < 1.0
print, 'nw_float_to_byte'
colors = nw_float_to_byte(colors)

IF keyword_set(tiff) THEN BEGIN
    colors = reverse(colors,2)
    print, 'WRITE_TIFF'
    WRITE_TIFF,name,planarconfig=2,red=colors[*,*,0],$
      green=colors[*,*,1],blue=colors[*,*,2]
ENDIF ELSE BEGIN
    print, 'WRITE_JPEG'
    WRITE_JPEG,name,colors,TRUE=3,QUALITY=quality
ENDELSE
END
