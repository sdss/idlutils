;-----------------------------------------------------------------------
;+
; NAME:
;   modfitscard
;
; PURPOSE:
;   Modify FITS card(s) in a file without changing the data.
;
; CALLING SEQUENCE:
;   modfitscard, filename, card, value, [ /delete _EXTRA=KeywordsForSxaddpar ]
;
; INPUTS:
;   filename  - f
;   card      - Name of FITS card(s) to add or modify
;   value     - New value(s) for FITS card
;
; OPTIONAL INPUTS:
;   delete    - If set, then delete all cards CARD from the header;
;               VALUE is ignored if set.
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;
; EXAMPLES:
;   Modify the value of the DATE keyword in the primary header of a FITS file.
;   IDL> modfitscard, 'test.fits', 'DATE', '1994-03-23'
;
; BUGS:
;   This routine calls MODFITS, which does not allow the size of the header
;   to be changed.  If a card is deleted, we simply set it to spaces.  If a
;   card if modified, that should work fine.  Adding cards could fail if
;   this needs to increase the number of header blocks; an erro will be
;   issued.
;
;   Wildcards are not supported for CARD, so you cannot say something like
;   IDL> modfitscard, 'test.fits', 'DATE*', '1994-03-23' ; Will not work!
;
; PROCEDURES CALLED:
;   headfits()
;   modfits
;   sxaddpar
;
; REVISION HISTORY:
;   19-Apr-2000  Written by David Schlegel, Princeton.
;-
;-----------------------------------------------------------------------
pro modfitscard, filename, card, value, delete=delete, $
 _EXTRA=KeywordsForSxaddpar

   ; Need at least 3 parameters
   if (N_params() LT 3 AND (N_params() EQ 2 AND NOT keyword_set(delete))) then begin
      print, 'Syntax - modfitscard, filename, card, value, _EXTRA=KeywordsForSxaddpar'
      return
   endif

   ncard = N_elements(card)
   if (ncard NE N_elements(value) AND NOT keyword_set(delete)) then begin
      print, 'Number of elements in CARD and VALUE do not agree'
      return
   endif

   hdr = headfits(filename)
   if (size(hdr, /tname) NE 'STRING') then begin
      print, 'File does not exist or FITS header is invalid'
      return
   endif

   if (keyword_set(delete)) then begin
      keyword = strmid(hdr, 0, 8)
      for icard=0, ncard-1 do begin
         cardname = string(card+'        ',format='(a8)')
         ifound = where(keyword EQ cardname)
         ilist = where(hdr EQ card[icard])
         if (ifound[0] NE -1) then hdr[ifound] = ''
      endfor
   endif else begin
      for icard=0, ncard-1 do begin
         sxaddpar, hdr, card[icard], value[icard], _EXTRA=KeywordsForSxaddpar
      endfor
   endelse

   modfits, filename, 0, hdr

   return
end 
;-----------------------------------------------------------------------
