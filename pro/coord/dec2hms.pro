
; Written by Douglas Finkbeiner in ancient times
; 29 Nov 2000 - double keyword added
; pass type double, or suffer 0.003 arcsec error
function dec2hms,angle_in, double=double  

  eps = (machar(double=double)).eps ; machine precision

  angle = double(angle_in)
  neg   = angle LT 0.0d
  angle = abs(angle)
  h     = floor(angle+eps)
  angle = (angle-h)*60.0d
  m     = floor(angle+eps*60)
  s     = ((angle-m)*60.0d) > 0 ; can be slightly LT 0 due to roundoff
  
  if keyword_set(double) then begin 
     if ((s ge 59.999949d) and (s le 60.00d)) then s=59.999949d
     hms=string(h,m,s,format='(I3.2,I3.2,F8.4)') 
  endif else begin 
     if ((s ge 59.949d) and (s le 60.00d)) then s=59.949d
     hms=string(h,m,s,format='(I3.2,I3.2,F5.1)')
  endelse 

  if (strmid(hms,7,1) eq ' ') then strput,hms,'0',7
  if neg then strput,hms,'-',0

return,hms
end
