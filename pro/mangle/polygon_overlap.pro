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
function polygon_overlap,poly1,poly2,newpoly=newpoly

newncaps=poly1.ncaps+poly2.ncaps
if(n_tags(newpoly) eq 0) then begin
    newpoly=construct_polygon(nelem=1,ncaps=newncaps)
    noreturn=1
endif
newpoly.ncaps=newncaps
newpoly.weight=poly1.weight
(*newpoly.caps)[0L:poly1.ncaps-1L]=(*poly1.caps)[*]
(*newpoly.caps)[poly1.ncaps:poly1.ncaps+poly2.ncaps-1L]=(*poly2.caps)[*]
newpoly.use_caps=(poly1.use_caps+ishft(poly2.use_caps,poly1.ncaps))
set_use_caps,newpoly,list,/add
newpoly.str=garea(newpoly)

if(NOT keyword_set(noreturn)) then $
  return,newpoly $
else $
  return,1

end
