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
;  depends on vagc
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
newpoly.use_caps=poly1.use_caps+ishft(poly2.use_caps,poly1.ncaps)
(*newpoly.caps)[0L:poly1.ncaps-1L]=(*poly1.caps)[*]
(*newpoly.caps)[poly1.ncaps:poly1.ncaps+poly2.ncaps-1L]=(*poly2.caps)[*]
newpoly.str=garea(newpoly)

return,newpoly
end
