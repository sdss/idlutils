;-----------------------------------------------------------------------
;+
; NAME:
;   djs_xyouts
;
; PURPOSE:
;   Modified version of XYOUTS
;
; CALLING SEQUENCE:
;   djs_xyouts
;
; INPUT:
;
; OUTPUTS:
;
; PROCEDURES CALLED:
;   TeXtoIDL()
;
; REVISION HISTORY:
;   16-Apr-2000 Written by D. Schlegel, Princeton
;-
;-----------------------------------------------------------------------
pro djs_xyouts, x, y, s, _EXTRA=KeywordsForXyouts

   xyouts, x, y, TeXtoIDL(s), _EXTRA=KeywordsForXyouts

   return
end 
;-----------------------------------------------------------------------
