;+
;------------------------------------------------------------------------------
;  propmotdis
;------------------------------------------------------------------------------
;  output:
;    the proper motion distance with c=H_0=1.
;  input:
;    z       redshift, a scalar or vector
;    OmegaM  Omega_Matter, scalar only
;    OmegaL  Omega_Lambda, scalar only
;------------------------------------------------------------------------------
;-
function propmotdis, z,OmegaM,OmegaL
  TINY= double(1.0e-16)
  if (OmegaM LT TINY) AND (OmegaL LT TINY) then begin
    dM= (z+0.5*z*z)/(1.0+z)
  endif else begin
    if OmegaL LT TINY then begin
      q0= 0.5*OmegaM-OmegaL
      dM= (z*q0+(q0-1.0)*(sqrt(2.0*q0*z+1.0)-1.0))/(q0*q0*(1.0+z))
    endif else begin
      dM= comdis(z,OmegaM,OmegaL)
      OmegaK= 1.0-OmegaM-OmegaL
      sqrtOmegaK= sqrt(abs(OmegaK))
      if OmegaK LT (-1.0*TINY) then dM= sin(sqrtOmegaK*dM)/sqrtOmegaK $
      else if OmegaK GT TINY then dM= sinh(sqrtOmegaK*dM)/sqrtOmegaK
    endelse
  endelse
  return, dM
end
