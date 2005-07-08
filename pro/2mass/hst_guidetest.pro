;------------------------------------------------------------------------------
;+
; NAME:
;   hst_guidetest
;
; PURPOSE:
;   Match a list of potential HST guide stars against the 2MASS catalog
;
; CALLING SEQUENCE:
;   hst_guidetest, filename, [ searchrad=, select_tags= ]
;
; INPUTS:
;   filename   - Input ASCII file name with at least 3 columns:
;                name, RA, Dec (where the coordinates are in degrees)
;
; OPTIONAL INPUTS:
;   search_rad - Search radius between input coorinates and 2MASS;
;                default to 5./3600 degrees
;   select_tags- Names of tags to print
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   The output ADIFF is the distance between the coordinates in arcsec.
;
;   Refer to the following 2MASS documentation for a description
;   of the 2MASS data structure:
;     http://tdc-www.harvard.edu/software/catalogs/tmc.format.html
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   09-Jul-2005  Written by D. Schlegel, LBL
;-
;------------------------------------------------------------------------------
pro hst_guidetest, filename, searchrad=searchrad, select_tags=select_tags

   if (NOT keyword_set(filename)) then begin
      print, 'Syntax - hst_guidetest, filename, [searchrad=, select_tags=]'
      return
   endif
   if (NOT keyword_set(searchrad)) then searchrad = 5./3600
   if (NOT keyword_set(select_tags)) then $
    select_tags = ['NAME', 'ADIFF', 'TMASS_PH_QUAL', $
     'TMASS_BL_FLG', 'TMASS_CC_FLG', 'TMASS_GAL_CONTAM', 'TMASS_MP_FLG', $
     'TMASS_USE_SRC']

   readcol, filename, name, radeg, decdeg, format='(a,d,d)'
   nstar = n_elements(radeg)
   for istar=0L, nstar-1L do begin
      obj1 = tmass_read(radeg[istar], decdeg[istar], searchrad)
      if (NOT keyword_set(objs)) then begin
         blankobj = obj1
         struct_assign, {junk:0}, blankobj
         objs = replicate(blankobj, nstar)
      endif
      objs[istar] = obj1
   endfor

   ; Prepend NAME,ADIFF to the structure
   adiff = djs_diff_angle(radeg, decdeg, objs.tmass_ra, objs.tmass_dec) * 3600.
   addtags = replicate(create_struct('NAME', '', 'ADIFF', 0.), nstar)
   addtags.name = name
   addtags.adiff = adiff
   objs = struct_addtags(addtags, objs)

   printobj = struct_selecttags(objs, select_tags=select_tags)
   ; Strip '2MASS_' from the beginning of the tag names for printing purposes
   alias = strarr(2,n_elements(select_tags))
   alias[0,*] = select_tags
   alias[1,*] = repstr(select_tags, 'TMASS_', '')
   struct_print, printobj, alias=alias

   return
end
;------------------------------------------------------------------------------
