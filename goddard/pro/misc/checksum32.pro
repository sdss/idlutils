pro checksum32, array, checksum
;+
; NAME:
;       CHECKSUM32
;
; PURPOSE:
;       To compute the 32bit checksum of an array (ones-complement arithmetic)
;
; EXPLANATION:
;       The 32bit checksum is adopted in the FITS Checksum convention
;       http://www.cv.nrao.edu/fits/documents/proposals/checksum/
;
; CALLING SEQUENCE:
;       CHECKSUM32, array, checksum
;
; INPUTS:
;       array - any idl array.   The number of bytes in the array must be a
;               multiple of four.
;
; OUTPUTS:
;       checksum - unsigned long scalar, giving sum of array elements using 
;                  ones-complement arithmetic
; METHOD:
;       Uses TOTAL() to sum the array into a double precision variable.  The
;       overflow bits beyond 2^32 are then shifted back to the least significant
;       bits.    Due to the limited precision of a DOUBLE variable, the summing
;       is done in chunks determined by MACHAR(). Adapted from FORTRAN code in
;      heasarc.gsfc.nasa.gov/docs/heasarc/ofwg/docs/general/checksum/node30.html
;
;      Could probably be done in a cleverer way (similar to the C
;      implementation) but then the array-oriented TOTAL() function could not 
;      be used.
; RESTRICTIONS:
;       (1) Requires V5.1 or later (uses unsigned integers)
;       (2) Not valid for object or pointer data types
;
; FUNCTION CALLED:
;       N_BYTES()
; MODIFICATION HISTORY:
;       Written    W. Landsman          June 2001
;-
 if N_params() LT 2 then begin
      print,'Syntax - CHECKSUM32, array, checksum'
      return
 endif
 N = N_bytes(array)
 if (N mod 4) NE 0 then message, $
     'ERROR - Number of bytes in supplied array must be a multiple of 4'

; Get maximum number of base 2 digits available in double precision, and 
; compute maximum number of longword values that can be coadded without losing
; any precision.

 str = machar(/double)
 maxnum = 2L^(str.it-33)          
 Niter =  (N-1)/maxnum
 checksum = 0.d0
  word32 =  2.d^32

 for i=0, Niter do begin

   if i EQ Niter then begin 
           nbyte = (N mod maxnum) 
           if nbyte EQ 0 then nbyte = maxnum
   endif else nbyte = maxnum
   checksum = checksum + total(ulong( array,maxnum*i,nbyte/4), /double)
 
; Fold any overflow bits beyond 32 back into the word.

   hibits = long(checksum/word32)
   while hibits GT 0 do begin
     checksum = checksum - (hibits*word32) + hibits    
     hibits = long(checksum/word32)
  endwhile

   checksum = ulong(checksum)

 endfor

 return
 end
