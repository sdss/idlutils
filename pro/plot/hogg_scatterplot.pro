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
;   xnpix       - width of greyscale grid in pixels; default 0.3*sqrt(N)
;   ynpix       - height of greyscale grid in pixels; same default
;   xrange      - x range; default minmax(x)
;   yrange      - y range; default minmax(y)
;   levels      - contour levels; default in source code
;   quantiles   - quantiles to plot on conditional plot; default [0.25,0.5,0.75]
;   satfrac     - fraction of pixels to saturate in greyscale; default 0
;   exponent    - stretch greyscale at exponent power; default 1.0
;   [etc]       - extras passed to "plot" command
; KEYWORDS:
;   conditional - normalize each column separately
;   labelcont   - label contours with numbers
; OPTIONAL OUTPUTS:
;   xvec        - [xnpix] vector of x values of grid pixel centers
;   yvec        - [ynpix] vector of y values of grid pixel centers
;   grid        - the greyscale grid [xnpix,ynpix] that was plotted
;   cumimage    - the cumulated grid [xnpix,ynpix] that was contoured
; BUGS:
;   Doesn't check inputs.
;   Ought to specify saturation not as a fraction of pixels, but as a fraction
;     of the total weight (ie, saturate inside a particular, specifiable
;     confidence region).  This mod is trivial.
;   Ought to specify min and max grey levels, and contour colors.
;   Contour thicknesses hard-coded to unity.
; REVISION HISTORY:
;   2002-12-04  written --- Hogg
;-
pro hogg_scatterplot, x,y,weight=weight, $
                      xrange=xrange,yrange=yrange,xnpix=xnpix,ynpix=ynpix, $
                      levels=levels,satfrac=satfrac, $
                      xvec=xvec,yvec=yvec,grid=grid,cumimage=cumimage, $
                      exponent=exponent, $
                      conditional=conditional, $
                      quantiles=quantiles, $
                      labelcont=labelcont, $
                      _EXTRA=KeywordsForPlot

; set defaults
ndata= n_elements(x)
if not keyword_set(weight) then weight= dblarr(ndata)+1.0
if not keyword_set(xnpix) then xnpix= ceil(0.3*sqrt(ndata)) > 10
if not keyword_set(ynpix) then ynpix= ceil(0.3*sqrt(ndata)) > 10
if not keyword_set(xrange) then xrange= minmax(x)
if not keyword_set(yrange) then yrange= minmax(y)
if not keyword_set(levels) then levels= errorf(0.5*(dindgen(3)+1))
if not keyword_set(quantiles) then quantiles= [0.25,0.5,0.75]
nquantiles= n_elements(quantiles)
if not keyword_set(satfrac) then satfrac= 0.0
if not keyword_set(exponent) then exponent= 1.0

; check inputs
; [tbd]

; make axes
plot, [0],[0],xrange=xrange,yrange=yrange,/xstyle,/ystyle, $
  _EXTRA=KeywordsForPlot,/nodata

; snap points to grid
xvec= xrange[0]+(xrange[1]-xrange[0])*(dindgen(xnpix)+0.5)/double(xnpix)
yvec= yrange[0]+(yrange[1]-yrange[0])*(dindgen(ynpix)+0.5)/double(ynpix)
xgrid= floor(xnpix*(x-xrange[0])/(xrange[1]-xrange[0]))
ygrid= floor(ynpix*(y-yrange[0])/(yrange[1]-yrange[0]))

; make and fill 1-d grid first, if necessary
if keyword_set(conditional) then begin
    colnorm= dblarr(xnpix)
    inxgrid= where(xgrid GE 0 AND xgrid LT xnpix,ninxgrid)
    for ii=0L,ninxgrid-1 do $
      colnorm[xgrid[inxgrid[ii]]]= colnorm[xgrid[inxgrid[ii]]] $
        +weight[inxgrid[ii]]
endif

; make and fill 2-d grid
grid= dblarr(xnpix,ynpix)
ingrid= where(xgrid GE 0 AND xgrid LT xnpix AND $
              ygrid GE 0 AND ygrid LT ynpix,ningrid)
for ii=0L,ningrid-1 do $
  grid[xgrid[ingrid[ii]],ygrid[ingrid[ii]]]= $
    grid[xgrid[ingrid[ii]],ygrid[ingrid[ii]]]+weight[ingrid[ii]]

; renormalize columns, if necessary
if keyword_set(conditional) then begin
    zeroindx= where(grid EQ 0.0,nzeroindx)
    grid= grid/(colnorm#(dblarr(ynpix)+1))
    if nzeroindx GT 0 then grid[zeroindx]= 0.0
endif

; compute quantiles, if necessary
if keyword_set(conditional) then begin
    qq= dblarr(xnpix,nquantiles)
    for ii=0L,xnpix-1 do begin
        inii= where(xgrid EQ ii,ninii)
	if ninii GT 0 then begin
            qq[ii,*]= weighted_quantile(y[inii],weight[inii],quant=quantiles)
        endif
    endfor

; otherwise cumulate image
endif else begin
    cumindex= reverse(sort(grid))
    cumimage= dblarr(xnpix,ynpix)
    cumimage[cumindex]= total(grid[cumindex],/cumulative) 
; renormalize the cumulated image so it really represents fractions of the
; *total* weight
    cumimage= cumimage/total(weight)
endelse

; scale greyscale
mingrey= 255.0
maxgrey= 127.0
maxgrid= grid[(reverse(sort(grid)))[ceil(satfrac*xnpix*ynpix)]]
mingrid= 0.0
tvgrid= mingrey+(maxgrey-mingrey)*((grid-mingrid)/(maxgrid-mingrid))^exponent
tvgrid= (tvgrid < mingrey) > maxgrey

; plot greyscale
tv, tvgrid,xrange[0],yrange[0],/data, $
  xsize=(xrange[1]-xrange[0]),ysize=(yrange[1]-yrange[0]) 

; plot quantiles, if necessary
if keyword_set(conditional) then begin
    for ii=0L,nquantiles-1 do begin
        oplot, xvec,qq[*,ii],psym=10
    endfor

; otherwise overplot contours
endif else begin
    if NOT keyword_set(labelcont) then labelcont=0
    contour, cumimage,xvec,yvec,levels=levels,/overplot, $
      c_labels=lonarr(n_elements(levels))+labelcont
endelse

; re-plot axes (yes, this is a HACK)
!P.MULTI[0]= !P.MULTI[0]+1
plot, [0],[0],xrange=xrange,yrange=yrange,/xstyle,/ystyle, $
  _EXTRA=KeywordsForPlot,/nodata

end
