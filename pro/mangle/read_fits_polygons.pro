;+
; NAME:
;   read_fits_polygons
; PURPOSE:
;   Read a "polygon" format fits file written by vagc, and return
;   in the IDL structure format
; CALLING SEQUENCE:
;   read_fits_polygons, infile, polygons
; INPUTS:
;   infile - input file name
; OPTIONAL INPUTS:
; OUTPUTS:
;   polygons - arrays of structures (eg those made by construct_field_polygon) 
; OPTIONAL INPUT/OUTPUTS:
; COMMENTS:
;   The main point of this is to extract the xcaps and cmcaps columns
;   and replace them with caps.x and caps.cm
; EXAMPLES:
; BUGS:
; PROCEDURES CALLED:
; REVISION HISTORY:
;   30-Nov-2002  Written by MRB (NYU)
;-
;------------------------------------------------------------------------------
pro read_fits_polygons, infile, polygons

if(NOT keyword_set(maxncaps)) then maxncaps=15

inpoly=mrdfits(infile,1)
intags=tag_names(inpoly)
cap1=construct_cap()
polygon1={caps:replicate(cap1,maxncaps)}
for i=0L, n_elements(intags)-1L do begin
    if(intags[i] ne 'XCAPS' and $
       intags[i] ne 'CMCAPS') then begin
        polygon1=create_struct(polygon1,intags[i], inpoly[0].(i))
    endif
endfor

polygons=replicate(polygon1,n_elements(inpoly))
struct_assign,inpoly,polygons
polygons.caps.x=inpoly.xcaps
polygons.caps.cm=inpoly.cmcaps

end
