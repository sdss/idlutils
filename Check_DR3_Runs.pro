pro Check_DR3_Runs

a = 'Written by Dimitri Apostol for Michael Blanton and David Hogg'
b = 'For use with the SDSS Data Releases (current: DR3)'
print, a, b

c = 'usage:'
d = 'Check_DR3_Runs'
print, c, d

e = 'Reading par file:'
f = 'tsChunk.dr3best.par'
print, e, f
DR3_Runs = yanny_readone(getenv('VAGC_DIR')+'/data/sdss/tsChunk.dr3best.par')

g = 'Reading current SDSS runlist...'
print, g
SDSS_Runs = sdss_runlist(rerun=137)

h = 'Comparing lists...'
print, h
counter = 0
for i=1, 10 do begin
	for j=1, 10 do begin
		w = 'For DR3 run #'+i+', SDSS run #'+j+' is a match!'
		x = 'There was no match in SDSS for DR3 run #'+i+''
		if DR3_Runs.run[i] eq SDSS_Runs.run[j] then print, w
		if DR3_Runs.run ne SDSS_Runs.run then begin
			print, x
			counter++
			endif
endfor
endfor
y = 'All DR3 runs matched up with a run on SDSS!'
z = 'There were '+counter+' DR3 run(s) that SDSS did not have on record.'
if counter gt 0 then begin
	print, y
endif else begin
	print, z
endelse
end
