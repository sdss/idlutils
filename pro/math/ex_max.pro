;+
; NAME:
;   ex_max
; PURPOSE:
;   expectation-maximization iterative multi-gaussian fit to data
; INPUTS:
;   weight      [N] array of data-point weights
;   point       [d,N] array of data points - N vectors of dimension d
;   amp         [M] array of gaussian amplitudes
;   mean        [d,M] array of gaussian mean vectors
;   var         [d,d,M] array of gaussian variance matrices
; OPTIONAL INPUTS:
;   maxiterate  maximum number of iterations; default to 1000
;   qa          name for QA plot PostScript file
; OUTPUTS:
;   amp         updated amplitudes
;   mean        updated means
;   var         updated variances
; OPTIONAL OUTPUTS:
;   entropy     final entropy, relative to one-gaussian case
;   probability [N,M] array of probabilities of point i in gaussian j
; BUGS:
;   Entropy calculation could be wrong; see in-code comments.
;   Stopping condition is hard-wired.
; DEPENDENCIES:
;   idlutils
; REVISION HISTORY:
;   2001-Aug-06  written by Blanton and Hogg (NYU)
;   2001-Oct-02  added data-point weights - Hogg
;-
pro ex_max, weight,point,amp,mean,var,maxiterate=maxiterate,qa=qa, $
  entropy=entropy,probability=probability

; set defaults
  if NOT keyword_set(maxiterate) then maxiterate= 1000

; check dimensions
  ndata= n_elements(weight)                    ; N
  ngauss= n_elements(amp)                      ; M
  dimen= n_elements(point)/n_elements(weight)  ; d
  splog, ndata,' data points,',dimen,' dimensions,',ngauss,' gaussians'

; cram inputs into correct format
  point= reform(double(point),dimen,ndata)
  amp= reform(double(amp),ngauss)
  mean= reform(double(mean),dimen,ngauss)
  var= reform(double(var),dimen,dimen,ngauss)

; compute entropy normalization -- ie, entropy for one-gaussian case
  amp1= total(weight)
  mean1= total(weight##(dblarr(dimen)+1D)*point,2)/amp1
  var1= 0d
  for i=0L,ndata-1 do begin
    delta= point[*,i]-mean1
    var1= var1+weight[i]*delta#delta
  endfor
  var1= var1/amp1
  invvar= invert(var1,/double)
  if dimen GT 1 then $
    normamp= amp1*sqrt(determ(invvar))/(2.0*!PI)^(dimen/2) $
  else $
    normamp= amp1*sqrt(invvar)/(2.0*!PI)^(dimen/2)
  probability1= dblarr(ndata)
  for i=0L,ndata-1 do begin
    delta= point[*,i]-mean1
    probability1[i]= normamp*exp(-0.5*delta#invvar#delta)
  endfor
; Hogg is not sure about the following formula:
  entropy1= total(weight*alog(probability1/amp1))/alog(2D)

; setup postscript file, if necessary
  if keyword_set(qa) AND dimen GT 1 then begin
    !P.FONT= -1 & !P.BACKGROUND= 255 & !P.COLOR= 0
    set_plot, "PS"
    xsize= 7.5 & ysize= 10.0
    device, file=qa,/inches,xsize=xsize,ysize=ysize, $
      xoffset=(8.5-xsize)/2.0,yoffset=(11.0-ysize)/2.0,/color
    !P.THICK= 4.0
    !P.CHARTHICK= !P.THICK & !X.THICK= !P.THICK & !Y.THICK= !P.THICK
    !P.CHARSIZE= 1.2
    !P.PSYM= 0
    !P.TITLE= ''
    !X.STYLE= 3
    !X.TITLE= ''
    !X.RANGE= 0
    !X.MARGIN= [6,0]
    !X.OMARGIN= [0,0]
    !X.CHARSIZE= 1.0
    !Y.STYLE= 3
    !Y.TITLE= ''
    !Y.RANGE= 0
    !Y.MARGIN= [3,0]
    !Y.OMARGIN= [0,0]
    !Y.CHARSIZE= 1.0
    !P.MULTI= [0,4,6]
    if dimen EQ 4 then !P.MULTI= [0,3,5]
    if dimen EQ 6 then !P.MULTI= [0,5,7]
    xyouts, 0,0,'!3'
    colorname= ['red','green','blue','grey','magenta','cyan','orange', $
      'purple','light red','navy','light magenta','yellow green']
    ncolor= n_elements(colorname)
  endif

; allocate space for probabilities and updated parameters
  probability= reform(dblarr(ndata*ngauss),ndata,ngauss)
  newamp= amp
  newmean= mean
  newvar= var

; begin iteration loop
  iteration= 0L
  lastplot= 0L
  repeat begin
    iteration= iteration+1

; compute (un-normalized) probabilities
    for j=0L,ngauss-1 do begin
      invvar= invert(var[*,*,j],/double)
      if dimen GT 1 then $
        normamp= amp[j]*sqrt(determ(invvar))/(2.0*!PI)^(dimen/2) $
      else $
        normamp= amp[j]*sqrt(invvar)/(2.0*!PI)^(dimen/2)
      for i=0L,ndata-1 do begin
        delta= point[*,i]-mean[*,j]
        probability[i,j]= normamp*exp(-0.5*delta#invvar#delta)
      endfor
    endfor

; compute entropy using un-normalized probabilities
; Hogg is unsure of the following formula:
    entropy= total(weight*alog(total(probability,2)/total(amp)))/ $
      alog(2D) - entropy1
    splog, iteration,': entropy S =',entropy,' bits'

; normalize probabilities
    probability= probability/(total(probability,2)#(dblarr(ngauss)+1))

; compute new quantities
    newamp= total(weight#(dblarr(ngauss)+1D)*probability,1)
    newmean= point#(weight#(dblarr(ngauss)+1D)*probability)/ $
      (newamp##(dblarr(dimen)+1.0))
    for j=0L,ngauss-1 do begin
      tmp= 0.0D
      for i=0L,ndata-1 do begin
        delta= point[*,i]-newmean[*,j]
        tmp= tmp+weight[i]*probability[i,j]*delta#delta
      endfor
      newvar[*,*,j]= tmp/newamp[j]
    endfor

; update
    splog, iteration,newamp
    damp= newamp-amp
    amp= newamp
    mean= newmean
    var= newvar

; check stopping condition -- no amplitude changes by more than one point
    stopflag= 0B
    if (max(abs(damp)) LT 1D-7 AND iteration GT 1) OR $
       (iteration GE maxiterate) then stopflag= 1B

; plot
    if keyword_set(qa) AND (iteration GT (lastplot*1.49)) then begin
      lastplot= iteration
      for d=0L,dimen-2 do begin
        djs_plot,point[d,*],point[dimen-1,*],psym=3
        theta= 2.0D *double(!PI)*dindgen(101)/100.0D
        x= cos(theta)
        y= sin(theta)
        djs_xyouts,!X.CRANGE[0],!Y.CRANGE[1]+0.1*(!Y.CRANGE[0]-!Y.CRANGE[1]), $
          string(iteration),alignment=0.0,charsize=0.75
        for j=0L,ngauss-1 do begin
          matrix= invert(var[*,*,j],/double)
          trace= matrix[d,d]+matrix[dimen-1,dimen-1]
          det= matrix[d,d]*matrix[dimen-1,dimen-1]-matrix[dimen-1,d]* $
            matrix[d,dimen-1]
          eval1= trace/2.0+sqrt(trace^2/4.0-det)
          eval2= trace/2.0-sqrt(trace^2/4.0-det)
          evec1= [matrix[dimen-1,d],eval1-matrix[d,d]]
          evec1= evec1/(sqrt(transpose(evec1)#evec1))[0]
          evec2= [evec1[1],-evec1[0]]
          evec1= evec1*2.0/sqrt(eval1)
          evec2= evec2*2.0/sqrt(eval2)
          xx= mean[d,j]+x*evec1[0]+y*evec2[0]
          yy= mean[dimen-1,j]+x*evec1[1]+y*evec2[1]
          djs_oplot,xx,yy,color=colorname[j MOD ncolor],thick=8
          youts=!Y.CRANGE[0]+0.075*(j+0.5)*(!Y.CRANGE[1]-!Y.CRANGE[0])
          djs_xyouts,!X.CRANGE[1],youts,string(round(amp[j],/L64))+' ', $
            color=colorname[j MOD ncolor],alignment=1.0,charsize=0.75
        endfor
      endfor
    endif

; stop
  endrep until stopflag
  if keyword_set(qa) AND dimen GT 1 then device, /close
  return
end
