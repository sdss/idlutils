
;+
; NAME:
;   djs_maskinterp
;
; PURPOSE:
;   Interpolate over masked pixels in a vector.
;
; CALLING SEQUENCE:
;   ynew = djs_maskinterp( yval, mask, [ xval ] )
;
; INPUTS:
;   yval       - Y values
;   mask       - Mask values correspoding to YVAL; interpolate over all pixels
;                where MASK is not 0
;
; OPTIONAL INPUTS:
;   xval       - X values corresponding to YVAL
;
; OUTPUTS:
;   ynew       - Y values after linearly interpolating over masked pixels
;
; COMMENTS:
;
; EXAMPLES:
;
; BUGS:
;   At present, this routine only supports 1-D arrays.
;   No tests are done that the arrays are 1-D, or that their dimensions agree.
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   27-Jan-2000  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------

function djs_maskinterp, yval, mask, xval

;   ndim = size(yval, /n_dimens)

   ibad = where(mask NE 0, nbad)
   if (nbad EQ 0) then $
      return, yval

   igood = where(mask EQ 0, ngood)
   if (ngood EQ 0) then $
      return, yval

   ynew = yval
   if (keyword_set(xval)) then $
    ynew[ibad] = interpol(yval[igood], xval[igood], xval[ibad]) $
   else $
    ynew[ibad] = interpol(yval[igood], igood, ibad)

   return, ynew
end
;------------------------------------------------------------------------------
