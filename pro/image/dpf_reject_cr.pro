function cr_find, im, gd, sig, nsigma, psfvals, ind0, neighbor=neighbor

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

; -------- look for peak more than nsigma sigma above background/psfval
  mpeak = (im[ind0] - (back1 > back2)/psfvals[0]) GT (nsigma*sig) OR $
    (im[ind0] - (back3 > back4)/psfvals[1]) GT (nsigma*sig)
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



pro cr_iter, im, psfvals, gd, nsigma=nsigma, niter=niter

  if NOT keyword_set(nsigma) then nsigma = 5
  if NOT keyword_set(niter)  then niter = 3

  sz = size(im, /dimens)

  sig = djsig(im, sigrej=5)   ; needs to be faster
  msig = im GT (nsigma*sig)

; -------- suspects (indexes of im) are above threshold on the first
;          pass, and neighbors of CRs on subsequent passes
  suspects = where(msig, nsuspect)
  if nsuspect EQ 0 then return   ; cannot find anything

  for iiter=0L, niter-1 do begin 
                                ; cr_find investigates suspects,
                                ; returns mpeak of same lenght (1=CR, 0=OK)
     thisnsigma = iiter EQ 0 ? nsigma : 3
     thispsfvals = iiter EQ 0 ? psfvals : [1.0, 1.0]
     mpeak = cr_find(im, gd, sig, thisnsigma, thispsfvals, suspects, neighbor=neighbor)
     wrej  = where(mpeak, nrej)
     print, 'iter ', iiter, '  CRs  ', nrej, total(gd)
     ; escape if we are done     
     if nrej EQ 0 then return
  
; -------- otherwise examine neighbors
     gd[suspects[wrej]] = 0B
     suspects = neighbor

  endfor

  return
end

pro cr

  psfvals = [0.56, 0.31]

  im=mrdfits('idR-000259-g3-0196.fit')
  im = long(im)+65536L*(im LT 0)

  im = im[100:899, 0:999]
  im = im-median(im)

  gd = im eq im

  cr_iter, im, psfvals, gd, nsigma=nsigma, niter=niter




  sz = size(im, /dimens)
  ind1 = where(gd eq 0)
  
  x = ind1 mod sz[0]
  y = ind1 / sz[0]
  atvplot, x, y, psym=6, color='magenta', syms=.5



  return
end
