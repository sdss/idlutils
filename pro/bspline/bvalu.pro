
;
;	This is a slow version of slatec_bvalu, needs to be sped
;       up before using as full replacement.
;
;
function bvalu, x, fullbkpt, coeff

     n = n_elements(coeff)
     k = n_elements(fullbkpt) - n
     nx = n_elements(x)
     indx = lonarr(nx)
     p = sort(x)

     ileft = k - 1L
     for i=0L, nx-1 do begin
        while (x[p[i]] GE fullbkpt[ileft+1] AND ileft LT n-1 ) do $
            ileft = ileft + 1L
        indx[i] = ileft
      endfor

      bf1 = bsplvn(fullbkpt, k, x, indx[p])
      answer = x*0.0

      spot = lindgen(k) - k + 1
      for i=k-1L,n-1 do begin
        inside = where(indx EQ i)
        if inside[0] NE -1 then answer[inside] = bf1[inside,*] # coeff[spot+i]
      endfor

      return, answer
end

