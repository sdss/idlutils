;+
; NAME:
;   ex_max_plot
; PURPOSE:
;   plot ex_max outputs
; INPUTS:
;   weight       [N] array of data-point weights
;   point        [d,N] array of data points - N vectors of dimension d
;   amp          [M] array of gaussian amplitudes
;   mean         [d,M] array of gaussian mean vectors
;   var          [d,d,M] array of gaussian variance matrices
;   psfilename   name for PostScript file
; OPTIONAL INPUTS:
;   nsig         number of sigma for half-width of each plot; default 5
;   label        [d] array of axis labels; default 'x_i'
;   contlevel    confidence levels for contouring; default [0.01,0.32]
; OUTPUTS:
; OPTIONAL OUTPUTS:
; BUGS:
;   Image resolutions hard-wired; they should be tied to the sizes of the
;     smallest gaussians.
; DEPENDENCIES:
; REVISION HISTORY:
;   2001-Oct-22  written - Hogg
;-
pro ex_max_plot, weight,point,amp,mean,var,psfilename,nsig=nsig, $
                 label=label,contlevel=contlevel

; check dimensions
  ndata= n_elements(weight)                    ; N
  ngauss= n_elements(amp)                      ; M
  dimen= n_elements(point)/n_elements(weight)  ; d
  splog, ndata,' data points,',dimen,' dimensions,',ngauss,' gaussians'

; cram inputs into correct format
  point= reform(double(point),dimen,ndata)
  amp= reform(double([[amp]]),ngauss)
  mean= reform(double(mean),dimen,ngauss)
  var= reform(double(var),dimen,dimen,ngauss)

; set defaults
  if NOT keyword_set(label) then $
    label= 'x!d'+strcompress(string(lindgen(dimen)),/remove_all)
  if NOT keyword_set(nsig) then nsig= 5d
  if NOT keyword_set(contlevel) then contlevel= [0.01,0.32]

; invert all matrices
  invvar= reform(dblarr(dimen*dimen*ngauss),dimen,dimen,ngauss)
  for j=0L,ngauss-1 do invvar[*,*,j]= invert(var[*,*,j],/double)

; compute mean and variance of the whole sample for plot ranges
  amp1= total(weight)
  mean1= total(weight##(dblarr(dimen)+1D)*point,2)/amp1
  var1= 0d
  for i=0L,ndata-1 do begin
    delta= point[*,i]-mean1
    var1= var1+weight[i]*delta#delta
  endfor
  var1= var1/amp1

; setup postscript file
  !P.FONT= -1 & !P.BACKGROUND= 255 & !P.COLOR= 0
  set_plot, "PS"
  xsize= 7.5 & ysize= 7.5
  device, file=psfilename,/inches,xsize=xsize,ysize=ysize, $
    xoffset=(8.5-xsize)/2.0,yoffset=(11.0-ysize)/2.0,/color
  !P.THICK= 4.0
  !P.CHARTHICK= !P.THICK & !X.THICK= !P.THICK & !Y.THICK= !P.THICK
  !P.CHARSIZE= 1.2
  axis_char_scale= 1.5
  tiny= 1.d-4
  !P.PSYM= 0
  !P.TITLE= ''
  !X.STYLE= 1
  !X.CHARSIZE= axis_char_scale
  !X.MARGIN= [1,1]*0.5*axis_char_scale
  !X.OMARGIN= [6,0]*axis_char_scale
  !X.RANGE= 0
  !Y.STYLE= 1
  !Y.CHARSIZE= !X.CHARSIZE
  !Y.MARGIN= 0.5*!X.MARGIN
  !Y.OMARGIN= 0.5*!X.OMARGIN
  !Y.RANGE= 0
  !P.MULTI= [0,dimen,dimen]

; hack to make font right
  xyouts, 0,0,'!3'

; make useful vectors for plotting
  colorname= ['red','green','blue','grey','magenta','cyan','dark yellow', $
    'purple','light green','orange','navy','light magenta','yellow green']
  ncolor= n_elements(colorname)
  theta= 2.0D *double(!PI)*dindgen(101)/100.0D
  x= cos(theta)
  y= sin(theta)

; make three passes of loops over all pairs of dimensions
  for pass=0,2 do begin
    for d2=dimen-1,0,-1 do begin
      for d1=0L,dimen-1 do begin

; set axis label properties
        !X.CHARSIZE= tiny
        if d2 EQ 0 then !X.CHARSIZE= axis_char_scale
        !Y.CHARSIZE= tiny
        if d1 EQ 0 then !Y.CHARSIZE= axis_char_scale
        !X.TITLE= ''
        if d2 EQ 0 then !X.TITLE= label[d1]
        !Y.TITLE= ''
        if d1 EQ 0 then !Y.TITLE= label[d2]

; set plot range and make axes
        !X.RANGE= mean1[d1]+[-nsig,nsig]*sqrt(var1[d1,d1])
        !Y.RANGE= mean1[d2]+[-nsig,nsig]*sqrt(var1[d2,d2])
        djs_plot,[0],[1],/nodata

; reset image and set x and y pixel centers
        npix_x= 32
        npix_y= 32
        image= dblarr(npix_x,npix_y)
        delta_x= (!X.CRANGE[1]-!X.CRANGE[0])/npix_x
        ximg= !X.CRANGE[0]+delta_x*(dindgen(npix_x)+0.5)
        delta_y= (!Y.CRANGE[1]-!Y.CRANGE[0])/npix_y
        yimg= !Y.CRANGE[0]+delta_y*(dindgen(npix_y)+0.5)

; increment greyscale image with data
        if pass EQ 0 then begin
          for i=0L,ndata-1 do begin
            xxi= floor(double(npix_x)* $
              (point[d1,i]-!X.CRANGE[0])/(!X.CRANGE[1]-!X.CRANGE[0]))
            yyi= floor(double(npix_y)* $
              (point[d2,i]-!Y.CRANGE[0])/(!Y.CRANGE[1]-!Y.CRANGE[0]))
            if xxi GE 0 AND xxi LT npix_x AND yyi GE 0 AND yyi LT npix_y then $
              image[xxi,yyi]= image[xxi,yyi]+weight[i]
          endfor
        endif
        image= image/delta_x/delta_y

; begin loop over gaussians
        if (pass EQ 1 OR pass EQ 2) AND (d1 NE d2) then begin
          for j=0L,ngauss-1 do begin

; get eigenvalues and eivenvectors of this 2x2
            var2d= [[var[d1,d1,j],var[d1,d2,j]],[var[d2,d1,j],var[d2,d2,j]]]
            tr= trace(var2d)
            det= determ(var2d,/double)
            eval1= tr/2.0+sqrt(tr^2/4.0-det)
            eval2= tr/2.0-sqrt(tr^2/4.0-det)
            evec1= [var2d[1,0],eval1-var2d[0,0]]
            evec1= evec1/(sqrt(transpose(evec1)#evec1))[0]
            evec2= [evec1[1],-evec1[0]]
            evec1= evec1*2.0*sqrt(eval1)
            evec2= evec2*2.0*sqrt(eval2)

; increment greyscale image with gaussians
            if pass EQ 1 then begin
              invvar2d= invert(var2d,/double)
              for xxi=0L,npix_x-1 do for yyi=0L,npix_y-1 do $
                image[xxi,yyi]= image[xxi,yyi]+ $
                amp[j]/sqrt(det)/2.0/!PI*exp(-0.5* $
                ([mean[d1,j],mean[d2,j]]-[ximg[xxi],yimg[yyi]])# $
                invvar2d#([mean[d1,j],mean[d2,j]]-[ximg[xxi],yimg[yyi]]))
            endif

; make and plot ellipse vectors
            if pass EQ 2 then begin
              xx= mean[d1,j]+x*evec1[0]+y*evec2[0]
              yy= mean[d2,j]+x*evec1[1]+y*evec2[1]
              djs_oplot,xx,yy,color=colorname[j MOD ncolor]

; end loop over gaussians
            endif
          endfor
        endif

; plot greyscale image
        if (pass EQ 0 OR pass EQ 1) AND (d1 NE d2) then begin
          loadct,0,/silent
          tvscl, -image,!X.CRANGE[0],!Y.CRANGE[0],/data, $
            xsize=(!X.CRANGE[1]-!X.CRANGE[0]), $
            ysize=(!Y.CRANGE[1]-!Y.CRANGE[0]) 

; re-make axes (yes, this is a HACK)
          !P.MULTI[0]= !P.MULTI[0]+1
          djs_plot,[0],[1],/nodata

; cumulate the image
          cumindex= sort(image)
          image[cumindex]= total(image[cumindex],/cumulative) 

; contour
          contour, image/max(image),ximg,yimg,levels=contlevel, $
;            c_annotation=['99.9','99','95','68'],c_charsize=1.0, $
            thick=1,/overplot,color=djs_icolor('red')
        endif

; if we are on the diagonal, change the y-range and hack to overplot
        if d1 EQ d2 then begin
          !P.MULTI[0]= !P.MULTI[0]+1
          !Y.RANGE= [0,2.0*nsig/abs(!X.CRANGE[1]-!X.CRANGE[0])]

; plot data histogram
          if pass EQ 0 then begin
            yhist= total(image,2)*delta_y/total(weight)
            djs_plot,ximg,yhist,psym=10,xstyle=5,ystyle=5
          endif

; plot model histogram
          if pass EQ 1 then begin
            yhist= 0D
            for j=0L,ngauss-1 do begin
              det= var[d1,d1,j]
              yhist= yhist+amp[j]/sqrt(det*2.0*!PI)/total(amp)* $
                exp(-0.5*(mean[d1,j]-ximg)^2/det)
            endfor
            djs_plot,ximg,yhist,psym=10,xstyle=5,ystyle=5
          endif

; plot 1-d gaussians
          if pass EQ 2 then begin
            djs_plot,[0],[0],/nodata,xstyle=5,ystyle=5
            nhist= npix_x*4
            xhist= !X.CRANGE[0]+ $
              (dindgen(nhist)+0.5)*(!X.CRANGE[1]-!X.CRANGE[0])/nhist
            yhist= 0D
            for j=0L,ngauss-1 do begin
              det= var[d1,d1,j]
              yhist1= amp[j]/sqrt(det*2.0*!PI)/total(amp)* $
                exp(-0.5*(mean[d1,j]-xhist)^2/det)
              yhist= yhist+yhist1
              djs_oplot,xhist,yhist1,color=colorname[j MOD ncolor]
            endfor
            djs_oplot,xhist,yhist
            !P.MULTI[0]= !P.MULTI[0]+1
            djs_plot,[0],[0],/nodata,xstyle=1,ystyle=5
          endif
        endif

; end loops and close file
      endfor
    endfor
  endfor
  device, /close
  return
end
