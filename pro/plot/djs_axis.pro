;-----------------------------------------------------------------------
;+
; NAME:
;   djs_axis
;
; PURPOSE:
;   Modified version of AXIS
;
; CALLING SEQUENCE:
;   djs_axis
;
; INPUT:
;
; OUTPUTS:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   Written by D. Schlegel, 21 Jan 1998, Durham
;-
;-----------------------------------------------------------------------
pro djs_axis, xtitle=xtitle, ytitle=ytitle, $
 _EXTRA=KeywordsForPlot

   axis, xtitle=TeXtoIDL(xtitle), ytitle=TeXtoIDL(ytitle), $
    _EXTRA=KeywordsForPlot

   return
end 
;-----------------------------------------------------------------------
