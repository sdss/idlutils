;+
; NAME:
;   bvalu2d
;
; PURPOSE:
;   Evaluate a bspline fit over 2 dependent variables
;
; CALLING SEQUENCE:
;   
;    z = bvalu2d(x, y, bkpt, coeff, ideriv=ideriv)
;
; INPUTS:
;   x          - vector of x positions to evaluate
;   y          - vector of y positions to evaluate
;   bkpt       - Breakpoint vector returned by efc
;   coeff      - B-spline coefficients calculated by efc 
;		   2d in this case [npoly, nbkpt-nord]
;
; OPTIONAL KEYWORDS:
;
;   ideriv     - Derivative to evaluate at x (default 0)
;
; OUTPUTS:
;   z          - Evaluations corresponding to x positions
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;
; EXAMPLES:
;
;
; PROCEDURES CALLED:
;   slatec_bvalu
;
; REVISION HISTORY:
;   13-Mar-2000  Written by Scott Burles, FNAL
;-
;------------------------------------------------------------------------------

function slatec_bvalu, x, bkpt, coeff, ideriv=ideriv

   if (NOT keyword_set(ideriv)) then ideriv=0L

   ideriv = long(ideriv)

   nbkpt = n_elements(bkpt)
   ncoeff = n_elements(coeff)

   k = nbkpt - ncoeff
   n = nbkpt - k
   if (ideriv LT 0 OR ideriv GE k) then begin
         print, 'ideriv is ', ideriv
         message, 'ideriv must be >= 0 and < nord'
   endif


   if k LT 1 then message, 'nord must be > 0'
   if n LT k then message, 'nbkpt must be >= 2*nord'

   minbkpt = bkpt[k-1]
   maxbkpt = bkpt[n]

;   if (min(x) LT minbkpt) then $
;       message, 'x values fall below the first breakpoint'

;   if (max(x) GT maxbkpt) then $
;       message, 'x values fall above the last breakpoint'

   work = fltarr(3*k)
   y = float(x)
   nx = n_elements(x)

   inbv = 1L
   xtemp = float(x < maxbkpt)
   xtemp = (xtemp > minbkpt)
   rr = call_external(getenv('IDLUTILS_DIR')+'/lib/libslatec.so', $
      'bvalu_idl', $
      float(bkpt), float(coeff), n, k, ideriv, xtemp, nx, inbv, work, y)

   return, y
end
l
;
;	Coeff actually contains a nord x ncoeff numbers
;       containing 2d information
;


function bvalu2d, x, y, fullbkpt, coeff, ideriv=ideriv

    npoly = (size(coeff))[0]
    ncoeff = (size(coeff))[1]

    z = x*0.0

    for i=0,npoly -1 do begin

      z = z + slatec_bvalu(x, fullbkpt, coeff[i,*], ideriv=ideriv) * y^i
    endfor

    return, z
end
;
;	Coeff actually contains a nord x ncoeff numbers
;       containing 2d information
;


function bvalu2d, x, y, fullbkpt, coeff, ideriv=ideriv

    npoly = (size(coeff))[0]
    ncoeff = (size(coeff))[1]

    z = x*0.0

    for i=0,npoly -1 do begin

      z = z + slatec_bvalu(x, fullbkpt, coeff[i,*], ideriv=ideriv) * y^i
    endfor

    return, z
end
