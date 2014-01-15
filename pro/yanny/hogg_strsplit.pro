;+
; NAME:
;   hogg_strsplit
; PURPOSE:
;   split strings on whitespace, except inside double quotes, plus other
;     stuff specialized for yanny_read
; BUGS:
;   demolishes the string
; REVISION HISTORY:
;   2002-10-10  written - Hogg
;-
PRO hogg_strsplit, string, output, count, recurse=recurse, verbose=verbose, $
    keepquote=keepquote
    ;
    IF KEYWORD_SET(verbose) THEN splog, 'splitting string >'+string+'<'
    ;
    ; Initialize unset variables, putting in first-element dummy value
    ; and splitting out comments
    ;
    IF ~KEYWORD_SET(recurse) THEN BEGIN
        output= 'NULL'
        count= 0
        string= (STRSPLIT(' '+STRCOMPRESS(string),'#',/EXTRACT))[0]
    ENDIF
    ;
    ; Do the dumbest thing, if possible
    ;
    IF (STRCOMPRESS(string,/REMOVE_ALL) EQ '') THEN RETURN
    ;
    ; Do the second-dumbest thing, if possible
    ;
    IF STREGEX(string,'[\"]') LT 0 THEN BEGIN
        pos = STREGEX(string,'\{ *\{ *\} *\}',LENGTH=len)
        IF (pos GE 0) THEN BEGIN
            string= STRMID(string,0,pos)+' "" '+STRMID(string,pos+len)
            hogg_strsplit, string, output, count, /recurse, verbose=verbose
        ENDIF ELSE BEGIN
            ;
            ; just split on spaces
            ;
            word = STRSPLIT(string, '[ ,;]+', /REGEX,/EXTRACT)
            output= [output, word]
            count = count + N_ELEMENTS(word)
        ENDELSE
    ENDIF ELSE BEGIN
        ;
        ; split on quotation marks and operate recursively
        ; Find the position and length of the first double-quoted string.
        ;
        pos = STREGEX(string,'\"([^"]*)\"',LENGTH=len)
        IF (pos GE 0) THEN BEGIN
            ;
            ; Split everyting prior to that quote, appending to OUTPUT
            ;
            hogg_strsplit, STRMID(string,0,pos), output, count, /recurse, $
                verbose=verbose
            ;
            ; Now add to that the quoted string, but excluding the quotation
            ; marks themselves. (Unless we are requested to keep the quotes).
            ;
            IF ~KEYWORD_SET(keepquote) THEN word = STRMID(string,pos+1,len-2) $
            ELSE word = STRMID(string,pos,len-1)
            output= [output, word]
            count = count + 1
            ;
            ; Finally, split everything after the quoted part,
            ; which might contain more quoted strings.
            ;
            hogg_strsplit, STRMID(string,pos+len), output, count, /recurse, $
                verbose=verbose
        ENDIF
    ENDELSE
    ;
    ; Remove first-element dummy value
    ;
    IF (~KEYWORD_SET(recurse) && (count GT 0)) THEN BEGIN
        output= output[1:count]
        IF KEYWORD_SET(verbose) THEN FOR i=0,count-1 DO PRINT, i,'>'+output[i]+'<'
    ENDIF
    RETURN
END
