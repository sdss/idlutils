pro usnob2fits_1, path, subdir, fname, outpath, hash

  rec_len = 80L
  
  dirstr = string(subdir, format='(I3.3)')
  catfile = path+'/'+dirstr+'/'+fname+'.cat'
  outdir  = outpath+'/'+dirstr
  if not file_test(outdir, /dir) then spawn, 'mkdir -p '+outdir
  outfile = outdir+'/'+fname+'.fit'

  openr, readlun, catfile, /get_lun, /swap_if_big_endian
  nbyte = (fstat(readlun)).size
  nstars = nbyte/rec_len
  data = ulonarr(rec_len/4, nstars)
  readu, readlun, data
  free_lun, readlun

  usnostruct = usnob10_extract(data)
  usnostruct.fldepoch = hash[usnostruct.fldid]

  mwrfits, usnostruct, outfile, /create

  return
end



pro usnob2fits

; -------- set paths
  dataroot = getenv('PHOTO_DATA')+'/'
  if dataroot eq '/' then message, 'you need to set PHOTO_DATA'
  path = dataroot+'usnob/'
  outpath = path+'fits/'

; -------- set up epoch hash
  epochfile = path+'/USNO-B-epochs.fit'
  ep = mrdfits(epochfile, 1)
  hash = fltarr(10000)
  hash[ep.field] = ep.epoch

  subdir = 90
  for i=0, 9 do begin 
     fname = 'b'+string(subdir*10+i, format='(I4.4)')
     usnob2fits_1, path, subdir, fname, outpath, hash
  endfor

  return
end
