
function cholesky_band, a

    ; compute cholesky decomposition of banded matrix
    ;   a[bandwidth, n]  n is the number of linear equations
 
    ; I'm doing lower cholesky decomposition from lapack, spbtf2.f

    bw = (size(a))[1]
    n = (size(a))[2]

    kd = bw - 1


    negative = where(a[0,*] LE 0)
    if negative[0] NE -1 then begin
       message, 'you have negative diagonals, difficult to root', /continue
       return, negative
    endif

    lower = [[a], [fltarr(bw,bw)]]

    kn = bw - 1 
    spot = 1 + lindgen(kn)
    bi = lindgen(kn)
    for i=1,kn-1 do bi = [bi,lindgen(kn-i)+(kn+1)*i]


    for j=0,n - 1 do begin
         lower[0,j] = sqrt(lower[0,j])
         lower[spot,j] = lower[spot,j] / lower[0,j]
         x = lower[spot,j]
         hmm = x # transpose(x)
         here = bi+(j+1)*bw
         lower[here] = lower[here] - hmm[bi]
    endfor

  return,lower
end
            
