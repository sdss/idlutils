;+
; NAME:
;   struct_trimtags
;
; PURPOSE:
;   Trim a structure to a list of selected and/or excluded tags
;
; CALLING SEQUENCE:
;   outstruct = struct_trimtags(instruct, [ select_tags=, except_tags= ]
;
; INPUTS:
;   instruct   - Input structure, which can be an array
;
; OPTIONAL INPUTS:
;   select_tags- List of tag names to include; this can use wildcards.
;   except_tags- List of tag names to exclude; this can use wildcards.
;
; OUTPUTS:
;   outstruct  - Ouput structure array
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   The selection based upon SELECT_TAGS is performed before excluding
;   tags based upon EXCEPT_TAGS.
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;   copy_struct
;   copy_struct_inx
;
; REVISION HISTORY:
;   05-Jun-2002  Written by D. Schlegel, Princeton
;------------------------------------------------------------------------------
function struct_trimtags, instruct, select_tags=select_tags, $
 except_tags=except_tags

   nout = n_elements(instruct)
   if (nout EQ 0) then return, 0
   if (NOT keyword_set(select_tags) AND NOT keyword_set(except_tags)) then $
    return, instruct

   tags = tag_names(instruct)
   ntag = n_elements(tags)

   ;----------
   ; Select which tags are wanted according to SELECT_TAGS.

   if (keyword_set(select_tags)) then begin
      qkeep = bytarr(ntag)
      for itag=0, ntag-1 do begin
         for jtag=0, n_elements(select_tags)-1 do begin
            if (strmatch(tags[itag], strupcase(select_tags[jtag]))) then $
             qkeep[itag] = 1B
         endfor
      endfor
   endif else begin
      qkeep = bytarr(ntag) + 1B
   endelse

   ;----------
   ; De-select which tags are excluded according to EXCEPT_TAGS.

   if (keyword_set(except_tags)) then begin
      for itag=0, ntag-1 do begin
         for jtag=0, n_elements(except_tags)-1 do begin
            if (strmatch(tags[itag], strupcase(except_tags[jtag]))) then $
             qkeep[itag] = 0B
         endfor
      endfor
   endif

   ;----------
   ; Create the output structure and copy the requested tags

   ikeep = where(qkeep, nkeep)
   if (nkeep EQ 0) then return, 0

   outstruct = create_struct(tags[ikeep[0]], instruct[0].(ikeep[0]))
   for ii=1, nkeep-1 do $
    outstruct = create_struct(outstruct, $
     tags[ikeep[ii]], instruct[0].(ikeep[ii]))

   struct_assign, {junk:0}, outstruct ; Zero-out all elements
   outstruct = replicate(outstruct, nout)
   struct_assign, instruct, outstruct

   return, outstruct
end
;------------------------------------------------------------------------------
