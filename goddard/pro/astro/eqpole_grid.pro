;+
; NAME:
;	EQPOLE_GRID
;
; PURPOSE:
;	Produce an overlay of latitude and longitude lines over a plot or image
; EXPLANATION:
;	Grid is written on the current graphics device using the equal area 
;	polar projection.   EQPOLE_GRID assumes that the output plot 
;	coordinates span the x and y ranges of -90 to 90 for a region that 
;	covers the equator to the chosen pole. The grid is assumed to go from 
;	the equator to the chosen pole.
;
; CALLING SEQUENCE:
;
;	EQPOLE_GRID[,DLONG,DLAT,[/SOUTHPOLE,LINESTYLE=N,/LABEL]
;
; INPUTS:
;
;	DLONG	= Optional input longitude line spacing in degrees. If left
;		  out, defaults to 30.
;       DLAT    = Optional input lattitude line spacing in degrees. If left
;                 out, defaults to 30.
;
; KEYWORDS:
;
;	SOUTHPOLE	= Optional flag indicating that the output plot is
;			  to be centered on the south rather than the north
;			  pole.
;	LINESTYLE	= Optional input integer specifying the linestyle to
;			  use for drawing the grid lines.
;	LABELS		= Optional flag for creating labels on the output
;			  grid on the prime meridian and the equator for
;			  lattitude and longitude lines. If set =2, then
;			  the longitude lines are labeled in hours and minutes.
;
; OUTPUTS:
;	Draws grid lines on current graphics device.
;
; CATAGORY:
;	SST-9 Graphics routine.
;
;
; COPYRIGHT NOTICE:
;
;	Copyright 1992, The Regents of the University of California. This
;	software was produced under U.S. Government contract (W-7405-ENG-36)
;	by Los Alamos National Laboratory, which is operated by the
;	University of California for the U.S. Department of Energy.
;	The U.S. Government is licensed to use, reproduce, and distribute
;	this software. Neither the Government nor the University makes
;	any warranty, express or implied, or assumes any liability or
;	responsibility for the use of this software.
;
;
;
; AUTHOR AND MODIFICATIONS:
;
;	J. Bloch	1.4	10/28/92
;
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
PRO EQPOLE_GRID,DLONG,DLAT,LINESTYLE=N,LABELS=LABEL,SOUTHPOLE=SOUTHPOLE

	if not keyword_set(n) then n=0
	if n_params() lt 2 then dlong = 30.0
	if n_params() lt 1 then dlat = 30.0
;
;	Do lines of constant longitude
;
	lat=90.0-findgen(180)
	if keyword_set(southpole) then lat = -lat
	lng=fltarr(180)
	lngtot = long(360.0/dlong)
	for i=0,lngtot do begin
		lng[*]=-180.0+(i*dlong)
		eqpole,lng,lat,x,y,southpole=southpole
		oplot,x,y,linestyle=n
	endfor
;
;	Do lines of constant latitude
;
	lng=findgen(360)
	lat=fltarr(360)
	lattot=long(180.0/dlat)
	for i=1,lattot do begin
		if not keyword_set(southpole) then lat[*]=90.0-(i*dlat) $
			else lat[*]=-90.0+(i*dlat)
		eqpole,lng,lat,x,y,southpole=southpole
		oplot,x,y,linestyle=n
	endfor
;
;	Do labeling if requested
;
	if keyword_set(label) then begin
;
;	Label equator
;
	    for i=0,lngtot-1 do begin
		lng = (i*dlong)
		eqpole,lng,0.0,x,y,southpole=southpole
		if label eq 1 then xyouts,x[0],y[0],noclip=0,$
			strcompress(string(lng,format="(I4)"),/remove_all) $
		else begin
		        tmp=sixty(lng*24.0/360.0)
		        xyouts,x[0],y[0],noclip=0,$
			    strcompress(string(tmp[0],tmp[1],$
			    format='(I2,"h",I2,"m")'),/remove_all),alignment=0.5
		endelse
	    endfor
;
;	Label prime meridian
;
	    for i=1,lattot-1 do begin
		if not keyword_set(southpole) then $
			lat=90-(i*dlat) else lat=-90+(i*dlat)
		eqpole,0.0,lat,x,y,southpole=southpole
		xyouts,x[0],y[0],noclip=0,$
			strcompress(string(lat,format="(I4)"),/remove_all)
	    endfor
	endif
	return
end

