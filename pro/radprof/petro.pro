;+
; NAME:
;
; PURPOSE:
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; OUTPUTS:
;
; OPTIONAL INPUT/OUTPUTS:
;
; COMMENTS:
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   28-Mar-2002  Written by Mike Blanton, NYU
;-
;------------------------------------------------------------------------------
function sb_annulus, nprof, profradius, profmean, radius

PI=3.14159265358979
profinterp,nprof,profmean,radius*1.25,maggies_out,profradius=profradius
profinterp,nprof,profmean,radius*0.8,maggies_in,profradius=profradius
val=(maggies_out-maggies_in)/(PI*radius^2*(1.25^2-0.8^2))
return,val

end
;
pro petro,nprof,profmean,petrorad=petrorad,petromaggies=petromaggies,petror50=petror50,petror90=petror90,fixed_petrorad=fixed_petrorad,petroratiolimit=petroratiolimit,npetrorad=npetrorad,profradius=profradius

PI=3.14159265358979

if(NOT keyword_set(petroratiolimit)) then petroratiolimit=0.2
if(NOT keyword_set(npetrorad)) then npetrorad=2.
if(NOT keyword_set(profradius)) then $
  profradius=[0., 0.564190, 1.692569, 2.585442, 4.406462, $
              7.506054, 11.576202, 18.584032, 28.551561, $
              45.503910, 70.510155, 110.530769, 172.493530, $
              269.519104, 420.510529, 652.500061]*0.396

; set petrorad
if(keyword_set(fixed_petrorad)) then begin
    petrorad=fixed_petrorad
endif else begin
    nradii=5000L
    radii=exp(alog(profradius[1])+(alog(profradius[nprof]) $
                                   -alog(profradius[1]))* $
              dindgen(nradii)/double(nradii))
    sb=sb_annulus(nprof#replicate(1.,nradii),profradius, $
                  profmean#replicate(1.,nradii),radii)
    profinterp,nprof#replicate(1.,nradii),profmean#replicate(1.,nradii), $
      radii,maggies_cum,profradius=profradius
    avgsb=maggies_cum/(PI*radii^2)
    
    indx=where(sb[0:nradii-2] gt petroratiolimit*avgsb[0:nradii-2] and $
               sb[1:nradii-1] lt petroratiolimit*avgsb[0:nradii-1])
    print,radii[indx]
    petrorad=radii[indx[0]]
    stop
    
endelse

end
