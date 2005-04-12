pro hogg_image_overlay_grid, hdr,overlay,factor=factor, $
                             _EXTRA=KeywordsForGrid
prefix= 'tmp_hogg_image_overlay_grid'
naxis1= round(sxpar(hdr,'NAXIS1'))
naxis2= round(sxpar(hdr,'NAXIS2'))
bangp= !P
bangx= !X
bangy= !Y
set_plot, 'PS'
dpi= floor((naxis1/7.5) < (naxis2/10.0))
xsize= double(naxis1)/double(dpi)
ysize= double(naxis2)/double(dpi)
device, filename=prefix+'.ps',xsize=xsize,ysize=ysize,/inches
!P.MULTI= [0,1,1]
!X.MARGIN= [0,0]
!X.OMARGIN= [0,0]
!Y.MARGIN= !X.MARGIN
!Y.OMARGIN= !Y.OMARGIN
nw_overlay_range, naxis1,naxis2,xrange,yrange
xstyle= 5
ystyle= 5
plot, [0],[0],/nodata, $
  xstyle=xstyle,xrange=xrange, $
  ystyle=ystyle,yrange=yrange
nw_ad_grid, hdr,_EXTRA=KeywordsForGrid
device, /close
!P= bangp
!X= bangx
!Y= bangy
overlay1= 1.-hogg_image_overlay(prefix+'.ps',naxis1,naxis2,factor=factor)
if keyword_set(overlay) then overlay= overlay+overlay1 $
  else overlay= overlay1
return
end
