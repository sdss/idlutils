;+
; NAME:
;   polygon_overlap
; PURPOSE:
;   create the polygon which is the overlap between two polygons
; CALLING SEQUENCE:
;   newpoly= polygon_overlap(poly1,poly2)
; INPUTS:
;   poly1 - first input polygon
;   poly2 - second input polygon
; OPTIONAL INPUTS:
; OUTPUTS:
;   newpoly - output polygon
; OPTIONAL INPUT/OUTPUTS:
; COMMENTS:
;   To get the area of the overlap (in sterradians):
;     newpoly=polygon_overlap(poly1,poly2)
;     print, newpoly.str
; EXAMPLES:
; BUGS:
; PROCEDURES CALLED:
; REVISION HISTORY:
;   31-Jan-2003  Written by MRB (NYU)
;-
;------------------------------------------------------------------------------
function polygon_overlap,poly1,poly2

newncaps=poly1.ncaps+poly2.ncaps
newpoly=construct_polygon(nelem=1,ncaps=newncaps)
newpoly.ncaps=poly1.ncaps+poly2.ncaps
newpoly.weight=poly1.weight
(*newpoly.caps)[0L:poly1.ncaps-1L]=(*poly1.caps)[*]
(*newpoly.caps)[poly1.ncaps:poly1.ncaps+poly2.ncaps-1L]=(*poly2.caps)[*]
use_caps=(poly1.use_caps+ishft(poly2.use_caps,poly1.ncaps))
for i=0L, newpoly.ncaps-1L do $
  if(is_cap_used(use_caps,i)) then $
  if(n_elements(list) gt 0) then $
  list=[list,i] $
else $
  list=[i]
set_use_caps,newpoly,list
newpoly.str=garea(newpoly)

return,newpoly
end
