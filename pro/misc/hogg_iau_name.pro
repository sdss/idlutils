;+
; NAME:
;   hogg_iau_name
; PURPOSE:
;   properly format astronomical source names to the IAU convention
; INPUTS:
;   ra         - J2000 deg
;   dec        - J2000 deg
;   prefix     - survey prefix
; OPTIONAL INPUTS:
;   precision  - how many decimal places to put on dec; ra gets one more
; COMMENTS:
;   Defaults to SDSS name conventions.
; BUGS:
;   Enforces J2000 "J".
;   Doesn't deal properly with precision<0 names, which *can* exist.
; REVISION HISTORY:
;   2004-04-14  started by you know who
;-
function hogg_iau_name, ra,dec,prefix,precision=precision
if (NOT keyword_set(prefix)) then prefix= 'SDSS'
if (NOT keyword_set(precision)) then precision= 1
adstr= adstring(ra,dec,precision,/truncate)
adstr= strsplit(adstr,' ',/extract)
adstr= strjoin(adstr,'')
return, prefix+' J'+adstr
end
