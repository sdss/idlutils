;+
; NAME:
;   hogg_scatterplot
; PURPOSE:
;   plot greyscale scatterplot with contours
; COMMENTS:
;   Doesn't overplot -- only plots.  This is because the IDL tvscl blots
;     out any other information on the plot.
;   Compares cumulated grid to the *total* weight -- ie, including points
;     outside the range (which is what you want; trust me).
; INPUTS:
;   x,y         - data values
; OPTIONAL INPUTS:
;   weight      - weighting for data points; default unity
;   xnpix       - width of greyscale grid in pixels; default 32
;   ynpix       - height of greyscale grid in pixels; default 32
;   xrange      - x range; default to minmax(x)
;   yrange      - y range; default to minmax(y)
;   levels      - contour levels; default to [0.5,0.75,0.95,0.99,0.999]
;   [etc]       - extras passed to "plot" command
; KEYWORDS:
;   sqrt        - make greyscale on SQRT stretch
; OPTIONAL OUTPUTS:
;   xvec        - [xnpix] vector of x values of grid pixel centers
;   yvec        - [ynpix] vector of y values of grid pixel centers
;   grid        - the greyscale grid [xnpix,ynpix] that was plotted
;   cumimage    - the cumulated grid [xnpix,ynpix] that was contoured
; BUGS:
;   Doesn't check inputs.
;   Contour thicknesses hard-coded to unity.
; REVISION HISTORY:
;   2002-12-04  written --- Hogg
;-
pro hogg_scatterplot, x,y,weight=weight, $
                      xrange=xrange,yrange=yrange,xnpix=xnpix,ynpix=ynpix, $
                      levels=levels, $
                      xvec=xvec,yvec=yvec,grid=grid,cumimage=cumimage, $
                      sqrt=sqrt, $
                      _EXTRA=KeywordsForPlot

; set defaults
ndata= n_elements(x)
if not keyword_set(weight) then weight= dblarr(ndata)+1.0
if not keyword_set(xnpix) then xnpix= 32
if not keyword_set(ynpix) then ynpix= 32
if not keyword_set(xrange) then xrange= minmax(x)
if not keyword_set(yrange) then yrange= minmax(y)
if not keyword_set(levels) then levels= [0.5,0.75,0.95,0.99,0.999]

; check inputs
; [tbd]

; make axes and empty grid
plot, [0],[0],xrange=xrange,yrange=yrange,/xstyle,/ystyle, $
  _EXTRA=KeywordsForPlot,/nodata
grid= dblarr(xnpix,ynpix)

; snap to grid
xvec= xrange[0]+(xrange[1]-xrange[0])*(dindgen(xnpix)+0.5)/double(xnpix)
yvec= yrange[0]+(yrange[1]-yrange[0])*(dindgen(ynpix)+0.5)/double(ynpix)
xgrid= floor(xnpix*(x-xrange[0])/(xrange[1]-xrange[0]))
ygrid= floor(ynpix*(y-yrange[0])/(yrange[1]-yrange[0]))
ingrid= where(xgrid GE 0 AND xgrid LT xnpix AND $
              ygrid GE 0 AND ygrid LT ynpix,ningrid)

; restrict to on-grid points
if ningrid GT 0 then begin
    xgrid= xgrid[ingrid]
    ygrid= ygrid[ingrid]
    wgrid= weight[ingrid]

; fill grid
    for ii=0L,ningrid-1 do $
      grid[xgrid[ii],ygrid[ii]]= grid[xgrid[ii],ygrid[ii]]+wgrid[ii]
endif

; scale greyscale
mingrey= 255.0
maxgrey= 127.0
maxgrid= max(grid)
mingrid= 0.0
if keyword_set(sqrt) then begin
    tvgrid= mingrey+(maxgrey-mingrey)*sqrt((grid-mingrid)/(maxgrid-mingrid))
endif else begin
    tvgrid= mingrey+(maxgrey-mingrey)*(grid-mingrid)/(maxgrid-mingrid)
endelse
tvgrid= tvgrid > 0
tvgrid= tvgrid < 255

; plot greyscale
tv, tvgrid,xrange[0],yrange[0],/data, $
  xsize=(xrange[1]-xrange[0]),ysize=(yrange[1]-yrange[0]) 

; cumulate image
cumindex= reverse(sort(grid))
cumimage= dblarr(xnpix,ynpix)
cumimage[cumindex]= total(grid[cumindex],/cumulative) 

; renormalize the cumulated image so it really represents fractions of the
; *total* weight
cumimage= cumimage/total(weight)

; overplot contours
contour, cumimage,xvec,yvec,levels=levels,thick=1,/overplot

; re-plot axes (yes, this is a HACK)
!P.MULTI[0]= !P.MULTI[0]+1
plot, [0],[0],xrange=xrange,yrange=yrange,/xstyle,/ystyle, $
  _EXTRA=KeywordsForPlot,/nodata

end
