;+
; NAME:
;   hogg_plot_defaults
; PURPOSE:
;   Set plotting defaults for all "hogg_" plots
; CALLING SEQUENCE:
;   hogg_plot_defaults
; REVISION HISTORY:
;   2003-01-08  written - Hogg
;-
pro hogg_plot_defaults
!P.FONT= -1
!P.BACKGROUND= djs_icolor('white')
!P.COLOR= djs_icolor('black')
!P.THICK= 2.0
!P.CHARTHICK= !P.THICK
!P.CHARSIZE= 1.0
!P.PSYM= 0
!P.LINESTYLE= 0
!P.TITLE= ''
!X.STYLE= 1
!X.THICK= 0.5*!P.THICK
!X.CHARSIZE= 1.0
!X.MARGIN= [1,1]*0.0
!X.OMARGIN= [6,6]*axis_char_scale-!X.MARGIN
!X.RANGE= 0
!X.TICKS= 0
!Y.STYLE= 1
!Y.THICK= !X.THICK
!Y.CHARSIZE= !X.CHARSIZE
!Y.MARGIN= 0.6*!X.MARGIN
!Y.OMARGIN= 0.6*!X.OMARGIN
!Y.RANGE= 0
!Y.TICKS= !X.TICKS
end
