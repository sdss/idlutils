;-----------------------------------------------------------------------
;+
; NAME:
;   djs_icolor
;
; PURPOSE:
;   Internal routine for converting a color name to an index.
;
; CALLING SEQUENCE:
;   icolor = djs_icolor(color)
;
; INPUT:
;   color:
;
; OUTPUTS:
;   icolor
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   Written by D. Schlegel, 27 September 1997, Durham
;-
;-----------------------------------------------------------------------
function djs_icolor, color

   if (NOT keyword_set(color)) then color = !p.color

   ncolor = N_elements(color)

   ; If COLOR is a string or array of strings, then convert color names
   ; to integer values
   if (size(color,/tname) EQ 'STRING') then begin ; Test if COLOR is a string

      ; Detemine the default color for the current device
      if (!d.name EQ 'X') then defcolor = 7 $ ; white for X-windows
       else defcolor = 0 ; black otherwise

      ; Load a simple color table with the basic 8 colors
      red   = [0, 1, 0, 0, 0, 1, 1, 1]
      green = [0, 0, 1, 0, 1, 0, 1, 1]
      blue  = [0, 0, 0, 1, 1, 1, 0, 1]
      tvlct, 255*red, 255*green, 255*blue
      icolor = 0 * (color EQ 'black') $
             + 1 * (color EQ 'red') $
             + 2 * (color EQ 'green') $
             + 3 * (color EQ 'blue') $
             + 4 * (color EQ 'cyan') $
             + 5 * (color EQ 'magenta') $
             + 6 * (color EQ 'yellow') $
             + 7 * (color EQ 'white') $
             + defcolor * (color EQ 'default')

   endif else begin
      icolor = color
   endelse

   return, icolor
end 
;-----------------------------------------------------------------------
