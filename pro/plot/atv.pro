;+
; NAME:
;       ATV
; 
; PURPOSE: 
;       Interactive display of 2-D images.
;
; CATEGORY: 
;       Image display.
;
; CALLING SEQUENCE:
;       atv [,array_name] [,min = min_value] [,max=max_value] 
;           [,/autoscale] [,/linear] [,/log] [,/histeq] 
;
; REQUIRED INPUTS:
;       None.  If atv is run with no inputs, the window widgets
;       are realized and images can subsequently be passed to atv
;       from the command line or from the pull-down file menu.
;
; OPTIONAL INPUTS:
;       array_name: a 2-D data array to display
;
; KEYWORDS:
;       min:        minimum data value to be mapped to the color table
;       max:        maximum data value to be mapped to the color table
;       autoscale:  set min and max to show a range of data values
;                   around the median value
;       linear:     use linear stretch
;       log:        use log stretch 
;       histeq:     use histogram equalization
;       
; OUTPUTS:
;       None.  
; 
; COMMON BLOCKS:
;       atv_state:  contains variables describing the display state
;       atv_images: contains the internal copies of the display image
;       atv_color:  contains colormap vectors
;
; RESTRICTIONS:
;       Requires the GSFC IDL astronomy library routines,
;       for fits input.
;       The current version only works with 8-bit color.
;       For a current list of atv's bugs and weirdnesses, go to
;              http://cfa-www.harvard.edu/~abarth/atv/atv.html
;
; SIDE EFFECTS:
;       Modifies the color table.
;
; EXAMPLE: 
;       To start atv running, just enter the command 'atv' at the
;       idl prompt, either with or without an array name as an input.
;       Only one atv window will be created at a time, so if one
;       already exists and another image is passed to atv from the
;       idl command line, the new image will be displayed in the
;       pre-existing atv window.
;
; MODIFICATION HISTORY:
;       Written by Aaron J. Barth, first release 17 December 1998.
;       This version is 1.0b3, last modified 08 June 1998.
;       For the most current version, revision history, and further 
;       information, go to:
;              http://cfa-www.harvard.edu/~abarth/atv/atv.html
;-
;----------------------------------------------------------------------


pro atv_startup

; This routine initializes the atv internal variables, and creates and
; realizes the window widgets.  It is only called by the atv main
; program level, when there is no previously existing atv window.

common atv_state, state
common atv_images, $
  main_image, $
  display_image, $
  scaled_image, $
  blink_image, $
  pan_image
common atv_color, r_vector, g_vector, b_vector

state = {                   $
          base_id: 0L, $                 ; id of top-level base
          base_min_size: [512L, 512L], $ ; min size for top-level base
          draw_base_id: 0L, $            ; id of base holding draw window
          draw_window_id: 0L, $          ; window id of draw window
          draw_widget_id: 0L, $          ; widget id of draw widget
          track_window_id: 0L, $         ; widget id of tracking window
          pan_window_id: 0L, $           ; widget id of pan window
          location_bar_id: 0L, $         ; id of (x,y,value) label
          min_text_id: 0L,  $            ; id of min= widget
          max_text_id: 0L, $             ; id of max= widget
          menu_ids: lonarr(19), $        ; list of top menu items
          brightness_slider_id: 0L, $    ; id of brightness widget
          contrast_slider_id: 0L, $      ; id of contrast widget
          keyboard_text_id: 0L, $        ; id of keyboard input widget
          image_min: 0.0, $              ; min(main_image)
          image_max: 0.0, $              ; max(main_image)
          min_value: 0.0, $              ; min data value mapped to colors
          max_value: 0.0, $              ; max data value mapped to colors
          mode: 'zoom', $                ; zoom or blink
          draw_window_size: [512L, 512L], $    ; size of main draw window
          track_window_size: 121L, $     ; size of tracking window
          pan_window_size: 121L, $       ; size of pan window
          pan_scale: 0.0, $              ; magnification of pan image
          image_size: [0L,0L], $         ; size of main_image
          invert_colormap: 0L, $         ; 0=normal, 1=inverted
          mouse: [0L, 0L],  $            ; cursor position in image coords
          scaling: 0L, $                 ; 0=linear, 1=log, 2=histeq
          offset: [0L, 0L], $            ; offset to viewport coords
          base_pad: [0L, 0L], $          ; padding around draw base
          pad: [0L, 0L], $               ; padding around draw widget
          zoom_level: 0L, $              ; integer zoom level, 0=normal
          zoom_factor: 1.0, $            ; magnification factor = 2^zoom_level
          centerpix: [0L, 0L], $         ; pixel at center of viewport
          pan_track: 0L, $               ; flag=1 while mouse dragging
          pan_offset: [0L, 0L], $        ; image offset in pan window
          lineplot_widget_id: 0L, $      ; id of lineplot widget
          lineplot_window_id: 0L, $      ; id of lineplot window
          lineplot_base_id: 0L, $        ; id of lineplot top-level base
          lineplot_size: [600L, 450L], $ ; size of lineplot window
          lineplot_pad: [0L, 0L], $      ; padding around lineplot window
          cursorpos: lonarr(2), $        ; cursor x,y for photometry
          centerpos: fltarr(2), $        ; centered x,y for photometry
          cursorpos_id: 0L, $            ; id of cursorpos widget
          centerpos_id: 0L, $            ; id of centerpos widget
          centerbox_id: 0L, $            ; id of centeringboxsize widget
          radius_id: 0L, $               ; id of radius widget
          innersky_id: 0L, $             ; id of inner sky widget
          outersky_id: 0L, $             ; id of outer sky widget
          skyresult_id: 0L, $            ; id of sky widget
          photresult_id: 0L, $           ; id of photometry result widget
          centerboxsize: 11L, $          ; centering box size
          r: 5L, $                       ; aperture photometry radius
          innersky: 10L, $               ; inner sky radius
          outersky: 20L $                ; outer sky radius
        }

; Read in a color table to initialize !d.table_size
loadct, 0, /silent

; Define the widgets.  For the widgets that need to be modified later
; on, save their widget ids in state variables

base = widget_base(title = 'atv', $
                   /column, /base_align_right, $
                   app_mbar = top_menu, $
                   uvalue = 'atv_base', $
                   /tlb_size_events)
state.base_id = base

tmp_struct = {cw_pdmenu_s, flags:0, name:''}

top_menu_desc = [ $
                  {cw_pdmenu_s, 1, 'File'}, $         ; file menu
                  {cw_pdmenu_s, 0, 'ReadFits'}, $
                  {cw_pdmenu_s, 0, 'WriteEPS'},  $
                  {cw_pdmenu_s, 0, 'WriteTiff'}, $
                  {cw_pdmenu_s, 2, 'Quit'}, $
                  {cw_pdmenu_s, 1, 'ColorMap'}, $     ; color menu
                  {cw_pdmenu_s, 0, 'Grayscale'}, $
                  {cw_pdmenu_s, 0, 'Blue-White'}, $
                  {cw_pdmenu_s, 0, 'Red-Orange'}, $
                  {cw_pdmenu_s, 0, 'Rainbow'}, $
                  {cw_pdmenu_s, 0, 'BGRY'}, $
                  {cw_pdmenu_s, 2, 'ATV Special'}, $
                  {cw_pdmenu_s, 1, 'Scaling'}, $      ; scaling menu
                  {cw_pdmenu_s, 0, 'Linear'}, $
                  {cw_pdmenu_s, 0, 'Log'}, $
                  {cw_pdmenu_s, 2, 'HistEq'}, $
                  {cw_pdmenu_s, 1, 'Help'}, $
                  {cw_pdmenu_s, 2, 'ATV Help'} $
                ]

top_menu = cw_pdmenu(top_menu, top_menu_desc, $
                     ids = state.menu_ids, $
                     /mbar, $
                     /help, $
                     /return_id, $
                     uvalue = 'top_menu')

track_base =    widget_base(base, /row)
track_base_1 =  widget_base(track_base, /column, /align_right)
track_base_1a = widget_base(track_base_1, /row, /align_bottom)
slider_base =   widget_base(track_base_1a, /column, /align_right)
minmax_base =   widget_base(track_base_1a, /column, /align_right)
track_base_2 =  widget_base(track_base, /row, /base_align_bottom)
button_base1 =  widget_base(base, /row, /base_align_bottom)
button_base2 =  widget_base(base, /row, /base_align_bottom)
mode_base =     widget_base(button_base1, /row, /base_align_bottom, /exclusive)

state.draw_base_id = $
  widget_base(base, $
              /column, /base_align_left, $
              /tracking_events, $
              uvalue = 'draw_base', $
              frame = 2)

state.brightness_slider_id = $
  widget_slider(slider_base, $
                /drag, $
                minimum = 0, $
                maximum = 2 * !d.table_size - 1, $
                title = 'Brightness', $
                uvalue = 'brightness', $
                value = !d.table_size, $
                /suppress_value)


state.contrast_slider_id = $
  widget_slider(slider_base, $
                /drag, $
                minimum = 0, $
                maximum = 100, $
                title = 'Contrast', $
                uvalue = 'contrast', $
                value = 50, $
                /suppress_value)

zoommode_button = $
  widget_button(mode_base, $
                value = 'ZoomMode', $
                uvalue = 'zoom_mode')

blinkmode_button = $
  widget_button(mode_base, $
                value = 'BlinkMode', $
                uvalue = 'blink_mode')

invert_button = $
  widget_button(button_base1, $
                value = 'Invert', $
                uvalue = 'invert')

reset_button = $
  widget_button(button_base1, $
                value = 'ResetColor', $
                uvalue = 'reset_color')

autoscale_button = $
  widget_button(button_base1, $
                uvalue = 'autoscale_button', $
                value = 'AutoScale')

fullrange_button = $
  widget_button(button_base1, $
                uvalue = 'full_range', $
                value = 'FullRange')

state.keyboard_text_id = $
  widget_text(button_base2, $
              /all_events, $
              scr_xsize = 1, $
              scr_ysize = 1, $
              units = 0, $
              uvalue = 'keyboard_text', $
              value = '')

zoomin_button = $
  widget_button(button_base2, $
                value = 'ZoomIn', $
                uvalue = 'zoom_in')

zoomout_button = $ 
  widget_button(button_base2, $
                value = 'ZoomOut', $
                uvalue = 'zoom_out')

zoomone_button = $
  widget_button(button_base2, $
                value = 'Zoom1', $
                uvalue = 'zoom_one')

center_button = $
  widget_button(button_base2, $
                value = 'Center', $
                uvalue = 'center')

setblink_button = $
  widget_button(button_base2, $
                uvalue = 'set_blink', $
                value = 'SetBlink')

done_button = $
  widget_button(button_base2, $
                value = 'Done', $
                uvalue = 'done')

state.min_text_id = $
  cw_field(minmax_base, $
           uvalue = 'min_text', $
           /floating,  $
           title = 'Min=', $
           value = state.min_value,  $
           /return_events, $
           xsize = 8)

state.max_text_id = $
  cw_field(minmax_base, $
           uvalue = 'max_text', $
           /floating,  $
           title = 'Max=', $
           value = state.max_value, $
           /return_events, $
           xsize = 8)

tmp_string = string(1000, 1000, 1.0e-10, $
                    format = '("(",i4,",",i4,") ",g12.5)' )

state.location_bar_id = $
  widget_label (track_base_1, $
                value = tmp_string,  $
                uvalue = 'location_bar',  frame = 1)

pan_window = $
  widget_draw(track_base_2, $
              xsize = state.pan_window_size, $
              ysize = state.pan_window_size, $
              frame = 2, uvalue = 'pan_window', $
              /button_events, /motion_events)

track_window = $
  widget_draw(track_base_2, $
              xsize=state.track_window_size, $
              ysize=state.track_window_size, $
              frame=2, uvalue='track_window')

state.draw_widget_id = $
  widget_draw(state.draw_base_id, $
              uvalue = 'draw_window', $
              /motion_events,  /button_events, $
              scr_xsize = state.draw_window_size[0], $
              scr_ysize = state.draw_window_size[1]) 

; Create the widgets on screen

widget_control, base, /realize

widget_control, zoommode_button, /set_button

; get the window ids for the draw widgets

widget_control, track_window, get_value = tmp_value
state.track_window_id = tmp_value
widget_control, state.draw_widget_id, get_value = tmp_value
state.draw_window_id = tmp_value
widget_control, pan_window, get_value = tmp_value
state.pan_window_id = tmp_value

; Find window padding sizes needed for resizing routines.
; Add extra padding for menu bar, since this isn't included in 
; the geometry returned by widget_info.
; Also add extra padding for margin (frame) in draw base.

basegeom = widget_info(state.base_id, /geometry)
drawbasegeom = widget_info(state.draw_base_id, /geometry)

state.pad[0] = basegeom.xsize - state.draw_window_size[0] 
state.pad[1] = basegeom.ysize - state.draw_window_size[1] + 30 
state.base_pad[0] = basegeom.xsize - drawbasegeom.xsize $
  + (2 * basegeom.margin)
state.base_pad[1] = basegeom.ysize - drawbasegeom.ysize + 30 $
  + (2 * basegeom.margin)

state.base_min_size = [512, state.base_pad[1] + 100]

; Initialize the vectors that hold the current color table.
; See the routine atv_stretchct to see why we do it this way.

r_vector = bytarr(!d.table_size * 3)
g_vector = bytarr(!d.table_size * 3)
b_vector = bytarr(!d.table_size * 3)

tmp_array = replicate(255, !d.table_size)
r_vector[!d.table_size * 2] = tmp_array
g_vector[!d.table_size * 2] = tmp_array
b_vector[!d.table_size * 2] = tmp_array

atv_getct, 0
state.invert_colormap = 0

xmanager, 'atv', state.base_id, /no_block

end

;--------------------------------------------------------------------

pro atv_displayall

; Call the routines to scale the image, make the pan image, and
; re-display everything.  Use this if the scaling changes (log/
; linear/ histeq), or if min or max are changed, or if a new image is
; passed to atv.  If the display image has just been moved around or
; zoomed without a change in scaling, then just call atv_refresh
; rather than this routine.

atv_scaleimage
atv_makepan
atv_refresh

end

;--------------------------------------------------------------------

pro atv_readfits

; Read in a new image when user goes to the File->ReadFits menu.
; Can be modified to use mrdfits if fits extensions are used.

common atv_state
common atv_images

fitsfile = $
  dialog_pickfile(filter = '*.fits', $
                  group = state.base_id, $
                  /must_exist, $
                  /read, $
                  title = 'Select Fits Image')
                        
if (fitsfile NE '') then begin  ; 'cancel' button returns empty string

; note:  found that "readfits" chokes on some non-standard 
; fits files, but "fits_read" handles them ok.
    
    fits_read, fitsfile, tmp_image

    if ( (size(tmp_image))[0] NE 2 ) then begin
        mesg = 'Warning-- selected file is not a 2-D fits image!'
        tmp_result = dialog_message(mesg, /error, $
                                    dialog_parent = state.base_id)

; If the new image is valid, put it into main_image

    endif else begin
        main_image = temporary(tmp_image)

        atv_getstats
        state.zoom_level =  0
        state.zoom_factor = 1.0
        atv_set_minmax
        atv_displayall
    endelse


    atv_cleartext
endif

end

;----------------------------------------------------------------------

pro atv_writetiff

; writes a tiff image of the current display

common atv_state
common atv_images

; Get filename to save image

filename = dialog_pickfile(filter = '*.tiff', $ 
                           file = 'atv.tiff', $
                          group =  state.base_id, $
                          /write)

tmp_result = findfile(filename, count = nfiles)

result = ''
if (nfiles GT 0 and filename NE '') then begin
    mesg = strarr(2)
    mesg[0] = 'Overwrite existing file:'
    tmp_string = strmid(filename, rstrpos(filename, '/') + 1)
    mesg[1] = strcompress(tmp_string + '?', /remove_all)
    result =  dialog_message(mesg, $
                             /default_no, $
                             dialog_parent = state.base_id, $
                             /question)                 
endif

if ((nfiles EQ 0 OR result EQ 'Yes') AND filename NE '') then begin
    tvlct, rr, gg, bb, /get
    rn = congrid(temporary(rr), 256)
    gn = congrid(temporary(gg), 256)
    bn = congrid(temporary(bb), 256)

    write_tiff, filename, bytscl(display_image), $
      red = temporary(rn), $
      green = temporary(gn), $
      blue = temporary(bn)
endif

atv_cleartext

end


;----------------------------------------------------------------------

pro atv_writeps

; writes an encapsulated postscript file of the current display, set
; to a width of 6 inches

common atv_state
common atv_images

filename = dialog_pickfile(filter = '*.eps', $ 
                           file = 'atv.eps', $
                          group =  state.base_id, $
                          /write)

tmp_result = findfile(filename, count = nfiles)

result = ''
if (nfiles GT 0 and filename NE '') then begin
    mesg = strarr(2)
    mesg[0] = 'Overwrite existing file:'
    tmp_string = strmid(filename, rstrpos(filename, '/') + 1)
    mesg[1] = strcompress(tmp_string + '?', /remove_all)
    result =  dialog_message(mesg, $
                             /default_no, $
                             dialog_parent = state.base_id, $
                             /question)                 
endif

if ((nfiles EQ 0 OR result EQ 'Yes') AND filename NE '') then begin

    
    screen_device = !d.name
    tvlct, rr, gg, bb, /get
    wset, state.draw_window_id
    tmp_image = bytscl(tvrd())

    aspect_ratio = $
      state.draw_window_size[1] / float(state.draw_window_size[0])
    
    set_plot, 'ps'
    device, $
      filename = filename, $
      /color, $
      bits_per_pixel = 8, $
      /encapsul, $
      /inches, $
      xsize = 6.0, $
      ysize = 6.0 * aspect_ratio
    
    rn = congrid(rr, 256)
    gn = congrid(gg, 256)
    bn = congrid(bb, 256)
    
    tvlct, temporary(rn), temporary(gn), temporary(bn)
    
    tv, temporary(tmp_image)

    device, /close
    set_plot, screen_device
    tvlct, temporary(rr), temporary(gg), temporary(bb)
endif

atv_cleartext

end

;----------------------------------------------------------------------

pro atv_cleartext

; Routine to clear the widget for keyboard input when the mouse is in
; the text window.  This de-allocates the input focus from the text
; input widget.

common atv_state

widget_control, state.draw_base_id, /clear_events
widget_control, state.keyboard_text_id, set_value = ''

end

;----------------------------------------------------------------------

pro atv_getoffset
common atv_state

; Routine to calculate the display offset for the current value of
; state.centerpix, which is the central pixel in the display window.

state.offset = $
  round( state.centerpix - $
         (0.5 * state.draw_window_size / state.zoom_factor) )

end

;----------------------------------------------------------------------

pro atv_zoom, zchange, recenter = recenter
common atv_state

; Routine to do zoom in/out and recentering of image

case zchange of
    'in':    state.zoom_level = (state.zoom_level + 1) < 6
    'out':   state.zoom_level = (state.zoom_level - 1) > (-6) 
    'one':   state.zoom_level =  0
    'none':  ; no change to zoom level: recenter on current mouse position
    else:  print,  'problem in atv_zoom!'
endcase

state.zoom_factor = 2.^state.zoom_level

if (n_elements(recenter) GT 0) then begin
    state.centerpix = state.mouse
    atv_getoffset
endif

atv_refresh

if (n_elements(recenter) GT 0) then begin
    newpos = (state.mouse - state.offset + 0.5) * state.zoom_factor
    wset,  state.draw_window_id
    tvcrs, newpos[0], newpos[1], /device 
    atv_gettrack
endif

end

;----------------------------------------------------------------------

function atv_polycolor, p

; Routine to return an vector of length !d.table_size,
; defined by a 5th order polynomial.   Called by atv_makect
; to define new color tables in terms of polynomial coefficients.

x = findgen(256)

y = p[0] + x * p[1] + x^2 * p[2] + x^3 * p[3] + x^4 * p[4] + x^5 * p[5]

w = where(y GT 255, nw)
if (nw GT 0) then y(w) = 255

w =  where(y LT 0, nw)
if (nw GT 0) then y(w) = 0

z = congrid(y, !d.table_size)

return, z
end

;----------------------------------------------------------------------

pro atv_makect, tablename

; Define new color tables here, in terms of 5th order polynomials.
; To define a new color table, first set it up using xpalette,
; then load current color table into 3 256-element vectors, and
; do a 5th order poly_fit.  Store the coefficients and name
; the color table here.  Invert if necessary.

common atv_state
common atv_color

case tablename of
    'ATV Special': begin
 
        r = atv_polycolor([39.4609, $
                           -5.19434, $
                           0.128174, $
                           -0.000857115, $
                           2.23517e-06, $
                           -1.87902e-09])
        
        g = atv_polycolor([-15.3496, $
                           1.76843, $
                           -0.0418186, $
                           0.000308216, $
                           -6.07106e-07, $
                           0.0000])
        
        b = atv_polycolor([0.000, $ 
                           12.2449, $
                           -0.202679, $
                           0.00108027, $
                           -2.47709e-06, $
                           2.66846e-09])
   end

; add more color table definitions here as needed...
    else:

endcase

tvlct, r, g, b

if (state.invert_colormap EQ 1) then begin
    r = abs (r - 255)
    g = abs (g - 255)
    b = abs (b - 255)
endif

r_vector(!d.table_size) = r
g_vector(!d.table_size) = g
b_vector(!d.table_size) = b
    
atv_stretchct

end

;----------------------------------------------------------------------

pro atv_getstats

; Get basic image stats: min and max, and size.

common atv_state
common atv_images

; this routine operates on main_image, which is in the
; atv_images common block

widget_control, /hourglass

state.image_size = [ (size(main_image))[1], (size(main_image))[2] ]

state.image_min = min(main_image)
state.image_max = max(main_image)

state.min_value = state.image_min
state.max_value = state.image_max

if (state.min_value GE state.max_value) then begin
    state.min_value = state.min_value - 1
    state.max_value = state.max_value + 1
endif

; zero the current display position on the center of the image

state.mouse = round(state.image_size / 2.)
state.centerpix = round(state.image_size / 2.)
atv_getoffset

end

;----------------------------------------------------------------------

pro atv_gettrack

; Create the image to display in the track window that tracks
; cursor movements.

common atv_state
common atv_images

; Get x and y for center of track window

zcenter = (0 > state.mouse < state.image_size)

track_image = $
  rebin(scaled_image[zcenter[0]:zcenter[0]+10,  $
                     zcenter[1]:zcenter[1]+10], $
        state.track_window_size, state.track_window_size, $
        /sample)

wset, state.track_window_id
tv, track_image

; Overplot an X on the central pixel in the track window, to show the
; current mouse position

device, set_graphics = 10
plots, [0.46, 0.54], [0.46, 0.54], /normal
plots, [0.46, 0.54], [0.54, 0.46], /normal
device, set_graphics = 3

; update location bar with x, y, and pixel value

loc_string = $
  string(state.mouse[0], $
         state.mouse[1], $
         main_image[state.mouse[0], $
                    state.mouse[1]], $
         format = '("(",i4,",",i4,") ",g12.5)') 
widget_control, state.location_bar_id, $
  set_value = loc_string

end

;----------------------------------------------------------------------

pro atv_event, event

; Main event loop for ATV widgets.

common atv_state
common atv_images
common atv_color, r_vector, g_vector, b_vector

widget_control, event.id, get_uvalue = uvalue

case uvalue of

    'zoom_mode': state.mode = 'zoom'
    'blink_mode': state.mode = 'blink'

    'atv_base': begin  ; main window resize: preserve display center
        atv_resize, event
        atv_refresh
        atv_cleartext
    end

    'top_menu': begin       ; selection from menu bar
        widget_control, event.value, get_value = event_name
        parent = widget_info(event.value, /parent)
        widget_control, parent, get_value = parent_name
        
        case parent_name of
            
            'File': begin
                case event_name of
                    'ReadFits': atv_readfits
                    'WriteEPS' : atv_writeps
                    'WriteTiff': atv_writetiff
                    'Quit':     atv_shutdown
                    else:
                endcase
            end

            'ColorMap': begin
                case event_name of
                    'Grayscale': atv_getct, 0
                    'Blue-White': atv_getct, 1
                    'Red-Orange': atv_getct, 3
                    'BGRY': atv_getct, 4
                    'Rainbow': atv_getct, 13
                    'ATV Special': atv_makect, event_name
                    else:
                endcase
            end

            'Scaling':  begin
                case event_name of
                    'Linear': state.scaling = 0
                    'Log': state.scaling = 1
                    'HistEq': state.scaling = 2
                    else:
                endcase
                atv_displayall
                atv_cleartext
            end
            
            'Help': atv_help

            else: print, 'Unknown event in file menu!'
        endcase
        
    end


; If the mouse enters the main draw base, set the input focus to
; the invisible text widget, for keyboard input.
; When the mouse leaves the main draw base, de-allocate the input
; focus by setting the text widget value.

    'draw_base': begin
        case event.enter of
            0: begin
                widget_control, state.keyboard_text_id, set_value = ''
            end
            
            1: begin
                widget_control, state.keyboard_text_id, /input_focus
            end
        endcase      
    end

    'draw_window': begin  ; mouse movement or button press

        if (event.type EQ 2) then begin      ; motion event
            tmp_event = [event.x, event.y]
            state.mouse = $
              round( (0.5 > $
                      ((tmp_event / state.zoom_factor) + state.offset) $
                      < (state.image_size - 0.5) ) - 0.5)
            atv_gettrack
        endif
               

        case state.mode of                   ; button events

            'blink': begin  ; button press or release in blink mode
                case event.type of                    
                    0: begin                     ; button press: blink
                        wset, state.draw_window_id
                        if n_elements(blink_image) GT 1 then $
                          tv, blink_image
                    end

                    1: begin                     ; button release: unblink
                        wset, state.draw_window_id
                        tv, display_image
                        
                    end
                    else:
                endcase
            end

            
            'zoom': begin   ; button press in zoom mode
                if (event.type EQ 0) then begin 

                    case event.press of
                        1: atv_zoom, 'in', /recenter
                        2: atv_zoom, 'none', /recenter
                        4: atv_zoom, 'out', /recenter
                        else: print,  'trouble in atv_event, mouse zoom'
                    endcase
                    
                endif
                
            end

        endcase
        widget_control, state.keyboard_text_id, /input_focus
                    
    end

    'brightness': atv_stretchct      ; brightness slider move
    'contrast'  : atv_stretchct      ; contrast slider move

    'invert': begin                  ; invert the color table
        state.invert_colormap = abs(state.invert_colormap - 1)
        tvlct, r, g, b, /get

        r = abs( r - 255 )
        g = abs( g - 255 )
        b = abs( b - 255 )
        r_vector = abs( r_vector - 255 )
        g_vector = abs( g_vector - 255 )
        b_vector = abs( b_vector - 255 )

        tvlct, r, g, b
        
        atv_cleartext
    end

    'reset_color': begin   ; set color sliders to default positions
        widget_control, $
          state.brightness_slider_id, set_value = !d.table_size 
        widget_control, $
          state.contrast_slider_id, set_value = 50
        atv_stretchct
        atv_cleartext
    end


    'min_text': begin     ; text entry in 'min = ' box
        atv_get_minmax, uvalue, event.value
        atv_displayall
    end

    'max_text': begin     ; text entry in 'max = ' box
        atv_get_minmax, uvalue, event.value
        atv_displayall
    end

    'autoscale_button': begin   ; autoscale the image
        atv_autoscale
        atv_displayall
        atv_cleartext
    end

    'full_range': begin    ; display the full intensity range
        state.min_value = state.image_min
        state.max_value = state.image_max
        if state.min_value GE state.max_value then begin
            state.min_value = state.max_value - 1
            state.max_value = state.max_value + 1
        endif
        atv_set_minmax
        atv_displayall
        atv_cleartext
    end

    'set_blink': begin     ; store current display image for blinking
        blink_image = display_image
    end
    
    'keyboard_text': begin  ; keyboard input with mouse in display window
        eventchar = string(event.ch)
        case eventchar of
            '1': atv_move_cursor, eventchar
            '2': atv_move_cursor, eventchar
            '3': atv_move_cursor, eventchar
            '4': atv_move_cursor, eventchar
            '6': atv_move_cursor, eventchar
            '7': atv_move_cursor, eventchar
            '8': atv_move_cursor, eventchar
            '9': atv_move_cursor, eventchar
            'r': atv_rowplot
            'c': atv_colplot
            's': atv_surfplot
            't': atv_contourplot
            'p': atv_mapphot
            else:  ;any other key press does nothing
        endcase
        widget_control, state.keyboard_text_id, /clear_event
    end

    'zoom_in':  atv_zoom, 'in'         ; zoom buttons
    'zoom_out': atv_zoom, 'out'
    'zoom_one': atv_zoom, 'one'

    'center': begin   ; center image and preserve current zoom level
        atv_drawbox
        state.centerpix = round(state.image_size / 2.)
        atv_getoffset
        atv_drawbox
        atv_getdisplay
    end

    'pan_window': begin    ; move the box around in the pan window
        case event.type of
            2: begin                     ; motion event
                if (state.pan_track EQ 1) then begin
                    atv_pantrack, event
                endif
            end
            
            0: begin                     ; button press
                state.pan_track = 1
                atv_pantrack, event
            end
            1: begin                     ; button release
                state.pan_track = 0
                atv_getdisplay
            end
            else:
        endcase
    end

    'done':  atv_shutdown

    else:  print, 'No match for uvalue....'  ; bad news if this happens

endcase

end

;----------------------------------------------------------------------

pro atv_drawbox

; routine to draw the box on the pan window, given the current center
; of the display image.
;
; By using device, set_graphics = 6, the same routine can be used both
; to draw the box, and to remove the box by drawing it over again at
; the same position.  So, to move the box around, call this routine at
; the old position to erase the old box, then get the new box position
; and update state.centerpix, then call this routine again to draw the
; new box.  

common atv_state

wset, state.pan_window_id

view_min = round(state.centerpix - $
        (0.5 * state.draw_window_size / state.zoom_factor))
view_max = round(view_min + state.draw_window_size / state.zoom_factor)

; Create the vectors which contain the box coordinates

box_x = float((([view_min[0], $
                 view_max[0], $
                 view_max[0], $
                 view_min[0], $
                 view_min[0]]) * state.pan_scale) + state.pan_offset[0]) 

box_y = float((([view_min[1], $
                 view_min[1], $
                 view_max[1], $
                 view_max[1], $
                 view_min[1]]) * state.pan_scale) + state.pan_offset[1]) 

; Plot the box

device, set_graphics = 6
plots, box_x, box_y, /device, thick = 2
device, set_graphics = 3

end

;----------------------------------------------------------------------

pro atv_shutdown

; routine to kill the atv window(s) and clear variables to conserve
; memory when quitting atv.  Since we can't delvar the atv internal
; variables, just set them equal to zero so they don't take up a lot
; of space.  Also clear the state and the color map vectors.

common atv_images
common atv_state
common atv_color

if (xregistered ('atv')) then begin
    widget_control, state.base_id, /destroy
endif

main_image = 0
display_image = 0
scaled_image = 0
blink_image = 0
pan_image = 0
r_vector = 0
g_vector = 0
b_vector = 0
state = 0

end

;----------------------------------------------------------------------
pro atv_pantrack, event

; routine to track the view box in the pan window during cursor motion

common atv_state

; erase the old box
atv_drawbox

; get the new box coords and draw the new box

tmp_event = [event.x, event.y] 

newpos = state.pan_offset > tmp_event < $
  (state.pan_offset + (state.image_size * state.pan_scale))

state.centerpix = round( (newpos - state.pan_offset ) / state.pan_scale)

atv_drawbox
atv_getoffset

end

;----------------------------------------------------------------------

pro atv_resize, event

; Routine to resize the draw window when a top-level resize event
; occurs.

common atv_state

tmp_event = [event.x, event.y]

window = (state.base_min_size > tmp_event)

newbase = window - state.base_pad

newsize = window - state.pad

widget_control, state.draw_base_id, $
  xsize = newbase[0], ysize = newbase[1]
widget_control, state.draw_widget_id, $
  xsize = newsize[0], ysize = newsize[1]

state.draw_window_size = newsize

end

;----------------------------------------------------------------------

pro atv_scaleimage

; Create a byte-scaled copy of the image, scaled according to
; the state.scaling parameter.  Add a padding of 5 pixels around the
; image boundary, so that the tracking window can always remain
; centered on an image pixel even if that pixel is at the edge of the
; image.    

common atv_state
common atv_images

; Since this can take some time for a big image, set the cursor 
; to an hourglass until control returns to the event loop.

widget_control, /hourglass

case state.scaling of
    0: tmp_image = $                 ; linear stretch
      bytscl(main_image, $                           
             min=state.min_value, $
             max=state.max_value, $
             top = !d.table_size)
    
    1: tmp_image = $                 ; log stretch
      bytscl( alog10 (bytscl(main_image, $                       
                             min=state.min_value, $
                             max=state.max_value, $
                             top = !d.table_size) + 1))
    
    2: tmp_image = $                 ; histogram equalization
      bytscl(hist_equal(main_image, $
                        minv = state.min_value, $    
                        maxv = state.max_value), $
             top = !d.table_size)
    
endcase

scaled_image = bytarr(state.image_size[0] + 10, $
                             state.image_size[1] + 10)

scaled_image[5, 5] = temporary(tmp_image)

end

;----------------------------------------------------------------------

pro atv_getdisplay

; make the display image from the scaled image by applying the zoom
; factor and matching to the size of the draw window, and display the
; image.

common atv_state
common atv_images


display_image = $
  bytarr(state.draw_window_size[0] + 2 * (round(state.zoom_factor) > 1), $
         state.draw_window_size[1] + 2 * (round(state.zoom_factor) > 1))

view_min = round(state.centerpix - $
                  (0.5 * state.draw_window_size / state.zoom_factor))
view_max = round(view_min + state.draw_window_size / state.zoom_factor)

view_min = (0 > view_min < (state.image_size - 1)) + 5
view_max = (0 > view_max < (state.image_size - 1)) + 5

newsize = round( (view_max - view_min + 1) * state.zoom_factor) > 1
startpos = abs( round(state.offset * state.zoom_factor) < 0)

tmp_image = congrid(scaled_image[view_min[0]:view_max[0], $
                                            view_min[1]:view_max[1]], $
                                            newsize[0], newsize[1])
display_image[startpos[0], startpos[1]] = tmp_image

; Display the image

wset, state.draw_window_id
erase
tv, display_image

end

;--------------------------------------------------------------------


pro atv_makepan

; Make the 'pan' image that shows a miniature version of the full image.

common atv_state
common atv_images

sizeratio = state.image_size[1] / state.image_size[0]

if (sizeratio GE 1) then begin
    state.pan_scale = float(state.pan_window_size) / float(state.image_size[1])
endif else begin
    state.pan_scale = float(state.pan_window_size) / float(state.image_size[0])
endelse

tmp_image = $
  scaled_image[5:state.image_size[0]+4, 5:state.image_size[1]+4]

pan_image = congrid(tmp_image, round(state.pan_scale * state.image_size[0]), $
                    round(state.pan_scale * state.image_size[1]) )

state.pan_offset[0] = round((state.pan_window_size - (size(pan_image))[1]) / 2)
state.pan_offset[1] = round((state.pan_window_size - (size(pan_image))[2]) / 2)

end


;----------------------------------------------------------------------

pro atv_move_cursor, direction

; Use keypad arrow keys to step cursor one pixel at a time.
; Get the new track image, and update the cursor position.

common atv_state

i = 1L

case direction of
    '2': state.mouse[1] = max([state.mouse[1] - i, 0])
    '4': state.mouse[0] = max([state.mouse[0] - i, 0])
    '8': state.mouse[1] = min([state.mouse[1] + i, state.image_size[1] - i])
    '6': state.mouse[0] = min([state.mouse[0] + i, state.image_size[0] - i])
    '7': begin
        state.mouse[1] = min([state.mouse[1] + i, state.image_size[1] - i])
        state.mouse[0] = max([state.mouse[0] - i, 0])
    end
    '9': begin
        state.mouse[1] = min([state.mouse[1] + i, state.image_size[1] - i])
        state.mouse[0] = min([state.mouse[0] + i, state.image_size[0] - i])
    end
    '3': begin
        state.mouse[1] = max([state.mouse[1] - i, 0])
        state.mouse[0] = min([state.mouse[0] + i, state.image_size[0] - i])
    end
    '1': begin
        state.mouse[1] = max([state.mouse[1] - i, 0])
        state.mouse[0] = max([state.mouse[0] - i, 0])
    end

endcase

newpos = (state.mouse - state.offset + 0.5) * state.zoom_factor

wset,  state.draw_window_id
tvcrs, newpos[0], newpos[1], /device

atv_gettrack

; Prevent the cursor move from causing a mouse event in the draw window

widget_control, state.draw_widget_id, /clear_events

end


;----------------------------------------------------------------------

pro atv_set_minmax

; Updates the min and max text boxes with new values.

common atv_state

widget_control, state.min_text_id, set_value = string(state.min_value)
widget_control, state.max_text_id, set_value = string(state.max_value)

end

;----------------------------------------------------------------------

pro atv_get_minmax, uvalue, newvalue

; Change the min and max state variables when user inputs new numbers
; in the text boxes. 

common atv_state

case uvalue of
    
    'min_text': begin
        if (newvalue LT state.max_value) then begin
            state.min_value = newvalue
        endif
    end

    'max_text': begin
        if (newvalue GT state.min_value) then begin
            state.max_value = newvalue
        endif
    end
        
endcase

atv_set_minmax

end

;--------------------------------------------------------------------

pro atv_refresh

; Make the display image from the scaled_image, and redisplay the pan
; image and tracking image. 

common atv_state
common atv_images

atv_getoffset
atv_getdisplay

; redisplay the pan image and plot the boundary box

wset, state.pan_window_id
erase
tv, pan_image, state.pan_offset[0], state.pan_offset[1]
atv_drawbox

; redisplay the tracking image

wset, state.track_window_id
atv_gettrack

wset, state.draw_window_id

end

;--------------------------------------------------------------------

pro atv_stretchct

; Change brightness and contrast according to slider values.
; For contrast, use same algorithm as IDL 'stretch' routine.
; For brightness, want a linear 'slide' of color table.
; Store the current color table in 3 vectors of length 
; (3 * !d.table_size), and when brightness slider moves,
; just 'slide' the color table along these larger vectors.

common atv_state
common atv_color, r_vector, g_vector, b_vector

widget_control, state.brightness_slider_id, $
  get_value = brightness

widget_control, state.contrast_slider_id, $
  get_value = contrast

gamma = 10^( (contrast/50.) - 1 )

case gamma of
    1.0: p = lindgen(!d.table_size)
    else: $
      p = long( ((findgen(!d.table_size) / !d.table_size ) ^ gamma) $
                * !d.table_size)
endcase

; use brightness slider value as zero-point of color table mapping.

r = r_vector[p + brightness]
g = g_vector[p + brightness]
b = b_vector[p + brightness]
tvlct, r, g, b

end


;--------------------------------------------------------------------

pro atv_getct, tablenum

; Read in a pre-defined color table, and invert if necessary.

common atv_color, r_vector, g_vector, b_vector
common atv_state

loadct, tablenum, /silent
tvlct, r, g, b, /get

if (state.invert_colormap EQ 1) then begin
    r = abs (r - 255)
    g = abs (g - 255)
    b = abs (b - 255)
endif

r_vector(!d.table_size) = r
g_vector(!d.table_size) = g
b_vector(!d.table_size) = b

atv_stretchct

end

;--------------------------------------------------------------------

pro atv_autoscale

; Routine to auto-scale the image.

common atv_state 
common atv_images

widget_control, /hourglass

med = median(main_image)
sig = stdev(main_image)

state.max_value = (med + (10 * sig)) < max(main_image)

state.min_value = (med - (2 * sig))  > min(main_image)
if (state.min_value LT 0 AND state.max_value GT 0) then begin
  state.min_value = 0.0
endif

if (state.min_value GE state.max_value) then begin
    state.min_value = state.min_value - 1
    state.max_value = state.max_value + 1
endif

atv_set_minmax

end  

;--------------------------------------------------------------------

pro atv_lineplot_init

; This routine creates the window for line plots

common atv_state

state.lineplot_base_id = $
  widget_base(/floating, $
              group_leader = state.base_id, $
              /column, $
              /base_align_right, $
              title = 'atv plot', $
              /tlb_size_events, $
              uvalue = 'lineplot_base')

state.lineplot_widget_id = $
  widget_draw(state.lineplot_base_id, $
              frame = 0, $
              scr_xsize = state.lineplot_size[0], $
              scr_ysize = state.lineplot_size[1], $
              uvalue = 'lineplot_window')

lbutton_base = $
  widget_base(state.lineplot_base_id, $
              /base_align_bottom, $
              /row)

lineplot_done = $
  widget_button(lbutton_base, $
                value = 'Done', $
                uvalue = 'lineplot_done')

widget_control, state.lineplot_base_id, /realize
widget_control, state.lineplot_widget_id, get_value = tmp_value
state.lineplot_window_id = tmp_value

basegeom = widget_info(state.lineplot_base_id, /geometry)
drawgeom = widget_info(state.lineplot_widget_id, /geometry)

state.lineplot_pad[0] = basegeom.xsize - drawgeom.xsize
state.lineplot_pad[1] = basegeom.ysize - drawgeom.ysize
    
xmanager, 'atv_lineplot', state.lineplot_base_id, /no_block

end

;--------------------------------------------------------------------

pro atv_rowplot

common atv_state
common atv_images

if (not (xregistered('atv_lineplot'))) then begin
    atv_lineplot_init
endif

wset, state.lineplot_window_id
erase

plot, main_image[*, state.mouse[1]], $
  xst = 3, yst = 3, psym = 10, $
  title = strcompress('Plot of row ' + $
                      string(state.mouse[1])), $
  xtitle = 'Column', $
  ytitle = 'Pixel Value'

widget_control, state.lineplot_base_id, /clear_events

end

;--------------------------------------------------------------------

pro atv_colplot

common atv_state
common atv_images

if (not (xregistered('atv_lineplot'))) then begin
    atv_lineplot_init
endif

wset, state.lineplot_window_id
erase

plot, main_image[state.mouse[0], *], $
  xst = 3, yst = 3, psym = 10, $
  title = strcompress('Plot of column ' + $
                      string(state.mouse[0])), $
  xtitle = 'Row', $
  ytitle = 'Pixel Value'

widget_control, state.lineplot_base_id, /clear_events
        
end

;--------------------------------------------------------------------

pro atv_surfplot

common atv_state
common atv_images

if (not (xregistered('atv_lineplot'))) then begin
    atv_lineplot_init
endif

wset, state.lineplot_window_id
erase

plotsize = $
  fix(min([50, state.image_size[0]/2., state.image_size[1]/2.]))
center = plotsize > state.mouse < (state.image_size - plotsize) 

tmp_string = $
  strcompress('Surface plot of ' + $
              strcompress('['+string(center[0]-plotsize)+ $
                          ':'+string(center[0]+plotsize-1)+ $
                          ','+string(center[1]-plotsize)+ $
                          ':'+string(center[1]+plotsize-1)+ $
                          ']', /remove_all))

surface, $
  main_image[center[0]-plotsize:center[0]+plotsize-1, $
             center[1]-plotsize:center[1]+plotsize-1], $
  title = temporary(tmp_string), $
  xtitle = 'X', ytitle = 'Y', ztitle = 'Pixel Value'

widget_control, state.lineplot_base_id, /clear_events

end

;--------------------------------------------------------------------

pro atv_contourplot

common atv_state
common atv_images

if (not (xregistered('atv_lineplot'))) then begin
    atv_lineplot_init
endif

wset, state.lineplot_window_id
erase

plotsize = $
  fix(min([50, state.image_size[0]/2., state.image_size[1]/2.]))
center = plotsize > state.mouse < (state.image_size - plotsize) 

contour_image =  main_image[center[0]-plotsize:center[0]+plotsize-1, $
                            center[1]-plotsize:center[1]+plotsize-1]
if (state.scaling EQ 1) then begin
    contour_image = alog10(contour_image)
    logflag = 'Log'
endif else begin
    logflag = ''
endelse

tmp_string =  $
  strcompress(logflag + $
              ' Contour plot of ' + $
              strcompress('['+string(round(center[0]-plotsize))+ $
                          ':'+string(round(center[0]+plotsize-1))+ $
                          ','+string(round(center[1]-plotsize))+ $
                          ':'+string(round(center[1]+plotsize-1))+ $
                          ']', /remove_all))

contour, temporary(contour_image), $
  nlevels = 10, $
  /follow, $
  title = temporary(tmp_string), $
  xtitle = 'X', ytitle = 'Y'

widget_control, state.lineplot_base_id, /clear_events
        
end

;----------------------------------------------------------------------

pro atv_lineplot_event, event

common atv_state

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'lineplot_done': widget_control, event.top, /destroy
    'lineplot_base': begin                       ; Resize event
        state.lineplot_size = [event.x, event.y]- state.lineplot_pad
        widget_control, state.lineplot_widget_id, $
          xsize = (state.lineplot_size[0] > 100), $
          ysize = (state.lineplot_size[1] > 100)
        wset, state.lineplot_window_id
    end    
else:
endcase

end

;----------------------------------------------------------------------

pro atv_help
common atv_state

h = strarr(45)
i = 0
h[i] =  'ATV HELP'
i = i + 1
h[i] =  ''
i = i + 1
h[i] =  'MENU BAR:'
i = i + 1
h[i] =  'File->ReadFits:  read in a new fits image from disk'
i = i + 1
h[i] =  'File->WriteEPS:  write an encapsulated PS file of the current display'
i = i + 1
h[i] =  'File->WriteTiff: write a tiff image of the current display'
i = i + 1
h[i] =  'File->Quit:      quits atv'
i = i + 1
h[i] =  'ColorMap Menu:   selects color table'
i = i + 1
h[i] =  'Scaling Menu:    selects linear, log, or histogram-equalized scaling'
i = i + 1
h[i] =  ''
i = i + 1
h[i] =  'CONTROL PANEL ITEMS:'
i = i + 1
h[i] =  'Brightness:      fairly self-explanatory'
i = i + 1
h[i] = 'Contrast:        also fairly self-explanatory'
i = i + 1
h[i] = 'Min:             shows minimum data value displayed; click to modify'
i = i + 1
h[i] = 'Max:             shows maximum data value displayed; click to modify'
i = i + 1
h[i] = 'Pan Window:      use mouse to drag the image-view box around'
i = i + 1
h[i] = ''
i = i + 1
h[i] = 'BUTTONS:'
i = i + 1
h[i] = 'ZoomMode:        toggles zoom mode:'
i = i + 1
h[i] = '                    button1 = zoom in & center'
i = i + 1 
h[i] = '                    button2 = center on current position'
i = i + 1
h[i] = '                    button3 = zoom out & center'
i = i + 1
h[i] = 'BlinkMode:       toggles blink mode:'
i = i + 1
h[i] = '                    press mouse button in main window to show blink image'
i = i + 1
h[i] = 'Invert:          inverts the current color table'
i = i + 1
h[i] = 'ResetColor:      sets the sliders back to defaults'
i = i + 1
h[i] = 'AutoScale:       sets min and max to show data values around histogram peak'
i = i + 1
h[i] = 'FullRange:       sets min and max to show the full data range of the image'
i = i + 1
h[i] = 'ZoomIn:          zooms in by x2'
i = i + 1
h[i] = 'ZoomOut:         zooms out by x2'
i = i + 1
h[i] = 'Zoom1:           sets zoom level to original scale'
i = i + 1
h[i] = 'Center:          centers image on display window'
i = i + 1
h[i] = 'SetBlink:        puts current image in blink buffer'
i = i + 1
h[i] = 'Done:            quits atv'
i = i + 1
h[i] = ''
i = i + 1
h[i] = 'Keyboard commands in display window:'
i = i + 1
h[i] = '    Numeric keypad (with NUM LOCK on) moves cursor'
i = i + 1
h[i] = '    r: row plot'
i = i + 1
h[i] = '    c: column plot'
i = i + 1
h[i] = '    s: surface plot'
i = i + 1
h[i] = '    t: contour plot'
i = i + 1
h[i] = '    p: aperture photometry at current position'

if (not (xregistered('atv_help'))) then begin
    help_base =  widget_base(/floating, $
                             group_leader = state.base_id, $
                             /column, $
                             /base_align_right, $
                             title = 'atv help', $
                             uvalue = 'help_base')

    help_text = widget_text(help_base, $
                            /scroll, $
                            value = h, $
                            xsize = 75, $
                            ysize = 24)
    
    help_done = widget_button(help_base, $
                              value = 'Done', $
                              uvalue = 'help_done')

    widget_control, help_base, /realize
    xmanager, 'atv_help', help_base, /no_block
    
endif

end

;----------------------------------------------------------------------

pro atv_help_event, event

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'help_done': widget_control, event.top, /destroy
    else:
endcase

end

;----------------------------------------------------------------------

pro atv_mapphot_refresh

; Aperture photometry routine by W. Colley, adapted for 
; inclusion in ATV by AJB

common atv_state
common atv_images

; coarse center on the star

xmin = (state.cursorpos[0] - ((state.centerboxsize - 1) / 2)) > 0
xmax = (xmin + state.centerboxsize) < (state.image_size[0] - 1)
ymin = (state.cursorpos[1] - ((state.centerboxsize - 1) / 2)) > 0
ymax = (ymin + state.centerboxsize) < (state.image_size[1] - 1)

small_image = main_image[xmin:xmax, ymin:ymax]

nx = (size(small_image))[1]
ny = (size(small_image))[2]

if (total(small_image) EQ 0.) then small_image = small_image + 1.

tt = findgen(nx)#(fltarr(ny)+1)
xcenter = round(total(tt*small_image)/float(total(small_image)))
tt = (fltarr(nx)+1)#findgen(ny)
ycenter = round(total(tt*small_image)/float(total(small_image)))

x = 0 > (xcenter + xmin) < (state.image_size[0] - 1)
y = 0 > (ycenter + ymin) < (state.image_size[1] - 1)

; calculate the sky

xmin = (x - state.outersky) > 0
xmax = (xmin + (2 * state.outersky + 1)) < (state.image_size[0] - 1)
ymin = (y - state.outersky) > 0
ymax = (ymin + (2 * state.outersky + 1)) < (state.image_size[1] - 1)

small_image = main_image[xmin:xmax, ymin:ymax]
nx = (size(small_image))[1]
ny = (size(small_image))[2]
i = lindgen(nx)#(lonarr(ny)+1)
j = (lonarr(nx)+1)#lindgen(ny)
xc = x - xmin
yc = y - ymin

w = where( (((i - xc)^2 + (j - yc)^2) GE state.innersky^2) AND $
           (((i - xc)^2 + (j - yc)^2) LE state.outersky^2),  nw)
if nw EQ 0 then begin
    print, 'No pixels in sky!!!!'
    xcent = -1.
    ycent = -1.
    sky = -1.
    flux = -1.
    goto, BADSKIP
endif

if nw GT 0 then sky = median(small_image(w))

; do the photometry

mag = 1.

s = size(main_image)
nxi = s[1]
nyi = s[2]

instr = string(0)

nx = ceil(state.r*2.)+4
pi = !pi
twopi = pi*2.

flux = float(x-x)
xcent = flux
ycent = flux
s = size(x)

i = findgen(nx)-float(nx)*0.5
ii0 = i # (i-i+1)
jj0 = (i-i+1) # i

i = (findgen(nx*mag)-(float(nx)*0.5)*mag - mag*0.5 + 0.5) / mag
ii1 = i # (i-i+1)
jj1 = (i-i+1) # i

str = string(0)
    
xcent = 0.
ycent = 0.

ix = floor(x)
iy = floor(y)

xi = (x-float(ix))
yi = (y-float(iy))

rx = ii0-xi
ry = jj0-yi

mask0 = (rx*rx + ry*ry le (state.r-0.5)^2)
clipmask = (rx*rx + ry*ry le (state.r+0.5)^2)

rx = ii1-xi
ry = jj1-yi

mask1 = (rx*rx + ry*ry le state.r^2)

bm0 = rebin(mask0,nx*mag,nx*mag,/sample)
mask2 = (mask1 eq 1) * (bm0 eq 0)

norm = total(mask1)

ix = floor(x)
iy = floor(y)

i1 = ix-nx/2
i2 = ix+nx/2-1
j1 = iy-nx/2
j2 = iy+nx/2-1

if ((i1 lt state.r) or (i2 gt nxi-state.r-1) or $
    (j1 lt state.r) or (j2 gt nyi-state.r-1)) then begin
        
    xcent = -1.
    ycent = -1.
    flux = -1.
    
endif else begin
    
    marr_sml = main_image[i1:i2,j1:j2] - sky
    marr = marr_sml
    t = marr*mask2+rebin(mask0*marr_sml,nx*mag,nx*mag,/sample)
    
    xcent = total(ii1*t)/total(t) + float(i1+nx/2)
    ycent = total(jj1*t)/total(t) + float(j1+nx/2)
    
    flux = total(marr_sml*mask0) + total(marr*mask2)
        
endelse

BADSKIP: begin
end

; output the results
  
state.centerpos = [xcent, ycent]

tmp_string = string(state.cursorpos[0], state.cursorpos[1], $
                    format = '("Cursor position:  x=",i4,"  y=",i4)' )
tmp_string1 = string(state.centerpos[0], state.centerpos[1], $
                    format = '("Object centroid:  x=",f6.1,"  y=",f6.1)' )
tmp_string2 = string(flux, $
                    format = '("Object counts: ",g12.6)' )
tmp_string3 = string(sky, $
                    format = '("Sky level: ",g12.6)' )

widget_control, state.centerbox_id, set_value = state.centerboxsize
widget_control, state.cursorpos_id, set_value = tmp_string
widget_control, state.centerpos_id, set_value = tmp_string1
widget_control, state.radius_id, set_value = state.r 
widget_control, state.outersky_id, set_value = state.outersky
widget_control, state.innersky_id, set_value = state.innersky
widget_control, state.skyresult_id, set_value = tmp_string3
widget_control, state.photresult_id, set_value = tmp_string2

end

;----------------------------------------------------------------------

pro atv_mapphot_event, event

common atv_state
common atv_images

widget_control, event.id, get_uvalue = uvalue

case uvalue of

    'centerbox': begin
        state.centerboxsize = long(event.value) > 0
        if ( (state.centerboxsize / 2 ) EQ $
             round(state.centerboxsize / 2.)) then $
          state.centerboxsize = state.centerboxsize + 1
        atv_mapphot_refresh
    end
        
    'radius': begin
        state.r = 1 > long(event.value) < state.innersky
        atv_mapphot_refresh
    end

    'innersky': begin
        state.innersky = state.r > long(event.value) < (state.outersky - 1)
        atv_mapphot_refresh
    end

    'outersky': begin
        state.outersky = long(event.value) > (state.innersky + 1)
        atv_mapphot_refresh
    end

    'mapphot_done': widget_control, event.top, /destroy
    else:
endcase

end

;----------------------------------------------------------------------

pro atv_mapphot

; aperture photometry front end

common atv_state

state.cursorpos = state.mouse

if (not (xregistered('atv_mapphot'))) then begin

    mapphot_base = $
      widget_base(/floating, $
                  /base_align_left, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'atv aperture photometry', $
                  uvalue = 'mapphot_base')
    
    tmp_string = $
      string(1000, 1000, $
             format = '("Cursor position:  x=",i4,"  y=",i4)' )

    state.cursorpos_id = $
      widget_label(mapphot_base, $
                   value = tmp_string, $
                   uvalue = 'cursorpos')

    state.centerbox_id = $
      cw_field(mapphot_base, $
               /long, $
               /return_events, $
               title = 'Centering box size (pix):', $
               uvalue = 'centerbox', $
               value = state.centerboxsize, $
               xsize = 5)
    
    tmp_string1 = $
      string(99999.0, 99999.0, $
             format = '("Object centroid:  x=",f7.1,"  y=",f7.1)' )
    
    state.centerpos_id = $
      widget_label(mapphot_base, $
                   value = tmp_string1, $
                   uvalue = 'centerpos')
    
    state.radius_id = $
      cw_field(mapphot_base, $
               /long, $
               /return_events, $
               title = 'Aperture radius:', $
               uvalue = 'radius', $
               value = state.r, $
               xsize = 5)
    
    state.innersky_id = $
      cw_field(mapphot_base, $
               /long, $
               /return_events, $
               title = 'Inner sky radius:', $
               uvalue = 'innersky', $
               value = state.innersky, $
               xsize = 5)
    
    state.outersky_id = $
      cw_field(mapphot_base, $
               /long, $
               /return_events, $
               title = 'Outer sky radius:', $
               uvalue = 'outersky', $
               value = state.outersky, $
               xsize = 5)
    
    tmp_string3 = string(10000000.00, $
                         format = '("Sky level: ",g12.6)' )
    
    state.skyresult_id = $
      widget_label(mapphot_base, $
                   value = tmp_string3, $
                   uvalue = 'skyresult')
    
    tmp_string2 = string(1000000000.00, $
                         format = '("Object counts: ",g12.6)' )
    
    state.photresult_id = $
      widget_label(mapphot_base, $
                   value = tmp_string2, $
                   uvalue = 'photresult', $
                   /frame)
    
    mapphot_done = $
      widget_button(mapphot_base, $
                    value = 'Done', $
                    uvalue = 'mapphot_done')
    
    widget_control, mapphot_base, /realize
    
    xmanager, 'atv_mapphot', mapphot_base, /no_block
    
endif

atv_mapphot_refresh

end

;----------------------------------------------------------------------

; Main program routine for ATV.  If there is no current ATV session,
; then run atv_startup to create the widgets.  If ATV already exists,
; then display the new image to the current ATV window.

pro atv, image, $
             min = minimum, $
             max = maximum, $
             autoscale = autoscale,  $
             linear = linear, $
             log = log, $
             histeq = histeq

common atv_state
common atv_images

if ( (n_params() EQ 0) AND (xregistered('atv'))) then begin
    print, 'USAGE: atv, array_name'
    print, '            [,min = min_value] [,max=max_value]'
    print, '            [,/autoscale] [,/linear] [,/log] [,/histeq]'
    retall
endif

if ( (n_params() NE 0) AND (size(image))[0] NE 2) then begin
    print, 'Input data must be a 2-d array!'
    retall
endif


if ( (n_params() EQ 0) AND (not (xregistered('atv')))) then begin
    main_image = bytscl(dist(500,500)^2 * sin(dist(500,500)/2.)^2)

endif else begin
    scaled_image = 0
    display_image = 0
    main_image = image
endelse

if (not (xregistered('atv'))) then atv_startup

atv_getstats

; check for command line keywords

if n_elements(minimum) GT 0 then begin
    state.min_value = minimum
endif

if n_elements(maximum) GT 0 then begin 
    state.max_value = maximum
endif

if state.min_value GE state.max_value then begin
    state.min_value = state.max_value - 1.
endif

atv_set_minmax

if (keyword_set(autoscale)) then atv_autoscale

if (keyword_set(linear)) then state.scaling = 0
if (keyword_set(log))    then state.scaling = 1
if (keyword_set(histeq)) then state.scaling = 2

state.zoom_level = 0
state.zoom_factor = 1.0

atv_displayall

end

