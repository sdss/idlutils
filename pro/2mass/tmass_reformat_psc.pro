pro tmass_reformat_psc

  inpath = '/peyton/scr/photo66/sdssdata/2mass/allsky/'
  outpath = '/peyton/scr/photo63/sdssdata/2mass/allsky/'
;  outpath = '/peyton/scr/photo58/2mass/'

  flist = findfile(inpath+'psc*.gz', count=fct)
  infile = strmid(flist, strlen(inpath))

  for i=0L, fct-1 do begin 
     outfile = repstr(infile[i], '.gz', '.fits')
     if file_test(outpath+outfile) then begin 
        print, outpath+outfile, ' already exists - skipping.'
     endif else begin 
        print, 'reading: ', inpath+infile[i]
        print, 'writing: ', outpath+outfile
        tmass_ascii2fits, inpath+infile[i], outpath+outfile
     endelse 
  endfor 

  return
end

