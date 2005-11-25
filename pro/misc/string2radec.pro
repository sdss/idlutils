;+
; NAME:
;   string2radec
;
; PURPOSE:
;   Convert hours, min, sec + deg, min, sec to ra dec in floating degrees
;
; CALLING SEQUENCE:
;   string2radec, rahour, ramin, rasec, decdeg, decmin, decsec, ra, dec 
; INPUTS:
;   rahour - hours in ra (string)
;   ramin - minutes in ra (string)
;   rasec - seconds in ra (string)
;   decdeg - degrees in dec (string) 
;   decmin - arcminutes in dec (string)
;   decsec - arcseconds in dec (string)
; OUTPUTS:
;   ra - ra in degrees
;   dec - dec in degrees
; COMMENTS:
;   The sign in dec is set by the sign in "decdeg", so that you need
;   to propagate the negative in "-00" to the whole expression
;
; BUGS:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   18-Nov-2003  Michael Blanton, NYU
;-
;------------------------------------------------------------------------------
pro string2radec, rahour, ramin, rasec, decdeg, decmin, decsec, ra, dec

if(n_params() lt 6) then begin
    print, 'Syntax - string2radec, rahour, ramin, rasec, decdeg, decmin, decsec, ra, dec'
    return
endif

ra=(double(rahour)+double(ramin)/60.+double(rasec)/3600.)*360./24
dec=(abs(double(decdeg))+double(decmin)/60.+double(decsec)/3600.)
dec=(1.-2.*(stregex(decdeg,'-') ge 0))*dec

end
;------------------------------------------------------------------------------
