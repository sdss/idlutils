;+
; NAME:
;   hogg_strsplit
; PURPOSE:
;   split strings on whitespace, except inside double quotes
; REVISION HISTORY:
;   2002-10-10  written - Hogg
;-
pro hogg_strsplit, string, output, count, recurse=recurse, verbose=verbose

   ; Initialize unset variables, putting in first-element dummy value
   if (NOT keyword_set(recurse)) then output = 'NULL'
   if (n_elements(output) EQ 1) then count = 0

   ; Do the dumbest thing, if possible
   if (strcompress(string,/remove_all) EQ '') then return

   if stregex(string,'\"') LT 0 then begin
      word = strsplit(strcompress(string), ' ', /extract)
      output= [output, word]
      count = count + n_elements(word)
   endif else begin
      ; split on quotation marks and operate recursively
      ; Find the position and length of the first double-quoted string.
      pos = stregex(string,'\"([^"]*)\"',length=len)
      if (pos GE 0) then begin
        ; Split everyting prior to that quote, appending to OUTPUT
        hogg_strsplit, strmid(string,0,pos), output, count, /recurse

        ; Now add to that the quoted string, but excluding the quotation
        ; marks themselves.
        word = strmid(string,pos+1,len-2)
        output= [output, word]
        count = count + 1

        ; Finally, split everything after the quoted part,
        ; which might contain more quoted strings.
        hogg_strsplit, strmid(string,pos+len), output, count, /recurse
      endif
   endelse

   ; Remove first-element dummy value
   if keyword_set(verbose) then for i=0,count do print, i,'>'+output[i]+'<'
   if (NOT keyword_set(recurse)) AND (count GT 0) then output= output[1:count]
   return
end
