;+
; NAME:
;   ucac_readzone()
;
; PURPOSE:
;   Read the raw UCAC data files for a specific declination zone within
;   a given RA range.
;
; CALLING SEQUENCE:
;   outdat = ucac_readzone(zone, ra_min, ra_max)
;
; INPUTS:
;   zone       - UCAC zone number (corresponding to a particular declination)
;   ra_min     - Minimum RA
;   ra_max     - Maximum RA
;
; OPTIONAL INPUTS:
;
; OUTPUT:
;   outdat     - Structure with UCAC data in its raw catalog format;
;                return 0 if no stars found
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;   readfmt
;
; REVISION HISTORY:
;   27-May-2003  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------
function ucac_readzone, thiszone, ra_min, ra_max

   common com_ucac, uindex

   ;----------
   ; Check inputs

   if (n_params() LT 3) then begin
      print, 'Wrong number of parameters!'
      return, 0
   endif
   if (ra_min GT ra_max OR ra_min LT 0 OR ra_min GT 360 $
    OR ra_max LT 0 OR ra_max GT 360) then begin
      print, 'Invalid RA_MIN,RA_MAX'
      return, 0
   endif

   ucac_dir = getenv('UCAC_DIR')
   if (NOT keyword_set(ucac_dir)) then begin
      print, 'Environment variable UCAC_DIR must be set!'
      return, 0
   endif

   ;----------
   ; Read the index file (if not already read and cached in memory)

   if (NOT keyword_set(uindex)) then begin
; Should we read the binary version of this file instead of ASCII ???
      indexfile = filepath('u2index.txt', root_dir=ucac_dir, subdir='info')
      readfmt, indexfile, 'I6,I8,I9,I4,I4,F6.1,F5.1', $
       nsbin, naz, nat, zn, jj, dcmax, ramax, skipline=10
      uindex = replicate( create_struct( $
       'NSBIN', 0L, $
       'NAZ'  , 0L, $
       'NAT'  , 0L, $
       'ZN'   , 0L, $
       'JJ'   , 0L, $
       'DCMAX', 0d, $
       'RAMAX', 0d ), n_elements(nsbin))
      uindex.nsbin = nsbin
      uindex.naz = naz
      uindex.nat = nat
      uindex.zn = zn
      uindex.jj = jj
      uindex.dcmax = dcmax
      uindex.ramax = ramax
   endif

   ;----------
   ; Determine where to seek in this zone file.

   jj = where(uindex.zn EQ thiszone, ct)
   if (ct EQ 0) then begin
      print, 'This zone not found'
      return, 0
   endif

   j1 = (where(uindex[jj].ramax * 15.d GE ra_min))[0]
   j1 = j1 > 0L
   j2 = (reverse(where(uindex[jj].ramax * 15.d LE ra_max)))[0] + 1L
   j2 = j2 < n_elements(jj) - 1L ; In the case that RA_MAX=360 deg

   if (j1 EQ 0) then i1 = 0L $
    else i1 = uindex[jj[j1-1]].naz
   i2 = uindex[jj[j2]].naz - 1L
   nrecord = i2 - i1 + 1L

   ;----------
   ; Read the binary format data

   thisfile = filepath(string(thiszone,format='("z",i3.3)'), $
    root_dir=ucac_dir, subdir='u2')

   blankdat = create_struct( $
    'RA'    , 0L, $
    'DEC'   , 0L, $
    'RMAG'  , 0 , $
    'E_RAM' , 0B, $
    'E_DEM' , 0B, $
    'NOBS'  , 0B, $
    'RFLAG' , 0B, $
    'NCAT'  , 0B, $
    'CFLAG' , 0B, $
    'EPRAM' , 0 , $
    'EPDEM' , 0 , $
    'PMRA'  , 0L, $
    'PMDE'  , 0L, $
    'E_PMRA', 0B, $
    'E_PMDE', 0B, $
    'Q_PMRA', 0B, $
    'Q_PMDE', 0B, $
    'TM_ID' , 0L, $
    'TM_J'  , 0 , $
    'TM_H'  , 0 , $
    'TM_KS' , 0 , $
    'TM_PH' , 0B, $
    'TM_CC' , 0B)
   outdat = replicate(blankdat, nrecord)
   openr, ilun, thisfile, /get_lun, /swap_if_big_endian
   point_lun, ilun, i1 * n_tags(blankdat, /length)
   readu, ilun, outdat
   close, ilun
   free_lun, ilun

   ;----------
   ; Trim to the RA range requested

   ikeep = where(outdat.ra GE ra_min*3600.d0*1000.d0 $
    AND outdat.ra LE ra_max*3600.d0*1000.d0, nkeep)
   if (nkeep EQ 0) then begin
      return, 0
   endif
   outdat = outdat[ikeep]

   return, outdat
end
;------------------------------------------------------------------------------
