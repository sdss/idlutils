;+
; NAME:
;   is_in_cap
; PURPOSE:
;   Is an xyz (or radec) position in a given cap?
; CALLING SEQUENCE:
;   result=is_in_cap(xyz, cap [, /radec]
; INPUTS:
;   xyz - xyz value(s) (or radec if /radec is set)
;   cap - single cap to check
; OPTIONAL INPUTS:
;   /radec - if set, assume xyz actually holds array [ra,dec]
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
function is_in_cap, ra=ra, dec=dec, xyz=xyz, cap

if(keyword_set(xyz)) then $
  usexyz=xyz $
else $
  usexyz=angles_to_x(ra,(90.D)-dec)

nxyz=n_elements(usexyz)/3L
dotp=(transpose(reform(usexyz,3,nxyz))#reform(cap.x,3,1))
if(cap.cm gt 0) then $
  return,1.-dotp lt abs(cap.cm) $
else $
  return,1.-dotp gt abs(cap.cm) 

end
