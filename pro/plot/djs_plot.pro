;-----------------------------------------------------------------------
;+
; NAME:
;   djs_plot
;
; PURPOSE:
;   Modified version of PLOT
;
; CALLING SEQUENCE:
;   djs_plot, [x,] y
;
; INPUT:
;   x:
;   y:
;
; OUTPUTS:
;
; PROCEDURES CALLED:
;  TeXtoIDL()
;
; REVISION HISTORY:
;   Written by D. Schlegel, 27 September 1997, Durham
;-
;-----------------------------------------------------------------------
pro djs_plot, x, y, xtitle=xtitle, ytitle=ytitle, title=title, $
 _EXTRA=KeywordsForPlot

   plot, x, y, xtitle=TeXtoIDL(xtitle), ytitle=TeXtoIDL(ytitle), $
    title=TeXtoIDL(title), _EXTRA=KeywordsForPlot

   return
end 
;-----------------------------------------------------------------------
