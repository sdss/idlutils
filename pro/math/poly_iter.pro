PRO poly_iter, x, y, ndeg, nsig, yfit, coeff=coeff

  good = bytarr(n_elements(x))+1B
  w = lindgen(n_elements(x))

  FOR i=1, 5 DO BEGIN 
      if (!version.release LT '5.4') then $
       coeff = poly_fit(x[w], y[w], ndeg, yfit) $
      else $
       coeff = poly_fit(x[w], y[w], ndeg, yfit, /double)

      res = y[w]-yfit
      sig = stddev(res)
      good[w] = good[w]*(abs(res) LT nsig*sig)
      w = where(good)
  ENDFOR 

  if (!version.release LT '5.4') then $
   coeff = poly_fit(x[w], y[w], ndeg) $
  else $
   coeff = poly_fit(x[w], y[w], ndeg, /double)


  yfit = poly(x, coeff)

  return
END
