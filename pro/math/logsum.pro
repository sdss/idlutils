;+
; NAME:
;	  logsum
; PURPOSE: (one line)
;   take natural log of the sum of natural logs (quickly)
; DESCRIPTION:
;
; CATEGORY:
;       Numerical
; CALLING SEQUENCE:
;   res= logsum(logs [,/double])
; INPUTS:
; OPTIONAL INPUT PARAMETERS:
; KEYWORD PARAMETERS:
;   /double - assume double precision input (otherwise assumes float)
; OUTPUTS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;	  Blanton and Roweis 2003-02-18j 
;-
function logsum, logs, double=double, const=const

maxlog=max(logs)
logxmax=alog((machar(double=double)).xmax)
const=logxmax-alog(2.*n_elements(logs))-maxlog
logsum=alog(total(exp(logs+const),double=double))-const
return,logsum

end
