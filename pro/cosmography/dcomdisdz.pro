;+
;------------------------------------------------------------------------------
;  dcomdisdz
;------------------------------------------------------------------------------
;  output:
;    the differential line-of-sight comoving distance dD/dz with c=H_0=1.
;  input:
;    z       redshift, a scalar or vector
;    OmegaM  Omega_Matter, scalar only
;    OmegaL  Omega_Lambda, scalar only
;------------------------------------------------------------------------------
;-
function dcomdisdz, z,OmegaM,OmegaL
  return, (1.0/sqrt((1.0+z)*(1.0+z)*(1.0+OmegaM*z)-z*(2.0+z)*OmegaL))
end
