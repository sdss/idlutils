;+
; NAME:
;   blanton_oned_meanplot
; PURPOSE:
;   plot sliding mean of one quantity vs one other
; COMMENTS:
; INPUTS:
;   x           - data values
;   z           - quantity to average
; OPTIONAL INPUTS:
;   weight      - weighting for data points; default unity
;   xrange      - x range; default to the number > minnum area
;   dxbin       - size of boxes in x-dir; default to a function of
;                 first and second moments 
;   levels      - contour levels; default to a function of image range
;   minnum      - minimum number of points in a sliding box to plot;
;                 default 100
; KEYWORDS:
; BUGS:
; REVISION HISTORY:
;   2003-01-08  written - Hogg
;-
pro blanton_oned_meanplot, x,z,weight=weight, $
                           xrange=xrange,dxbin=dxbin, $
                           levels=levels, axis_char_scale=axis_char_scale, $
                           maskonly=maskonly, $
                           minnum=minnum, $
                           bin_mean=bin_mean, $
                           bin_number=bin_number, input_mean=input_mean

if(NOT keyword_set(minnum)) then minnum=1L
if(NOT keyword_set(axis_char_scale)) then axis_char_scale=1.75

; take moments
ndata= n_elements(x)
if not keyword_set(weight) then weight= fltarr(ndata)+1.0
weightsum= total(weight,/double)
qmean= total(weight*z,/double)/weightsum
qvar= total(weight*(z-qmean)^2,/double)/weightsum
xmean= total(weight*x,/double)/weightsum
xvar= total(weight*(x-xmean)^2,/double)/weightsum

; set defaults
if not keyword_set(dxbin) then dxbin= sqrt(xvar)/3.0
if not keyword_set(minnum) then minnum= 100

; deal with negatives harshly
dxbin= abs(dxbin)

; make (overlapping) bins
factor= 3.0                     ; number of bin centers per bin width
factor2= 8.0                    ; number of sigmas to cover
if not keyword_set(xrange) then begin ; base the bins on moments if no xrange
    nxbin= ceil(factor*2.0*factor2*sqrt(xvar)/dxbin)+1
    xbin= xmean+(dxbin/factor)*(dindgen(nxbin)-0.5*double(nxbin-1))
endif else begin                ; base the bins on xrange if possible
    nxbin= ceil(factor*abs((xrange[1]-xrange[0])/dxbin))+1
    sign= (xrange[1]-xrange[0])/abs(xrange[1]-xrange[0])
    xbin= xrange[0]+sign*(dxbin/factor)*dindgen(nxbin)
endelse

; make mean image
if(NOT keyword_set(input_mean)) then begin
    image= blanton_weighted_mean_line(x,z,weight,xbin,dxbin)
    bin_number= image[*,0]
    bin_weight= image[*,1]
    bin_weight2= image[*,2]
    bin_mean= image[*,3]
endif

; check values and set contour levels
factor= 10.0
good= where(bin_number GT minnum,count_good)
if(count_good gt 0) then begin
    limits_indx=good
endif else begin
    splog,'WARNING: no bins above minnum'
    limits_indx=lindgen(n_elements(bin_number))
endelse
temp= minmax(bin_mean[limits_indx])
if not keyword_set(levels) then $
  levels= temp[0]+(temp[1]-temp[0])/factor*dindgen(ceil(factor+1.0))
nlevels= n_elements(levels)

; set x and y ranges
if not keyword_set(xrange) then begin
    xrange= minmax(xbin[limits_indx])
endif
yrange=[-0.1,1.1*max(bin_mean[limits_indx])]

; set plot range
nticks=6/axis_char_scale
!X.TICKINTERVAL= hogg_interval(xrange,nticks=nticks)
!Y.TICKINTERVAL= hogg_interval(yrange,nticks=nticks)

if(keyword_set(maskonly)) then begin
    tmpxticksize=!X.TICKLEN
    !X.TICKLEN=0.0001
    tmpyticksize=!Y.TICKLEN
    !Y.TICKLEN=0.0001
    plot, [0],[0],xrange=xrange,yrange=yrange,/nodata
    !X.TICKLEN=tmpxticksize
    !Y.TICKLEN=tmpyticksize
    return
endif
plot,xbin[limits_indx],bin_mean[limits_indx],xrange=xrange, $
  yrange=yrange,thick=4

nlimits_indx=n_elements(limits_indx)
if(xrange[1] gt xrange[0]) then $
  sign=1 $
else $
  sign=-1
for i=0L, nlevels-1L do begin
    icut=where((bin_mean[limits_indx[0:nlimits_indx-2]] lt levels[i] and $
                bin_mean[limits_indx[1:nlimits_indx-1]] $
                gt levels[i]) or $
               (bin_mean[limits_indx[0:nlimits_indx-2]] gt levels[i] and $
                bin_mean[limits_indx[1:nlimits_indx-1]] $
                lt levels[i]),ncut)
    for j=0L, ncut-1L do begin
        xloc=xbin[limits_indx[icut[j]]]+ $
          (xbin[limits_indx[icut[j]+1]]-xbin[limits_indx[icut[j]]])* $
          (levels[i]-bin_mean[limits_indx[icut[j]]])/ $
          (bin_mean[limits_indx[icut[j]+1]]-bin_mean[limits_indx[icut[j]]])
        if(sign*xloc gt sign*xrange[0] and sign*xloc lt sign*xrange[1]) then $
          begin
            oplot,xloc+0.5*dxbin*[-1.,1.], [levels[i],levels[i]]
            if(j eq 0 and bin_mean[limits_indx[icut[j]]] lt levels[i]) then $
              djs_xyouts,xloc-sign*0.5*dxbin, levels[i], $
              strtrim(string(levels[i],format='(f20.1)'),2), $ 
              alignment=1., charsize=0.8, noclip=0
        endif
    endfor
endfor

end
