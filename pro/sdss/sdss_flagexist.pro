;+
; NAME:
;   sdss_flagexist
;
; PURPOSE:
;   Returns whether a flag exists
;
; CALLING SEQUENCE:
;   exist= sdss_flagexist(flagprefix, label, flagexist=)
;
; INPUTS:
;   flagprefix - Flag name (scalar string).  The following are supported:
;                SPPIXMASK, TARGET, TTARGET.
;   label      - String name(s) corresponding to each non-zero bit in FLAGVALUE.
;
; OUTPUTS:
;   exist - 1 if label exists for this flag (0 otherwise)
;   flagexist - 1 if this flag exists (0 otherwise)
;
; PROCEDURES CALLED:
;   sdss_maskbits
;
; DATA FILES:
;   $IDLUTILS_DIR/data/sdss/sdssMaskbits.par
;
; REVISION HISTORY:
;   2010-07-02: made by modifying sdss_flagval, MRB, NYU
;-
;------------------------------------------------------------------------------
FUNCTION sdss_flagexist, flagprefix, inlabel, flagexist=flagexist
    ;
    ; Declare a common block so that the mask names are remembered between calls.
    ;
    COMMON com_maskbits, maskbits, masktype, maskalias
    ;
    ; Usage
    ;
    IF (N_PARAMS() NE 2 OR N_ELEMENTS(flagprefix) NE 1) THEN $
        MESSAGE, 'Syntax - exist = sdss_flagexist(flagprefix, label [, flagexist=])'
    ;
    ; Generate a list of all non-blank labels as a string array
    ;
    alllabel = STRSPLIT(inlabel[0], /EXTRACT)
    FOR i=1, N_ELEMENTS(inlabel)-1 DO $
        alllabel = [alllabel, STRSPLIT(inlabel[i], /EXTRACT)]
    ilabel = WHERE(alllabel NE '', nlabel)
    IF (nlabel EQ 0) THEN RETURN, 0B
    alllabel = alllabel[ilabel]
    ;
    ; Ensure the common block is set
    ;
    sdss_maskbits
    ;
    ; Check for aliases
    ;
    aliasmatch = WHERE(STRUPCASE(flagprefix[0]) EQ STRUPCASE(maskalias.alias),ct)
    IF (ct GT 0) THEN prefix = maskalias[aliasmatch[0]].flag $
    ELSE prefix = flagprefix[0]
    ;
    ; Check the flag
    ;
    imatch=WHERE(STRUPCASE(prefix) EQ STRUPCASE(maskbits.flag), ct)
    IF (ct NE 0) THEN flagexist=1B ELSE BEGIN
        flagexist=0B
        RETURN, 0B
    ENDELSE
    ;
    ; Check the labels (only check the first label?)
    ;
    imatch = WHERE((STRUPCASE(prefix) EQ STRUPCASE(maskbits.flag)) && $
        (STRUPCASE(alllabel[0]) EQ STRUPCASE(maskbits.label)), ct)
    exist = (ct EQ 1)
    RETURN, exist
END
