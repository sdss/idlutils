;+
; NAME:
;   cap_distance
;
; PURPOSE:
;   Return distance from coordinates to a cap, in degrees.
;
; CALLING SEQUENCE:
;   cap_distance
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; OUTPUT:
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   The sign is positive if in the cap, and negative if outside
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;   angles_to_x()
;
; REVISION HISTORY:
;   19-Jun-2003  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------
function cap_distance, radec, cap

   usexyz = angles_to_x(radec[0,*],(90.D)-radec[1,*])
   nobj = n_elements(usexyz) / 3L
   dotprod = transpose(reform(usexyz,3,nobj)) # reform(cap.x,3,1)
   cdist = (acos((1.D) - abs(cap.cm)) - acos(dotprod)) * 180.D0 / !dpi
   cdist = cdist - 2 * cdist * (cap.cm LT 0) ; Flip the sign if CM is negative

   return, cdist
end
