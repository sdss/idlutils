;+
; NAME:
;   hogg_manyd_scatterplot
; PURPOSE:
;   plot N-dimensional data sets
; INPUTS:
;   weight       [N] array of data-point weights
;   point        [d,N] array of data points - N vectors of dimension d
;   psfilename   name for PostScript file; if no filename is given, then the
;                  plots will simply be sent to the currently active device
; OPTIONAL INPUTS:
;   nsig         number of sigma for half-width of each plot; default 5
;   label        [d] array of axis labels; default 'x_i'
;   levels       confidence levels for contouring; defaults in source code
;   range        [2,d] array of plotting ranges
;   xdims,ydims  indices of data dimensions to use on each x and y axis
;   xnpix,ynpix  number of pixels in x and y dimensions of each panel
;   axis_char_scale  size of characters on labels
;   quantiles    vector of fractions at which to plot quantiles on conditional
;                   panels
;   satfrac      fraction of pixels to saturate in each panel; default 0.0
;   default_font  font command to send to set font for plotting
; KEYWORDS:
;   conditional  plot the conditional distribution of y on x 
;   sqrt         sqrt stretch on image
; OUTPUTS:
; OPTIONAL OUTPUTS:
; BUGS:
; DEPENDENCIES:
; REVISION HISTORY:
;   2002-12-14  re-constructed from ex_max_plot -- Hogg
;-
pro hogg_manyd_scatterplot, weight,point,psfilename,nsig=nsig, $
                 label=label,levels=levels,range=range, $
                 conditional=conditional,xdims=xdims,ydims=ydims, $
                 sqrt=sqrt, $
                 axis_char_scale=axis_char_scale,xnpix=xnpix,ynpix=ynpix, $
                 quantiles=quantiles,satfrac=satfrac, $
                 default_font=default_font

; set defaults
if (keyword_set(conditional) and (not keyword_set(quantiles))) then $
  quantiles=[0.25,0.5,0.75]
if NOT keyword_set(label) then $
  label= 'x!d'+strcompress(string(lindgen(dimen)),/remove_all)
if NOT keyword_set(nsig) then nsig= 5d
if NOT keyword_set(contlevel) then contlevel= [0.01,0.05,0.32,2.0/3.0]
if NOT keyword_set(axis_char_scale) then axis_char_scale= 1.75

; check dimensions
ndata= n_elements(weight)       ; N
dimen= n_elements(point)/n_elements(weight) ; d
splog, ndata,' data points,',dimen,' dimensions

; which dimensions should we look at?
if(NOT keyword_set(xdims)) then xdims=lindgen(dimen)
if(NOT keyword_set(ydims)) then ydims=lindgen(dimen)
if(NOT keyword_set(default_font)) then default_font='!3'
xdimen=n_elements(xdims)
ydimen=n_elements(ydims)

; cram inputs into correct format
point= reform(double(point),dimen,ndata)
weight= reform(double(weight),ndata)

; compute mean and variance of the whole sample for plot ranges
if NOT keyword_set(range) then begin
    amp1= total(weight)
    mean1= total(weight##(dblarr(dimen)+1D)*point,2)/amp1
    var1= 0d
    for i=0L,ndata-1 do begin
        delta= point[*,i]-mean1
        var1= var1+weight[i]*delta#delta
    endfor
    var1= var1/amp1
    range= dblarr(2,dimen)
    for d1= 0,dimen-1 do range[*,d1]= mean1[d1]+[-nsig,nsig]*sqrt(var1[d1,d1])
endif

; save system plotting parameters for later restoration
bangP= !P
bangX= !X
bangY= !Y

; setup postscript file
xsize= 7.5 & ysize= 7.5
if keyword_set(psfilename) then begin
    set_plot, "PS"
    device, file=psfilename,/inches,xsize=xsize,ysize=ysize, $
      xoffset=(8.5-xsize)/2.0,yoffset=(11.0-ysize)/2.0,/color
endif
!P.FONT= -1
!P.BACKGROUND= djs_icolor('white')
!P.COLOR= djs_icolor('black')
!P.THICK= 2.0
!P.CHARTHICK= !P.THICK
!P.CHARSIZE= 1.0
tiny= 1.d-4
!P.PSYM= 0
!P.LINESTYLE= 0
!P.TITLE= ''
!X.STYLE= 1
!X.THICK= 0.5*!P.THICK
!X.CHARSIZE= tiny
!X.MARGIN= [1,1]*0.0
!X.OMARGIN= [6,6]*axis_char_scale-!X.MARGIN
!X.RANGE= 0
!X.TICKS= 0
!Y.STYLE= 1
!Y.THICK= !X.THICK
!Y.CHARSIZE= !X.CHARSIZE
!Y.MARGIN= 0.6*!X.MARGIN
!Y.OMARGIN= 0.6*!X.OMARGIN
!Y.RANGE= 0
!Y.TICKS= !X.TICKS
!P.MULTI= [xdimen*ydimen,xdimen,ydimen]
xyouts, 0,0,default_font

; loop over all pairs of dimensions
for id2=ydimen-1L,0L,-1 do begin
    for id1=0L,xdimen-1 do begin
        d1=xdims[id1]
        d2=ydims[id2]
        if d1 lt 0 or d2 lt 0 then begin
            !P.MULTI[0]=!P.MULTI[0]-1L
        endif else begin 

; set axis label properties
            !X.CHARSIZE= tiny
            !Y.CHARSIZE= tiny
            !X.TITLE= ''
            !Y.TITLE= ''

; set plot range
            nticks=6/axis_char_scale
            !X.TICKINTERVAL= hogg_interval(range[*,d1],nticks=nticks)
            !Y.TICKINTERVAL= hogg_interval(range[*,d2],nticks=nticks)

; are we on one of the plot edges?
; NB: must run this check before plotting!
            xprevblank=0
            yprevblank=0
            xnextblank=0
            ynextblank=0
            if (id1 gt 0) then if (xdims[id1-1] eq -1) then xprevblank=1
            if (id1 lt xdimen-1) then if (xdims[id1+1] eq -1) then xnextblank=1
            if (id2 gt 0) then if (ydims[id2-1] eq -1) then ynextblank=1
            if (id2 lt xdimen-1) then if (ydims[id2+1] eq -1) then yprevblank=1
            leftside= 0B
            if (!P.MULTI[0] EQ 0) OR $
              (((!P.MULTI[0]-1) MOD xdimen) EQ (xdimen-1) OR $
               xprevblank eq 1) then leftside= 1B
            topside= 0B
            if (!P.MULTI[0] EQ 0) OR $
              (floor(float(!P.MULTI[0]-1)/xdimen) EQ (ydimen-1) OR $
               yprevblank eq 1) then topside= 1B
            rightside= 0B
            if (((!P.MULTI[0]-1) MOD xdimen) EQ 0 OR $
                xnextblank eq 1) then rightside= 1B
            bottomside= 0B
            if (floor(float(!P.MULTI[0]-1)/xdimen) EQ 0 OR $
                ynextblank eq 1) then bottomside= 1B

; plot
            if d1 NE d2 then begin
                hogg_scatterplot, point[d1,*],point[d2,*],weight=weight, $
                  xrange=range[*,d1],yrange=range[*,d2], $
                  xnpix=xnpix,ynpix=ynpix, $
                  levels=levels,satfrac=satfrac,sqrt=sqrt, $
                  conditional=conditional,quantiles=quantiles
            endif else begin
                hogg_plothist, point[d1,*],weight=weight, $
                  xrange=range[*,d1],npix=xnpix,yticklen=1d-10
            endelse

; make axis labels afterwards
            if bottomside then begin
                axis,!X.CRANGE[0],!Y.CRANGE[0],xaxis=0, $
                  xtitle=label[d1],xcharsize=axis_char_scale
            endif
            if topside then begin
                axis,!X.CRANGE[0],!Y.CRANGE[1],xaxis=1, $
                  xtitle=label[d1],xcharsize=axis_char_scale
            endif
            if leftside AND (d1 NE d2) then begin
                axis,!X.CRANGE[0],!Y.CRANGE[0],yaxis=0, $
                  ytitle=label[d2],ycharsize=axis_char_scale
            endif
            if rightside AND (d1 NE d2) then begin
                axis,!X.CRANGE[1],!Y.CRANGE[0],yaxis=1, $
                  ytitle=label[d2],ycharsize=axis_char_scale
            endif

; end loops and close file
        endelse 
    endfor
endfor
if keyword_set(psfilename) then device, /close

; restore system plotting parameters
!P= bangP
!X= bangX
!Y= bangY
return
end
