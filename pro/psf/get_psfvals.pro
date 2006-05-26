pro get_psfvals, image, ivar, clean, xstar, ystar, satmask=satmask, badpixels=badpixels

  if NOT keyword_set(nsigma) then nsigma = 40
  if NOT keyword_set(satmask) then message, 'you really should set satmask'
  if NOT keyword_set(badpixels) then message, 'works better if you set badpixels'
; -------- statistics
  sz = size(image, /dim)
  row = lindgen((sz[1]-1)/16+1)*16
  squash = image[*, row]
  squashbad = badpixels[*, row]
  wgoodsquash = where(squashbad EQ 0, ngoodsquash)
  if ngoodsquash LT 100 then message, 'your whole image is bad!'
  djs_iterstat, squash[wgoodsquash], sigma=sigma, mean=mean, sigrej=3

; -------- high pixels
  im  = (image-mean)*(1B-badpixels)
  ind = where(im GT (nsigma*sigma), nhigh)

  if nhigh eq 0 then message, 'no high pixels!'

  ix = ind mod sz[0]
  iy = ind / sz[0]

  ixm = (ix-1) > 0
  ixp = (ix+1) < (sz[0]-1)

  iym = (iy-1) > 0
  iyp = (iy+1) < (sz[1]-1)

  maxnb = im[ixm, iy] > im[ixp, iy] > im[ix, iym] > im[ix, iyp] > $
    im[ixm, iyp] > im[ixp, iyp] > im[ixp, iym] > im[ixm, iym]

  isig = sqrt(ivar[ind])
  peak = im[ind]*isig GT (maxnb*isig + 1)
  peak = peak AND ((satmask OR badpixels)[ind] EQ 0)

; -------- real peaks (mostly) - still need to worry about
;          diff. spikes, badcols
  w = where(peak, npeak)

; 02 12 22
; 01 11 21
; 00 10 20 

  im00 = im[ixm[w], iym[w]]
  im10 = im[ix[w],  iym[w]]
  im20 = im[ixp[w], iym[w]]

  im01 = im[ixm[w], iy[w]]
  im11 = im[ix[w],  iy[w]]
  im21 = im[ixp[w], iy[w]]

  im02 = im[ixm[w], iyp[w]]
  im12 = im[ix[w],  iyp[w]]
  im22 = im[ixp[w], iyp[w]]

  back1 = (im01+im21)/2.
  back2 = (im10+im12)/2.
  back = (back1+back2)/2.
  diag = (im00+im02+im20+im22)/4.

; -------- get psfvals  (or hardwire them like a wimp!)
  psfvals = [.46, .21]  ; assuming 1.88 pixel FWHM or bigger
                                ; if the PSF is smaller, you are
                                ; BADLY sampled!

  print, 'PSFVALs:', psfvals

  rat = (((back) > 0) )/im11
  rat2 = ((diag > 0))/im11

  wstar = where(rat GT psfvals[0] and rat2 GT psfvals[1])

; -------- Find ALL CRs with psf_reject_cr
  cr = psf_reject_cr(image-mean, ivar, psfvals, satmask=satmask)
  clean = djs_maskinterp(image-mean, cr, iaxis=0, /const)

  xstar = ix[w[wstar]]
  ystar = iy[w[wstar]]

; -------- get robust PSF from rats

  return
end


; pass in psfs
; return components, coefficients
pro stamps2pca, psfs, comp=comp, coeff=coeff, recon=recon

  sz = size(psfs, /dimen)

  data0 = transpose(reform(psfs, sz[0]*sz[1], sz[2]))
  means = total(data0, 2)/(sz[0]*sz[1])

  data = data0 ; make a copy
  allcomp = transpose(pcomp(data, /double, /standard))
  
  ncomp = 9   ; keep ncomp components
  comp = allcomp[*, 0:ncomp-1]
  norm = 1./sqrt(total(comp^2, 1))
  for i=0L, ncomp-1 do comp[*, i] = comp[*, i]*norm[i]

  coeff = comp##data0

  if arg_present(recon) then begin 
     recon = reform(transpose(coeff)##comp, sz[0], sz[1], sz[2])
     for i=0L, sz[2]-1 do recon[*, *, i] = recon[*, *, i]+means[i]
  endif

  return
end




function stamp_center_iter, image, rad, maxiter=maxiter, dx=dx, dy=dy, $
              center=center

; -------- defaults
  if NOT keyword_set(rad) then message, 'must set rad'
  if NOT keyword_set(maxiter) then maxiter = 5

; -------- check inputs
  sz = size(image, /dimen)
  if NOT keyword_set(center) then begin 
     cen = (sz-1)/2
     if array_equal(cen, (sz-1)/2.) eq 0 then message, 'pass arrays of odd dimension'
     if rad GT min(cen) then message, 'rad too big'
     center = cen
  endif

  dx = 0
  dy = 0
; -------- check center not too close to edge
  if min(center) LT 2 or max(center) GT (sz[0]-3) then begin 
     print, 'center near edge of box'
     return, image
  endif 


  shifted_image = image

; -------- find flux-weighted center, sinc shift, iterate
  xwt = transpose(findgen(2*rad+1)-rad) ; column vector

  for i=1L, maxiter do begin 
     subimg = shifted_image[center[0]-rad:center[0]+rad, center[1]-rad:center[1]+rad]
     subtot = total(subimg)
     dx0 = (xwt # total(subimg,2) / subtot)[0]*1.1
     dy0 = (xwt # total(subimg,1) / subtot)[0]*1.1
     dx = dx+dx0
     dy = dy+dy0
;     print, i, dx, dy, dx0, dy0
     if (abs(dx) > abs(dy)) lt 1 then shifted_image = sshift2d(image, -[dx, dy])
  endfor 

  return, shifted_image
end



function histgap, x, gapsize=gapsize

  sind = sort(x)
  xs = x[sind]
  diff = xs-shift(xs, 1)

  gapsize = max(diff, maxind)

  return, xs[maxind]
end


function spread_stack, stack, npad

  sz = size(stack, /dim)
  box = sz[0]
  if sz[1] NE sz[0] then stop
  np = sz[2]

  if NOT keyword_set(npad) then npad = 0
  mask = bytarr(box, box)
  mask[npad:box-npad-1, npad:box-npad-1] = 1B

  nx   = ceil(sqrt(np))
  npix = nx*box
  arr  = fltarr(npix, npix)

  for i=0, np-1 do begin 
     stamp = stack[*, *, i]

     ix = i mod nx
     iy = i / nx
     arr[ix*box:(ix+1)*box-1, iy*box:(iy+1)*box-1] = stamp*mask

  endfor

  return, arr
end


function psf_par

  par = {boxrad:  12, $  ; box radius of PSF cutout (2*boxrad+1, 2*boxrad+1)
         fitrad:  9, $   ; radius of region used in PSF fit
         cenrad:  1}   ; region used to center PSF
         
; nsigma ?
; nfaint?
; use ivar in psf_fit
; check condition of matrix in psf_fit


  return, par
end


function psf_norm, image, rad

  if NOT keyword_set(rad) then message, 'must set rad'
  sz = size(image, /dimen)
  cen = (sz-1)/2

  if rad GT min(cen) then message, 'rad too big'

  subimg = image[cen[0]-rad:cen[0]+rad, cen[1]-rad:cen[1]+rad]
  subtot = total(subimg)
  return, subtot

end




pro stamp_renorm, stamp, sivar, par

  nstamp = (size(stamp, /dimen))[2]
  for istamp=0L, nstamp-1 do begin 
     norm = psf_norm(stamp[*, *, istamp], par.cenrad)
     stamp[*, *, istamp] = stamp[*, *, istamp]/norm
     sivar[*, *, istamp] = sivar[*, *, istamp]*norm^2
  endfor 

  return
end


function stamps, image, ivar, px, py, par, shift=shift, dx=dx, dy=dy, $
                 stampivar=stampivar

  rad = par.cenrad              ; box rad. used for center and norm
  sz = size(image, /dim)
  boxrad = par.boxrad           ; postage stamp size is boxrad*2+1
  box = boxrad*2+1
  np = n_elements(px)           ; number of stars
  
  arr = fltarr(box, box, np)
  stampivar = fltarr(box, box, np)

  x0 = (px-boxrad) > 0
  x1 = (px+boxrad) < (sz[0]-1)
  y0 = (py-boxrad) > 0
  y1 = (py+boxrad) < (sz[1]-1)
  
  sx0 = x0-px+boxrad
  sx1 = x1-px+boxrad
  sy0 = y0-py+boxrad
  sy1 = y1-py+boxrad

  dx = fltarr(np)               ; sub-pixel offsets
  dy = fltarr(np)

  for i=0L, np-1 do begin 
     stamp = fltarr(box, box)
     sivar = fltarr(box, box)
     stamp[sx0[i]:sx1[i], sy0[i]:sy1[i]] = image[x0[i]:x1[i], y0[i]:y1[i]]
     sivar[sx0[i]:sx1[i], sy0[i]:sy1[i]] = ivar[x0[i]:x1[i], y0[i]:y1[i]]

     if keyword_set(shift) then begin 
        stampcen = stamp_center_iter(stamp, rad, maxiter=10, $
                                  dx=dx0, dy=dy0)
        subtot = psf_norm(stampcen, par.cenrad)
        dx[i]=dx0 & dy[i]=dy0
        stamp = temporary(stampcen)

     endif else begin 
        subtot = psf_norm(stamp, par.cenrad)
     endelse

     arr[*, *, i] = stamp/subtot
     stampivar[*, *, i] = sivar*subtot^2

  endfor

; -------- reject those where central pixel is not the highest.

  cenbrt = bytarr(np)
  for i=0L, np-1 do cenbrt[i] = max(arr[*, *, i]) EQ arr[boxrad, boxrad, i]
  wbrt = where(cenbrt, nbrt)

  if nbrt EQ 0 then message, 'no stars are bright - this is impossible'
  arr = arr[*, *, wbrt]
  stampivar = stampivar[*, *, wbrt]
  px = px[wbrt]
  py = py[wbrt]
  dx = dx[wbrt]
  dy = dy[wbrt]

  return, arr
end



pro psfplot, sub, x, coeff=coeff, bin=bin

  binfac = keyword_set(bin) ? 2:1
  x0 = 6*binfac
  x1 = 12*binfac

  w=where(abs(sub[9*binfac,9*binfac,*]) lt 1)

  yr = [-1, 1]*0.005

  !p.multi = [0, x1-x0+1, x1-x0+1]
  xx = findgen(max(x))
  
  for j=x1, x0, -1 do for i=x0, x1 do begin 
     plot, x[w], sub[i, j, w], ps=3, yr=yr, chars=.1
     if keyword_set(coeff) then oplot, xx, poly(xx, coeff[i, j, *])
  endfor 

  return
end


; make sure the outliers are rejected on a star by star basis. 
; /reject rejects whole stars
function psf_fit, stack, ivar, x, y, par, ndeg=ndeg, reject=reject

  x0 = par.boxrad-par.fitrad
  x1 = par.boxrad+par.fitrad

  psfsize = (size(stack, /dimen))[0]
  if psfsize NE (2*par.boxrad+1) then message, 'parameter mismatch'

  nstamp = (size(stack, /dimen))[2]
  ncoeff = (ndeg+1)*(ndeg+2)/2
  if NOT keyword_set(ndeg) then ndeg = 1

  cf = fltarr(psfsize, psfsize, ncoeff)

; -------- construct A matrix
  A = dblarr(ncoeff, nstamp)
  col = 0
  xd = double(x)
  yd = double(y)
  for ord=0L, ndeg do begin
     for ypow=0, ord do begin 
        xpow = (ord-ypow)
        A[col, *] = xd^xpow * yd^ypow
        col = col+1
     endfor
  endfor

; -------- do fit
;  W = dblarr(nstamp)+1
  for i=x0, x1 do begin 
     for j=x0, x1 do begin 
        W = reform(ivar[i, j, *])        ; should use ivar here!
        data = reform(stack[i, j, *])
        hogg_iter_linfit, A, data, W, coeff, nsigma=3, /median, /truesigma
        cf[i, j, *] = coeff
     endfor
  endfor

; -------- reject
  if keyword_set(reject) then begin 
     nsigma = 3
     model = psf_eval(x, y, cf, par)
     bad = (model-stack)^2*ivar GT nsigma^2
     nbad = total(total(bad[x0:x1, x0:x1, *], 1), 1)
     good = where(nbad LE 5, ngood)
     print, 'keeping ', ngood, ' stars.'
     cf = psf_fit(stack[*, *, good], ivar[*, *, good], x[good], y[good], $
                  par, ndeg=ndeg)

  endif

  return, cf
end


  
function psf_eval, x, y, coeff, par, dx=dx, dy=dy

  psfsize = (size(coeff, /dimen))[0]
  ncoeff = (size(coeff, /dimen))[2]
  npsf = n_elements(x) 
  ndeg = long(sqrt(ncoeff*2))-1
  if (ndeg+1)*(ndeg+2)/2 NE ncoeff then stop
  
; -------- compute A matrix
  A = dblarr(ncoeff, npsf)
  col = 0
  xd = double(x)
  yd = double(y)
  for ord=0L, ndeg do begin
     for ypow=0, ord do begin 
        xpow = (ord-ypow)
        A[col, *] = xd^xpow * yd^ypow
        col = col+1
     endfor
  endfor

  psfs = fltarr(psfsize, psfsize, npsf)
  for i=0L, psfsize-1 do begin 
     for j=0L, psfsize-1 do begin 
        psfs[i, j, *] = reform(coeff[i, j, *])#A
     endfor
  endfor

  if keyword_set(dx) AND keyword_set(dy) then begin 
     for i=0L, npsf-1 do begin 
        psfs[*, *, i] = sshift2d(psfs[*, *, i], [dx[i], dy[i]])
        psfs[*, *, i] = psfs[*, *, i]/psf_norm(psfs[*, *, i], par.cenrad)
     endfor
  endif

  return, psfs
end



function median_stack, stack

  if size(stack, /n_dim) NE 3 then message, 'stack should be a 3D array'
  sz = size(stack, /dim)

  med = fltarr(sz[0], sz[1])

  for i=0L, sz[0]-1 do begin 
     for j=0L, sz[1]-1 do begin 
        med[i, j] = median(stack[i, j, *])
     endfor
  endfor

  return, med
end



function sinc_binup2, data
  sz = size(data, /dim)
  image = fltarr(sz[0]*2, sz[1]*2)*data[0]

  xbox = djs_laxisnum(sz, iaxis = 0)
  ybox = djs_laxisnum(sz, iaxis = 1)

  image[xbox*2  , ybox*2] = data
  image[xbox*2+1, ybox*2] = sshift2d(data, [-0.5, 0])
  image[xbox*2  , ybox*2+1] = sshift2d(data, [0, -0.5])
  image[xbox*2+1, ybox*2+1] = sshift2d(data, [-0.5, -0.5])

  return, image
end



function mockimage, psf

  pad = 20
  nx = 2048
  ny = 1489
  image = fltarr(nx, ny)
  npix = (size(psf, /dim))[0]
  brad = (npix-1)/2


  for i=0, 200 do begin
     stamp = psf*randomu(iseed)*100
     dcen = randomu(iseed, 2)-0.5
     stamp = sshift2d(stamp, -dcen)
     stamp = stamp+sqrt(stamp > 0)*randomn(iseed, npix, npix)
     cen = randomu(iseed, 2)*([nx, ny]-2*pad)+pad
     image[cen[0]-brad:cen[0]+brad, cen[1]-brad:cen[1]+brad] = $
       image[cen[0]-brad:cen[0]+brad, cen[1]-brad:cen[1]+brad] + stamp
  endfor

  image = image+randomn(iseed, nx, ny)*0.1

  return, image
end



function fit_extra_power, res, dx, dy

  npix = 19
  ndeg = 4
  brad = (npix-1)/2
  nstamp = (size(res, /dimen))[2]
  ff = dcomplexarr(npix, npix, nstamp)
  for i=0L, nstamp-1 do ff[*, *, i] = fft(res[*, *, i])

  fnew = ff*0
  for i=0L, brad-2 do begin 
     poly_iter, dx, imaginary(ff[brad, i, *]), ndeg, 3, yfit
     fnew[brad, i, *] = complex(0, yfit)
     fnew[brad, npix-i-1, *] = complex(0, -yfit)

     poly_iter, dx, imaginary(ff[brad-1, i, *]), ndeg, 3, yfit
     fnew[brad-1, i, *] = complex(0, yfit)
     fnew[brad+1, npix-i-1, *] = complex(0, -yfit)

     poly_iter, dx, imaginary(ff[brad+1, i, *]), ndeg, 3, yfit
     fnew[brad+1, i, *] = complex(0, yfit)
     fnew[brad-1, npix-i-1, *] = complex(0, -yfit)

     poly_iter, dy, imaginary(ff[i, brad, *]), ndeg, 3, yfit
     fnew[i, brad, *] = complex(0, yfit)
     fnew[npix-i-1, brad, *] = complex(0, -yfit)

     poly_iter, dy, imaginary(ff[i, brad-1, *]), ndeg, 3, yfit
     fnew[i, brad-1, *] = complex(0, yfit)
     fnew[npix-i-1, brad+1, *] = complex(0, -yfit)

     poly_iter, dy, imaginary(ff[i, brad+1, *]), ndeg, 3, yfit
     fnew[i, brad+1, *] = complex(0, yfit)
     fnew[npix-i-1, brad-1, *] = complex(0, -yfit)

  endfor

  for i=0L, brad-3 do begin 
     poly_iter, dx, imaginary(ff[brad-2, i, *]), ndeg, 3, yfit
     fnew[brad-2, i, *] = complex(0, yfit)
     fnew[brad+2, npix-i-1, *] = complex(0, -yfit)

     poly_iter, dx, imaginary(ff[brad+2, i, *]), ndeg, 3, yfit
     fnew[brad+2, i, *] = complex(0, yfit)
     fnew[brad-2, npix-i-1, *] = complex(0, -yfit)

     poly_iter, dy, imaginary(ff[i, brad-2, *]), ndeg, 3, yfit
     fnew[i, brad-2, *] = complex(0, yfit)
     fnew[npix-i-1, brad+2, *] = complex(0, -yfit)

     poly_iter, dy, imaginary(ff[i, brad+2, *]), ndeg, 3, yfit
     fnew[i, brad+2, *] = complex(0, yfit)
     fnew[npix-i-1, brad-2, *] = complex(0, -yfit)

  endfor

  rnew = res*0
  for i=0, nstamp-1 do rnew[*, *, i] = float(fft(fnew[*, *, i], /inv))

  return, rnew
end


; subtract PSF stars from image and see how well we did!
function image_psf_sub, image_in, psfs, px, py, dx, dy

  image = image_in
  rad = 1
  sz = size(image, /dim)
  boxrad = 9
  box    = boxrad*2+1
  nstar  = n_elements(px) 

  x0 = (px-boxrad) > 0
  x1 = (px+boxrad) < (sz[0]-1)
  y0 = (py-boxrad) > 0
  y1 = (py+boxrad) < (sz[1]-1)
  
  sx0 = x0-px+boxrad
  sx1 = x1-px+boxrad
  sy0 = y0-py+boxrad
  sy1 = y1-py+boxrad

  for i=0L, nstar-1 do begin 
     stamp    = psfs[*, *, i] ; assume this is already sinc shifted
     model    = stamp[sx0[i]:sx1[i], sy0[i]:sy1[i]]
     subimage = image[x0[i]:x1[i], y0[i]:y1[i]] 
     poly_iter, model, subimage, 1, 3, fit

     image[x0[i]:x1[i], y0[i]:y1[i]] = image[x0[i]:x1[i], y0[i]:y1[i]] -fit


  endfor

  return, image
end


function faint_struc, N

  nmax = 5
  str = {npsf:0, $
         px:fltarr(nmax), $
         py:fltarr(nmax), $
         peak:fltarr(nmax)}
  
  if keyword_set(N) then begin
     str = replicate(str, N)
  endif 

  return, str
end



pro multi_psf, stamps, stampivar, psfs, par, sub, faint, nfaint=nfaint

  sub = stamps                        ; copy of array for output
  nstamp = (size(stamps, /dimen))[2]
  npix = (size(stamps, /dimen))[0]
  nsigma = 5
  faint = faint_struc(nstamp)
  if NOT keyword_set(nfaint) then nfaint = 3
  if nfaint GT n_elements(faint[0].peak) then message, 'nfaint too large'
  rad = 3

  xbox = djs_laxisnum([npix, npix], iaxis = 0)
  ybox = djs_laxisnum([npix, npix], iaxis = 1)

  mask = bytarr(npix, npix)
  npad = par.boxrad-par.fitrad
  mask[npad:npix-npad-1, npad:npix-npad-1] = 1B

  xcen = (npix-1)/2
  ycen = (npix-1)/2
  mask = mask AND (((xbox-xcen)^2+(ybox-ycen)^2) GT rad^2)

; -------- loop over stamps
  for i=0L, nstamp-1 do begin 

     fmask = mask

     psf = psfs[*, *, i]
     im = stamps[*, *, i]-psf
     iv = stampivar[*, *, i]
     
     for j=0, nfaint-1 do begin 
; -------- look for another peak
        maxval = max(im*fmask, maxind)
        if maxval*sqrt(iv[maxind]) GT nsigma then begin 

           ix = maxind mod npix
           iy = maxind  /  npix
        
; -------- get sub-pixel center

           junk = stamp_center_iter(im, 1, dx=dx0, dy=dy0, center=[ix, iy], maxiter=2)
           if (dx0 > dy0) GE 2 then begin 
              print, 'Centering error on stamp', i, dx0, dy0
           endif else begin 
              px = ix+dx0
              py = iy+dy0
              
; -------- subtract shifted PSF form im
              spsf = sshift2d(psf, [px, py]-(npix-1)/2)
              norm = maxval/max(spsf)
              im = im-spsf*norm
              
; -------- store results
              faint[i].npsf = faint[i].npsf+1
              faint[i].px[j] = px
              faint[i].py[j] = py
              faint[i].peak = norm

              fmask = fmask AND ((xbox-px)^2+ $
                                 (ybox-py)^2) GT rad^2

           endelse
        endif
     endfor

     sub[*, *, i] = im
  endfor
  return
end


function psf_chisq, stamps, stampivar, par

  nstamp = (size(stamps, /dimen))[2]
  npix = (size(stamps, /dimen))[0]
  npad = par.boxrad-par.fitrad
  mask = bytarr(npix, npix)
  mask[npad:npix-npad-1, npad:npix-npad-1] = 1B
  w = where(mask, nmask)
  chisq = fltarr(nstamp)

  w = where(mask)
  for i=0L, nstamp-1 do begin 
     chisq[i] = total((stamps[*, *, i])[w]^2 * (stampivar[*, *, i])[w])/nmask
  endfor

  return, chisq
end




; doesn't use psf to get radius -- maybe should!
; changes stamps and sub!!!
pro psf_zero, stamps, stampivar, sub, psf, par, faint, chisq

  nstamp = (size(stamps, /dimen))[2]
  npix = (size(stamps, /dimen))[0]
  rad = 3

;  chisq = fltarr(nstamp)
  xbox = djs_laxisnum([npix, npix], iaxis = 0)
  ybox = djs_laxisnum([npix, npix], iaxis = 1)

  mask = bytarr(npix, npix)
  npad = par.boxrad-par.fitrad
  mask[npad:npix-npad-1, npad:npix-npad-1] = 1B

  xcen = (npix-1)/2
  ycen = (npix-1)/2
  mask = mask AND (((xbox-xcen)^2+(ybox-ycen)^2) GT rad^2)

  for i=0L, nstamp-1 do begin 
     fmask = mask
     for j=0L, faint[i].npsf-1 do begin 
        fmask = fmask AND ((xbox-faint[i].px[j])^2+ $
                           (ybox-faint[i].py[j])^2) GT rad^2
     endfor
     wmask = where(fmask, ngoodpix)
     if ngoodpix LT 10 then message, 'we have a problem'
     djs_iterstat, (sub[*, *, i])[wmask], mean=mean, sigma=sigma

     stamps[*, *, i] = stamps[*, *, i]-mean
     sub[*, *, i] = sub[*, *, i]-mean

  endfor

  return
end





pro callit

  run = 273
  camcol = 3
  field = 500

  run = 4828
  camcol = 3
  field = 258


  fname = sdss_name('idR', run, camcol, field, filter='i')
  sdss_readimage, fname, image, ivar, satmask=satmask
  badpixels = smooth(float(ivar EQ 0), 19, /edge) NE 0

;  image     =     image[*, 100:249]
;  ivar      =      ivar[*, 100:249]
;  satmask   =   satmask[*, 100:249]
;  badpixels = badpixels[*, 100:249]

  par = psf_par()
  get_psfvals, image, ivar, clean, x, y, satmask=satmask, badpixels=badpixels


  stamps = stamps(clean, ivar, x, y, par, /shift, dx=dx, dy=dy, stampivar=stampivar)
  nstamp = n_elements(dx) 

; -------- get median psf
  psf = median_stack(stamps)
  psfs0 = stamps
  for i=0L, nstamp-1 do psfs0[*, *, i] = psf

  multi_psf, stamps, stampivar, psfs0, par, sub, faint, nfaint=3
  psf_zero, stamps, stampivar, sub, psf, par, faint, chisq
  stamp_renorm, stamps, stampivar, par

  multi_psf, stamps, stampivar, psfs0, par, sub1, faint, nfaint=3
; maybe recenter here
  recon = sub1+psfs0

; -------- do spatial PSF fit
  cf = psf_fit(recon, stampivar, x, y, par, ndeg=3, /reject)
  psfs1 = psf_eval(x, y, cf, par)

  multi_psf, stamps, stampivar, psfs1, par, sub2, faint, nfaint=3


  stamps2pca, psfs1, comp=comp, coeff=coeff, recon=recon

  chisq = psf_chisq(sub2, stampivar, par)


; center up
; compute psf0 (median)
; subtract 3 faint stars
; get new zero
; recenter
; fit psf1
; subtract 5 faint stars
; get new zero  (with tilt?)
; fit psf2
; toss anything that doesn't fit well within fitrad. 



; =======================================
;  this is all junk

; -------- subtract stupid psf from stamps
  sub = stamps
  for i=0L, (size(sub, /dimen))[2]-1 do sub[*, *, i] = sub[*, *, i]-psf
  sind = sort(sqrt(dy*dy+dx*dx))
  foo = spread_stack(sub[*, *, sind])
  sigs = fltarr(nstamp)
  for i=0L, nstamp-1 do sigs[i] = stdev(sub[7:11, 7:11, i])


; -------- residual
  res = stamps-psfs
  bar = spread_stack(res)
  
  bar = spread_stack(res[*, *, sind])
  bsigs = fltarr(nstamp)
  for i=0L, nstamp-1 do bsigs[i] = stdev(res[7:11, 7:11, i])


  blank = image_psf_sub(clean, psfs0, x, y, dx, dy)



  return
end



pro foobar

  raw = readfits('/scr/apache20/dfink/ctio/oct98/fits/n7obj/obj7100.fits')
  bias = readfits('bias.fits')
  flat = readfits('final_flat.fits')

  image = mask*(raw-bias)/(flat + (mask eq 0))



  return
end
