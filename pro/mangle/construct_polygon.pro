;+
; NAME:
;   construct_polygon
; PURPOSE:
;   Create the structure for a polygon. 
;   This has the number of caps stored, a bitmask indicating whether 
;   to use each cap, the weight, and the area
; CALLING SEQUENCE:
;   poly=construct_polygon([maxncaps= ])
; INPUTS:
; OPTIONAL INPUTS:
;   maxncaps - the maximum number of caps allowed for any polygon
; OUTPUTS:
; OPTIONAL INPUT/OUTPUTS:
; COMMENTS:
; EXAMPLES:
; BUGS:
;   Number of caps limited to 64
; PROCEDURES CALLED:
; REVISION HISTORY:
;   01-Oct-2002  Written by MRB (NYU)
;-
;------------------------------------------------------------------------------
function construct_polygon, maxncaps=maxncaps

if(NOT keyword_set(maxncaps)) then maxncaps=15L
if(maxncaps gt 64) then $
  message,'Maximum number of caps per polygon is 64'

; make cap structure
cap1=construct_cap()

polygon={polystr, $
         ncaps:0L, $
         weight:0.D, $
         str:0.D, $
         use_caps:ulong64(0), $
         caps:replicate(cap1,maxncaps)}

return,polygon

end
