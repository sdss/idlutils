; 29 nov 2000 fixed to handle "d" properly! - DPF
function hms2dec,hmsstring

; Replace any h, m, or s in the string with a space
hms=strlowcase(hmsstring+' ')
hpos=strpos(hms,'h')
if (hpos ge 0) then strput, hms, ' ', hpos
hpos=strpos(hms,'d')
if (hpos ge 0) then strput, hms, ' ', hpos
mpos=strpos(hms,'m')
if (mpos ge 0) then strput, hms, ' ', mpos
spos=strpos(hms,'s')
if (spos ge 0) then strput, hms, ' ', spos

spos=strpos(hms,':')
if (spos ge 0) then strput, hms, ' ', spos
spos=strpos(hms,':')
if (spos ge 0) then strput, hms, ' ', spos

; strip leading spaces
while (strpos(hms,' ') eq 0) do hms=strmid(hms,1,strlen(hms)-1)
neg = (strmid(hms,0,1) eq '-') 
if neg then strput,hms,' ',0
while (strpos(hms,' ') eq 0) do hms=strmid(hms,1,strlen(hms)-1)

cut=strpos(hms,' ')
if (cut gt 0) then begin
  hstr=strmid(hms,0,cut)
  hms=strmid(hms,cut+1,strlen(hms))
  reads,hstr,h
endif else h=0
while (strpos(hms,' ') eq 0) do hms=strmid(hms,1,strlen(hms)-1)
cut=strpos(hms,' ')
if (cut gt 0) then begin
  reads,strmid(hms,0,cut),m
  hms=strmid(hms,cut+1,strlen(hms))
endif else m=0

while (strpos(hms,' ') eq 0) do hms=strmid(hms,1,strlen(hms)-1)
cut=strpos(hms,' ')
if (cut gt 0) then begin
  reads,strmid(hms,0,cut),s
  hms=strmid(hms,cut+1,strlen(hms))
endif else s=0
dec=h+m/60.0d + s/3600.0d
if neg then dec=-dec
return,dec
end
