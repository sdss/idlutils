;+
; NAME:
;  hogg_bwify
; PURPOSE:
;  make b/w image from color
;-
pro hogg_bwify, infile,outfile
quality= 90
read_jpeg, infile,colors,true=3
colors[*,*,1]= 255-colors[*,*,1]
colors[*,*,0]= colors[*,*,1]
colors[*,*,2]= colors[*,*,1]
WRITE_JPEG, outfile,temporary(colors),TRUE=3,QUALITY=quality
return
end
