;+
; NAME:
;   print_maskbits
;
; PURPOSE:
;   Print the maskbits table for debugging purposes.
;
; CALLING SEQUENCE:
;   print_maskbits, [flagprefix], [/alias]
;
; INPUTS:
;   flagprefix - Flag name (scalar string).  If not set, everything will
;                be printed.
;
; OPTIONAL INPUTS:
;   alias      - If set, print any aliases associated with the flagprefix.
;
; PROCEDURES CALLED:
;   sdss_maskbits
;
; DATA FILES:
;   $IDLUTILS_DIR/data/sdss/sdssMaskbits.par
;
; REVISION HISTORY:
;   2014-03-27: written, BAW, NYU
;-
PRO print_maskbits, flagprefix, alias=alias
    ;
    ; Declare a common block so that the mask names are remembered between calls.
    ;
    COMMON com_maskbits, maskbits, masktype, maskalias
    ;
    ; Ensure the common block is set
    ;
    sdss_maskbits
    ;
    ;
    ;
    table = ['']
    IF KEYWORD_SET(flagprefix) THEN BEGIN
        ;
        ; Check for aliases
        ;
        aliasmatch = WHERE(STRUPCASE(flagprefix[0]) EQ STRUPCASE(maskalias.alias),ct)
        IF (ct GT 0) THEN BEGIN
            prefix = maskalias[aliasmatch[0]].flag
            IF KEYWORD_SET(alias) THEN $
                table = [table, STRUPCASE(flagprefix[0]) + ' is an alias for ' $
                + STRUPCASE(prefix) + '.']
        ENDIF ELSE prefix = flagprefix[0]
        w = WHERE(maskbits.flag EQ prefix,ct)
        FOR i = 0, ct-1 DO BEGIN
            PRINT, maskbits[w].label[i], maskbits[w].bit[i], maskbits[w].description[i]
        ENDFOR
    ENDIF
END
