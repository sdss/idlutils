;+
; NAME:
;   wise_match
;
; PURPOSE:
;   Match a set of RA/Decs to WISE
;
; CALLING SEQUENCE:
;   wise_match, ra, dec, [ tol=, match=, imatch=, nmatch=, columns=, /fill ]
;
; INPUTS:
;   ra         - RA coordinate(s) in deg [N]
;   dec        - Dec coordinate(s) in deg [N]
;
; OPTIONAL INPUTS:
;   tol        - Matching radius in arcsec; default to 6 arcsec
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;   match      - Structure with catalog matches [Nmatch, or N if /FILL set]
;   imatch     - Index in RA/Dec list of corresponding objects in MATCH
;                [Nmatch, or N if /FILL set]
;   nmatch     - Number of matches
;
; COMMENTS:
;
; EXAMPLES:
;
; BUGS:
;    All string values are blank-padded to the same length for each tag,
;      even if it should be a NULL entry.
;    NULL entries for floating-point values are returned as NaN.
;    NULL entries for integer-values are returned as 0.
;
; DATA FILES:
;      $WISE_DIR/fits/wise-allsky-cat-part??.fits
;      $WISE_DIR/fits/wise-allsky-cat-part??-radec.fits
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   18-Apr-2012  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
pro wise_match, ra, dec, tol=tol1, match=match, imatch=imatch, nmatch=nmatch, $
 fill=fill, _EXTRA=KeywordsForMRDFITS

   common com_wise_match, decrange1, decrange2

   if (n_elements(ra) EQ 0 OR n_elements(ra) NE n_elements(dec)) then $
    message, 'RA, DEC must be set and have equal number of values'
   topdir = getenv('WISE_DIR')
   if (NOT keyword_set(topdir)) then $
    message, 'WISE_DIR must be set'
   if (n_elements(tol1) NE 0) then tol = tol1 $
    else tol = 6.
   dtol = tol[0] / 3600.

   if (NOT keyword_set(decrange1)) then begin
      readfmt, top_dir+'/wise-allsky-cat-dec-ranges.txt', $
       '6X,F10.6,14X,F10.6', decrange1, decrange2
      if (NOT keyword_set(decrange1)) then $
       message, 'Error reading Dec ranges'
   endif



   return
end
