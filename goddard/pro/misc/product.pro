        FUNCTION PRODUCT, ARRAY
;+
; NAME:
;       PRODUCT
; PURPOSE:
;       Calculates the product of all the elements of an array
; EXPLANATION:
;       PRODUCT() is the multiplicative equivalent of TOTAL().   
; CALLING SEQUENCE:
;       Result = PRODUCT(ARRAY)
; INPUT PARAMETERS:
;       ARRAY   = Array of elements to multiply together.  For instance, ARRAY
;                 could contain the dimensions of another array--then
;                 PRODUCT(ARRAY) would be the total number of elements of that
;                 other array.
; OUTPUT:
;       The result of the function is the total product of all the elements of
;       ARRAY.   If the input is double precision or 64bit integer, then the 
;       result will be the same; otherwise the result will be floating point.
; RESTRICTIONS:
;       ARRAY must be a numerical type.

; PROCEDURE:
;      Vector multiplication in groups of powers of two make this operation
;      faster than a simple FOR loop.  The number of actual multiplications is 
;      still N_ELEMENTS(ARRAY).  Double precision should be used for the highest
;      accuracy when multiplying many numbers.
; MODIFICATION HISTORY:
;       William Thompson, Feb. 1992.
;       Converted to IDL V5.0   W. Landsman   September 1997
;       Use vector algorithm from C. Markwardt's CMPRODUCT W. Landsman Nov. 2001   
;        
;-
;
        ON_ERROR,2
;
;  Check the number of parameters.
;
        IF N_PARAMS() NE 1 THEN MESSAGE,'Syntax:  Result = PRODUCT(ARRAY)'
;
;  Check the type of ARRAY.
;
       SZ = SIZE(ARRAY)
       TYPE = SZ[SZ[0]+1]
       IF TYPE EQ 0 THEN MESSAGE,'ARRAY not defined'
       IF TYPE EQ 7 THEN MESSAGE,'Operation illegal with string arrays'
       IF TYPE EQ 8 THEN MESSAGE,'Operation illegal with structures'
;
;  Calculate the product.    Make sure output is at least Floating pt.
;
       if (type EQ 5) or (type GE 14) then X = ARRAY ELSE X = FLOAT(ARRAY)
       N = N_ELEMENTS(X)
       WHILE N GT 1 DO BEGIN
           IF (N MOD 2) THEN X[0] = X[0] * X[N-1]
            N2 = FLOOR(N/2)
            X = X[0:N2-1] * X[N2:*]
            N = N2
        ENDWHILE
;
        RETURN, X[0]
        END
