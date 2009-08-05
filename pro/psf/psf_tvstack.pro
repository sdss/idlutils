pro psf_tvstack, stamps, window=wnum

  if n_elements(wnum) EQ 0 then wnum = 1
  s = psf_grid(stamps, 1)
  sz = size(s, /dimens)
  bx=sz[0]*2
  by=sz[1]*2

  sbig = rebin(s, bx, by, /sample)

  if (!d.window EQ wnum) AND (!d.x_size EQ bx) AND (!d.y_size EQ by) then begin 
;     erase
  endif else begin 
     window, wnum, xsize=bx, ysize=by
  endelse 

  tv, bytscl(sbig,min=-0.02,max=0.12)

  return
end
