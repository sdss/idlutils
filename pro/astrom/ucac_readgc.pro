;+
; NAME:
;   ucac_readgc()
;
; PURPOSE:
;   Read the UCAC data files for a great circle on the sky.
;
; CALLING SEQUENCE:
;   outdat = ucac_readgc(node, incl, gcwidth)
;
; INPUTS:
;   node       - Node of great circle [degrees]
;   incl       - Inclination of great circle [degrees]
;   gcwidth    - Width of great circle [degrees]
;
; OPTIONAL INPUTS:
;
; OUTPUT:
;   outdat     - Structure with UCAC data in its raw catalog format;
;                return 0 if no stars found
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;
; EXAMPLES:
;   a=ucac_readgc(95.,40.,2.5)
;   a=ucac_readgc(95.,10.,1.0)
;
; BUGS:
;   This is slightly wrong: a=ucac_readgc(95.,1.25,0.1)
;
; PROCEDURES CALLED:
;   radec_to_munu
;   ucac_readindex()
;   ucac_readzone()
;
; REVISION HISTORY:
;   27-May-2003  Written by D. Schlegel and N. Padmanabhan, Princeton.
;-
;------------------------------------------------------------------------------
function ucac_intersect, dec0, node, incl, nu

   DRADEG = 180.d0 / !dpi
   sini = sin(incl/DRADEG)
   cosi = cos(incl/DRADEG)
   sinnu = sin(nu/DRADEG)
   cosnu = cos(nu/DRADEG)
   sinmu = (sin(dec0/DRADEG) - sinnu * cosi) / (cosnu * sini)
   cosmu = sqrt(1 - sinmu^2)
   cosmu = [-cosmu,cosmu]
   yy = sinmu * cosnu * cosi - sinnu * sini
   xx = cosmu * cosnu
   ra = node + atan(yy,xx) * DRADEG
   cirrange, ra

   return, ra
end
;------------------------------------------------------------------------------
function ucac_readgc_add, outdat, thiszone, ravec

   if (ravec[0] GT 360) then ravec = ravec - 360
   newdat = ucac_readzone(thiszone, ravec[0], ravec[1])
   if (NOT keyword_set(newdat)) then return, outdat
   if (NOT keyword_set(outdat)) then return, newdat
   return, [outdat, newdat]
end
;------------------------------------------------------------------------------
function ucac_readgc1, node, incl, gcwidth, thiszone, decmin, decmax

   ; These are the declinations of the great circle
   dec1max = incl - 0.5d0 * gcwidth
   dec2max = incl + 0.5d0 * gcwidth
   dec1min = -incl - 0.5d0 * gcwidth ; = -dec2max
   dec2min = -incl + 0.5d0 * gcwidth ; = -dec1max

   ; CASE: Zone is completely above the great circle
   if (dec2max LE decmin) then return, 0

   ; CASE: Zone is completely below the great circle
   if (decmax LE dec1min) then return, 0

   ; CASE: Zone overlaps for entire 360 degrees
   if (dec2min GE decmin AND dec1max LE decmax) then begin
      ravec = [0.d0, 360.d0]

   ; CASE: Take a cap at the top of the great circle
   endif else if (decmax GE dec1max) then begin
      nu = incl - dec1max
      ravec = ucac_intersect(decmin, node, incl, nu)
      if (nu GT 0) then ravec = reverse(ravec)

   ; CASE: Take a cap at the bottom of the great circle
   endif else if (decmin LE dec2min) then begin
      nu = incl - dec2max
      ravec = ucac_intersect(decmax, node, incl, nu)
      if (nu GT 0) then ravec = reverse(ravec)

   ; CASE: Take two intersections...
   endif else begin
      ravec1 = ucac_intersect(decmax, node, incl, dec1max-incl)
      ravec2 = ucac_intersect(decmin, node, incl, dec2max-incl)
      ravec = [ravec1[0], ravec2[0], ravec2[1], ravec1[1]]
   endelse

   ; Now read the data, but watch for wrapping at RA=360 degrees!
   outdat = 0
print,'RA: ',ravec
   if (ravec[0] LE ravec[1]) then begin
      outdat = ucac_readgc_add(outdat, thiszone, ravec[0:1])
   endif else begin
      outdat = ucac_readgc_add(outdat, thiszone, [ravec[0], 360])
      outdat = ucac_readgc_add(outdat, thiszone, [0, ravec[1]])
   endelse
   if (n_elements(ravec) GT 2) then begin
      if (ravec[2] LE ravec[3]) then begin
         outdat = ucac_readgc_add(outdat, thiszone, ravec[2:3])
      endif else begin
         outdat = ucac_readgc_add(outdat, thiszone, [ravec[2], 360])
         outdat = ucac_readgc_add(outdat, thiszone, [0, ravec[3]])
      endelse
   endif

   return, outdat
end
;------------------------------------------------------------------------------
function ucac_readgc, node, incl, gcwidth

   common com_ucac, uindex

   outdat = 0

   ;----------
   ; Check inputs

   if (n_params() LT 3) then begin
      print, 'Wrong number of parameters!'
      return, 0
   endif

   ;----------
   ; Read the index file

   uindex = ucac_readindex()

   ;----------
   ; Loop over all zones

   for thiszone=min(uindex.zn), max(uindex.zn) do begin
print,'ZONE ',thiszone,n_elements(outdat) ; ???
      jj = (where(uindex.zn EQ thiszone, ct))[0]
      if (ct GT 0) then begin
         decmax = uindex[jj].dcmax
         decmin = decmax - 0.5d0
         moredat = ucac_readgc1(node, incl, gcwidth, thiszone, decmin, decmax)
         if (keyword_set(moredat)) then $
          outdat = keyword_set(outdat) ? [outdat,moredat] : moredat
      endif
   endfor

   ;----------
   ; Now trim to objects exactly within the great circle bounds

   if (keyword_set(outdat)) then begin
      convfac = 1d0 / 3600d0 / 1000d0
      radec_to_munu, outdat.ra*convfac, outdat.dec*convfac, mu, nu, $
       node=node, incl=incl
      ikeep = where(abs(nu) LE 0.5d0 * gcwidth, nkeep)
      if (nkeep EQ 0) then outdat = 0 $
       else outdat = outdat[ikeep]
   endif

   return, outdat
end
;------------------------------------------------------------------------------
