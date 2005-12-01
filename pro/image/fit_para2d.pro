
function fit_para2d, x, y, im, wt, model=model, chi2=chi2

     xbasis = fpoly(x,3)
     ybasis = fpoly(y,3)
  
     action = (x[*]*0) # replicate(1,6)
     action[*,0]  =1
     action[*,1] = xbasis[*,1]
     action[*,2] = ybasis[*,1]
     action[*,3] = xbasis[*,2]
     action[*,4] = xbasis[*,1] * ybasis[*,1]
     action[*,5] = ybasis[*,2]

     if (size(im))[0] EQ 1 then n_im = 1 $
     else n_im = (size(im))[2]
     res = fltarr(6, n_im)
     model = im*0.

     for i=0, n_im-1 do begin
     
       a = action * (sqrt(wt[*,i]) # replicate(1,6))
       alpha = transpose(a) # a
       beta = transpose(action) # (im[*,i] * wt[*,i])

       la_choldc, alpha, /double, status=status
       if status EQ 0 then  $
       res[*,i] = la_cholsol(alpha, beta)
     endfor
     model = action # res
     chi2 = (im - model)^2 * wt  
     return, res
end

