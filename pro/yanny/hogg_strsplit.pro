;+
; NAME:
;   hogg_strsplit
; PURPOSE:
;   split strings on whitespace, except inside double quotes
; REVISION HISTORY:
;   2002-10-10  written - Hogg
;-
pro hogg_strsplit, string,output,count,recurse=recurse

; initialize unset variables
if NOT keyword_set(recurse) AND keyword_set(output) then tmp= temporary(output)
if NOT keyword_set(output) then count= 0

; do the dumbest thing, if possible
if strcompress(string,/remove_all) EQ '' then begin
endif else if stregex(string,'\"') LT 0 then begin
    word= strsplit(strcompress(string),'[ ]+',/regex,/extract)
    if NOT keyword_set(output) then output= word else output= [output, word]
    count= count+n_elements(word)
endif else begin

; split on quotation marks and operate recursively
    if not keyword_set(count) then count= 0
    pos= stregex(string,'\"([^"]*)\"',length=len)
    if pos GE 0 then begin
        hogg_strsplit, strmid(string,0,pos),output,count,/recurse
        count= count+1
        word= strmid(string,pos+1,len-2)
        if not keyword_set(output) then output= word else output= [output, word]
        hogg_strsplit, strmid(string,pos+len),output,count,/recurse
    endif
endelse
return
end
