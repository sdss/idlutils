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
;   keyname    - Keyword name of which to find its corresponding value
;
; OPTIONAL INPUTS:
;
; OUTPUT:
;   result     - Value of parameter in header as either a string or an
;                array of strings; return '' if parameter not found
;
; OPTIONAL OUTPUTS:
;   count      - Return the number of parameters found
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

   count = 0

   if (N_params() LT 2) then begin
      print, 'Syntax - result = yanny_par(hdr, keyname, [count= ] )'
      return, ''
   endif

   nhead = N_elements(hdr)
   if (nhead EQ 0) then begin
      print, 'Header contains no elements'
      return, ''
   endif

   if (size(keyname, /tname) EQ 'UNDEFINED') then begin
      print, 'KEYNAME is undefined'
      return, ''
   endif

   keylist = strarr(nhead)
   keystring = strarr(nhead)
   for i=0, nhead-1 do begin
      keylist[i] = (str_sep( strtrim(hdr[i],2), ' '))[0]
   endfor

   ; Locate the first keyword that matches
   indx = where(keyname EQ keylist, ct)
   if (ct EQ 0) then return, ''
   j = indx[0]

   ; Find the string after the keyword
   ipos = strpos(hdr[j], keylist[j]) + strlen(keylist[j])
   keystring = strtrim( strmid(hdr[j], ipos+1), 2 )

   ; Remove any comments from this string
   ipos = strpos(keystring, '#')
   if (ipos EQ 0) then keystring = '' $
    else if (ipos GT 0) then keystring = strtrim(strmid(keystring, 0, ipos),2)

   ; If any single quote exists, then split the string by looking for
   ; everything within single quotes.
   ; Otherwise, split the string using spaces.
   if (strpos(keystring, "'") NE -1) then begin
      ; The following is a kludge to take strings between successive
      ; pairs of single quotes.

; Below is the 5.3 version ???
;      result = strsplit(keystring, "'", /extract)
;      result = result[ 2*lindgen((n_elements(result)/2) > 1) ]

; Below is the 5.2 version ???
      result = str_sep(keystring, "'")
      result = result[ 2*lindgen((n_elements(result)/2) > 1) + 1 ]

   endif else begin
; Below is the 5.3 version ???
;      result = strsplit(keystring, " ", /extract)

; Below is the 5.2 version ???
      result = str_sep(strcompress(keystring), " ")
   endelse

   ; If the result has only 1 element, then return a scalar.
   count = n_elements(result)
   if (count EQ 1) then result = result[0]

   return, result
end        
;------------------------------------------------------------------------------
