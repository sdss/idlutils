;+
; NAME:
;   bitlist
; PURPOSE:
;   return vector containing which bits are set in the input
; CALLING SEQUENCE:
;   bits=bitlist(mask)
; BUGS
;   ulong64() is wasteful
; REVISION HISTORY
;   2003-02-22  written - Blanton
;-
function bitlist, mask, count

isbit=mask and ulong64(2)^lindgen(64)
return,where(isbit gt 0, count)

end
