
pro acs_peaks, acsflt_file

   suff = rstrpos(acsflt_file, 'flt.fit')
   if suff LE 0 then return

   xy_file = strmid(acsflt_file, 0, suff) + 'xy.fits'

   temp_str = { ext : 0, $ 
                  x : 0.0, $
                  y : 0.0, $
               flux : 0.0, $
               mult:  1L, $
               flag:  0L }
   final_str = 0

   for ext=1,4,3 do begin

     image = mrdfits(acsflt_file,ext,hdr)
     error = mrdfits(acsflt_file,ext+1)
     dq    = mrdfits(acsflt_file,ext+2)
  
     sub = image - median(image)
     cr_mask = (dq AND 12288) GT 0

     wt =  1./(error^2 + (error EQ 0.)) * (cr_mask EQ 0) * (error GT 0)

     sigma=1.0
     find_sb, sub, wt, x=x, y=y, flux=flux, pa_degrees=pa_degrees, $
                 fwhm=fwhm, sigma=sigma

;     list = transpose([[x],[y]])
;     matchnd, list, list, 5.0*sigma, m1=m1, m2=m2, d12=d12

      nobj = n_elements(x)

      poss_str = temp_str
      poss_str.ext = ext
      poss_str.x = x[0]
      poss_str.y = y[0]
      poss_str.flux = flux[0]

      for i=1L,nobj-1L do begin
        min_dist = min((x[i]-poss_str.x)^2 + (y[i]-poss_str.y)^2 ,pl)
        if min_dist LT (5.0*sigma)^2 then $
           poss_str[pl].mult = poss_str[pl].mult + 1  $
        else begin    
           temp_str.x = x[i] 
           temp_str.y = y[i] 
           temp_str.flux = flux[i] 
           temp_str.ext = ext
           poss_str = struct_append(poss_str, temp_str)
        endelse 
     endfor 

   final_str = struct_append(final_str, poss_str)
  endfor

  mwrfits, final_str, xy_file, /create

return
end
