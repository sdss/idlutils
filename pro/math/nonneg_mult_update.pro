;+
; NAME:
;	 nonneg_mult_update
; PURPOSE: (one line)
;	 Apply an SSL multiplicative update to iterate nonnegative quadratic problem 
; DESCRIPTION:
;  Using the method of Sha, Saul, & Lee (2002), "Multiplicative
;  updates for nonnegative quadratic programming in support vector
;  machines" (UPenn Tech Report MS-CIS-02-19), apply a multiplicative
;  update to an attempted solution to a nonnegative quadratic problem
;  (QP with box constraints):
;     F(v) = (1/2) v^T.A.v + b^T.v for v_i >= 0 for all i.
; CATEGORY:
;       Numerical
; CALLING SEQUENCE:
;	 new = nonneg_mult_update(old,avfunc,b)
; INPUTS:
;	 old - start vector
;  avfunc - function which returns A+.v or A-.v, depending
;  b - vector
; OPTIONAL INPUT PARAMETERS:
; KEYWORD PARAMETERS:
; OUTPUTS:
;  factor - return the factor used in this vector
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
;  Untested.
; PROCEDURE:
; MODIFICATION HISTORY:
;	  Written 2003-01-02 MRB (NYU) at suggestion of Sam Roweis
;-
function nonneg_mult_update,old,avfunc,b,factor=factor

avpos=call_function(avfunc,old,1.)
avneg=call_function(avfunc,old,-1.)

; if you are at zero, multiplicative updates don't change
; your value, so just ignore
nnindx=where(old gt 0.D,nncount)
factor=dblarr(n_elements(old))
new=dblarr(n_elements(old))
if(nncount gt 0) then begin
    factor[nnindx]= $
      (-b[nnindx]+sqrt(b[nnindx]^2+4.*avpos[nnindx]*avneg[nnindx]))/ $
      (2.*avpos[nnindx])
  new[nnindx]=old[nnindx]*factor[nnindx]
endif

return,new

end
