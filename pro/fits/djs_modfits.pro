;-----------------------------------------------------------------------
;+
; NAME:
;   djs_modfits
;
; PURPOSE:
;   Wrapper for MODFITS that allows the header to increase in size.
;
; CALLING SEQUENCE:
;   djs_modfits, filename, data, [hdr, exten_no=]
;
; INPUTS:
;   filename  -
;   data      -
;
; OPTIONAL INPUTS:
;   hdr       -
;   exten_no  -
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;   modfits
;   mrdfits()
;   mwrfits
;   readfits()
;   writefits
;
; INTERNAL PROCEDURES:
;   bitsperpixel()
;
; REVISION HISTORY:
;   17-May-2000  Written by David Schlegel, Princeton.
;-
;-----------------------------------------------------------------------
function bitsperpixel, type

   tvec = [0,1,2,4,4,8,8,0,0,16,0,0,2,4,8,8]
   return, tvec[type]
end
;-----------------------------------------------------------------------
pro djs_modfits, filename, data, hdr, exten_no=exten_no

   ; Need at least 2 parameters
   if (N_params() LT 2) then begin
      print, 'Syntax - djs_modfits, filename, data, [hdr, exten_no=]'
      return
   endif

   if (NOT keyword_set(exten_no)) then exten_no = 0

   ;----------
   ; Make sure the header cards are all exactly 80 characters

   if (keyword_set(hdr)) then begin
      hdr = strmid(hdr+string(' ',format='(a80)'),0,80)
   endif

   ;----------
   ; If we don't think the header size or data size will require a new block,
   ; call MODFITS to modify the header

   qbigger = 0

   if (keyword_set(hdr)) then begin
      hdr1 = headfits(filename, exten=exten_no)
      if (NOT keyword_set(hdr1)) then $
       message, 'EXTEN_NO does not exist in file '+filename
;      if ((n_elements(hdr)+79)/80 GT (n_elements(hdr1)+79)/80) then qbigger = 1
      if (n_elements(hdr) GT n_elements(hdr1)) then qbigger = 1
   endif

   if (keyword_set(data)) then begin
      data1 = mrdfits(filename, exten_no)
      qstruct = size(data, /tname) EQ 'STRUCT'
      if (qstruct) then begin
         nbytes1 = n_tags(data1, /length)
         nbytes = n_tags(data, /length)
      endif else begin
         nbytes1 = n_elements(data1) * bitsperpix(size(data1,/type))
         nbytes = n_elements(data) * bitsperpix(size(data,/type))
      endelse
      if (NOT keyword_set(data1) OR $
       (nbytes+2879)/2880 GT (nbytes1+2879)/2880) then qbigger = 1
   endif

   ;----------
   ; For now, the Goddard routine MODFITS does not work with structures.
   ; So don't use it in that case.

   if ((qbigger EQ 0) AND qstruct EQ 0) then begin
      modfits, filename, data, hdr, exten_no=exten_no
      return
   endif

   ;----------
   ; Read in all the headers and data arrays for FILENAME

   data1 = readfits(filename, hdr1)
   pdata = ptr_new(data1)
   phdr = ptr_new(hdr1)
   nhdu = 1

   while (keyword_set(hdr1)) do begin
      hdr1 = 0
      data1 = mrdfits(filename, nhdu, hdr1)
      if (keyword_set(hdr1)) then begin
         phdr = [phdr, ptr_new(hdr1)]
         pdata = [pdata, ptr_new(data1)]
         nhdu = nhdu + 1
      endif
   endwhile

   if (exten_no GE n_elements(phdr)) then $
    message, 'EXTEN_NO does not exist in file '+filename

   ;----------
   ; Re-write all the headers and data arrays to FILENAME, modifying the
   ; one specified by EXTEN_NO

   if (keyword_set(hdr)) then begin
      ptr_free, phdr[exten_no]
      phdr[exten_no] = ptr_new(hdr)
   endif

   if (keyword_set(data)) then begin
      ptr_free, pdata[exten_no]
      pdata[exten_no] = ptr_new(data)
   endif

   writefits, filename, *(pdata[0]), *(phdr[0])
   for ihdu=1, nhdu-1 do begin
;      mwrfits, *(pdata[0]), filename, *(phdr[0])
; DPF fix 3 June 2000 
     mwrfits, *(pdata[ihdu]), filename, *(phdr[ihdu])
   endfor

   ;----------
   ; Free memory
   for ihdu=0, nhdu-1 do begin
      ptr_free, phdr[ihdu]
      ptr_free, pdata[ihdu]
   endfor

   return
end 
;-----------------------------------------------------------------------
