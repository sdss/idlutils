function create_usnostruct, n

;   ftemp = create_struct( name='USNO_STRUCT', $
   ftemp = create_struct( $
    'RA', 0.0D, $
    'DEC', 0.0D, $
    'RMAG', 0.0, $
    'BMAG', 0.0, $
    'X', 0.0, $
    'Y', 0.0 )

   usnostruct = replicate(ftemp, n)

   return, usnostruct
end

;+
;+------------------------------------------------------------------------  
; NAME:
;       usno_readzone
;+------------------------------------------------------------------------  
; PURPOSE:
;       Read given RA range out of one deczone. 
;+------------------------------------------------------------------------  
; INPUTS:
;   catpath   - path to catalogue files (.cat and .acc)
;   zone      - zone number (float, 1/10 degrees)
;   ra0,ra1   - ra limits (deg)
;+------------------------------------------------------------------------  
; OUTPUTS:
;   data      - float(3,N) array of results.  
;                 data[0,*] = RA (in .01 arcsec)
;                 data[1,*] = (dec+90) (in .01 arcsec)
;                 data[2,*] = magnitudes packed in 32-bit int (see below)
;+------------------------------------------------------------------------  
; COMMENTS:
;   uses point_lun to skip to requested part of file.  Very fast. 
;
;   Requests are padded by 1/10 the interpolation grid spacing.  This
;     padding is trimmed unless that would yield a null result. 
;
;   Warning - this routine interpolates file index positions
;             and works only if the star distribution is approximately
;             uniform (which it is).  
;+------------------------------------------------------------------------  
;-
PRO usno_readzone, catpath, zone, ra0, ra1, result

; error trapping
  IF (ra0 LT 0.0) OR (ra0 GT 360.0) OR (ra1 LT 0.0) OR (ra1 GT 360.0) THEN $
    message, 'RA out of range'

  IF (ra0 GE ra1) THEN message, 'ra0 >= ra1'

; pad RA range
  pad = 3.75/10. ; one tenth the index interpolation grid spacing
  raread = [ra0-pad, ra1+pad]
  raread = ((raread) < 360.0) > 0.0

; read .acc file (1-indexed)
  zstr = 'zone'+string(zone, format='(I4.4)')

; --- use something faster than readcol in next version!
;  readcol, catpath+zstr+'.acc', ra_acc, ind, n, /silent

  accfile = djs_filepath(zstr+'.acc', root_dir=catpath)
  catfile = djs_filepath(zstr+'.cat', root_dir=catpath)
  flist = findfile(accfile, count=ct)
  IF ct NE 1 THEN message, 'cannot find file ' + accfile
  grid = dblarr(3, 96)
  openr, rlun, accfile, /get_lun, /swap_if_little_endian
  readf, rlun, grid
  free_lun, rlun
  ra_acc = reform(grid[0, *])
  ind    = reform(grid[1, *])
  n      = reform(grid[2, *])
  ntag = n_elements(ra_acc)

; pad arrays
  ra = [ra_acc, 24.] *15. ; convert to degrees
  indmax = ind[ntag-1]+n[ntag-1]-1
  ind = [ind, indmax ]

; get (zero-indexed) offsets in .cat file
  indrange = long(interpol(ind, ra, raread))-1L
  ind0 = indrange[0]
  ind1 = indrange[1]

; read .cat file
  openr, readlun, catfile, /get_lun, /swap_if_little_endian
  nstars = (ind1-ind0)+1
  data = lonarr(3, nstars)
  point_lun, readlun, ind0*12L
  readu, readlun, data
  free_lun, readlun

; trim unwanted RA stars
  racat  = transpose(data[0, *]) /3.6d5
  good = where((racat LE ra1) AND (racat GE ra0), ct)
  IF ct GT 0 THEN BEGIN 
     result = data[*, good]
  ENDIF ELSE BEGIN 
     result = data  ; keep padding
  ENDELSE 

  return
end

;+
;+------------------------------------------------------------------------  
; NAME:
;       usno_cone
;+------------------------------------------------------------------------  
; PURPOSE:
;       Determine RA,dec regions to read and call usno_readzone
;+------------------------------------------------------------------------  
; INPUTS:
;   racen     - RA of region center (J2000)    (degrees)
;   deccen    - dec of region center (J2000)   (degrees)
;   rad       - radius of region               (degrees)
;+------------------------------------------------------------------------  
; OUTPUTS:
;   data      - float(3,N) array of results.  
;                 data[0,*] = RA (in .01 arcsec)
;                 data[1,*] = (dec+90) (in .01 arcsec)
;                 data[2,*] = magnitudes packed in 32-bit int (see below)
;+------------------------------------------------------------------------  
; COMMENTS:    
;   calls usno_readzone
;+------------------------------------------------------------------------  
; REVISION HISTORY
;   Written  2000 Apr 15 by D. P. Finkbeiner
;
;+------------------------------------------------------------------------  
;-
PRO usno_cone, catpath, racen, deccen, rad, result

; declination range
  dec0 = (deccen-rad) > (-90.0)
  dec1 = (deccen+rad) < (+90.0)

; RA range (overly conservative)
  maxdec = abs(dec0) > abs(dec1)
  cosd = cos(maxdec/!radeg)
  IF cosd GT rad/180. THEN BEGIN 
     ra0 = ((racen-rad/cosd) + 360) MOD 360
     ra1 = ((racen+rad/cosd) + 360) MOD 360
  ENDIF ELSE BEGIN 
     ra0 = 0.
     ra1 = 360.
  ENDELSE
     
; dec zone numbers
  z0 = floor((90+dec0)/7.5) < 23
  z1 = floor((90+dec1)/7.5) < 23

; loop over zones
  FOR z=z0, z1 DO BEGIN 

     zone = z*75
     IF (ra0 LT ra1) THEN BEGIN 
        usno_readzone, catpath, zone, ra0, ra1, zdata
     ENDIF ELSE BEGIN 
        usno_readzone, catpath, zone, ra0, 360.0, zdata1
        usno_readzone, catpath, zone, 0, ra1, zdata2
        zdata = [[zdata1], [zdata2]]
     ENDELSE 
     
     IF n_elements(data) EQ 0 THEN $
       data=zdata $
     ELSE $
       data=[[data], [zdata]]

  ENDFOR 

; strip extra dec
  deccat = transpose(data[1, *]) /3.6d5 - 90.
  good = where((deccat GE dec0) AND (deccat LE dec1), ct)

  IF ct GT 0 THEN BEGIN 
     dtrim = data[*, good]
  ENDIF ELSE BEGIN 
     dtrim = data  ; keep padding
  ENDELSE 
  
; Now use dot products to strip extras
  racat  = transpose(dtrim[0, *]) /3.6d5
  deccat = transpose(dtrim[1, *]) /3.6d5 - 90.
  uvobj = ll2uv(double([[racat], [deccat]])) ; (n,3) array
  uvcen = ll2uv(double([[racen], [deccen]])) ; (1,3) array
  dot   = uvobj#transpose(uvcen)
  good = where(dot GE cos(rad*!dpi/180.d), ct)

  IF ct GT 0 THEN BEGIN 
     result = dtrim[*, good]
  ENDIF ELSE BEGIN 
     result = dtrim  ; keep padding
  ENDELSE 

  return
end

;+
;+------------------------------------------------------------------------  
; NAME:
;       usno_read
;+------------------------------------------------------------------------  
; PURPOSE:
;       Read star list from the USNO-A2.0 catalogue
;+------------------------------------------------------------------------  
; INPUTS:
;   racen     - RA of region center (J2000)    (degrees) (may be array)
;   deccen    - dec of region center (J2000)   (degrees) (may be array)
;   rad       - radius of region               (degrees) (may be array)
;+------------------------------------------------------------------------  
; OUTPUTS:
;   racat,    - (RA,dec) of stars in region (J2000)  (degrees)
;     deccat 
;   magb      - B magnitude of stars
;   magr      - R magnitude
;+------------------------------------------------------------------------  
; COMMENTS:    
;   Reads US Naval Observatory catalogue v. A2.0 (50,000,000 stars)
;     and returns all stars within radius "rad" of (racen,deccen)
;
;   Coords returned are RA,dec J2000 at the epoch of the plates.
;   Beware of high proper motion stars.  Typical astrometric error is
;   0.25", but can be much worse.  Local errors should be about .15"
; 
;   For information on the USNO-A2.0 see http://www.usno.navy.mil
;+------------------------------------------------------------------------  
; REVISION HISTORY
;   Loosely based on starlist.pro by Doug Finkbeiner and John
;   Moustakas, 1999 mar 26
;
;   Written  2000 Apr 15 by D. P. Finkbeiner
;   Modified 2000 Apr 18 to use dot product in final trim (DPF)
;   Modified 2001 Jul 17 R & B mags were reversed !  (DPF)
;
;+------------------------------------------------------------------------  
;-
function usno_read, racen, deccen, rad, path=path

; set path
  IF (NOT keyword_set(path)) THEN path = '/u/schlegel/mt/cdrom'

; Read the stars - loop over pointings
  nstar = n_elements(racen)
  FOR i=0, nstar-1 DO BEGIN 
     radi = i < (n_elements(rad)-1) ; don't require that rad be array
     usno_cone, path, racen[i], deccen[i], rad[radi], zdata
;    append to list
     IF n_elements(data) EQ 0 THEN $
       data=zdata $
     ELSE $
       data=[[data], [zdata]]
  ENDFOR 

  if n_elements(data) EQ 0 then print, 'NO Data - try a bigger radius.'
  if n_elements(data) EQ 3 then ntot = 1 else $
    ntot = (size(data,/dimens))[1]
  if (ntot EQ 0) then return, 0
  usnostruct = create_usnostruct(ntot)

; unpack data array
  usnostruct.ra  = transpose(data[0, *]) /3.6d5
  usnostruct.dec = transpose(data[1, *]) /3.6d5 - 90.
  info   = transpose(data[2, *])

; unpack B and R magnitudes from info array
  magrint = (info MOD 1000L)
  magbint = (info MOD 1000000L) - magrint
  usnostruct.bmag = magbint/10000.
  usnostruct.rmag = magrint/10.

  return, usnostruct
end

