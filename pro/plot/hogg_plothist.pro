;+
; NAME:
;   hogg_plothist
; PURPOSE:
;   plot histogram of weighted points
; INPUTS:
;   x           - data values
; OPTIONAL INPUTS:
;   weight      - weighting for data points; default unity
;   npix        - number of bins in range
;   xrange      - x range; default minmax(x)
;   yrange      - y range; default [-0.1,1.0]*max
;   [etc]       - extras passed to "plot" command
; KEYWORDS:
;   overplot    - overplot, don't plot anew
; OPTIONAL OUTPUTS:
;   xvec        - [npix] vector of x values of grid pixel centers
;   hist        - the histogram itself
; COMMENTS:
;   Divides total weight in each bin by binwidth.
; BUGS:
;   Doesn't check inputs.
; REVISION HISTORY:
;   2002-12-14  written -- Hogg
;-
pro hogg_plothist, x,weight=weight, $
                   xrange=xrange,yrange=yrange,npix=npix, $
                   xvec=xvec,hist=hist,overplot=overplot, $
                   _EXTRA=KeywordsForPlot

; set defaults
ndata= n_elements(x)
if not keyword_set(weight) then weight= dblarr(ndata)+1.0
if not keyword_set(npix) then npix= ceil(0.3*sqrt(ndata)) > 10
if not keyword_set(xrange) then xrange= minmax(x)

; check inputs
; [tbd]

; snap points to grid
xvec= xrange[0]+(xrange[1]-xrange[0])*(dindgen(npix)+0.5)/double(npix)
xgrid= floor(npix*(x-xrange[0])/(xrange[1]-xrange[0]))

; make and fill histogram
hist= dblarr(npix)
inxgrid= where(xgrid GE 0 AND xgrid LT npix,ninxgrid)
for ii=0L,ninxgrid-1 do begin
    hist[xgrid[inxgrid[ii]]]= hist[xgrid[inxgrid[ii]]]+weight[inxgrid[ii]]
endfor
hist= hist*double(npix)/(xrange[1]-xrange[0])

; set y range
if not keyword_set(yrange) then yrange= [-0.1,1.1]*max(hist)

; plot
if NOT keyword_set(overplot) then begin
    plot, xrange,0.0*xrange,psym=0, $
      xrange=xrange,yrange=yrange,/xstyle,/ystyle, $
      _EXTRA=KeywordsForPlot,thick=1
endif
oplot, xvec,hist,psym=10

end
