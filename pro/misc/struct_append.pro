;+
; NAME:
;   struct_append
;
; PURPOSE:
;   Append more array elements to a structure.
;
; CALLING SEQUENCE:
;   outstruct = struct_append( struct1, struct2 )
;
; INPUTS:
;   struct1    - First structure; the output structure will match the tags
;                in this, and match the name if it's a named structure.
;   struct2    - Second structure to append to the first.
;
; OPTIONAL INPUTS:
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   If either structure is undefined, then return the other one only.
;
; EXAMPLES:
;   > a={one:1,two:2}
;   > b={one:11,three:33}
;   > print,struct_append(a,b)
;     {       1       2}{      11       0}
;
; BUGS:
;
; PROCEDURES CALLED:
;   headfits()
;
; REVISION HISTORY:
;   26-Jun-2000  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------
function struct_append, struct1, struct2

   if (NOT keyword_set(struct1) AND NOT keyword_set(struct2)) then $
    return, 0
   if (NOT keyword_set(struct1)) then return, struct2
   if (NOT keyword_set(struct2)) then return, struct1

   num1 = n_elements(struct1)
   num2 = n_elements(struct2)

   obj1 = struct1[0]
   outstruct = replicate(obj1, num1+num2)
   outstruct[0:num1-1] = struct1[*]
   for irow=0L, num2-1 do begin
      struct_assign, struct2[irow], obj1
      outstruct[num1+irow] = obj1
   endfor

   return, outstruct
end
;------------------------------------------------------------------------------
