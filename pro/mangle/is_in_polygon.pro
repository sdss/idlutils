;+
; NAME:
;   is_in_polygon
; PURPOSE:
;   Is an xyz (or radec) position in a given polygon?
; CALLING SEQUENCE:
;   result=is_in_polygon(xyz, polygon [, /radec, ncaps=ncaps]
; INPUTS:
;   xyz - xyz value (or radec if /radec is set)
;   polygon - polygon with caps to check
; OPTIONAL INPUTS:
;   /radec - if set, assume xyz actually holds array [ra,dec]
;   ncaps - override polygon.ncaps (if ncaps < polygon.ncaps)
; OUTPUTS:
; OPTIONAL INPUT/OUTPUTS:
; COMMENTS:
; EXAMPLES:
; BUGS:
; PROCEDURES CALLED:
; REVISION HISTORY:
;   01-Oct-2002  Written by MRB (NYU)
;-
;------------------------------------------------------------------------------
function is_in_polygon, ra=ra, dec=dec, xyz=xyz, polygon, ncaps=ncaps

usencaps=polygon.ncaps
if(keyword_set(ncaps)) then usencaps=ncaps < polygon.ncaps

if(keyword_set(ra)) then $
  nxyz=n_elements(ra) $ 
else $
  nxyz=n_elements(xyz)/3

in_polygon=lonarr(nxyz)+1L
for icap=0L, usencaps-1L do begin 
    if(is_cap_used(polygon.use_caps,icap)) then $
      in_polygon=in_polygon and $
      (is_in_cap(ra=ra,dec=dec,xyz=xyz,(*polygon.caps)[icap]))
endfor

return,in_polygon

end
