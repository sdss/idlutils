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

   ; If X values don't exist, then create them as PLOT or OPLOT would do
   npt = N_elements(x)
   if (keyword_set(y)) then begin
      xtmp = x
      ytmp = y
   endif else begin
      xtmp = lindgen(npt)
      ytmp = x
   endelse

   plot, xtmp, ytmp, xtitle=TeXtoIDL(xtitle), ytitle=TeXtoIDL(ytitle), $
    title=TeXtoIDL(title), _EXTRA=KeywordsForPlot

   return
end 
;-----------------------------------------------------------------------
