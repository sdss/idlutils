;+
; NAME:
;   multi_psf_fit
; PURPOSE:
;   given an image and a psf, fit a multiple psf model to the image
; CALLING SEQUENCE:
;   multi_psf_fit, image, invvar, psf [, x=, y=, flux=, npsf= ]
; INPUTS:
;   image - [N,M] image to fit
;   invvar - [N,M] inverse variance image
;   psf - [P,P] psf image (assumed to be centered at P/2)
; OPTIONAL INPUTS:
;   npsf - number of psfs to fit (default to 2)
; OPTIONAL KEYWORDS:
;   /silent - call mpfit silently
; OUTPUTS:
;   x - [npsf] x centers of best fit
;   y - [npsf] y centers of best fit
;   flux - [npsf] fluxes of best fit
; COMMENTS:
;   Uses 'find' to get starting positions and then calls 'mpfit'. 
; BUGS:
;   Only well-tested for double-psf case.  
; REVISION HISTORY:
;   31-Mar-2002  Written by Mike Blanton, NYU
;-
;------------------------------------------------------------------------------
function multi_psf_fit_func, params

common com_mpf, psf, image, invvar, psfflux, nx, ny, np, model, npsf

; interpret inputs
psfflux=fltarr(npsf)
xpos=fltarr(npsf)
ypos=fltarr(npsf)
xpos[0:npsf-1L]=params[0:npsf-1L]
ypos[0:npsf-1L]=params[npsf:2L*npsf-1L]

; now create two psf images
psfmodel=fltarr(nx,ny,npsf)
for i=0L, npsf-1L do begin
    tmp_psf=fltarr(nx,ny)
    embed_stamp, tmp_psf, psf, xpos[i]-float(np/2L), ypos[i]-float(np/2L)
    psfmodel[*,*,i]=tmp_psf
endfor

; create matrix to solve
aa=fltarr(npsf,npsf)
for i=0L, npsf-1L do $
  for j=0L, npsf-1L do $
  aa[i,j]=total(psfmodel[*,*,i]*psfmodel[*,*,j]*invvar, /double)
bb=fltarr(npsf)
for i=0L, npsf-1L do $
  bb[i]=total(psfmodel[*,*,i]*image*invvar, /double)

; now solve for fluxes
psfflux=invert(aa)#bb

; now get chi2 to return
model=fltarr(nx,ny)
for i=0L, npsf-1L do $
  model=model+psfmodel[*,*,i]*psfflux[i]
deviates=(image-model)*sqrt(invvar)
chi2=total(deviates^2)

return, reform(deviates,nx*ny)

end
;
pro multi_psf_fit, image1, invvar1, psf1, x=x, y=y, flux=flux, model=model1, $
                   chi2=chi2, npsf=npsf1

common com_mpf

; check inputs
if(n_params() lt 3) then begin
    print, 'Syntax - multi_psf_fit, image, invvar, psf [, invvar=, x=, y=, flux=, $'
    print, '              npsf=, /silent '
    return
endif
npsf=2L
if(keyword_set(npsf1)) then npsf=long(npsf1)
nd=size(image1,/n_dim)
if(nd lt 2) then begin
    message, 'image must have at least 2 dimensions', /continue
    return
endif
if(n_elements(image1) ne n_elements(invvar1)) then begin
    message, 'image and invvar must be same size', /continue
    return
endif
if(nd gt 2) then begin
    splog, 'note: taking first 2d plane of high dimensional image'
    image=image1[*,*,0]
    invvar=invvar1[*,*,0]
endif else begin
    image=image1	
    invvar=invvar1
endelse
nx=(size(image,/dim))[0]
ny=(size(image,/dim))[1]
nd=size(psf1,/n_dim)
if(nd lt 2) then begin
    message, 'psf must have at least 2 dimensions', /continue
    return
endif
if(nd gt 2) then begin
    splog, 'note: taking first 2d plane of high dimensional psf'
    psf=psf1[*,*,0]
endif else begin
    psf=psf1	
endelse
np=(size(psf,/dim))[0]
if(np ne (size(psf,/dim))[1]) then begin
    message, 'psf must be square image', /continue
    return
endif

; get first guesses from find
;    - determine sig of psf (assumes it is centered)
xx=(findgen(np)-float(np/2L))#replicate(1.,np)
yy=transpose(xx)
r2=xx^2+yy^2
sigma=sqrt(0.5*total(r2*psf,/double)/total(psf,/double))
fwhm=0.8*sigma*sqrt(2.*alog(2.))  ; underestimate to be a bit pushy
;    - determine noise and back
back=median(image)
noise=1./(sqrt(median(invvar)))
;    - run daofind and take top two fluxes
;      (reduce threshold until there are two ...)
nstars=0
nsig=10.
while(nstars lt npsf and nsig gt 0.1) do begin
    hmin=back+nsig*noise
    find, image, sx, sy, sflux, sharp, round, hmin, fwhm, [-1.0, 1.], $
      [0.2, 1.], /silent
    nstars=n_elements(sx)
    nsig=nsig*0.5
endwhile
if(nstars lt npsf) then begin
    message, 'image just does not have '+string(npsf)+' peaks', /continue
    return
endif
sx=sx[0:npsf-1L]
sy=sy[0:npsf-1L]
sflux=sflux[0:npsf-1L]

; now use mpfit to do fit
inpars=[sx, sy]
pi1={step:0.1, $
     mpmaxstep:2., $
     limited:[1,1], $
     limits:[0.,float(nx)-1.]}
pi=replicate(pi1, npsf*2L)
outpars=mpfit('multi_psf_fit_func', inpars, /auto, parinfo=pi, quiet=silent)
chi2=multi_psf_fit_func(outpars)
x=outpars[0:npsf-1L]
y=outpars[npsf:2.*npsf-1L]
flux=psfflux
model1=model

end
