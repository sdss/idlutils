;+
; NAME:
;   write_fits_polygons
; PURPOSE:
;   Write a "polygon" format fits file from the IDL format
; CALLING SEQUENCE:
;   write_fits_polygons, outfile, polygons
; INPUTS:
;   outfile - output file name
;   polygons - arrays of structures (eg those made by construct_field_polygon) 
; OPTIONAL INPUTS:
; OUTPUTS:
; OPTIONAL INPUT/OUTPUTS:
; COMMENTS:
;   The main point of this is to replace caps.x and caps.cm with 
;   xcaps and cmcaps columns
; EXAMPLES:
; BUGS:
; PROCEDURES CALLED:
; REVISION HISTORY:
;   03-Dec-2002  Written by MRB (NYU)
;-
;------------------------------------------------------------------------------
pro write_fits_polygons, outfile, polygons, hdr=hdr

tags=tag_names(polygons)
poly1=construct_polygon()
outpoly1={xcaps:poly1.caps.x, cmcaps:poly1.caps.cm}
for i=0L, n_elements(tags)-1L do begin
    if(tags[i] ne 'CAPS') then $ 
      outpoly1=create_struct(outpoly1,tags[i], polygons[0].(i))
endfor

outpoly=replicate(outpoly1,n_elements(polygons))
struct_assign,polygons,outpoly
outpoly.xcaps=polygons.caps.x
outpoly.cmcaps=polygons.caps.cm

sxaddpar,hdr,'SDSSGA_T',systime(),'Time of creation of polygon fits file'
sxaddpar,hdr,'VAGC_VER',vagc_version(),'Version of vagc used'
mwrfits,0,outfile,hdr,/create
mwrfits,outpoly,outfile


end
