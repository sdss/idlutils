;+
; NAME:
;   sersic
;
; PURPOSE:
;   Convolves a radial profile with seeing (expressed as a sum of
;   gaussians) assuming axisymmetry
;
; CALLING SEQUENCE:
;   profmeansee=convolve_radial(nprof, profmean, seeing_width, $
;                               [seeing=, seegrid=, /setseegrid])
;
; INPUTS:
;   nprof - number of entries to use in profmean [N]
;   profmean - radial profile [15,N]
;   seeing_width - absolute width of seeing [N]
;
; OPTIONAL INPUTS:
;   seeing - relative widths and amplitudes of seeing gaussians
;   setseegrid - if set, reset the seegrid
;
; OUTPUTS:
;
; OPTIONAL INPUT/OUTPUTS:
;   seegrid - matrix of seeing_width and radius
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
;   23-Mar-2002  Written by Mike Blanton, NYU
;-
;------------------------------------------------------------------------------
pro sersic_params,amp,nsersic,r0,maggies=maggies,r50=r50,r90=r90,radius_vals=radius_vals

if(nsersic lt 0.1 OR nsersic gt 10. OR r0 lt 1.e-3 OR r0 gt 30. or $
   amp gt 1.e+1 or amp lt 1.e-20) then begin
    r50=1.e-6
    r90=1.e-6
    maggies=1.e+30
    return
endif

if(NOT keyword_set(radius_vals)) then $
  radius_vals=exp(alog(r0*0.03)+(alog(r0*50000.)-alog(r0*0.03))* $
                  dindgen(800)/800.)
nrad=n_elements(radius_vals)
i=lindgen(nrad-1L)
ip1=i+1L
dradius_vals=dblarr(nrad)
dradius_vals[i]=radius_vals[ip1]-radius_vals[i]
dradius_vals[nrad-1L]=radius_vals[nrad-1L]-radius_vals[nrad-2L]

sersic_vals=sersic(radius_vals,amp,nsersic,r0)

PI=3.14159265358979
cummaggies=total(2.*PI*radius_vals*dradius_vals*sersic_vals,/double, $
                 /cumulative)
maggies=cummaggies[nrad-1L]
r50indx=where(cummaggies[i] lt 0.5*maggies and cummaggies[ip1] gt 0.5*maggies)
r50s=(0.5*maggies-cummaggies[r50indx])/ $
  (cummaggies[r50indx+1L]-cummaggies[r50indx])
r50=radius_vals[r50indx]+(radius_vals[r50indx+1L]-radius_vals[r50indx])*r50s
r90indx=where(cummaggies[i] lt 0.9*maggies and cummaggies[ip1] gt 0.9*maggies)
r90s=(0.9*maggies-cummaggies[r90indx])/ $
  (cummaggies[r90indx+1L]-cummaggies[r90indx])
r90=radius_vals[r90indx]+(radius_vals[r90indx+1L]-radius_vals[r90indx])*r90s

end
