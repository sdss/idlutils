;+
; NAME:
;   slatec_bvalu
;
; PURPOSE:
;   Evaluate a bspline 
;
; CALLING SEQUENCE:
;   
;    y = slatec_bvalu(x, bkpt, coeff, ideriv=ideriv)
;
; INPUTS:
;   x          - vector of positions to evaluate
;   bkpt       - Breakpoint vector returned by efc
;   coeff      - B-spline coefficients calculated by efc
;
; OPTIONAL KEYWORDS:
;
;   ideriv     - Derivative to evaluate at x (default 0)
;
; OUTPUTS:
;   y          - Evaluations corresponding to x positions
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;
; EXAMPLES:
;
;
;
; PROCEDURES CALLED:
;   bvalu_idl in slatec/src/idlwrapper.c
;      which calls bvalu.f in libslatecidl.so
;
; REVISION HISTORY:
;   15-Oct-1999  Written by Scott Burles, Chicago
;-
;------------------------------------------------------------------------------

function slatec_bvalu, x, bkpt, coeff, ideriv=ideriv

   if (NOT keyword_set(ideriv)) then ideriv=0L

   nbkpt = n_elements(bkpt)
   ncoeff = n_elements(coeff)

   k = nbkpt - ncoeff
   n = nbkpt - k
   if (ideriv LT 0 OR ideriv GE k) then $
         message, 'ideriv must be >= 0 and < nord'

   if k LT 1 then message, 'nord must be > 0'
   if n LT k then message, 'nbkpt must be >= 2*nord'

   minbkpt = bkpt[k-1]
   maxbkpt = bkpt[n]

;   if (min(x) LT minbkpt) then $
;       message, 'x values fall below the first breakpoint'

;   if (max(x) GT maxbkpt) then $
;       message, 'x values fall above the last breakpoint'

   work = fltarr(3*k)
   y = x
   nx = n_elements(x)

   inbv = 1L
   xtemp = (x < maxbkpt)
   xtemp = (xtemp > minbkpt)
   rr = call_external(getenv('IDL_EVIL')+'libslatecidl.so','bvalu_idl', $
      bkpt, coeff, n, k, ideriv, xtemp, nx, inbv, work, y)

   return, y
end
