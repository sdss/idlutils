;+
;------------------------------------------------------------------------------
;  dpropdisdz
;------------------------------------------------------------------------------
;  output:
;    the differential line-of-sight proper distance dD/dz with c=H_0=1.
;  input:
;    z       redshift, a scalar or vector
;    OmegaM  Omega_Matter, scalar only
;    OmegaL  Omega_Lambda, scalar only
;------------------------------------------------------------------------------
;-
function dpropdisdz, z,OmegaM,OmegaL
  return, (dcomdisdz(z,OmegaM,OmegaL)/(1.0+z))
end
