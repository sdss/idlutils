pro plot_poly,poly,offset=offset,xrange=xrange,yrange=yrange, $
              filename=filename,fill=fill,nooutline=nooutline, $
              xsize=xsize, ysize=ysize, over=over, color=color, $
              minside=minside, dangle=dangle, outline_thick=outline_thick, $
              splot=splot

if(not keyword_set(offset)) then offset=0.
if(not keyword_set(outline_thick)) then outline_thick=0.001
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
if(keyword_set(offset)) then $
  xtitle='ra-'+strtrim(string(offset),2) $
else $
  xtitle='ra'

if(not keyword_set(xrange) OR not keyword_set(yrange) and $
   not keyword_set(over)) then begin
    yrange=[1.e+10,-1.e+10]
    xrange=[1.e+10,-1.e+10]
    for i=0L, n_elements(poly)-1L do begin
        if(garea(poly[i]) gt 0.) then begin
            gverts,poly[i],angle=angle, verts=verts, edges=edges, ends=ends, $
              dangle=dangle,minside=minside,/plot
            x_to_angles,verts,ra,theta
            ramoffset=(ra-offset) 
            indx=where(ramoffset lt 0.,count)
            if(count gt 0) then ramoffset[indx]=ramoffset[indx]+360.
            dec=reform(90.-theta,n_elements(theta))
            ramoffset=reform(ramoffset,n_elements(ramoffset))
            yrange[0]=min([yrange[0],dec])
            yrange[1]=max([yrange[1],dec])
            xrange[0]=min([xrange[0],ramoffset])
            xrange[1]=max([xrange[1],ramoffset])
        endif
    endfor
endif

if(NOT keyword_set(over)) then $
  plot,[0],[0],/nodata,xtitle=xtitle,ytitle='dec', $
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
        if(keyword_set(fill)) then begin
            if(keyword_set(splot)) then $
              spolyfill,ramoffset,dec,color=use_color[i],noclip=0 $
            else $
              polyfill,ramoffset,dec,color=use_color[i],noclip=0
        endif
        if(NOT keyword_set(nooutline)) then begin
            if(keyword_set(splot)) then $
              oplot,ramoffset,dec,color=use_color[i], $
              thick=outline_thick $
            else $
              soplot,ramoffset,dec,color=use_color[i], $
              thick=outline_thick 
        endif
    endif
endfor

if(keyword_set(filename)) then begin
    end_print
endif

end
