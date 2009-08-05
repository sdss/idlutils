; set some params for the pipeline
function psf_par

  par = {boxrad:  12, $  ; box radius of PSF cutout (2*boxrad+1, 2*boxrad+1)
         fitrad:  9, $   ; radius of region used in PSF fit
         cenrad:  1}   ; region used to center PSF
         
; nsigma ?
; nfaint?
; use ivar in psf_polyfit
; check condition of matrix in psf_polyfit


  return, par
end


