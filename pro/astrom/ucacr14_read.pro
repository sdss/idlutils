;+
; NAME:
;   ucacr14_read
; PURPOSE:
;   Read in a region of UCAC r14 data 
; CALLING SEQUENCE:
;   ucac= ucacr14_read(ra, dec, radius)
; INPUTS:
;   ra, dec - central location (J2000 deg)
;   radius - search radius (deg)
; COMMENTS:
;   UCAC r14 is the internal USNO catalog for Dec>+38 deg 
;   used by the SDSS DR7.2 for astrometric calibration
; REVISION HISTORY:
;   12-Jan-2010 MRB, NYU
;-
;------------------------------------------------------------------------------
function ucacr14_read, ra, dec, radius

common com_ucacr14_read, indx

if(NOT keyword_set('UCACR14_DIR')) then $
  message, 'UCACR14_DIR must be set'

;; assume minimum field size sqrt(0.5) deg radius
fradius= sqrt(0.5)
fudge=0.02

if(n_elements(ra) gt 1 OR $
   n_elements(dec) gt 1 OR $
   n_elements(radius) gt 1) then begin
    message, 'RA, DEC, and RADIUS must be single element in UKIDSS_READ()'
endif

fitsdir= 'fits'
filebase= 'ucacr14'

if(n_tags(ucacr14_indx) eq 0) then begin
    indx= mrdfits(getenv('UCACR14_DIR')+'/'+fitsdir+'/'+filebase+'-indx.fits', $
                  1, /silent)
    if(n_tags(indx) eq 0) then $
      message, 'Must run UCACR14_EXTRACT!'
endif

;; find matching fields
spherematch, ra, dec, indx.ra, indx.dec, radius+fradius+fudge, $
  m1, m2, max=0
if(m2[0] eq -1) then return, 0
nread= n_elements(m2)
iread=m2

;; now read in each and find any things to match 
obj=0
for i=0L, nread-1L do begin
    tmp_obj= mrdfits(getenv('UCACR14_DIR')+'/'+ $
                     indx[iread[i]].datafile,1, /silent)
    spherematch, ra, dec, tmp_obj.ra, tmp_obj.dec, radius, m1, m2, max=0
    if(m2[0] ne -1) then begin
        if(n_tags(obj) eq 0) then $
          obj= tmp_obj[m2] $
        else $
          obj= [obj, tmp_obj[m2]]
    endif
endfor

return, obj

end
;------------------------------------------------------------------------------
