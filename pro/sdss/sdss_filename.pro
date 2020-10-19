;+
; NAME:
;   sdss_filename
; PURPOSE:
;   Return an SDSS file name given its type and identifiers
; CALLING SEQUENCE:
;   filename= sdss_filename(filetype [, keywords])
; INPUTS:
;   filetype - name of file type
;   keywords - named keywords with values necessary to define 
;              file location on disk
; COMMENTS:
;   Calls construct_filename()
; REVISION HISTORY:
;   2015-06-02: written, MRB, NYU
;-

function sdss_filename_healpixgrp, _EXTRA=keywords

if tag_exist(keywords,'healpix') then begin
  healpix = long(keywords.healpix)
  subdir = strtrim(healpix/1000,2)
endif else begin
  message,'healpix not found'
endelse

return, subdir

end
;

function sdss_filename_apgprefix, _EXTRA=keywords

if tag_exist(keywords,'telescope') then begin
  telescope = keywords.telescope
  if telescope eq 'apo25m' or telescope eq 'apo1m' then begin
    prefix = 'ap'
  endif else if telescope eq 'lco25m' then begin
    prefix = 'as'
  endif else begin
    message,'telescope = '+telescope+' not supported'
  endelse
endif

if tag_exist(keywords,'instrument') then begin
  instrument = keywords.instrument
  if instrument eq 'apogee-n' then begin
    prefix = 'ap'
  endif else if instrument eq 'apogee-s' then begin
    prefix = 'as'
  endif else begin
    message,'instrument = '+instrument+' not supported'
  endelse
endif

return, prefix

end
;
function sdss_filename_platedir, _EXTRA=keywords

plateid= keywords.plateid
platedir= string(plateid/100, f='(i4.4)')+'XX'+'/'+ $
  string(plateid, f='(i6.6)')

return, platedir

end
;
function sdss_filename_designdir, _EXTRA=keywords

designid= keywords.designid
designdir= string(designid/100, f='(i4.4)')+'XX'+'/'+ $
  string(designid, f='(i6.6)')

return, designdir

end
;
function sdss_filename_plateid6, _EXTRA=keywords

plateid= keywords.plateid

if(plateid lt 10000) then $
  plateid_string= string(plateid, f='(i6.6)') $
else $
  plateid_string= strtrim(string(plateid),2)

return, plateid_string

end
;
function sdss_filename, filetype, _EXTRA=keywords

common com_sdss_filename, config

function_base= 'sdss_filename_'

if(n_elements(config) eq 0) then begin
    inifile= getenv('TREE_DIR')+'/data/sdss_paths.ini'
    config=mg_read_config(inifile)
endif

return, construct_filename(config, filetype, function_base=function_base, $
                           _EXTRA=keywords)

end

