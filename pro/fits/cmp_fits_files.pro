;-----------------------------------------------------------------------
;+
; NAME:
;   cmp_fits_files
;
; PURPOSE:
;   Compare the contents of two FITS files.
;
; CALLING SEQUENCE:
;   cmp_fits_files, filename1, filename2, [ /verbose ]
;
; INPUTS:
;   filename1 - First FITS file
;   filename2 - Second FITS file
;
; OPTIONAL INPUTS:
;   verbose   - If set, then report extensions that are the same, as
;               well as reporting any differences
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   All HDUs are compared, both images and structures.
;   Report a warning if the variable type is different, for example if
;     one file contains a structure and the other an image, or if one
;     contains an integer image and the other a floating-point image.
;   For images, report a warning if the number of array elements disagree,
;     or if any values disagree.
;   For structures, report a warning if the number of structure tags disagree,
;     or if any values disagree.
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;   mrdfits()
;   splog
;
; REVISION HISTORY:
;   06-Nov-2003  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------
pro cmp_fits_files, filename1, filename2, verbose=verbose

   ; Need at least 2 parameters
   if (N_params() LT 2) then begin
      print, 'Syntax - cmp_fits_files, filename1, filename2, [ /verbose ]'
      return
   endif

   ;----------
   ; Loop over each extension until done

   exten = 0L
   data1 = mrdfits(filename1, exten, status=stat1, /silent)
   data2 = mrdfits(filename2, exten, status=stat2, /silent)
   while (stat1 GE 0 AND stat2 GE 0) do begin
      if (size(data1, /tname) NE size(data2, /tname)) then begin
         splog, 'Extension ', exten, ' differs in variable type'
      endif else if (size(data1, /tname) EQ 'STRUCT') then begin
         tags = tag_names(data1)
         if (n_tags(data1) NE n_tags(data2)) then begin
            splog, 'Extension ', exten, ' differs in number of tags'
         endif else begin
            for itag=0L, n_tags(data1)-1 do begin
               junk = where(data1.(itag) NE data2.(itag), nbad)
               if (nbad GT 0) then $
                splog, 'Extension ', exten, ' tag=', tags[itag], $
                 ' differs for ', nbad, ' elements' $
               else $
                if (keyword_set(verbose)) then $
                 splog, 'Extension ', exten, ' tag=', tags[itag], ' is the same'
            endfor
         endelse
      endif else begin
         if (n_elements(data1) NE n_elements(data2)) then begin
            splog, 'Extension ', exten, ' differs in number of elements'
         endif else begin
            junk = where(data1 NE data2, nbad)
            if (nbad GT 0) then $
             splog, 'Extension ', exten, ' differs for ', nbad, ' elements' $
            else $
             if (keyword_set(verbose)) then $
              splog, 'Extension ', exten, ' is the same'
         endelse
      endelse

      exten = exten + 1
      data1 = mrdfits(filename1, exten, status=stat1, /silent)
      data2 = mrdfits(filename2, exten, status=stat2, /silent)
   endwhile

   return
end 
;------------------------------------------------------------------------------
