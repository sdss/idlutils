;+
; NAME:
;   construct_field_polygon
; PURPOSE:
;   Create the structure for a SDSS field polygon 
; CALLING SEQUENCE:
;   poly=construct_field_polygon([maxncaps= ])
; INPUTS:
; OPTIONAL INPUTS:
;   maxncaps - the maximum number of caps allowed for any polygon
; OUTPUTS:
; OPTIONAL INPUT/OUTPUTS:
; COMMENTS:
; EXAMPLES:
; BUGS:
; PROCEDURES CALLED:
; REVISION HISTORY:
;   01-Oct-2002  Written by MRB (NYU)
;-
;------------------------------------------------------------------------------
function construct_field_polygon, maxncaps=maxncaps

if(NOT keyword_set(maxncaps)) then maxncaps=15L

; make cap structure
cap1=construct_cap()

field_polygon={fieldpolystr, ncaps:0L, weight:0.D, str:0.D, $
               caps:replicate(cap1,maxncaps), $
               field_va_mulimits:dblarr(2), $
               field_va_nulimits:dblarr(2), $
               ok_run_va_mulimits:dblarr(2), $
               ok_scanline_va_nulimits:dblarr(2), $
               ok_stripe_va_etalimits:dblarr(2), $
               primary_va_mulimits:dblarr(2) $
              }

return,field_polygon

end
