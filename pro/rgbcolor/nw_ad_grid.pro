;+
;NAME:
;  nw_ad_grid
;PURPOSE:
;  Creates AD coordinate grid
;CALLING SEQUENCE:
;  nw_ad_grid,rain,decin,hdr,[dra=,ddec=,name=,linethick=,color=,/nolabels]
;INPUTS:
;  rain,decin  - coordinates on which the grid will be centered
;  hdr         - header of the FITS image to be overlayed
;  
;OPTIONAL INPUTS:
;  dra,ddec    - spacing of grid lines
;  linethick   - thickness of line in unrebinned pixels -- assuming the PS file
;                has xsize=7.5in!
;  color       - 
;OPTIONAL KEYWORDS:
;  nolabels    - don't label grid lines
;OPTIONAL OUTPUTS:
;  
;EXAMPLE:
;  
;OUTPUTS:
;  PS file
;DEPENDENCIES:
;  
;BUGS:
;  Requires PS file to have xsize=7.5in
;
;REVISION HISTORY:
;  7/8/04 written - wherry
;-
PRO nw_ad_grid,rain,decin,hdr,dra=dra,ddec=ddec,nra=nra,ndec=ndec, $
               linethick=linethick,color=color,nolabels=nolabels, $
               charsize=charsize

NX = sxpar(hdr,'NAXIS1')
NY = sxpar(hdr,'NAXIS2')

IF (NOT keyword_set(dra)) THEN dra=.1
IF (NOT keyword_set(ddec)) THEN ddec=.1

IF (NOT keyword_set(linethick)) THEN linethick=2
lthick= 2000.*linethick/NX ; empirical HACK

IF (NOT keyword_set(charthick)) THEN charthick=lthick*2.0
IF (NOT keyword_set(charsize)) THEN charsize=lthick/2.0

IF (NOT keyword_set(nra)) THEN nra=10
IF (NOT keyword_set(ndec)) THEN ndec=10
IF (NOT keyword_set(npoints)) THEN npoints=long(nra+ndec+1)*100L

racen = dra*round(rain/dra)
deccen = ddec*round(decin/ddec)

ra_val = dblarr(2*npoints+1)+racen[0]
dec_line= deccen+ndec*ddec*(dindgen(2*npoints+1)-npoints)/double(npoints)

temp=0
FOR i=-nra,nra DO BEGIN
    adxy,hdr,ra_val+dra*i,dec_line,x_dec_line,y_dec_line
    valid = where(x_dec_line ge 0 and x_dec_line le NX and $
                  y_dec_line ge 0 and y_dec_line le NY)
    IF (valid[0] ne -1) THEN BEGIN
        oplot,x_dec_line,y_dec_line,thick=lthick,color=color
        IF (NOT keyword_set(nolabels)) THEN BEGIN
            in_pts = reverse(where(y_dec_line lt NY))
            dx = x_dec_line[in_pts[0]]-x_dec_line[in_pts[1]]
            dy = y_dec_line[in_pts[0]]-y_dec_line[in_pts[1]]
            angle = atan(dy,dx)*180D0/!DPI
            xyouts,x_dec_line[in_pts[0]],y_dec_line[in_pts[1]],'RA = '+$
              strcompress(string(racen+dra*i,format='(F7.2)'),/remove_all)+$
              ' deg',alignment=1,charthick=charthick,charsize=charsize,$
              orientation=angle,color=color
        ENDIF
    ENDIF
ENDFOR

nlines=temp
dec_val = dblarr(2*npoints+1)+deccen[0]
ra_line= racen+nra*dra*(dindgen(2*npoints+1)-npoints)/double(npoints)

FOR j=-ndec,ndec DO BEGIN
    adxy,hdr,ra_line,dec_val+ddec*j,x_ra_line,y_ra_line
    valid = where(y_ra_line ge 0 and y_ra_line le NY and $
                  x_ra_line ge 0 and x_ra_line le NX)
    IF (valid[0] ne -1) THEN BEGIN
        oplot,x_ra_line,y_ra_line,thick=lthick,color=color
        IF (NOT keyword_set(nolabels)) THEN BEGIN
            in_pts = where(x_ra_line lt NX)
            dx = x_ra_line[in_pts[0]]-x_ra_line[in_pts[1]]
            dy = y_ra_line[in_pts[0]]-y_ra_line[in_pts[1]]
            angle = atan(dy,dx)*180D0/!DPI
            xyouts,x_ra_line[in_pts[0]],y_ra_line[in_pts[0]],'Dec = '+$
              strcompress(string(deccen+ddec*j,format='(F7.2)'),/remove_all)+$
              ' deg',alignment=1,charthick=charthick,charsize=charsize,$
              orientation=angle,color=color
        ENDIF
    ENDIF
ENDFOR

END
