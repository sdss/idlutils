;+
; NAME:
;   fill_bspline
;
; PURPOSE:
;   Calculate a B-spline in the least-squares sense 
;     based on two variables: x which is sorted and spans a large range
;				  where bkpts are required
;  		and 	      y which can be described with a low order
;				  polynomial	
;
; CALLING SEQUENCE:
;   
;   coeff = efc2d(x, y, z, invsig, npoly, nbkptord, fullbkpt)
;
; INPUTS:
;   x          - data x values
;   y          - data y values
;   z          - data z values
;   invsig     - inverse error array of y
;   npoly      - Order of polynomial (as a function of y)
;   nbkptord   - Order of b-splines (4 is cubic)
;   fullbkpt   - Breakpoint vector returned by efc
;
; RETURNS:
;   coeff      - B-spline coefficients calculated by efc
;
; OUTPUTS:
;
; OPTIONAL KEYWORDS:
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   please sort x for this routine
;
; EXAMPLES:
;
;
; PROCEDURES CALLED:
;
;   efc_idl in src/slatec/idlwrapper.c
;         which wraps to efc.o in libslatecidl.so
;
; REVISION HISTORY:
;   10-Mar-2000 Written by Scott Burles, FNAL
;-
;------------------------------------------------------------------------------
pro test_bspline, nx, nbkpt
   x = dindgen(nx)
   y = randomu(200, nx, /normal)*1.0d
   zmodel = 10.0*sin(x/10.0) + y
   z = zmodel + randomu(100,nx,/normal)
   invsig = fltarr(nx) + 1.0
   npoly = 2L
   nbkptord = 4L
   fullbkpt = (findgen(nbkpt + nbkptord*2-1) - (nbkptord - 1))/nbkpt * nx 
   stime1 = systime(1)
   coeff = efcmn(x, z, invsig, nbkptord, fullbkpt)
   stime2 = systime(1)
   coeffb = fill_bspline(x, y, z, invsig, 1, nbkptord, fullbkpt)
   stime3 = systime(1)
   print, stime2-stime1, stime3-stime2

;   zfit = bvalu2d(x, y, fullbkpt, coeff)
   zfit = slatec_bvalu(x, fullbkpt, coeff)

return
end



function fill_bspline, x, y, z, invsig, npoly, nbkptord, fullbkpt

    
      nx = n_elements(x)
      nbkpt= n_elements(fullbkpt)
      n = (nbkpt - nbkptord)
      nfull = n*npoly

      coeff = fltarr(nfull)

      xmin = min([fullbkpt[nbkptord-1],x])
      xmax = max([fullbkpt[n],x])

;
;	Make sure nord bkpts on each side lie outside [xmin,xmax]
;
	for i=0,nbkptord-1 do fullbkpt[i] = min([fullbkpt[i],xmin])
	for i=n,nbkpt-1 do fullbkpt[i] = max([fullbkpt[i],xmax]) 

;
;     Loop through data points, and process at every once each breakpoint
;     is crossed.
;
      bw = npoly * nbkptord   ; this is the bandwidth

      if keyword_set(y) then begin
         stuff = (y # replicate(1,nbkptord))[*]
         ypoly = reform(flegendre(stuff, npoly),nx,bw)
      endif

      
 
      low = 0
      ileft = nbkptord - 1L
      high = bw + ileft

      indx = lonarr(nx)
      for i=0L, nx-1 do begin
        while (x[i] GE fullbkpt[ileft+1] AND ileft LT n-1 ) do $
            ileft = ileft + 1L
        indx[i] = ileft
      endfor
      
      bf1 = bsplvn(fullbkpt, nbkptord, x, indx)
      bf = reform(bf1[*] #replicate(1,npoly),nx, bw)

      a = bf * ypoly * (invsig # replicate(1,bw))
      b = z * invsig

;      alphafull = fltarr(nx, nfull)
;      alphafull[*,0:bw-1] = a
;      for i=0L, nx-1 do $
;      alphafull[i,*] = shift(alphafull[i,*],(indx[i]-nbkptord+1)*npoly)
;
;      atest = alphafull ## transpose(alphafull)
;      btest = alphafull ## b


      alpha = dblarr(bw,nfull+bw)
      beta = dblarr(nfull+bw)

      bi = lindgen(bw)
      bo = lindgen(bw)
      for i=1,bw-1 do bi = [bi,lindgen(bw-i)+(bw+1)*i]
      for i=1,bw-1 do bo = [bo,lindgen(bw-i)+bw*i]

      ilist = indx[uniq(indx)]
      for i=0, n_elements(ilist) - 1 do begin

        itop = i*npoly
        ibottom = (itop + bw < nfull) - 1
        inside = where(indx EQ ilist[i], ict)

        if (ict NE 0) then begin

          work = a[inside,*] ## transpose(a[inside,*])
          wb =  b[inside] # a[inside,*] 

          alpha[bo+itop*bw] = alpha[bo+itop*bw] + work[bi]
          beta[itop:ibottom] = beta[itop:ibottom] + wb
        endif
      endfor

; this changes alpha
    errb = cholesky_band(alpha)   

; this changes beta to contain the solution
    errs = cholesky_solve(alpha, beta)   

    return, beta[lindgen(nfull)]
end 
