;+
; NAME:
;   yanny_par
;
; PURPOSE:
;   Obtain the value of a parameter in the header of a Yanny file.
;
; CALLING SEQUENCE:
;   result = yanny_par( hdr, keyname, [count=count] )
;
; INPUTS:
;   hdr        - Header lines in Yanny file, which are usually keyword pairs.
;
; OPTIONAL INPUTS:
;
; OUTPUT:
;   result     - Value of parameter in header; return 0 if parameter not found
;
; OPTIONAL OUTPUTS:
;   count      - Return the number of paramters found
;
; COMMENTS:
;   This routine is meant to be analogous to the Goddard function SXPAR()
;   for reading from FITS headers.
;
; EXAMPLES:
;
; BUGS:
;   Wildcards are not supported for KEYNAME.
;
; PROCEDURES CALLED:
;
; INTERNAL SUPPORT ROUTINES:
;
; REVISION HISTORY:
;   02-Nov-1999  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------
function yanny_par, hdr, keyname, count=count

   if (N_params() LT 2) then begin
      print, 'Syntax - result = yanny_par(hdr, keyname, [count= ] )'
      return, 0
   endif

   nhead = N_elements(hdr)
   if (nhead EQ 0) then return, -1

   if (size(keyname, /tname) EQ 'UNDEFINED') then begin
      print, 'keyname is undefined, pass a string'
      return, ''
   endif

   keylist = strarr(nhead)
   keystring = strarr(nhead)
   for i=0, nhead-1 do begin
      keylist[i] = (str_sep( strtrim(hdr[i],2), ' '))[0]
   endfor

   indx = where(keyname EQ keylist, ct)
   if (ct EQ 0) then begin
      count = 0
      result = 0
   endif else begin
      count = ct
      result = 0
      for i=0, ct-1 do begin
         j = indx[i]

         ; Find the string after the keyword
         ipos = strpos(hdr[j], keylist[j]) + strlen(keylist[j])
         keystring = strtrim( strmid(hdr[j], ipos+1), 2 )

         ; Remove any comments from this string
         ipos = strpos(keystring, '#')
         if (ipos EQ 0) then keystring = '' $
          else if (ipos GT 0) then keystring = strmid(keystring, 0, ipos)

         if (strpos(keystring, "'") NE -1) then begin
            ; Type is STRING
            res = (str_sep(keystring, "'"))[1]
         endif else if (strpos(keystring, ".") NE -1) then begin
            ; Type is DOUBLE
            res = double(keystring)
         endif else begin
            ; Type is LONG
            res = long(keystring)
         endelse

         if (i EQ 0) then result = res $
          else result = [result, res]

      endfor
   endelse

   return, result
end        
;------------------------------------------------------------------------------
