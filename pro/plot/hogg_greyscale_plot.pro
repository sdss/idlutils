;+
; NAME:
;   hogg_greyscale_plot
; PURPOSE:
;   Make a pretty greyscale plot from an astronomical image.
; CALLING SEQUENCE:
;   greyscale, data,pixscale,scalename,lo,hi,filename,[title='title',/sigma]
; INPUTS:
;   data       the image
;   filename   name for the output PostScript file
; OPTIONAL INPUTS:
;   pixscale   units per pixel, eg arcmin/pixel
;   scalename  units, eg "arcmin"
;   lo,hi      levels to appear totally black (lo) and totally white (hi)
;              (these are in terms of sigma if sigma keyword is set); if
;              hi<lo, the image is made negative
;   title      title for the plot
;   xpt,ypt    x and y vectors of points to overplot -- set symbols with
;                !P.SYM and !P.SYMSIZE
; OUTPUTS:
;              a PostScript file called filename
; KEYWORDS:
;   sigma      when set, take lo and hi to be in terms of the sigma in the
;              center part of the image from djs_iterstat, and relative to the
;              mean from iterstat
;   noaxes     don't plot axes and labels
;   startps    BLANTON: comment your code!
;   endps      BLANTON: comment your code!
; COMMENTS:
;   The source code can be easily modified to include contouring.  In fact
;   the next revision ought to add optional contouring keywords and inputs.
; BUGS/FEATURES:
;   There may be something wrong with the axes; check few-pixel images.
;   No contouring available (but see "COMMENTS" and the source code).
; REVISION HISTORY:
;   1999-08-01  Written - Hogg
;   2001-05-01  Fonts improved - Hogg
;   2002-09-16  Added overplotting - Hogg
;-
pro hogg_greyscale_plot, data,filename, $
                         pixscale=pixscale,scalename=scalename,lo=lo,hi=hi, $
                         title=title,sigma=sigma,xpt=xpt,ypt=ypt, $
                         noaxes=noaxes, $
                         startps=startps,endps=endps

; set defaults
if NOT keyword_set(pixscale) then pixscale= 1.0
if NOT keyword_set(scalename) then scalename= 'pix'
if NOT keyword_set(lo) then begin
    lo= -5.0
    hi= 5.0
    sigma= 1
endif

; find size, center
nx= (size(data))(1) & ny= (size(data))(2)
xcent= float(nx-1)/2.0 & ycent= float(ny-1)/2.0
x1= xcent-200 & x2= xcent+200 & y1= ycent-200 & y2= ycent+200
if x1 LT 0 then x1= 0 & if x2 GE nx then x2= nx-1
if y1 LT 0 then y1= 0 & if y2 GE ny then y2= ny-1

; scale image
mean= 0.0 & rms= 1.0
if keyword_set(sigma) then $
  djs_iterstat, data(x1:x2,y1:y2),mean=mean,sigma=rms
if lo LT hi then image= (float(data)-(lo*rms+mean))/(hi*rms-lo*rms) $
else image= ((hi*rms+mean)-float(data))/(hi*rms-lo*rms)
image= (floor(image*255.99) > 0) < 255

; "size" is width or height in inches
size= 6.0

; "margin" is a fractional space given for axes, captions etc.
margin= 0.0

; open PS file if necessary
if(keyword_set(filename) and keyword_set(startps)) then begin
    set_plot, "PS"
    device, file=filename,/inches,xsize=size,ysize=size, $
      xoffset=(7.5-size),yoffset=(10.0-size),bits_per_pixel=8
    hogg_plot_defaults
endif

; adjust plotting parameters
if keyword_set(title) then !P.TITLE= title

; hack to make axes default font
xyouts, 0,0,'!3'

; deal with aspect ratio issues
if nx GT ny then !P.POSITION=[0.0,1.0-float(ny)/float(nx),1.0,1.0] $
else !P.POSITION=[0.0,0.0,float(nx)/float(ny),1.0]
!P.POSITION= (!P.POSITION-1.0)*(1.0-margin)+1.0

; plot contours and image
x= (findgen(nx)-xcent)*pixscale & y= (findgen(ny)-ycent)*pixscale
contour, [[0,0],[1,1]],/nodata,xstyle=4,ystyle=4,title=''
xsize=((1.0-margin)*size)
if nx LT ny then xsize=xsize*float(nx)/float(ny)
ysize=((1.0-margin)*size)
if ny LT nx then ysize=ysize*float(nx)/float(ny)
loadct,0,/silent
tv, image,(margin*size),(size-ysize),/inches,xsize=xsize

; contour, data,x,y,/noerase,levels=(mean+10.0*hi*rms*(findgen(5)+1.0))
if NOT keyword_set(noaxes) then begin
    contour, data,x,y,/noerase,/nodata,$
      xtitle="!8x!3  ("+scalename+")", $
      xrange= [-0.5,float(nx)-0.5]*pixscale, $
      ytitle= "!8y!3  ("+scalename+")", $
      yrange= [-0.5,float(ny)-0.5]*pixscale
endif

; overplot points
if keyword_set(xpt) and keyword_set(ypt) then begin
    djs_oplot, xpt,ypt,psym=!P.PSYM,symsize=!P.SYMSIZE
endif

; close PS file if necessary
if(keyword_set(filename) and (not keyword_set(startps))) then $
  device, /close
end
