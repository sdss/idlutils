;+
; NAME:
;   profinterp
;
; PURPOSE:
;   Interpolates a radial profile of the sort output by photo
;
; CALLING SEQUENCE:
;   profinterp,nprof,profmean,radius,flux, [fluxerr=, profradius= $
;      proferr=, radiusscale=, fluxscale=]
;
; INPUTS:
;   nprof - number of measured elements in the profile 
;   profmean - values (in maggies) in the profile [15]
;   radius - a set of values to interpolate to [N]
;   flux - calculated flux
;
; OPTIONAL INPUTS:
;   proferr - errors in profile
;   profradius - boundaries of annuli in profile (set to photo default
;                in arcsec)
;   radiusscale - asinh scale for radii
;   fluxscale - asinh scale for fluxes
;
; OUTPUTS:
;   fluxerr - calculated error
;
; OPTIONAL INPUT/OUTPUTS:
;
; COMMENTS:
;   Set up for using the profMean in the tsObj files of the SDSS,
;   input and output in maggies (or any linear measure of surface 
;   brightness
;
; EXAMPLES:
;
; BUGS:
;   Slow.
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   16-Jan-2002  Written by Mike Blanton, NYU
;-
;------------------------------------------------------------------------------
pro profinterp,nprof,profmean,radius,flux,fluxerr=fluxerr, $
               profradius=profradius, proferr=proferr, $
               radiusscale=radiusscale, fluxscale=fluxscale

if(NOT keyword_set(radiusscale)) then radiusscale=0.05
if(NOT keyword_set(fluxscale)) then fluxscale=1.e-10
if(NOT keyword_set(profradius)) then $
  profradius=[0., 0.564190, 1.692569, 2.585442, 4.406462, $
              7.506054, 11.576202, 18.584032, 28.551561, $
              45.503910, 70.510155, 110.530769, 172.493530, $
              269.519104, 420.510529, 652.500061]*0.396

PI=3.14159265358979d

cumprof=dblarr(nprof+1l)
indx=lindgen(nprof)
indxp1=lindgen(nprof)+1l
cumprof[1l:n_elements(cumprof)-1l]= $
  total(profmean[indx]*PI*(profradius[indxp1]^2-profradius[indx]^2), $
        /cumulative)
stop

aprofradius=asinh(profradius[0:n_elements(cumprof)-1]/radiusscale)
acumprof=asinh(cumprof/fluxscale)
stop

aflux=spline(aprofradius,acumprof,asinh(radius/radiusscale))
flux=fluxscale*sinh(aflux)

end
