;+
; NAME:
;   dust_getmap
;
; PURPOSE:
;   Reproject dust map to projection described by a FITS header
;
; CALLING SEQUENCE:
;   image=dust_getmap(hdr, mapname, ipath=, bhpath=)
;
; INPUTS:
;   hdr      - FITS astrometric header.  Must be parsed properly by extast
;   mapname  - one of the following (case insensitive)
;               BH  : Burstein-Heiles 4*E(B-V)
;               I100: 100-micron map in MJy/Sr
;               X   : X-map, temperature-correction factor
;               T   : Temperature map in degrees Kelvin for n=2 emissivity
;               IX  : Temperature-corrected 100-micron map in MJy/Sr
;               Ebv : E(B-V) in magnitudes
;               mask: 8-bit mask
;   
; OPTIONAL INPUTS:
;   ipath    - path for dust maps; default is $DUST_DIR/maps
;   bhpath   - path name for BH maps
; 
; OUTPUTS:
;   image    - reprojected dust/IRAS/whatever image
;   
; EXAMPLES:
;   To read in an halpha map, then generate a dust map in the same
;    projection: 
;
;   halpha = readfits('Halpha.fits', hdr)
;   dust   = dust_getmap(hdr, 'Ebv')
;
; COMMENTS:
;   Params ipath and bhpath are passed to dust_getval. 
;   Keywords /noloop and /interp are always set. 
;   The other keywords of dust_getval have no meaning in this
;     context. 
;   
; REVISION HISTORY:
;   2003-Jan-30   Written by Douglas Finkbeiner, Princeton
;----------------------------------------------------------------------
function dust_getmap, hdr, mapname, ipath=ipath, bhpath=bhpath

  sx = sxpar(hdr, 'NAXIS1')
  sy = sxpar(hdr, 'NAXIS2')
  lbox = lindgen(sx, sy)
  xbox = lbox mod sx
  ybox = temporary(lbox) / sx

  extast, hdr, astr
  xy2ad, xbox, ybox, astr, l, b
  delvarx, xbox, ybox

  image = dust_getval(l, b, map=mapname, /noloop, /interp, ipath=ipath, bhpath=bhpath)

  return, image
end
