;
; Given a set of values and weights, 
; returns the weighted quantile or 
; set of quantiles
; MB 07/02
;
function weighted_quantile,values,weights,quant=quant

if(n_elements(values) le 1) then return,values[0]
if(n_elements(quant) eq 0) then quant=[0.5]

isort=sort(values)
svalues=values[isort]
sweights=weights[isort]
scum=total(sweights,/cumulative,/double)
scum=scum/scum[n_elements(scum)-1L]
j=lindgen(n_elements(scum)-1L)
jp1=j+1L

quantile=dblarr(n_elements(quant))
for iquant=0L, n_elements(quant)-1L do begin
    ipos=where(scum[j] le quant[iquant] and $
               scum[jp1] gt quant[iquant],ispos)
    quantile[iquant]=svalues[n_elements(svalues)-1L]
    if(scum[0] gt quant[iquant]) then quantile[iquant]=svalues[0]
    if(ispos gt 0) then quantile[iquant]=svalues[ipos[0]+1]
endfor

return,quantile

end
