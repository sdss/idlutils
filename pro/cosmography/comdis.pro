;+
;------------------------------------------------------------------------------
;  comdis
;------------------------------------------------------------------------------
;  output:
;    the line-of-sight comoving distance with c=H_0=1.
;  input:
;    z       redshift, a scalar or vector
;    OmegaM  Omega_Matter, scalar only
;    OmegaL  Omega_Lambda, scalar only
;------------------------------------------------------------------------------
;-
function comdis, z,OmegaM,OmegaL
  stepsize=0.01 ; minimum stepsize
  nsteps= long(z/stepsize)+1
  dz= z/double(nsteps)
  dC= double(0.0*z)
  sz= size(z)
  if sz(0) EQ 0 then begin
    for zz=0.5*dz,z,dz do dC = dC+dz*dcomdisdz(zz,OmegaM,OmegaL)
  endif else begin
    nvalues= sz((size(sz))(1)-1) & help, nvalues
    for i=0,nvalues-1 do begin
      for zz=0.5*dz(i),z(i),dz(i) do dC(i) = dC(i)+dz(i)*dcomdisdz(zz,OmegaM,OmegaL)
    endfor
  endelse
  return, dC
end
