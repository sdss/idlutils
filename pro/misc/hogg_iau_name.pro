;+
; BUGS:
;   no header
;   need epoch flag/input
;-
function hogg_iau_name, ra,dec,prefix,precision=precision
if (NOT keyword_set(prefix)) then prefix= 'SDSS'
if (NOT keyword_set(precision)) then precision= 1
adstr= adstring(ra,dec,precision,/truncate)
adstr= strsplit(adstr,' ',/extract)
adstr= strjoin(adstr,'')
return, prefix+' J'+adstr
end
