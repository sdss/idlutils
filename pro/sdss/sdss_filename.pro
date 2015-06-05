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
; REVISION HISTORY:
;   2015-06-02: written, MRB, NYU
;-
function sdss_filename_platedir, _EXTRA=keywords

plateid= keywords.plateid
platedir= string(plateid/100, f='(i4.4)')+'XX'+'/'+ $
  string(plateid, f='(i6.6)')

return, platedir

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

if(n_elements(config) eq 0) then begin
    inifile= getenv('SDSS_PYTHON_MODULE_DIR')+'/data/sdss_paths.ini'
    config=mg_read_config(inifile)
endif

;; get template
filename= config->get(filetype, section='paths')

;; handle python format variables
filename= parse_string_format(filename, _EXTRA=keywords)

;; handle environmental variables
wordchars='\$([A-Za-z0-9_]*)'
indx= stregex(filename, wordchars, length=length)
while(indx ne -1) do begin
    mid=strmid(filename, indx+1, length-1)
    value= getenv(mid)
    filename= strmid(filename, 0, indx)+value+strmid(filename, indx+length)
    indx= stregex(filename, wordchars, length=length)
endwhile

;; execute functions
wordchars='\%([A-Za-z0-9_]*)'
indx= stregex(filename, wordchars, length=length)
while(indx ne -1) do begin
    mid=strmid(filename, indx+1, length-1)
    value= call_function('sdss_filename_'+mid, _EXTRA=keywords)
    filename= strmid(filename, 0, indx)+value+strmid(filename, indx+length)
    indx= stregex(filename, wordchars, length=length)
endwhile

return, filename

end

