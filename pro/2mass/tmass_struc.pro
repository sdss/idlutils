;+
; NAME:
;   tmass_struc
;
; PURPOSE:
;   Define data structure for FITS copy of 2MASS data
;
; CALLING SEQUENCE:
;   struc = tmass_struc(N)
;
; INPUTS:
;   N     - number of elements in structure array (default 1)
;
; OUTPUTS:
;   struc - 2MASS data structure
;
; COMMENTS:
;   Used by tmass_ascii2fits.  We use DEC instead of the 2MASS
;   name of DECL for declination.
;
; REVISION HISTORY:
;   2003-Jun-26  Written by Douglas Finkbeiner, Princeton
;
;----------------------------------------------------------------------
function tmass_struc, N

  struc = {ra:      0.d, $
           dec:     0.d, $
           err_maj: 0., $
           err_min: 0., $
           err_ang: 0., $
           j_m:     0.,$
           j_ivar:  0., $
           h_m:     0.,$
           h_ivar:  0., $
           k_m:     0., $
           k_ivar:  0., $
           ph_qual: 'ZZZ', $
           rd_flg:  0, $
           bl_flg:  0, $
           cc_flg:  'zzz', $
           ndetect: bytarr(3), $
           nobserve: bytarr(3), $
           gal_contam: 0b, $
           mp_flg: 0b, $
           pts_key: 0L, $
           hemis: ' ', $
           jdate: 0d, $
           dup_src: 0b, $
           use_src: 0b }

  if keyword_set(N) then struc = replicate(struc, N)

  return, struc
end
