function gauss_kernel, sigma, nsub=nsub, exp=exp

    if NOT keyword_set(nsub) then nsub = 5


    if keyword_set(exp) then npix = 10.0*sigma + 1 $
    else npix = 5.0*sigma + 1

    x1 = 1.0+findgen(npix)
    xl = [reverse(-x1),0.0,x1]
    sneaky = (findgen(nsub) - (nsub-1)/2.0)/nsub

    x = sneaky # replicate(1,2*npix+1) + xl ## replicate(1,nsub)

    if keyword_set(exp) then expl = exp(-abs(x)/sigma) $
    else expl = exp(-x^2/(2.0*sigma))

    kernel = total(expl,1)/ total(expl)

    return, kernel
end



