;+
; NAME:
;    lle
; PURPOSE: (one line)
;    Perform local linear embedding
; DESCRIPTION:
;    Uses Sam Roweis's local linear embedding technique to reduce the 
;    dimensionality of a data set.
; CATEGORY:
;    Mathematical
; CALLING SEQUENCE:
;    lle, data, k, coords, weights=weights
; INPUTS:
;    data - [p,N] data to be reduced
;    k - number of output dimensions desired
; OUTPUTS: 
;    coords - [k,N] embedding coordinates
; OPTIONAL OUTPUTS PARAMETERS:
;    weights - reconstruction weights
; OPTIONAL INPUT PARAMETERS:
; KEYWORD PARAMETERS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; BUGS:
;    Not completed yet, do not use
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;    2003-05-14 - Written by Michael Blanton (NYU)
;-
pro lle_find_neighbors, data, nneighbors, neighbors

ndim=(size(data))[0]
if(ndim eq 1) then $
  p=1 $
else $
  p=(size(data,/dimensions))[0]
ndata=n_elements(data)/ndim

neighbors=lonarr(nneighbors,ndata)

for i=0L, ndata-1L do begin
    dist2=total((data-data[*,i]#replicate(1.,ndata))^2,1)
    sortdist2=sort(dist2)
;   assumes i is one of first nneighbor neighbors
    n=0
    splog,i
    for j=0L, nneighbors do begin
        if(i ne sortdist2[j]) then begin
            neighbors[n,i]=sortdist2[j]
            n=n+1
        endif
    endfor
endfor

end
;
pro lle_reconstruct_weights, data, neighbors, weights

ndim=(size(data))[0]
if(ndim eq 1) then $
  p=1 $
else $
  p=(size(data,/dimensions))[0]
ndata=n_elements(data)/ndim
nneighbors=n_elements(neighbors)/ndata

weights=dblarr(nneighbors,ndata)
for i=0L, ndata-1L do begin
    zz=data[*,neighbors[*,i]]
    for j=0L, ndim-1L do $
      zz[j,*]=zz[j,*]-data[j,i]
    covar=transpose(zz)#zz
    covar=covar+1.e-3*trace(covar)*identity(nneighbors)
    ww=invert(covar)#replicate(1.,nneighbors)
    weights[*,i]=ww/total(ww,/double)
endfor

end
;                                
pro lle_embedding_coords, weights, coords


end
;                                ;
pro lle, data, k, coords, weights=weights

if(NOT keyword_set(nneighbors)) then nneighbors=20

; check args
if (n_params() lt 1) then begin
    print, 'Syntax - lle, data, k, coords [, weights= ]'
    return
endif

; check dimensions
ndim=(size(data))[0]
if(ndim eq 1) then $
  p=1 $
else $
  p=(size(data,/dimensions))[0]
n=n_elements(data)/p
if(k gt p) then begin
    splog, 'k must be less than or equal to p!'
    splog, 'k= '+string(k)
    splog, 'p= '+string(p)
    return
endif

lle_find_neighbors, data, nneighbors, neighbors

lle_reconstruct_weights, data, neighbors, weights

lle_embedding_coords, weights, coords

return

end
