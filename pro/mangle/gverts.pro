;+
; NAME:
;   gverts
; PURPOSE:
;   Get vertices along edge of a polygon
; CALLING SEQUENCE:
;   verts=gverts(polygon)
; INPUTS:
;   polygon - spherical polygon specification
; OPTIONAL INPUTS:
; OUTPUTS:
;   verts - [3,N] locations of vertices
; OPTIONAL INPUT/OUTPUTS:
; COMMENTS:
; EXAMPLES:
; BUGS:
; PROCEDURES CALLED:
; REVISION HISTORY:
;   31-Jan-2002  Written by Mike Blanton, NYU
;-
;------------------------------------------------------------------------------
pro gverts, polygon, angle=angle, verts=verts, edges=edges, ends=ends, $
            tol=tol, verbose=verbose, dangle=dangle, nve=nve, $
            continuous=continuous, plot=plot, minside=minside

if(NOT keyword_set(minside)) then minside=5
if(keyword_set(plot)) then begin
    continuous=1
    nowaste=1
    if(NOT keyword_set(dangle)) then dangle=0.1
endif
if(NOT keyword_set(verbose)) then $
  verbose=0L $
else $
  verbose=1L
if(n_elements(tol) eq 0) then tol=0.
if(NOT keyword_set(nve)) then nve=5L

for j=0L, polygon.ncaps-1L do begin
    if(is_cap_used(polygon.use_caps,j)) then begin
        if(n_elements(used_caps) eq 0) then $
          used_caps=[j] $
        else $
          used_caps=[used_caps,j]
    endif
endfor
nused_caps=n_elements(used_caps)
if(nused_caps eq 0) then return

; Call grouping software
soname = filepath('libidlmangle.so', $
                  root_dir=getenv('IDLUTILS_DIR'), subdirectory='lib')
area=0.D
x=reform((*polygon.caps)[used_caps].x[*],3,nused_caps)
cm=reform([(*polygon.caps)[used_caps].cm],nused_caps)
nv=1L
vcirc=0L
nev=0L
nev0=0L
nvmax=n_elements(x)*(n_elements(x)+1L)+4L
ve_p=dblarr(3L*nve*nvmax)
angle_p=dblarr(nvmax)
ipv_p=lonarr(nvmax)
ev_p=lonarr(nvmax)
retval = call_external(soname, 'idl_gverts', $
                       double(x), double(cm), $
                       long(nused_caps), $
                       double(tol), long(vcirc), long(nv), long(nve), $
                       double(ve_p), double(angle_p), long(ipv_p), $
                       long(nev), long(nev0), long(ev_p))
if(keyword_set(dangle)) then begin
    maxangle=max(angle_p[0L:nv-1L])
    nve=ceil(maxangle/(dangle*!DPI/180.)) > minside
    ve_p=dblarr(3L*nve*nvmax)
    retval = call_external(soname, 'idl_gverts', $
                           double(x), double(cm), $
                           long(nused_caps), $
                           double(tol), long(vcirc), long(nv), long(nve), $
                           double(ve_p), double(angle_p), long(ipv_p), $
                           long(nev), long(nev0), long(ev_p))
endif

verts=reform(ve_p,3,nve,nvmax)
verts=verts[0:2,0:nve-1,0:nv-1]
angle=angle_p[0:nv-1]
edges=ipv_p[0:nv-1]
ends=ev_p[0:nv-1]

if(keyword_set(continuous)) then begin
    outverts=dblarr(3,nve*nv+1)
    outverts[*,0L:nve*nv-1L]=verts[*]
    outverts[*,nve*nv]=verts[*,0]
    useverts=lonarr(nve*nv+1)+1L
    if(keyword_set(nowaste)) then begin
        chord=sqrt(total((outverts[*,1L:nve*nv]-outverts[*,0L:nve*nv-1])^2,1))
        sep=180./!DPI*2.*asin(0.5*chord)
        currsep=sep[0]
        useverts=lonarr(nve*nv+1)
        useverts[lindgen(nv+1)*nve]=1
        for i=1, nve*nv-1L do begin
            if(currsep gt dangle) then begin
                useverts[i]=1
                currsep=sep[i]
            endif else begin
                currsep=currsep+sep[i]
            endelse
        endfor
    endif
    iuseverts=where(useverts,cuseverts)
    if(cuseverts eq 0) then $
        message,'no vertices'
    verts=outverts[*,iuseverts]
    outverts=0
endif

if(retval) then begin
    splog,'WARNING: gverts.c returned error message - '+string(retval)
endif

return
end
;------------------------------------------------------------------------------
