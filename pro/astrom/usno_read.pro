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

