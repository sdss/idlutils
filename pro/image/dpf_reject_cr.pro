;+
; NAME:
;   psf_reject_cr_single
;
; PURPOSE:
;   test a list of "suspect" pixels for cosmic rays (CRs)
;
; CALLING SEQUENCE:
;   result=psf_reject_cr_single(im, gd, ivar, satmask, min_sigma, $
;         c3fac, psfvals, ind0, neighbor=neighbor)
;
; INPUTS:
;   im        - image to test
;   gd        - array of "good pixels" to use (1=good)
;   ivar      - inverse variance of image
;   satmask   - saturated pixel mask (1=saturated)
;   min_sigma - minimum value (in sigma) for condition 2
;   c3fac     - consistency factor [in sigma] for condition 3
;   psfvals   - values of psf at 1 pix and sqrt(2) pixels from center
;   ind0      - index list of pixels to investigate
;
; OUTPUTS:
;   result    - byte array of results, same length as ind0 (1=CR)
;
; OPTIONAL OUTPUTS:
;   neighbor  - index list of neighbors of just-found CRs
;
; EXAMPLES:
;   always called by psf_reject_cr
;
; COMMENTS:
;   Algorithms designed by Kazu Shimasaku, implemented in C by R. Lupton
;    re-implemented by M. Blanton as reject_cr. 
;    Now completely rewritten by D. Finkbeiner as psf_reject_cr.
;    see psf_reject_cr for more details. 
;   
; REVISION HISTORY:
;   2005-Mar-09  Written by Douglas Finkbeiner, Princeton
;
;----------------------------------------------------------------------
function psf_reject_cr_single, im, gd, ivar, satmask, min_sigma, $
            c3fac, psfvals, ind0, neighbor=neighbor

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
  back3 = (gd[xl, yu]*im[xl, yu] + gd[xr, yd]*im[xr, yd])/(gd[xl, yu]+gd[xr, yd] > 1)
  back4 = (gd[xr, yu]*im[xr, yu] + gd[xl, yd]*im[xl, yd])/(gd[xr, yu]+gd[xl, yd] > 1)

;  gdb1 = gd[xl, y0] AND gd[xr, y0] AND (ivar[xl, y0] * ivar[xr, y0] NE 0)
;  gdb2 = gd[x0, yd] AND gd[x0, yu] AND (ivar[x0, yd] * ivar[x0, yu] NE 0)
;  gdb3 = gd[xl, yu] AND gd[xr, yd] AND (ivar[xl, yu] * ivar[xr, yd] NE 0)
;  gdb4 = gd[xr, yu] AND gd[xl, yd] AND (ivar[xr, yu] * ivar[xl, yd] NE 0)
  gdb1 = (ivar[xl, y0] * ivar[xr, y0] NE 0)
  gdb2 = (ivar[x0, yd] * ivar[x0, yu] NE 0)
  gdb3 = (ivar[xl, yu] * ivar[xr, yd] NE 0)
  gdb4 = (ivar[xr, yu] * ivar[xl, yd] NE 0)
; -------- CONDITION #2
; ??? Should we use sigma_sky instead of isig ???
  minback = (back1 < back2 < back3 < back4)
  cond2 = (im[ind0] - minback)*isig GT min_sigma

; -------- CONDITION #3
; comments from CR.c in photo:
; *   (p - cond3_fac*N(p) - sky) > (mean + cond3_fac*N(mean) - sky)/PSF(d)
; * where PSF(d) is the value of the PSF at a distance d, mean is the average
; * of two pixels a distance d away, and N(p) is p's standard deviation. In
; * practice, we multiple PSF(d) by some fiddle factor, cond3_fac2

  p = im[ind0]
  isigp  = sqrt(ivar[ind0])

  isigab = sqrt(ivar[xl, y0]*ivar[xr, y0])
  cond31 = (p*isigp - c3fac)*isigab GE isigp*(back1*isigab+c3fac*sqrt(ivar[xl, y0]+ivar[xr, y0])/2)/PSFvals[0]
  isigab = sqrt(ivar[x0, yd]*ivar[x0, yu])
  cond32 = (p*isigp - c3fac)*isigab GE isigp*(back2*isigab+c3fac*sqrt(ivar[x0, yd]+ivar[x0, yu])/2)/PSFvals[0]
  isigab = sqrt(ivar[xl, yu]*ivar[xr, yd])
  cond33 = (p*isigp - c3fac)*isigab GE isigp*(back3*isigab+c3fac*sqrt(ivar[xl, yu]+ivar[xr, yd])/2)/PSFvals[1]
  isigab = sqrt(ivar[xr, yu]*ivar[xl, yd])
  cond34 = (p*isigp - c3fac)*isigab GE isigp*(back4*isigab+c3fac*sqrt(ivar[xr, yu]+ivar[xl, yd])/2)/PSFvals[1]

; -------- if any if the four background estimates is good and
;          violates the PSF, then condition 3 is satisfied.
  cond3 = (cond31 AND gdb1) OR (cond32 AND gdb2) OR $
          (cond33 AND gdb3) OR (cond34 AND gdb4)


; -------- CONDITION #4
;           check that neighbors are not saturated

  cond4 = bytarr(n_elements(ind0))+1B
  nbx   = [xr, xr, x0, xl, xl, xl, x0, xr]
  nby   = [y0, yu, yu, yu, y0, yd, yd, yd]
  wsat  = where(satmask[nbx, nby], nsat)

  if nsat GT 0 then begin 
     isat = wsat mod n_elements(ind0) 
     cond4[isat] = 0B
  endif 

; -------- See which pixels satisfy all conditions:

  mpeak = cond2 AND cond3 AND cond4

  mpeak = mpeak AND gd[ind0]  ; apply mask

  w = where(mpeak, npeak)
  if npeak EQ 0 then begin      ; do not set neighbors
     delvarx, neighbor
     return, mpeak
  endif 

; -------- replace detected CRs for next round.
  im[ind0[w]] = minback[w]

; -------- get neighbors
  if arg_present(neighbor) then begin 
     neighborx = [xr[w], xr[w], x0[w], xl[w], xl[w], xl[w], x0[w], xr[w]]
     neighbory = [y0[w], yu[w], yu[w], yu[w], y0[w], yd[w], yd[w], yd[w]]
     
     neighbor_all = neighbory*sz[0]+neighborx
     u = uniq(neighbor_all, sort(neighbor_all))
     neighbor = neighbor_all[u]
  endif 

  return, mpeak
end



function dpf_reject_cr, im, psfvals, ivar, satmask=satmask, $
            nsigma=nsigma, cfudge=cfudge, niter=niter

  if NOT keyword_set(nsigma) then nsigma = 6.0
  if NOT keyword_set(cfudge) then cfudge = 3.0
  if NOT keyword_set(niter)  then niter = 6
  if NOT keyword_set(satmask) then message, 'need to set satmask'

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
     mpeak = psf_reject_cr_single(im, gd, ivar, satmask, nsigma, c3fac, thispsfvals, suspects, neighbor=neighbor)
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


  sdss_readimage, '/u/dss/data/259/fields/3/idR-000259-g3-0196.fit', im, ivar, $
    satmask=satmask, rerun=137

;  im=mrdfits('idR-000259-g3-0196.fit')
;  im = long(im)+65536L*(im LT 0)

;  im = im[100:899, 0:999]

  im = im-median(im)




  mask = ivar eq 0
  foo = djs_maskinterp(im, mask, iaxis=0, /const)

  nsigma = 6.0

  ivar1    = ivar[6:15, 1240:1249]
  foo1     = foo[6:15, 1240:1249]
  satmask1 = satmask[6:15, 1240:1249]


  gd = dpf_reject_cr(foo, psfvals, ivar, satmask=satmask, nsigma=4.5)



;  gd = dpf_reject_cr(foo1, psfvals, ivar1, satmask=satmask1)

  reject_cr, foo, ivar, psfvals, rejects


  atverase
  sz = size(im, /dimens)
  ind1 = where((gd eq 0) and (ivar NE 0))
  
  x = ind1 mod sz[0]
  y = ind1 / sz[0]
  atvplot, x, y, psym=6, color='magenta', syms=1

  x = rejects mod sz[0]
  y = rejects / sz[0]
  atvplot, x, y, psym=7, color='blue', syms=1


  return
end
