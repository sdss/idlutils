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
;   yrange      - y range; default chosen dumbly!
;   [etc]       - extras passed to "plot" command
; KEYWORDS:
;   overplot    - overplot, don't plot anew
;   ploterr     - plot Poisson error bars too
;   log         - take log_10 before plotting
; OPTIONAL OUTPUTS:
;   xvec        - [npix] vector of x values of grid pixel centers
;   hist        - the histogram itself (ie, the total weight in each
;                 bin divided by the binwidth).
;   err         - the Poisson uncertainties on each point (ie, the
;                 sqrt of the sum of the squares of the weights,
;                 divided by the binwidth).
; COMMENTS:
;   Divides total weight in each bin by binwidth.
; BUGS:
;   Doesn't check inputs.
;   Super-slow!
; REVISION HISTORY:
;   2002-12-14  written -- Hogg
;-
pro hogg_plothist, x,weight=weight, $
                   xrange=xrange,yrange=yrange,npix=npix, $
                   xvec=xvec,hist=hist,err=err, $
                   overplot=overplot,ploterr=ploterr,log=log, $
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
err= dblarr(npix)
inxgrid= where(xgrid GE 0 AND xgrid LT npix,ninxgrid)
for ii=0L,ninxgrid-1 do begin
    hist[xgrid[inxgrid[ii]]]= hist[xgrid[inxgrid[ii]]] $
      +weight[inxgrid[ii]]
    err[xgrid[inxgrid[ii]]]= err[xgrid[inxgrid[ii]]] $
      +(weight[inxgrid[ii]])^2
endfor
hist= hist*double(npix)/abs(xrange[1]-xrange[0])
err= sqrt(err)*double(npix)/abs(xrange[1]-xrange[0])

; take log?
if keyword_set(log) then begin
    err= (err/hist)/alog(10.0)
    hist= alog10(hist)

; set y range
    if not keyword_set(yrange) then yrange= [-1.5,0.2]*max(hist)
endif else begin
    if not keyword_set(yrange) then yrange= [-0.1,1.1]*max(hist)
endelse

; plot
if NOT keyword_set(overplot) then begin
    plot, xrange,0.0*xrange,psym=0, $
      xrange=xrange,yrange=yrange,/xstyle,/ystyle, $
      _EXTRA=KeywordsForPlot,thick=1
endif
oplot, xvec,hist,psym=10
if keyword_set(ploterr) then $
  djs_oploterr, xvec,hist,yerr=err,psym=0

end
