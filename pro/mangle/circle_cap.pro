;+
; NAME:
;   circle_cap
; PURPOSE:
;   Return a cap centered on a certain set of coordinates
;   of a certain size.
; CALLING SEQUENCE:
;   cap=circle_cap(xyz, radius [, /radec])
; INPUTS:
;   xyz - xyz value (or radec if /radec is set)
;   radius - proper radius in degrees of cap
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
function circle_cap, ra=ra, dec=dec, xyz=xyz , radius

d2r=!DPI/180.D

if(keyword_set(ra)) then $
  usexyz=angles_to_x(ra,(90.D)-dec) $
else $
  usexyz=xyz

cap=construct_cap()
cap.x=usexyz
cap.cm=(1.D)-cos(radius*d2r)

return,cap

end
