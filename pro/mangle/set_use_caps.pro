;+
; NAME:
;   set_use_caps
; PURPOSE:
;   Set the bits in use_caps for a polygon such 
;   that a certain list of caps are being used. Unless
;   /allow_doubles is set, this routine automatically
;   sets use_caps such that no two caps with use_caps
;   set are identical. If /add is set, this routine 
;   doesn't set use_caps to zero before proceeding. 
; CALLING SEQUENCE:
;   set_use_caps,polygon,list [, /allow_doubles, add=add]
; INPUTS:
;   polygon - [Npoly] polygon or polygons to alter
;   list - [Nindices] list of indices to set in each polygon
; OPTIONAL INPUTS:
; OUTPUTS:
; OPTIONAL INPUT/OUTPUTS:
; COMMENTS:
; EXAMPLES:
; BUGS:
;   Number of caps limited to 64
; PROCEDURES CALLED:
; REVISION HISTORY:
;   09-Nov-2002  Written by MRB (NYU)
;-
;------------------------------------------------------------------------------
pro set_use_caps, polygon, list, allow_doubles=allow_doubles, add=add, $
                  tol=tol

if(NOT keyword_set(add)) then polygon.use_caps=0
if(n_elements(tol) eq 0) then tol=1.D-10

for i=0L, n_elements(list)-1L do $
  polygon.use_caps=polygon.use_caps or ulong64(2)^list[i]

if(NOT keyword_set(allow_doubles)) then begin
    for ipoly=0L, n_elements(polygon)-1L do begin
        for i=0L, polygon[ipoly].ncaps-1L do begin
            if(is_cap_used(polygon[ipoly].use_caps,i)) then begin
                for j=i+1L, polygon[ipoly].ncaps-1L do begin
                    if(is_cap_used(polygon[ipoly].use_caps,j)) then begin
                        if(abs(polygon[ipoly].caps[i].x[0]- $
                               polygon[ipoly].caps[j].x[0]) lt tol and $
                           abs(polygon[ipoly].caps[i].x[1]- $
                               polygon[ipoly].caps[j].x[1]) lt tol and $
                           abs(polygon[ipoly].caps[i].x[2]- $
                               polygon[ipoly].caps[j].x[2]) lt tol and $
                           abs(polygon[ipoly].caps[i].cm- $
                               polygon[ipoly].caps[j].cm) lt tol) then $
                          polygon[ipoly].use_caps= $
                          polygon[ipoly].use_caps and (NOT ulong64(2)^j)
                    endif
                endfor
            endif
        endfor
    endfor
endif

end
