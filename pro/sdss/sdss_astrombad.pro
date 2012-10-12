;+
; NAME:
;   sdss_astrombad
; PURPOSE:
;   For a list of RUN, CAMCOL, FIELD, return whether each field has bad astrometry
; CALLING SEQUENCE:
;   bad= sdss_astrombad(run, camcol, field)
; INPUTS:
;   run, camcol, field - [N] field identifiers
;   rerun - which rerun 
; OUTPUTS:
;   bad - 0 for good, 1 for bad
; COMMENTS:
;   Reads data from:
;    $BOSS_PHOTOOBJ/astromqa/astromQAFields.fits
; REVISION HISTORY:
;   10-Oct-2012  morphed by M. Blanton, NYU
;------------------------------------------------------------------------------
function sdss_astrombad, run, camcol, field

common com_astrombad, qafields

if(n_elements(run) eq 0) then $
   message, 'RUN, CAMCOL, FIELD need at least one element'
if(n_elements(run) ne n_elements(camcol) OR $
   n_elements(camcol) ne n_elements(field)) then $
   message, 'RUN, CAMCOL, FIELD need the same number of elements'
if(~keyword_set(getenv('BOSS_PHOTOOBJ'))) then $
   message, 'Environmental variable BOSS_PHOTOOBJ must be set'

if(n_tags(qafields) eq 0) then begin
   qafieldsfile= getenv('BOSS_PHOTOOBJ')+'/astromqa/astromQAFields.fits'
   if(~file_test(qafieldsfile)) then $
      message, 'File required: '+qafieldsfile
   qafields= hogg_mrdfits(qafieldsfile, 1, $
                          columns=['run', 'camcol', 'field', 'astrombad'], $
                          nrow=28800)
endif

rcf= run*20000L+camcol*2000L+field
isort= sort(rcf)
iuniq= uniq(rcf[isort])

arcf= qafields.run*20000L+qafields.camcol*2000L+qafields.field

match, rcf[isort[iuniq]], arcf, ircf, iarcf, /sort, count=count

if(n_elements(iuniq) ne count) then $
   message, 'Not all run/camcol/fields matched in astrombad'

bad= bytarr(n_elements(run))
bad[isort[iuniq[ircf]]]= qafields[iarcf].astrombad

istart=0L
for i=0L, n_elements(iuniq)-1L do begin
   iend= iuniq[i]
   icurr= isort[istart:iend]
   ilast= isort[iend]
   bad[icurr]= bad[ilast]
   istart=iend+1L
endfor

return, bad

end
;------------------------------------------------------------------------------
