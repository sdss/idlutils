;
;   Find and remove cosmic-rays
;
; Algorithms designed by Kazu Shimasaku, implemented in C by R. Lupton

; min_sigma   - min sigma above sky in pixel for CR candidates

function cr_find, im, gd, ivar, min_sigma, c3fac, psfvals, ind0, neighbor=neighbor

  isig = sqrt(ivar[ind0]) ; inverse sigma
  sz = size(im, /dimens)

; -------- get Cartesian coords (x,y) from index
  x0 = ind0 mod sz[0]
  y0 = ind0 / sz[0]

; -------- neighbors (left, right, down, up)
  xl = (x0-1) > 0
  xr = (x0+1) < (sz[0]-1)
  yd = (y0-1) > 0
  yu = (y0+1) < (sz[1]-1)

; -------- calculate background along 4 axes
  back1 = (gd[xl, y0]*im[xl, y0] + gd[xr, y0]*im[xr, y0])/(gd[xl, y0]+gd[xr, y0] > 1)
  back2 = (gd[x0, yd]*im[x0, yd] + gd[x0, yu]*im[x0, yu])/(gd[x0, yd]+gd[x0, yu] > 1)
  back3 = (gd[xl, yu]*im[xl, yu] + gd[xl, yd]*im[xl, yd])/(gd[xl, yu]+gd[xl, yd] > 1)
  back4 = (gd[xr, yu]*im[xr, yu] + gd[xr, yd]*im[xr, yd])/(gd[xr, yu]+gd[xr, yd] > 1)

; -------- CONDITION #2

; ??? use sigma_sky instead of isig ???
  cond2 = (im[ind0] - (back1 < back2 < back3 < back4))*isig GT min_sigma

; -------- CONDITION #3
; *   (p - cond3_fac*N(p) - sky) > PSF(d)*(mean + cond3_fac*N(mean) - sky)
; * where PSF(d) is the value of the PSF at a distance d, mean is the average
; * of two pixels a distance d away, and N(p) is p's standard deviation. In
; * practice, we multiple PSF(d) by some fiddle factor, cond3_fac2

  p = im[ind0]
  isigp  = sqrt(ivar[ind0])

  isigab = sqrt(ivar[xl, y0]*ivar[xr, y0])
  cond31 = (p*isigp - c3fac)*isigab GE isigp*(back1*isigab+c3fac*sqrt(ivar[xl, y0]+ivar[xr, y0]))/PSFvals[0]
  isigab = sqrt(ivar[x0, yd]*ivar[x0, yu])
  cond32 = (p*isigp - c3fac)*isigab GE isigp*(back2*isigab+c3fac*sqrt(ivar[x0, yd]+ivar[x0, yu]))/PSFvals[0]
  isigab = sqrt(ivar[xl, yu]*ivar[xl, yd])
  cond33 = (p*isigp - c3fac)*isigab GE isigp*(back3*isigab+c3fac*sqrt(ivar[xl, yu]+ivar[xl, yd]))/PSFvals[1]
  isigab = sqrt(ivar[xr, yu]*ivar[xr, yd])
  cond34 = (p*isigp - c3fac)*isigab GE isigp*(back4*isigab+c3fac*sqrt(ivar[xr, yu]+ivar[xr, yd]))/PSFvals[1]

  cond3 = cond31 OR cond32 OR cond33 OR cond34
  
; -------- look for peak more than nsigma sigma above background/psfval
;  mpeak = ((im[ind0] - (back1 > back2)/psfvals[0])*isig GT nsigma) OR $
;    ((im[ind0] - (back3 > back4)/psfvals[1])*isig GT nsigma)

  mpeak = cond2 AND cond3

  mpeak = mpeak AND gd[ind0]  ; apply mask

; -------- get neighbors
  if arg_present(neighbor) then begin 
     w = where(mpeak, npeak)
     if npeak EQ 0 then begin ; do not set neighbors
        delvarx, neighbor
        return, mpeak
     endif 
     neighborx = [xr[w], xr[w], x0[w], xl[w], xl[w], xl[w], x0[w], xr[w]]
     neighbory = [y0[w], yu[w], yu[w], yu[w], y0[w], yd[w], yd[w], yd[w]]
     
     neighbor_all = neighbory*sz[0]+neighborx
     u = uniq(neighbor_all, sort(neighbor_all))
     neighbor = neighbor_all[u]
  endif 

  return, mpeak
end



function dpf_reject_cr, im, psfvals, ivar, nsigma=nsigma, cfudge=cfudge, $
            niter=niter

  if NOT keyword_set(nsigma) then nsigma = 6.0
  if NOT keyword_set(cfudge) then cfudge = 3.0
  if NOT keyword_set(niter)  then niter = 6

  sz = size(im, /dimens)
  gd = bytarr(sz[0], sz[1])+1B

;  sig = djsig(im, sigrej=5)   ; needs to be faster

  sig = 5 ;???
  msig = im GT (nsigma*sig)

; -------- suspects (indexes of im) are above threshold on the first
;          pass, and neighbors of CRs on subsequent passes
  suspects = where(msig, nsuspect)
  if nsuspect EQ 0 then return, gd  ; cannot find anything

  for iiter=0L, niter-1 do begin 
                                ; cr_find investigates suspects,
                                ; returns mpeak of same lenght (1=CR, 0=OK)

     c3fac = iiter EQ 0 ? cfudge : 0.0
;     thispsfvals = iiter EQ 0 ? psfvals : [1.0, 1.0]
     thispsfvals = psfvals
     mpeak = cr_find(im, gd, ivar, nsigma, c3fac, thispsfvals, suspects, neighbor=neighbor)
     wrej  = where(mpeak, nrej)
;     print, 'iter ', iiter, '  CRs  ', nrej, n_elements(gd)-total(gd)
     ; escape if we are done     
     if nrej EQ 0 then return, gd
  
; -------- otherwise examine neighbors
     gd[suspects[wrej]] = 0B
     suspects = neighbor

  endfor

  return, gd
end

pro cr

  psfvals = [0.56, 0.31]
;  psfvals = [.625, .391] ; 1.0 arcsec seeing


  sdss_readimage, '/u/dss/data/259/fields/3/idR-000259-g3-0195.fit', im, ivar,  rerun=137

;  im=mrdfits('idR-000259-g3-0196.fit')
;  im = long(im)+65536L*(im LT 0)

;  im = im[100:899, 0:999]

  im = im-median(im)


  mask = ivar eq 0
  foo = djs_maskinterp(im, mask, iaxis=0, /const)

  nsigma = 5.0
  gd = dpf_reject_cr(foo, psfvals, ivar, nsigma=nsigma, niter=1, cfudge=3.)



  atverase
  sz = size(im, /dimens)
  ind1 = where((gd eq 0) and (ivar NE 0))
  
  x = ind1 mod sz[0]
  y = ind1 / sz[0]
  atvplot, x, y, psym=6, color='magenta', syms=.5



  return
end
