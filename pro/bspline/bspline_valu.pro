
;
;	This is a slow version of slatec_bvalu, needs to be sped
;       up before using as full replacement.
;
;
function bspline_valu, x, sset

      n = n_elements(sset.coeff)
      k = n_elements(sset.fullbkpt) - n
      nx = n_elements(x)

      if nx EQ 0 then return, -1

      indx = intrv(x, sset.fullbkpt, k)

      bf1 = bsplvn(sset.fullbkpt, k, x, indx)
      answer = x*0.0

      spot = lindgen(k) - k + 1
      for i=k-1L,n-1 do begin
        inside = where(indx EQ i)
        if inside[0] NE -1 then answer[inside] = bf1[inside,*] # $
                  sset.coeff[spot+i]
      endfor

      return, answer
end

