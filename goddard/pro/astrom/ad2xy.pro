pro ad2xy, a, d, astr, x, y
;+
; NAME:
;     AD2XY
; PURPOSE:
;     Compute X and Y from  RA and DEC and a FITS  astrometry structure
; EXPLANATION:
;     The procedure WCSXY2SPH is used to compute native coordinates, and the 
;     inverse of the CD matrix is applied to obtain X and Y. AD2XY is meant to
;     be used internal to other procedures.   For interactive purposes, use ADXY.
;
; CALLING SEQUENCE:
;     AD2XY, a ,d, astr, x, y   
;
; INPUTS:
;     A -     R.A. in DEGREES, scalar or vector
;     D -     Dec. in DEGREES, scalar or vector
;     ASTR - astrometry structure, output from EXTAST procedure containing:
;        .CD   -  2 x 2 array containing the astrometry parameters CD1_1 CD1_2
;               in DEGREES/PIXEL                                   CD2_1 CD2_2
;        .CDELT - 2 element vector giving increment at reference point in
;               DEGREES/PIXEL
;        .CRPIX - 2 element vector giving X and Y coordinates of reference pixel
;               (def = NAXIS/2) in FITS convention (first pixel is 1,1)
;        .CRVAL - 2 element vector giving R.A. and DEC of reference pixel 
;               in DEGREES
;        .CTYPE - 2 element vector giving projection types 
;        .LONGPOLE - scalar longitude of north pole (default = 180) 
;        .PROJP1 - Scalar parameter needed in some projections
;        .PROJP2 - Scalar parameter needed in some projections
;;
; OUTPUTS:
;     X     - row position in pixels, scalar or vector
;     Y     - column position in pixels, scalar or vector
;
;     X,Y will be in the standard IDL convention (first pixel is 0), and
;     *not* the FITS convention (first pixel is 1)         
; REVISION HISTORY:
;     Converted to IDL by B. Boothman, SASC Tech, 4/21/86
;     Use astrometry structure,  W. Landsman      Jan. 1994   
;     Do computation correctly in degrees  W. Landsman       Dec. 1994
;     Only pass 2 CRVAL values to WCSSPH2XY   W. Landsman      June 1995
;     Don't subscript CTYPE      W. Landsman       August 1995        
;     Converted to IDL V5.0   W. Landsman   September 1997
;     Understand reversed X,Y (X-Dec, Y-RA) axes,   W. Landsman  October 1998
;     Consistent conversion between CROTA and CD matrix W. Landsman October 2000
;     No special case for tangent projection W. Landsman June 2003
;-
 On_error,2

 if N_params() lT 4 then begin
        print,'Syntax -- AD2XY, a, d, astr, x, y'
        return
 endif

 radeg = 180.0D/!DPI                 ;Double precision !RADEG
 ctype = astr.ctype
 crval = astr.crval

 coord = strmid(ctype,0,4)
 reverse = ((coord[0] EQ 'DEC-') and (coord[1] EQ 'RA--')) or $
           ((coord[0] EQ 'GLAT') and (coord[1] EQ 'GLON')) or $
           ((coord[0] EQ 'ELAT') and (coord[1] EQ 'ELON'))
 if reverse then crval = rotate(crval,2)        ;Invert CRVAL?

 if (ctype[0] EQ '') then begin   
      ctype = ['RA---TAN','DEC--TAN']
      message,'No CTYPE specified - assuming TANgent projection',/INF
 endif      
     
  wcssph2xy, a, d, xsi, eta, CTYPE = ctype, PROJP1 = astr.projp1, $
        PROJP2 = astr.projp2, LONGPOLE = astr.longpole, CRVAL = crval, $
        LATPOLE = astr.latpole

  cd = astr.cd
  cdelt = astr.cdelt

  if cdelt[0] NE 1.0 then begin
         cd[0,0] = cd[0,0]*cdelt[0] & cd[0,1] = cd[0,1]*cdelt[0]
         cd[1,1] = cd[1,1]*cdelt[1] & cd[1,0] = cd[1,0]*cdelt[1]
     endif

 if reverse then begin
     temp = xsi &  xsi = eta & eta = temp
 endif

 crpix = astr.crpix
 cdinv = invert(cd)
 x = ( cdinv[0,0]*xsi + cdinv[0,1]*eta + crpix[0] - 1 )
 y = ( cdinv[1,0]*xsi + cdinv[1,1]*eta + crpix[1] - 1 )

 return
 end
