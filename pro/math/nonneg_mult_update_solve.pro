;+
; NAME:
;	 nonneg_mult_update_solve
; PURPOSE: (one line)
;	 Use nonneg_mult_update to iterate to convergence
; DESCRIPTION:
;  From some starting point, iterates to convergence a
;  box-constrained QP problem
; CATEGORY:
;       Numerical
; CALLING SEQUENCE:
;	 solution = nonneg_mult_update_solve(start,avfunc,b)
; INPUTS:
;	 start - start vector
;  avfunc - function which returns A+.v or A-.v, depending
;  b - vector
; OPTIONAL INPUT PARAMETERS:
; KEYWORD PARAMETERS:
;  /matrix - indicates that avfunc is actually just the matrix to
;            apply
; OUTPUTS:
;	 Return value is the shifted array.
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
;  Tested only in simple cases.
; PROCEDURE:
; MODIFICATION HISTORY:
;	  Written 2003-01-02 MRB (NYU) at suggestion of Sam Roweis
;-
function nnmus_default_avfunc,vec,sign

common nnmus_com, nnmus_matrix_pos, nnmus_matrix_neg

if(sign gt 0.) then return, nnmus_matrix_pos#vec
return, nnmus_matrix_neg#vec

end
;
function nnmus_value,vec,avfunc,b

common nnmus_com, nnmus_matrix_pos, nnmus_matrix_neg

avpos=call_function(avfunc,vec,1.)
avneg=call_function(avfunc,vec,-1.)
av=avpos-avneg
vav=(transpose(vec)#av)[0]

val=(0.5*vav+b#vec)[0]
return,val

end
;
function nonneg_mult_update_solve,start,avfunc,b,matrix=matrix,tol=tol, $
                                  verbose=verbose

common nnmus_com

if(NOT keyword_set(tol)) then tol=1.D-7

; set avfunc to use
use_avfunc=avfunc
if(keyword_set(matrix)) then begin
    nnmus_matrix_pos=avfunc > 0.D
    nnmus_matrix_neg=abs(avfunc < 0.D)
    use_avfunc='nnmus_default_avfunc'
endif

sol=start
oldval=nnmus_value(sol,use_avfunc,b)
splog,'oldval='+string(oldval)
diff=tol*2.
while(abs(diff) gt tol) do begin
    sol=nonneg_mult_update(sol,use_avfunc,b,factor=factor)
    newval=nnmus_value(sol,use_avfunc,b)
    if(keyword_set(verbose)) then begin
        splog,'newval='+string(newval)
;        splog,'sol='+string(sol)
;        splog,'factor='+string(factor)
    endif
    diff=(newval-oldval)
    oldval=newval
endwhile

return,sol

end
