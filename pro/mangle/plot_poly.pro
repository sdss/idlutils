pro plot_poly,poly,offset=offset,xrange=xrange,yrange=yrange, $
              filename=filename,fill=fill,nooutline=nooutline, $
              xsize=xsize, ysize=ysize, over=over, color=color, $
              minside=minside, dangle=dangle

if(not keyword_set(xrange)) then xrange=[0.,360.]
if(not keyword_set(yrange)) then yrange=[-90.,90.]
if(not keyword_set(offset)) then offset=0.
if(not keyword_set(minside)) then minside=7
if(not keyword_set(dangle)) then dangle=0.05
if(n_elements(color) eq 0) then $
  use_color=fix(floor(64.0+127.0*randomu(seed,n_elements(poly))))
if(n_elements(color) eq 1) then use_color=replicate(color,n_elements(poly))
if(n_elements(color) gt 1) then use_color=color

if(keyword_set(filename)) then begin
    set_print,filename=filename,xsize=xsize,ysize=ysize
endif

;if(keyword_set(fill)) then $
  ;loadct,0
if(NOT keyword_set(over)) then $
  plot,[0],[0],/nodata,xtitle='ra-'+strtrim(string(offset),2),ytitle='dec', $
  xrange=xrange,yrange=yrange

for i=0L, n_elements(poly)-1L do begin
    if(garea(poly[i]) gt 0.) then begin
        gverts,poly[i],angle=angle, verts=verts, edges=edges, ends=ends, $
          dangle=dangle,minside=minside,/plot
        x_to_angles,verts,ra,theta
        ramoffset=(ra-offset) 
        indx=where(ramoffset lt 0.,count)
        if(count gt 0) then ramoffset[indx]=ramoffset[indx]+360.
        dec=90.-theta
        if(keyword_set(fill)) then $
          polyfill,ramoffset,dec,color=use_color[i],noclip=0
        if(NOT keyword_set(nooutline)) then $
          oplot,ramoffset,dec,thick=0.001,color=use_color[i]
    endif
endfor

if(keyword_set(filename)) then begin
    end_print
endif

end
