;+
;------------------------------------------------------------------------------
;  angdidis
;------------------------------------------------------------------------------
;  output:
;    the angular diameter distance with c=H_0=1.
;  input:
;    z       redshift, a scalar or vector
;    OmegaM  Omega_Matter, scalar only
;    OmegaL  Omega_Lambda, scalar only
;------------------------------------------------------------------------------
;-
function angdidis, z,OmegaM,OmegaL
  return, propmotdis(z,OmegaM,OmegaL)/(1.0+z)
end
