;+
; NAME:
;   extract_profmean
; PURPOSE:
;   Extract a photoesque radial profile
; CALLING SEQUENCE
;   extract_profmean, image, center, profmean, proferr $
;     [,profradius=profradius] [,invvar=invvar] 
; INPUTS:
;   image       - [nx,ny] image
;   center      - [2,ncent] center of extraction
; OPTIONAL INPUTS:
;   invvar      - [nx,ny] inverse variance image; default to unity
;   profradius  - [nrad] defining profile, in pixels; default to PHOTO aps
; KEYWORDS:
; OUTPUTS:
;   profmean    - [nrad,ncent] annular fluxes
;   proferr - [nrad,ncent] uncertainties
; COMMENTS:
;   This runs djs_phot EXACTLY on apertures with radius < 12, and QUICKLY on
;     apertures with radius > 12.
; DEPENDENCIES:
;   idlutils
; BUGS:
; REVISION HISTORY:
;   2002-09-04  Written - Blanton
;   2002-09-12  Modified to use djsphot - Hogg
;-
pro extract_profmean, image, center, profmean, proferr, $
                      profradius=profradius, invvar=invvar, $
                      nprof=nprof

; set defaults
  if NOT keyword_set(profradius) then $
    profradius= [  0.564190,   1.692569,   2.585442,   4.406462, $
                   7.506054,  11.576202,  18.584032,  28.551561, $ 
                  45.503910,  70.510155, 110.530769, 172.493530, $
                 269.519104, 420.510529, 652.500061]
  if NOT keyword_set(invvar) then invvar= 0.0*image+1.0

; choose precise and imprecise regions
  cutoff= 12.0
  iexact= where(profradius LT cutoff,nexact)
  iquick= where(profradius GE cutoff,nquick)

; create output arrays
  nrad= n_elements(profradius)
  ncent= n_elements(center)/2
  center= reform(center,2,ncent)

; measure aperture fluxes on invvar and image*invvar, exactly and quickly
  skyrad = 0
  if nexact GT 0 then begin
    area1= djs_phot(center[0,*],center[1,*],profradius[iexact],skyrad, $
      invvar,calg='none',salg='none',srejalg='none',/exact)
    profmean1= djs_phot(center[0,*],center[1,*],profradius[iexact],skyrad, $
      image*invvar,calg='none',salg='none',srejalg='none',/exact)
    area1= reform(area1,ncent,nexact)
    profmean1= reform(profmean1,ncent,nexact)
  endif
  if nquick GT 0 then begin
    area2= djs_phot(center[0,*],center[1,*],profradius[iquick],skyrad, $
      invvar,calg='none',salg='none',srejalg='none',/quick)
    profmean2= djs_phot(center[0,*],center[1,*],profradius[iquick],skyrad, $
      image*invvar,calg='none',salg='none',srejalg='none',/quick)
    area2= reform(area2,ncent,nquick)
    profmean2= reform(profmean2,ncent,nquick)
  endif

; recombine exact and quick results
  if nquick EQ 0 then begin
    area= area1
    profmean= profmean1
  endif
  if nexact EQ 0 then begin
    area= area2
    profmean= profmean2
  endif
  if nexact GT 0 AND nquick GT 0 then begin
    area= [[area1],[area2]]
    profmean= [[profmean1],[profmean2]]
  endif
  area= transpose(area)
  profmean= transpose(profmean)

; deal with annuli
  lowareaindx=where(area/(!DPI*profradius^2) lt 0.95 OR $
                    area ne area, lowareacount)
  for i=nrad-1L,1L,-1L do begin
      area[i,*]= area[i,*]-area[i-1,*]
      profmean[i,*]= profmean[i,*]-profmean[i-1,*]
  endfor

; divide out areas
  profmean= profmean/area
  proferr= 1.0/sqrt(area)

  nprof=n_elements(profradius)
  if(lowareacount gt 0) then begin
      nprof=lowareaindx[0]
      profmean[nprof:nrad-1]=0.
  endif

end
