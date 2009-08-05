;+
; NAME:
;   psf_fit_coeffs
;
; PURPOSE:
;   Attempt to fit coefficients for delta-function PSF model
;
; CALLING SEQUENCE:
;   pstr = psf_fit_coeffs(image, ivar, satmask, par, cf, status=)
;
; INPUTS:
;   image   - image to operate on 
;   ivar    - iverse variance image
;   satmask - mask of saturated pixels (1=saturated)
;   par     - structure from psf_par.pro
;
; OUTPUTS:
;   cf      - fit coeffs
;   status  - status flags
;   pstr    - structure containing useful information about PSF stars
;
; OPTIONAL OUTPUTS:
;   
; EXAMPLES:
;   
; COMMENTS:
;   
; REVISION HISTORY:
;   2009-Jul-10 - Written by Douglas Finkbeiner, CfA (visiting IfA)
;
;----------------------------------------------------------------------
pro stamp_renorm, stamp, sivar, par

  nstamp = (size(stamp, /dimen))[2]
  for istamp=0L, nstamp-1 do begin 
     norm = psf_norm(stamp[*, *, istamp], par.cenrad)
     stamp[*, *, istamp] = stamp[*, *, istamp]/norm
     sivar[*, *, istamp] = sivar[*, *, istamp]*norm^2
  endfor 

  return
end



pro chisq_cut, chisq, x, y, dx, dy, stamps, stampivar, psfs, arr
  
; -------- keep stars with chisq LT 1 but keep at least half of them.
  chisqval = median(chisq) > 1
  w = where(chisq LT chisqval, nstar)

  splog, 'Cutting to', nstar, ' stars.'

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



function psf_fit_coeffs, image, ivar, satmask, par, cf, status=status, $
                         stamps=stamps

; -------- highest order fit to attempt
  ndeg = 3

; -------- timer
  t1 = systime(1)
  status = 0L

; CAREFUL HERE!!!

; -------- look for negative pixels
;  wneg = where(image LE 0, nneg)
;  if nneg GT 0 then begin 
;     status = status OR 1
;     ivar[wneg] = 0
;  endif

; -------- determine badpixels mask (pixels not to use for stamps)
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
  if nstamp GT 1 then begin
     median_psf = djs_median(stamps, 3)
     

     psfs0 = stamps
     for i=0L, nstamp-1 do psfs0[*, *, i] = median_psf

     psf_multi_fit, stamps, stampivar, psfs0, par, sub, faint, nfaint=0
     psf_zero, stamps, stampivar, sub, median_psf, par, faint, chisq
     stamp_renorm, stamps, stampivar, par

; -------- first chisq cut.  Some garbage (diffraction spikes, etc.)
;          may have leaked in - let's get it before we go on. 
; or not     
;     chisq = psf_chisq(stamps-psfs0, stampivar, par, dx=dx, dy=dy)
     
     psf_multi_fit, stamps, stampivar, psfs0, par, sub1, faint, nfaint=3
; maybe recenter here
     recon = sub1+psfs0
     
; -------- do spatial PSF fit
     cf = psf_polyfit(recon, stampivar, x, y, par, ndeg=ndeg, /reject, $
                      cond=cond, chisq=chisq)
     
; -------- if condition number is bad try again
     while max(cond) GT 100000 do begin 
        ndeg--
        splog, 'Condition Number:', max(cond), '  Falling back to ndeg =', ndeg
        if ndeg EQ -1 then stop
        cf = psf_polyfit(recon, stampivar, x, y, par, ndeg=ndeg, /reject, cond=cond)
     endwhile
     
     
     psfs1 = psf_eval(x, y, cf, par.cenrad)
     psf_multi_fit, stamps, stampivar, psfs1, par, sub2, faint, nfaint=3
     
;  stamps2pca, psfs1, comp=comp, coeff=coeff, recon=recon
     
     chisq = psf_chisq(sub2, stampivar, par, dx=dx, dy=dy)
     
     sub3 = sub2
help, 'foo1', x

sind = sort(chisq)
psf_tvstack, stamps[*, *, sind], window=1

     chisq_cut, chisq, x, y, dx, dy, stamps, stampivar, psfs1, sub3

help, 'foo2', x
     
     recon = sub3+psfs1
     cf = psf_polyfit(recon, stampivar, x, y, par, ndeg=ndeg, /reject, cond=cond)
help, 'foo3', x

     psfs2 = psf_eval(x, y, cf, par.cenrad)
  endif else begin 
     cond = 1.0
     cf = stamps
     ndeg = 0
     chisq = 0.0
     status = status OR 2
  endelse

print, '--------> CONDITION NUMBER ', max(cond), ' for ndeg =', ndeg

; -------- maybe make room for some QA stuff in here...
  delvarx, result
  result = {nstar: n_elements(x), $
            x: x+dx, $
            y: y+dy, $
            chisq: chisq, $
            ndeg: ndeg, $
            coeff: cf, $
            boxrad: par.boxrad, $
            fitrad: par.fitrad, $
            cenrad: par.cenrad, $
            condition: max(cond), $
            status: status}

  splog, 'Time: ', systime(1)-t1
  
  return, result
end
