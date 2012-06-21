;+
; NAME:
;   numlines() 
;
; PURPOSE:
;   Returns the number of lines in a file.
;
; CALLING SEQUENCE:
;   lines = numlines( infile )
;
; INPUT:
;   infile:      Input file name
;
; OUTPUTS:
;   lines:       Number of lines in the file.
;
; PROCEDURES CALLED:
;   FILE_LINES()
;
; NOTE:
;   This is purely a wrapper on FILE_LINES(), but
;   is retained for backwards-compatibility
;
; REVISION HISTORY:
;   Replaced numlines which has been removed from Goddard, B. A. Weaver, 2012-06-21   
;-
FUNCTION numlines, infile
    ;
    ; Need 1 parameter
    ;
    IF N_PARAMS() LT 1 THEN BEGIN
        PRINT, 'Syntax - Lines = numlines( infile )'
        RETURN, -1
    ENDIF
    MESSAGE, 'You should be using the IDL built-in FILE_LINES() instead of numlines().', /INFORMATIONAL
    RETURN, FILE_LINES(infile)
END
