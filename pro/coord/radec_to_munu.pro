;+
; NAME:
;   munu_to_radec
;
; PURPOSE:
;   Convert from equatorial coordinates to SDSS great circle coordinates.
;
; CALLING SEQUENCE:
;   radec_to_munu, ra, dec, mu, nu, [ stripe=, node=, incl= ]
;
; INPUTS:
;   ra         - Right ascension (J2000 degrees)
;   dec        - Declination (J2000 degrees)
;
; OPTIONAL INPUTS:
;   stripe     - Stripe number for SDSS coordinate system.  If specified,
;                the NODE,INCL are ignored; scalar or array with same
;                dimensions as MU.
;   node       - Node of great circle on the J2000 celestial equator (degrees),
;                scalar or array with same dimensions as MU.
;   incl       - Inclination of great circle relative to the J2000
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS:
;   mu         - Mu coordinate, scalar or array (degrees)
;   nu         - Nu coordinate, scalar or array (degrees)
;
; COMMENTS:
;   Either STRIPE or NODE,INCL must be specified.
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;   cirrange
;   stripe_to_incl()
;
; REVISION HISTORY:
;   20-Feb-2002  Written by M. Blanton, NYU
;   03-Oct-2002  Modified by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------
pro radec_to_munu, ra, dec, mu, nu, stripe=stripe, node=node, incl=incl

   if (n_params() NE 4) then $
    message, 'Wrong number of parameters'

   if (keyword_set(stripe)) then begin
      node = 95.d
      incl = stripe_to_incl(stripe)
   endif else begin
      if (n_elements(node) NE 1 AND n_elements(incl) NE 1) then $
       message, 'Must specify either STRIPE or NODE,INCL'
   endelse
   if (n_elements(ra) NE n_elements(dec)) then $
    message, 'Number of elements in RA and DEC must agree'

   r2d = 180.d / !dpi
   d2r = !dpi / 180.d

   if (n_elements(node) NE 1 OR n_elements(incl) NE 1) then begin
      node = 95.d
      incl = stripe_to_incl(stripe)
   endif

   x1 = cosdec * cosra
   y1 = cosdec * sinra
   z1 = sindec
   x2 = x1
   y2 = y1 * cosi + z1 * sini
   z2 = -y1 * sini + z1 * cosi
   mu = r2d * atan(y2,x2) + node
   nu = r2d * asin(z2)
   cirrange, mu

   return
end
;------------------------------------------------------------------------------
