;+
; NAME:
;   comdis
; PURPOSE:
;   Compute comoving line-of-sight distances (c/H_0=1).
; CALLING SEQUENCE:
;   D= comdis(z,OmegaM,OmegaL)
; INPUTS:
;   z       - redshift or vector of redshifts
;   OmegaM  - Omega-matter at z=0
;   OmegaL  - Omega-Lambda at z=0
; OPTIONAL INPUTS:
; KEYWORDS
; OUTPUTS:
;   comoving line-of-sight distance in units of the Hubble length c/H_0.
; COMMENTS:
; BUGS:
; EXAMPLES:
; PROCEDURES CALLED:
;   dcomdisdz()
; REVISION HISTORY:
;   25-Jun-2000  Written by Hogg (IAS)
;-
;------------------------------------------------------------------------------
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
