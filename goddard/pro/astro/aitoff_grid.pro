;+
; NAME:
;       AITOFF_GRID
;
; PURPOSE:
;       Produce an overlay of latitude and longitude lines over a plot or image
; EXPLANATION:
;       The grid is plotted on the current graphics device. AITOFF_GRID 
;       assumes that the ouput plot coordinates span the x-range of 
;       -180 to 180 and the y-range goes from -90 to 90.
;
; CALLING SEQUENCE:
;
;       AITOFF_GRID [,DLONG,DLAT, LABEL =, /NEW, CHARTHICK=, CHARSIZE=, _EXTRA=]
;
; OPTIONAL INPUTS:
;
;       DLONG   = Optional input longitude line spacing in degrees. If left
;                 out, defaults to 30.
;       DLAT    = Optional input lattitude line spacing in degrees. If left
;                 out, defaults to 30.
;
; OPTIONAL INPUT KEYWORDS:
;
;       LABEL           = Optional keyword specifying that the lattitude and
;                         longitude lines on the prime meridian and the
;                         equator should be labeled in degrees. If LABELS is
;                         given a value of 2, i.e. LABELS=2, then the longitude
;                         labels will be in hours and minutes instead of
;                         degrees.
;        CHARSIZE       = If /LABEL is set, then CHARSIZE specifies the size
;                         of the label characters (passed to XYOUTS)
;        CHARTHICK     =  If /LABEL is set, then CHARTHICK specifies the 
;                         thickness of the label characters (passed to XYOUTS)
;       /NEW          =   If this keyword is set, then AITOFF_GRID will create
;                         a new plot grid, rather than overlay an existing plot.
;
;       Any valid keyword to OPLOT such as COLOR, LINESTYLE, THICK can be 
;       passed to AITOFF_GRID (though the _EXTRA facility) to to specify the
;       color, style, or thickness of the grid lines.
; OUTPUTS:
;       Draws grid lines on current graphics device.
;
; EXAMPLE:
;       Create a labeled Aitoff grid of the Galaxy, and overlay stars at 
;       specified Galactic longitudes, glong and latitudes, glat
;
;       IDL> aitoff_grid,/label,/new        ;Create labeled grid
;       IDL> aitoff, glong, glat, x,y      ;Convert to X,Y coordinates
;       IDL> plots,x,y,psym=2              ;Overlay "star" positions
;
; AUTHOR AND MODIFICATIONS:
;
;       J. Bloch        1.2     6/2/91
;       Converted to IDL V5.0   W. Landsman   September 1997
;       Create default plotting coords, if needed   W. Landsman  August 2000
;       Added _EXTRA, CHARTHICK, CHARSIZE keywords  W. Landsman  March 2001
;-
PRO AITOFF_GRID,DLONG,DLAT,LABEL=LABEL, NEW = new, _EXTRA= E, $
     CHARSIZE = charsize, CHARTHICK =charthick

         if n_params() lt 2 then dlong = 30.0
        if n_params() lt 1 then dlat = 30.0

; If no plotting axis has been defined, then create a default one

        new = keyword_set(new)
        if not new then new =  (!X.crange[0] EQ 0) and (!X.crange[1] EQ 0)
        if new then plot,[-180,180],[-90,90],/nodata,xsty=5,ysty=5
;
;       Do lines of constant longitude
;
        lat=findgen(180)-90
        lng=fltarr(180)
        lngtot = long(360.0/dlong)
        for i=0,lngtot do begin
                lng[*]=-180.0+(i*dlong)
                aitoff,lng,lat,x,y
                oplot,x,y,_extra=e
        endfor
;
;       Do lines of constant latitude
;
        lng=findgen(360)-180.0
        lat=fltarr(360)
        lattot=long(180.0/dlat)
        for i=1,lattot do begin
                lat[*]=-90+(i*dlat)
                aitoff,lng,lat,x,y
                oplot,x,y,_extra=e
        endfor
;
;       Do labeling if requested
;
        if keyword_set(label) then begin
;
;       Label equator
;
            for i=0,lngtot-1 do begin
                lng = (i*dlong)
                if (lng ne 0.0) and (lng ne 180.0) then begin
                    aitoff,lng,0.0,x,y
                    if label eq 1 then xyouts,x[0],y[0],$
                        strcompress(string(lng,format="(I4)"),/remove_all), $
                        charsize = charsize, charthick = charthick $
                    else begin
                        tmp=sixty(lng*24.0/360.0)
                        xyouts,x[0],y[0],$
                            strcompress(string(tmp[0],tmp[1],$
                            format='(I2,"h",I2,"m")'),/remove_all), $
                       alignment=0.5, charsize = charsize, charthick = charthick
                    endelse
                endif
            endfor
;
;       Label prime meridian
;
            for i=1,lattot-1 do begin
                lat=-90+(i*dlat)
                aitoff,0.0,lat,x,y
                xyouts,x[0],y[0],$
                        strcompress(string(lat,format="(I4)"),/remove_all), $
                        charsize = charsize, charthick = charthick
            endfor
        endif

        return
end
