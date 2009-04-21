;-----------------------------------------------------------------------
;+
; NAME:
;   djs_plot
;
; PURPOSE:
;   Modified version of PLOT
;
; CALLING SEQUENCE:
;   djs_plot, [x,] y, [bin= ]
;
; INPUT:
;   x:
;   y:
;
; OPTIONAL KEYWORDS:
;   bin        - If set, then plot an evenly-spaced subsample of BIN points,
;                or 100 points if BIN=1
;
; OUTPUTS:
;
; COMMENTS:
;   Pass COLOR, PSYM, and SYMSIZE to djs_oplot.
;
; PROCEDURES CALLED:
;   djs_oplot
;   TeXtoIDL()
;
; REVISION HISTORY:
;   Written by D. Schlegel, 27 September 1997, Durham
;   bin keyword added, 26 March 2008 - D. Finkbeiner
;-
;-----------------------------------------------------------------------
pro djs_plot, x, y, xtitle=xtitle, ytitle=ytitle, title=title, $
 color=color, psym=psym, symsize=symsize, nodata=nodata, $
 bin=bin, _EXTRA=KeywordsForPlot

   ; If X values don't exist, then create them as PLOT or OPLOT would do
   npt = N_elements(x)
   if (n_elements(y) GT 0) then begin
      xtmp = x
      ytmp = y
   endif else begin
      xtmp = lindgen(npt)
      ytmp = x
   endelse

   if (keyword_set(xtitle)) then xtitle_tex = TeXtoIDL(xtitle)
   if (keyword_set(ytitle)) then ytitle_tex = TeXtoIDL(ytitle)
   if (keyword_set(title)) then title_tex = TeXtoIDL(title)

;   plot, xtmp, ytmp, xtitle=xtitle_tex, ytitle=ytitle_tex, $
;    title=title_tex, _EXTRA=KeywordsForPlot
   plot, xtmp, ytmp, xtitle=xtitle_tex, ytitle=ytitle_tex, $
    title=title_tex, _EXTRA=KeywordsForPlot, /nodata

   if (NOT keyword_set(nodata)) then $
    djs_oplot, xtmp, ytmp, color=color,psym=psym, symsize=symsize, $
     bin=bin, _EXTRA=KeywordsForPlot

   return
end 
;-----------------------------------------------------------------------
