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

   if (keyword_set(xtitle)) then xtitle_tex = TeXtoIDL(xtitle)
   if (keyword_set(ytitle)) then ytitle_tex = TeXtoIDL(ytitle)
   if (keyword_set(title)) then title_tex = TeXtoIDL(title)

   plot, xtmp, ytmp, xtitle=xtitle_tex, ytitle=ytitle_tex, $
    title=title_tex, _EXTRA=KeywordsForPlot

   return
end 
;-----------------------------------------------------------------------
