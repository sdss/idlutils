
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



pro stamp_renorm, stamp, sivar, par

  nstamp = (size(stamp, /dimen))[2]
  for istamp=0L, nstamp-1 do begin 
     norm = psf_norm(stamp[*, *, istamp], par.cenrad)
     stamp[*, *, istamp] = stamp[*, *, istamp]/norm
     sivar[*, *, istamp] = sivar[*, *, istamp]*norm^2
  endfor 

  return
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



function psf_chisq, stamps, stampivar, par, dx=dx, dy=dy

  nstamp = (size(stamps, /dimen))[2]
  if ~(keyword_set(dx) && keyword_set(dy)) then begin
     dx = fltarr(nstamp)
     dy = fltarr(nstamp)
  endif 

  if n_elements(dx) NE nstamp then message, 'index bug!'

  npix = (size(stamps, /dimen))[0]
  npad = par.boxrad-par.fitrad
  mask = bytarr(npix, npix)
  mask[npad:npix-npad-1, npad:npix-npad-1] = 1B
  chisq = fltarr(nstamp)

  for i=0L, nstamp-1 do begin 
     w = where(mask AND (stampivar[*, *, i] NE 0), nmask)
     shiftstamp =  sshift2d(stamps[*, *, i], [dx[i], dy[i]])
     chisq[i] = total(shiftstamp[w]^2 * (stampivar[*, *, i])[w])/nmask
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


pro chisq_cut, chisq, x, y, dx, dy, stamps, stampivar, psfs, arr
  
; -------- keep stars with chisq LT 1 but keep at least half of them.
  chisqval = median(chisq) > 1
  w = where(chisq LT chisqval)
  chisq     = chisq[w]
  x         = x[w]
  y         = y[w]        
  dx        = dx[w]       
  dy        = dy[w]       
  stamps    = stamps[*, *, w]
  stampivar = stampivar[*, *, w]
  psfs      = psfs[*, *, w]     
  arr       = arr[*, *, w]      

  return
end



pro callit

  run = 273
  camcol = 3
  field = 500

  run = 4828
  camcol = 3
  field = 258


  par = psf_par()

  fname = sdss_name('idR', run, camcol, field, filter='i')
  sdss_readimage, fname, image, ivar, satmask=satmask


  badpixels = smooth(float(ivar EQ 0), par.fitrad*2+1, /edge) GT $
    ((1./par.fitrad)^2/10)

; -------- find some stars (not a complete list)
  psf_findstars, image, ivar, par.boxrad, clean, x, y, $
    satmask=satmask, badpixels=badpixels

; -------- cut out postage stamps around them
  stamps = psf_stamps(clean, ivar, x, y, par, /shift, dx=dx, dy=dy, $
                      stampivar=stampivar)
  nstamp = n_elements(dx) 

; -------- get median psf
  median_psf = djs_median(stamps, 3)
  psfs0 = stamps
  for i=0L, nstamp-1 do psfs0[*, *, i] = median_psf

  psf_multi_fit, stamps, stampivar, psfs0, par, sub, faint, nfaint=3
  psf_zero, stamps, stampivar, sub, median_psf, par, faint, chisq
  stamp_renorm, stamps, stampivar, par

  psf_multi_fit, stamps, stampivar, psfs0, par, sub1, faint, nfaint=3
; maybe recenter here
  recon = sub1+psfs0

; -------- do spatial PSF fit
  cf = psf_fit(recon, stampivar, x, y, par, ndeg=3, /reject)
  psfs1 = psf_eval(x, y, cf, par)

  psf_multi_fit, stamps, stampivar, psfs1, par, sub2, faint, nfaint=3


;  stamps2pca, psfs1, comp=comp, coeff=coeff, recon=recon

  chisq = psf_chisq(sub2, stampivar, par, dx=dx, dy=dy)

  sub3 = sub2

  chisq_cut, chisq, x, y, dx, dy, stamps, stampivar, psfs1, sub3
  recon = sub3+psfs1
  cf = psf_fit(recon, stampivar, x, y, par, ndeg=3, /reject)
  psfs2 = psf_eval(x, y, cf, par)


  chisq = psf_chisq(sub2, stampivar, par, dx=dx, dy=dy)

  sind = sort(chisq)
  atv, spread_stack(sub2[*, *, sind], 3)


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

  return
end



pro foobar

  raw = readfits('/scr/apache20/dfink/ctio/oct98/fits/n7obj/obj7100.fits')
  bias = readfits('bias.fits')
  flat = readfits('final_flat.fits')

  image = mask*(raw-bias)/(flat + (mask eq 0))



  return
end
