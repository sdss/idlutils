;+
;NAME:
;  nw_rgb_make
;PURPOSE:
;  Creates JPEG from images
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
;  rebinfactor - integer by which to multiply NX and NY
;OPTIONAL KEYWORDS:
;  saturatetowhite
;              - choose whether to saturate high-value pixels to white
;                or to color
;OPTIONAL OUTPUTS:
;  
;EXAMPLE:
;  
;KEYWORDS:
;  none
;OUTPUTS:
;  JPEG
;DEPENDENCIES:
;  
;BUGS:
;  
;REVISION HISTORY:
; 12/03/03 written - wherry
;-
PRO nw_rgb_make,Rim,Gim,Bim,name=name,scales=scales,nonlinearity= $
                nonlinearity,origin=origin,rebinfactor=rebinfactor, $
                saturatetowhite=saturatetowhite

;set defaults?
IF NOT keyword_set(name) THEN name = 'blah.jpg' ;what is default name?

;assume Rim,Gim,Bim same type, same size
IF size(rim,/tname) eq 'STRING' THEN BEGIN
    R = mrdfits(Rim)
    dim = size(R,/dimensions)
    NX = LONG(dim[0])
    NY = LONG(dim[1])
    colors = fltarr(NX,NY,3)
    colors[*,*,0] = R
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

colors = nw_scale_rgb(colors,scales=scales)
colors = nw_arcsinh(colors,nonlinearity=nonlinearity)
IF NOT n_elements(saturatetowhite) THEN $
  colors = nw_cut_to_box(colors,origin=origin)
image = nw_float_to_byte(colors)
IF n_elements(rebinfactor) THEN $ 
  image = nw_rebin_image(image,rebinfactor)

WRITE_JPEG,name,image,TRUE=3,QUALITY=100
END
