;+
; NAME:
;   HOGG_MRDFITS
; PURPOSE:
;   Wrapper on mrdfits to read in a chunk at a time
; CALLING SEQUENCE:
; INPUTS:
;   see MRDFITS
; KEYWORDS:
;   see MRDFITS
;   nrowchunk  - number of rows to read at a time.
; COMMENTS:
;   Useful when "columns" is set, so you can get a couple
;   of columns without holding the whole file in memory
; OUTPUTS:
;   see MRDFITS
; REVISION HISTORY:
;   2002-02-08  written by Hogg
;-
function hogg_mrdfits, file,extension,header, silent=silent, $
   range=range,nrowchunk=nrowchunk, _EXTRA=inputs_for_mrdfits

  if not keyword_set(range) then begin
    naxis2= sxpar(headfits(file,exten=extension,silent=silent),'NAXIS2')
    if(NOT keyword_set(silent)) then splog, naxis2
    range= [0,naxis2-1]
  endif

  if not keyword_set(nrowchunk) then nrowchunk= 1000

  chunkrange= [range[0],((range[0]+nrowchunk-1) < range[1])]
  while (chunkrange[1] GE chunkrange[0]) do begin

    if(NOT keyword_set(silent)) then splog, chunkrange
    chunkresult= mrdfits(file,extension,header, $
      range=chunkrange,silent=silent,_EXTRA=inputs_for_mrdfits)
    if(NOT keyword_set(silent)) then help, chunkresult
    if not keyword_set(result) then begin
        result=replicate(chunkresult[0],range[1]-range[0]+1)
    endif 
    result[chunkrange[0]-range[0]:chunkrange[1]-range[0]]=chunkresult

    chunkrange[0]= chunkrange[0]+nrowchunk
    chunkrange[1]= (chunkrange[1]+nrowchunk) < range[1]

  endwhile

  return, result
end
