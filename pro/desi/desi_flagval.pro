;+
; NAME:
;   desi_flagval
;
; PURPOSE:
;   Return bitmask values corresponding to labels.
;
; CALLING SEQUENCE:
;   value = desi_flagval(flagprefix, label)
;
; INPUTS:
;   flagprefix - Flag name (scalar string).
;   label      - String name(s) corresponding to each non-zero bit in FLAGVALUE.
;
; OPTIONAL KEYWORDS:
;
; OUTPUTS:
;   value      - Signed long with any number of its bits set.
;
; OPTIONAL OUTPUTS:
;
; COMMENTS:
;   This function is the inverse of SDSS_FLAGNAME().
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;   desi_maskbits
;
; DATA FILES:
;   $IDLUTILS_DIR/data/desi/desiMaskbits.par
;
; REVISION HISTORY:
;   16-Oct-2020 Written by D. Schlegel, LBL, based upon SDSS_FLAGVAL()
;-
;------------------------------------------------------------------------------
FUNCTION desi_flagval, flagprefix, inlabel
    ;
    ; Declare a common block so that the mask names are remembered between calls.
    ;
    COMMON com_desibits, maskbits, masktype, maskalias
    ;
    ; Usage
    ;
    IF (N_PARAMS() NE 2 OR N_ELEMENTS(flagprefix) NE 1) THEN $
        MESSAGE, 'Syntax - value = desi_flagval(flagprefix, label)'
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
    desi_maskbits
    ;
    ; Check for aliases
    ;
    aliasmatch = WHERE(STRUPCASE(flagprefix[0]) EQ STRUPCASE(maskalias.alias),ct)
    IF (ct GT 0) THEN prefix = maskalias[aliasmatch[0]].flag $
    ELSE prefix = flagprefix[0]
    ;
    ; decide the data type the answer is going to be returned in
    ;
    typematch=(WHERE(STRUPCASE(prefix) EQ STRUPCASE(masktype.flag), ct))[0]
    IF (ct EQ 0) THEN $
        MESSAGE, 'ABORT: Mask type not defined for '+prefix
    CASE masktype[typematch].datatype OF
        16: BEGIN
            flagvalue = 0
            two = 2
            END
        32: BEGIN
            flagvalue = 0L
            two = 2L
            END
        64: BEGIN
            flagvalue = 0LL
            two = 2LL
            END
        ELSE: MESSAGE, 'ABORT: Unknown datatype value ' $
            + STRTRIM(masktype[typematch].datatype,2)
    ENDCASE
    ;
    ; Find the match for each label, and add its value to the output
    ;
    FOR ilabel=0, nlabel-1 DO BEGIN
        imatch = WHERE((STRUPCASE(prefix) EQ STRUPCASE(maskbits.flag)) $
            AND (STRUPCASE(alllabel[ilabel]) EQ STRUPCASE(maskbits.label)), ct)
        IF (ct NE 1) THEN $
            MESSAGE, 'ABORT: Unknown bit label ' + STRUPCASE(alllabel[ilabel]) $
            + ' for flag ' + STRUPCASE(prefix)
        flagvalue = flagvalue + two^(maskbits[imatch[0]].bit)
    ENDFOR
    RETURN, flagvalue
END
