;+
; NAME:
;   is_in_window
; PURPOSE:
;   Is an xyz (or radec) position in any of a given list of polygons?
; CALLING SEQUENCE:
;   result=is_in_window(xyz, polygons [, /radec, ncaps=ncaps]
; INPUTS:
;   xyz - xyz value (or radec if /radec is set)
;   polygons - polygons with caps to check
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
function is_in_window, xyz, polygons, radec=radec, ncaps=ncaps, $
                       in_polygon=in_polygon

if(keyword_set(radec)) then $
  nxyz=n_elements(xyz)/2 $ 
else $
  nxyz=n_elements(xyz)/3

in_window=lonarr(nxyz)
in_polygon=lonarr(nxyz)-1L
curr_polygon=0L
while(curr_polygon lt n_elements(polygons)) do begin
    indx_not_in=where(in_polygon eq -1L,count_not_in)
    if(count_not_in gt 0) then begin
        indx_in_curr_polygon= $
          where(is_in_polygon(xyz[*,indx_not_in],polygons[curr_polygon], $
                              radec=radec,ncaps=ncaps),count_in_curr_polygon)
        if(count_in_curr_polygon gt 0) then $
          in_polygon[indx_not_in[indx_in_curr_polygon]]=curr_polygon
    endif
    curr_polygon=curr_polygon+1L
endwhile
in_window=(in_polygon ge 0L)
return,in_window

end
