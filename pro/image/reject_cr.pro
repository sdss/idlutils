;------------------------------------------------------------------------------
;+
; NAME:
;   reject_cr
;
; PURPOSE:
;   Detects cosmic rays by finding features sharper than the PSF
;
; CALLING SEQUENCE:
;   reject_cr, image, image_ivar, psfvals, rejects, nsig=nsig, $
;     cfudge=cfudge, c2fudge=c2fudge
;
; INPUTS:
;   image - [nx,ny] input image (sky-subtracted)
;   image_ivar - [nx,ny] variance image
;   psfvals - [2] values of psf at 1 pix and sqrt(2) pixels from center
;
; OPTIONAL INPUTS:
;   nsig - number of sigma above background required (default 6)
;   cfudge - number of sigma inconsistency required (default 3.)
;   c2fudge - fudge factor applied to psf (default 0.8)
;   threshold - threshold flux to keep a CR (default 0.)
;   niter - number of iterations to search for neighbors (default 3)
;
; OUTPUTS:
;   rejects - [nrejects] list of rejected pixels (-1 if none)
;   nrejects - number of rejected pixels
;
; COMMENTS:
;   Ignores pixels with image_ivar set to zero. 
;
; BUGS:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   Started - 18-Nov-2003 M. Blanton (NYU)
;-
;------------------------------------------------------------------------------
pro reject_cr_single, image, image_ivar, psfvals, rejected, nsig=nsig, $
                   cfudge=cfudge, c2fudge=c2fudge, nrejects=nrejects

if(n_elements(nsig) eq 0) then nsig=6.
if(n_elements(cfudge) eq 0) then cfudge=3.
if(n_elements(c2fudge) eq 0) then c2fudge=0.6

soname=filepath('libimage.so', $
                root_dir=getenv('IDLUTILS_DIR'), subdirectory='lib')
xnpix=(size(image,/dim))[0]
ynpix=(size(image,/dim))[1]
rejected=intarr(xnpix,ynpix)
retval=call_external(soname, 'idl_reject_cr_psf', float(image), $
                     float(image_ivar), $
                     long(xnpix), long(ynpix), float(nsig), float(psfvals), $
                     float(cfudge), float(c2fudge), fix(rejected))
return

end
;
pro reject_cr, image, image_ivar, psfvals, rejects, nsig=nsig, $
               cfudge=cfudge, c2fudge=c2fudge, nrejects=nrejects, $
               threshold=threshold, niter=niter

if(n_elements(niter) eq 0) then niter=3

; First detect cosmics the normal way
tmp_image=image
reject_cr_single, tmp_image, image_ivar, psfvals, rejected, nsig=nsig, $
  cfudge=cfudge, c2fudge=c2fudge
if(max(rejected) eq 0) then return

; interpolate them???

for k=0L, niter-1L do begin
; Now check neighbors with tough conditions
    tmp_ivar=0.*image_ivar
    xnpix=(size(image,/dim))[0]
    ynpix=(size(image,/dim))[1]
    rejects=where(rejected)
    xrejects=rejects mod xnpix
    yrejects=rejects / xnpix
    for i=-1,1 do begin
        for j=-1,1 do begin
            neighbors=(((xrejects+i)>0)<xnpix)+(((yrejects+j)>0)<ynpix)*xnpix
            tmp_ivar[neighbors]=image_ivar[neighbors]
        endfor
    endfor
    tmp_ivar[rejects]=0.
    reject_cr_single, tmp_image, image_ivar, psfvals, newrejected, nsig=nsig, $
      cfudge=0., c2fudge=c2fudge
    rejected=rejected OR newrejected
    
; interpolate them???

endfor

if(keyword_set(threshold)) then begin
; Assemble events and apply threshold
    mask=grow_object(rejected,nadd=nadd)
    isort=sort(mask)
    iuniq=uniq(mask[isort])
    istart=iuniq[0]+1L
    for i=1, n_elements(iuniq)-1L do begin
        iend=iuniq[i]
        icurr=isort[istart:iend]
        flux=total(image[icurr])
        if(flux lt threshold) then rejected[icurr]=0
        istart=iend+1L
    endfor
    mask=0
endif

rejects=where(rejected,nrejects)
    
end
