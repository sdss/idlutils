;+
; NAME:
;   where_polygons_overlap
; PURPOSE:
;   Check which polygons overlap a given polygon
; CALLING SEQUENCE:
;   where_polygons_overlap, origpoly, matchpoly, matches, nmatches
; INPUTS:
;   origpoly  - single polygon to check against
;   matchpoly - [N] array of polygons to check against origpoly
; OPTIONAL INPUTS:
; OUTPUTS:
;   matches - [M<=N] indices of matching polygons (-1 if none)
;   nmatches - number of matching polygons
; OPTIONAL INPUT/OUTPUTS:
; COMMENTS:
; EXAMPLES:
; BUGS:
; PROCEDURES CALLED:
; REVISION HISTORY:
;   25-Sep-2003  Written by Mike Blanton, NYU
;-
;------------------------------------------------------------------------------
pro where_polygons_overlap, origpoly, matchpoly, matches, nmatches

; Call grouping software
soname = filepath('libidlmangle.so', $
                  root_dir=getenv('IDLUTILS_DIR'), subdirectory='lib')
area=0.D
x=reform((*origpoly.caps).x[*],3,origpoly.ncaps)
cm=reform([(*origpoly.caps).cm],origpoly.ncaps)
maxncaps=max(matchpoly.ncaps)
xmatch=dblarr(3,maxncaps,n_elements(matchpoly))
cmmatch=dblarr(maxncaps,n_elements(matchpoly))
for i=0L, n_elements(matchpoly)-1L do begin
    xmatch[*,0:matchpoly[i].ncaps-1,i]=(*matchpoly[i].caps).x[*]
    cmmatch[0:matchpoly[i].ncaps-1,i]=(*matchpoly[i].caps).cm
endfor
ismatch=lonarr(n_elements(matchpoly))
retval = call_external(soname, 'idl_where_polygons_overlap', $
                       double(x), double(cm),long(origpoly.ncaps), $
                       double(xmatch), double(cmmatch),long(maxncaps), $
                       long(n_elements(matchpoly)), long(matchpoly.ncaps), $
                       long(ismatch))
matches=where(ismatch,nmatches)
return
end
;------------------------------------------------------------------------------
