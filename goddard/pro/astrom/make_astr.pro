pro make_astr,astr, CD=cd, DELTA = cdelt, CRPIX = crpix, CRVAL = crval, $
                    CTYPE = ctype, LATPOLE = LATPOLE, LONGPOLE = longpole, $ 
                    PROJP1 = projp1, PROJP2 = projp2
;+
; NAME:
;       MAKE_ASTR
; PURPOSE:
;       Build an astrometry structure from input parameter values
; EXPLANATION:
;       This structure can be subsequently placed in a FITS header with 
;       PUTAST
;
; CALLING SEQUENCE:
;       MAKE_ASTR, astr, CD = , DELT =, CRPIX =, CRVAL =, CTYPE =,
;               LATPOLE = , LONGPOLE =, PROJP1 =, PROJP2 =    
;
; OUTPUT PARAMETER:
;       ASTR - Anonymous structure containing astrometry info.  See the 
;              documentation for EXTAST for descriptions of the individual
;              tags
;
; REQUIRED INPUT KEYWORDS
;       CRPIX - 2 element vector giving X and Y coordinates of reference pixel
;               (def = NAXIS/2).  VALUES MUST BE IN FITS CONVENTION (first pixel
;               is [1,1]) AND NOT IDL CONVENTION (first pixel is [0,0]).
;       CRVAL - 2 element double precision vector giving R.A. and DEC of 
;               reference pixel in DEGREES
; OPTIONAL INPUT KEYWORDS
;       CD -  2 x 2 array containing the astrometry parameters CD1_1 CD1_2
;              in DEGREES/PIXEL                                CD2_1 CD2_2
;       DELT - 2 element vector giving physical increment at reference pixel
;              CDELT default = [1.0D, 1.0D].
;       CTYPE - 2 element string vector giving projection types, default
;              ['RA---TAN','DEC--TAN']
;       LATPOLE - Scalar latitude of the north pole, default = 0
;       LONGPOLE - scalar longitude of north pole, default = 180
;                Note that the default value of 180 is valid only for zenithal
;               projections; it should be set to PV2_1 for conic projections,
;               and zero for other projections.
;       PROJP1 - Scalar parameter needed in some projections, usually 
;                corresponding to FITS keyword PV2_1, default = 0.0
;       PROJP2 - Scalar parameter needed in some projections, usually 
;                corresponding to FITS keyword PV2_2, default = 0.0
;
; NOTES:
;       (1) An anonymous structure is created to avoid structure definition
;               conflicts.    This is needed because some projection systems
;               require additional dimensions (i.e. spherical cube
;               projections require a specification of the cube face).
;       (2) The name of the keyword for the CDELT parameter is DELT because
;               the IDL keyword CDELT would conflict with the CD keyword
;       (3) The astrometry structure definition was slightly modified in 
;               July 2003; all angles are now double precision, and the 
;               LATPOLE tag was added.
; REVISION HISTORY:
;       Written by   W. Landsman              Mar. 1994
;       Converted to IDL V5.0                 Jun  1998
;       Added LATPOLE, all angles double precision  W. Landsman July 2003
;-
 On_error,2

 if ( N_params() LT 1 ) then begin
	print,'Syntax - MAKE_ASTR, astr, CD = , DELT =, CRPIX =, CRVAL =, '
        print,'	            CTYPE =, LATPOLE= , LONGPOLE =, PROJP1= , PROJP2= ]'
	return
 endif


 if N_elements( cd ) EQ 0 then cd = [ [1.,0.], [0.,1.] ]

 if N_elements( crpix) EQ 0 then message, $
	'ERROR - CRPIX is a required keyword for a new astrometry structure'
 
 if N_elements( crval) EQ 0 then message, $
	'ERROR - CRVAL is a required keyword for a new astrometry structure'

 if N_elements( ctype)  EQ 0 then ctype = ['RA---TAN','DEC--TAN']

 if N_elements( cdelt) EQ 0 then cdelt = [1.0D, 1.0D]

 if N_elements(longpole) EQ 0 then longpole = 180.0D
 if N_elements(latpole) EQ 0 then latpole = 0.0D

 if N_elements(projp1) EQ 0 then projp1 = 0.0

 if N_elements(projp2) EQ 0 then projp2 = 0.0

 ASTR = {CD: double(cd), CDELT: double(cdelt), $
		CRPIX: float(crpix), CRVAL:double(crval), $
		CTYPE: string(ctype), LONGPOLE: double( longpole[0]),  $
		LATPOLE: double( latpole[0]), PROJP1: double(projp1[0]), $
                PROJP2: double(projp2[0])}

  return
  end
