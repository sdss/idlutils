;+
; NAME:
;   construct_polygon
; PURPOSE:
;   Create the structure for a polygon. 
;   This has the number of caps stored, a bitmask indicating whether 
;   to use each cap, the weight, and the area
; CALLING SEQUENCE:
;   poly=construct_polygon()
; INPUTS:
; OPTIONAL INPUTS:
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
function construct_polygon,ncaps=ncaps,nelem=nelem

if(NOT keyword_set(ncaps)) then ncaps=1
if(NOT keyword_set(nelem)) then nelem=1

; make cap structure
cap1=construct_cap()
cap=replicate(cap1,ncaps)
polygon1={polystr, $
          ncaps:0L, $
          weight:0.D, $
          str:0.D, $
          use_caps:ulong64(0), $
          caps:ptr_new(cap)}
polygon=replicate(polygon1,nelem)
for i=0L, nelem-1L do $
  polygon[i].caps=ptr_new(cap)

return,polygon

end
