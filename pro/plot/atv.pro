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
;       atv [,array_name OR fits_file] [,min = min_value] [,max=max_value] 
;           [,/autoscale] [,/linear] [,/log] [,/histeq] 
;
; REQUIRED INPUTS:
;       None.  If atv is run with no inputs, the window widgets
;       are realized and images can subsequently be passed to atv
;       from the command line or from the pull-down file menu.
;
; OPTIONAL INPUTS:
;       array_name: a 2-D data array to display
;          OR
;       fits_file:  a fits file name, enclosed in single quotes
;
; KEYWORDS:
;       min:        minimum data value to be mapped to the color table
;       max:        maximum data value to be mapped to the color table
;       autoscale:  set min and max to show a range of data values
;                      around the median value
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
;       atv_pdata:  contains plot and text annotation information
;
; RESTRICTIONS:
;       Requires the GSFC IDL astronomy library routines,
;         for fits input.
;       The current version doesn't read fits extensions.
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
;
;       Modified 26 Jul 1999 by D. Schlegel to add overplotting via
;       the routines ATVPLOT, ATVXYOUTS, ATVCONTOUR, and ATVERASE.
;       At present, these overplots are only in the main draw window.
;       The arguments C_ORIENTATION and C_SPACING are not supported.
;       The default color for all overplots is 'red'.
;
;       This version is 1.0b4, last modified 02 August 1999.
;       For the most current version, revision history, instructions,
;       and further information, go to:
;              http://cfa-www.harvard.edu/~abarth/atv/atv.html
;
;  new features since last release:
;  made crosshair in tracking image green
;  changed mode selection to a droplist
;  added color mode for dragging mouse on main draw window
;  completely changed brightness/contrast algorithm
;  added stern special color table
;  fixed problem where unblink image should have been set in 
;    atv_getdisplay
;  removed color sliders
;  made min and max text boxes bigger
;  changed base structure
;  lowered maximum numbers of text and contour plots
;  changed startup image
;
;  added SYMSIZE keyword to ATVPLOT command
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
  unblink_image, $      ; added AJB 7/26/99
  pan_image
common atv_color, r_vector, g_vector, b_vector
common atv_pdata, pdata, ptext, pcon, phistory

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
          menu_ids: lonarr(25), $        ; list of top menu items
;          brightness_slider_id: 0L, $    ; id of brightness widget
;          contrast_slider_id: 0L, $      ; id of contrast widget
          brightness: 500L, $           
          contrast: 500L, $
          slidermax: 1000L, $            ; max val for sliders (min=1)
          keyboard_text_id: 0L, $        ; id of keyboard input widget
          image_min: 0.0, $              ; min(main_image)
          image_max: 0.0, $              ; max(main_image)
          min_value: 0.0, $              ; min data value mapped to colors
          max_value: 0.0, $              ; max data value mapped to colors
          mode: 'color', $                ; Zoom, Blink, or Color
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
          pan_track: 0B, $               ; flag=1 while mouse dragging
          cstretch: 0B, $                ; flag = 1 while stretching colors
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
          outersky: 20L  $               ; outer sky radius
        }

nmax = 5000L
pdata = {                               $
          nplot: 0L,                    $ ; Number of line plots
          nmax:  nmax,                  $ ; Maximum number of line plots
          x: replicate(ptr_new(),nmax), $ ; X vector
          y: replicate(ptr_new(),nmax), $ ; Y vector
          color: lonarr(nmax),          $ ; COLOR for PLOT
          psym: lonarr(nmax),           $ ; PSYM for PLOT
          symsize: fltarr(nmax),        $ ; PSYM for PLOT
          thick: fltarr(nmax)           $ ; THICK for PLOT
        }

nmax = 500L
ptext = {                               $
          nplot: 0L,                    $ ; Number of text plots
          nmax:  nmax,                  $ ; Maximum number of text plots
          x: fltarr(nmax),              $ ; X position
          y: fltarr(nmax),              $ ; Y position
          string: replicate(ptr_new(),nmax), $ ; Text string
          alignment: fltarr(nmax),      $ ; ALIGNMENT for XYOUTS
          charsize: fltarr(nmax),       $ ; CHARSIZE for XYOUTS
          charthick: fltarr(nmax),      $ ; CHARTHICK for XYOUTS
          color: lonarr(nmax),          $ ; COLOR for XYOUTS
          font: lonarr(nmax),           $ ; FONT for XYOUTS
          orientation: fltarr(nmax)     $ ; ORIENTATION for XYOUTS
        }

nmax = 10L
pcon = {                                $
          nplot: 0L,                    $ ; Number of contour plots
          nmax:  nmax,                  $ ; Maximum number of contour plots
          z: replicate(ptr_new(),nmax), $ ; Z image
          x: replicate(ptr_new(),nmax), $ ; X vector
          y: replicate(ptr_new(),nmax), $ ; Y vector
          c_annotation: replicate(ptr_new(),nmax), $ ; C_ANNOTATION for CONTOUR
          c_charsize: fltarr(nmax),     $ ; C_CHARSIZE for CONTOUR
          c_charthick: fltarr(nmax),    $ ; C_CHARTHICK for CONTOUR
          c_colors: replicate(ptr_new(),nmax), $ ; C_COLORS for CONTOUR
          c_labels: replicate(ptr_new(),nmax), $ ; C_LABELS for CONTOUR
          c_linestyle: replicate(ptr_new(),nmax), $ ; C_LINESTYLE for CONTOUR
          c_orientation: fltarr(nmax),  $ ; C_ORIENTATION for CONTOUR
          c_spacing: fltarr(nmax),      $ ; C_SPACING for CONTOUR
          c_thick: replicate(ptr_new(),nmax), $ ; C_THICK for CONTOUR
          cell_fill: intarr(nmax),      $ ; CELL_FILL for CONTOUR
          closed: intarr(nmax),         $ ; CLOSED for CONTOUR
          downhill: intarr(nmax),       $ ; DOWNHILL for CONTOUR
          fill: intarr(nmax),           $ ; FILL for CONTOUR
          irregular: intarr(nmax),      $ ; IRREGULAR for CONTOUR
          levels: replicate(ptr_new(),nmax), $ ; LEVELS for CONTOUR
          max_value: fltarr(nmax),      $ ; MAX_VALUE for CONTOUR
          min_value: fltarr(nmax),      $ ; MIN_VALUE for CONTOUR
          nlevels: lonarr(nmax)         $ ; NLEVELS for CONTOUR
        }

phistory = intarr(pdata.nmax + ptext.nmax + pcon.nmax)

; Read in a color table to initialize !d.table_size
; As a bare minimum, we need the 8 basic colors used by ATV_ICOLOR(),
; plus 2 more for a color map.
loadct, 0, /silent
if (!d.table_size LT 10) then $
 message, 'Too few colors available for color table'

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
                  {cw_pdmenu_s, 0, 'Stern Special'}, $
                  {cw_pdmenu_s, 2, 'ATV Special'}, $
                  {cw_pdmenu_s, 1, 'Scaling'}, $      ; scaling menu
                  {cw_pdmenu_s, 0, 'Linear'}, $
                  {cw_pdmenu_s, 0, 'Log'}, $
                  {cw_pdmenu_s, 2, 'HistEq'}, $
                  {cw_pdmenu_s, 1, 'Labels'}, $       ; labels menu
                  {cw_pdmenu_s, 0, 'TextLabel'}, $
                  {cw_pdmenu_s, 0, 'Contour'}, $
                  {cw_pdmenu_s, 0, 'EraseLast'}, $
                  {cw_pdmenu_s, 2, 'EraseAll'}, $
                  {cw_pdmenu_s, 1, 'Help'}, $         ; help menu
                  {cw_pdmenu_s, 2, 'ATV Help'} $
                ]

top_menu = cw_pdmenu(top_menu, top_menu_desc, $
                     ids = state.menu_ids, $
                     /mbar, $
                     /help, $
                     /return_id, $
                     uvalue = 'top_menu')

track_base =    widget_base(base, /row)
info_base = widget_base(track_base, /column, /base_align_right)
;track_base_1 =  widget_base(track_base, /column, /align_right)
;track_base_1a = widget_base(track_base_1, /row, /align_bottom)
;slider_base =   widget_base(track_base_1a, /column, /align_right)
;minmax_base =   widget_base(track_base_1a, /column, /align_right)
;track_base_2 =  widget_base(track_base, /row, /base_align_bottom)
button_base1 =  widget_base(base, /row, /base_align_bottom)
button_base2 =  widget_base(base, /row, /base_align_bottom)
;mode_base =     widget_base(button_base1, /row, /base_align_bottom, /exclusive)

state.draw_base_id = $
  widget_base(base, $
              /column, /base_align_left, $
              /tracking_events, $
              uvalue = 'draw_base', $
              frame = 2)

state.min_text_id = $
  cw_field(info_base, $
           uvalue = 'min_text', $
           /floating,  $
           title = 'Min=', $
           value = state.min_value,  $
           /return_events, $
           xsize = 12)

state.max_text_id = $
  cw_field(info_base, $
           uvalue = 'max_text', $
           /floating,  $
           title = 'Max=', $
           value = state.max_value, $
           /return_events, $
           xsize = 12)

tmp_string = string(1000, 1000, 1.0e-10, $
                    format = '("(",i4,",",i4,") ",g12.5)' )

state.location_bar_id = $
  widget_label (info_base, $
                value = tmp_string,  $
                uvalue = 'location_bar',  frame = 1)



pan_window = $
  widget_draw(track_base, $
              xsize = state.pan_window_size, $
              ysize = state.pan_window_size, $
              frame = 2, uvalue = 'pan_window', $
              /button_events, /motion_events)

track_window = $
  widget_draw(track_base, $
              xsize=state.track_window_size, $
              ysize=state.track_window_size, $
              frame=2, uvalue='track_window')


;state.brightness_slider_id = $
;  widget_slider(slider_base, $
;                /drag, $
;                minimum = 1, $
;                maximum = state.slidermax, $
;                title = 'Brightness', $
;                uvalue = 'brightness', $
;                value = state.slidermax/2, $
;                /suppress_value)


;state.contrast_slider_id = $
;  widget_slider(slider_base, $
;                /drag, $
;                minimum = 1, $
;                maximum = state.slidermax, $
;                title = 'Contrast', $
;                uvalue = 'contrast', $
;                value = state.slidermax/2, $
;                /suppress_value)

modelist = ['Color', 'Zoom', 'Blink']
mode_droplist_id = widget_droplist(button_base1, $
                                   frame = 1, $
                                   title = 'MouseMode:', $
                                   uvalue = 'mode', $
                                   value = modelist)

;zoommode_button = $
;  widget_button(mode_base, $
;                value = 'ZoomMode', $
;                uvalue = 'zoom_mode')
;
;blinkmode_button = $
;  widget_button(mode_base, $
;                value = 'BlinkMode', $
;                uvalue = 'blink_mode')

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

state.draw_widget_id = $
  widget_draw(state.draw_base_id, $
              uvalue = 'draw_window', $
              /motion_events,  /button_events, $
              scr_xsize = state.draw_window_size[0], $
              scr_ysize = state.draw_window_size[1]) 

; Create the widgets on screen

widget_control, base, /realize

;widget_control, zoommode_button, /set_button

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

; modified 7/28/99 AJB
state.base_min_size = [state.base_pad[0] + 512, state.base_pad[1] + 100]

; Initialize the vectors that hold the current color table.
; See the routine atv_stretchct to see why we do it this way.

r_vector = bytarr(!d.table_size-8)
g_vector = bytarr(!d.table_size-8)
b_vector = bytarr(!d.table_size-8)

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

; Modified by AJB 7/29/99 to do a screen capture with tvrd()
; and stretch the screen color table to 256 colors
if ((nfiles EQ 0 OR result EQ 'Yes') AND filename NE '') then begin

    wset, state.draw_window_id

    tvlct, rr, gg, bb, /get

    rn = congrid(rr[8:!d.table_size-1], 248)
    gn = congrid(gg[8:!d.table_size-1], 248)
    bn = congrid(bb[8:!d.table_size-1], 248)

    rvec = bytarr(256)
    gvec = bytarr(256)
    bvec = bytarr(256)

    rvec[0] = rr  ; load in the first 8 colors
    gvec[0] = gg
    bvec[0] = bb

    rvec[8] = temporary(rn)
    gvec[8] = temporary(gn)
    bvec[8] = temporary(bn)

    write_tiff, filename, tvrd(), $
      red = temporary(rvec), $
      green = temporary(gvec), $
      blue = temporary(bvec)
endif

atv_cleartext

end


;----------------------------------------------------------------------

pro atv_writeps

; writes an encapsulated postscript file of the current display, set
; to a width of 6 inches

common atv_state
common atv_images

widget_control, /hourglass

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
    tvlct, rr, gg, bb, 8, /get
    wset, state.draw_window_id

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
    
    rn = congrid(rr, 248)
    gn = congrid(gg, 248)
    bn = congrid(bb, 248)
    
    tvlct, temporary(rn), temporary(gn), temporary(bn), 8
; AJB added atv_plotall below 7/28/99 to do plot overlays    
;    tv, temporary(tmp_image)
    tv, bytscl(display_image, top = 247) + 8
    atv_plotall

    device, /close
    set_plot, screen_device
    tvlct, temporary(rr), temporary(gg), temporary(bb), 8
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

; Routine to return an vector of length !d.table_size-8,
; defined by a 5th order polynomial.   Called by atv_makect
; to define new color tables in terms of polynomial coefficients.

x = findgen(256)

y = p[0] + x * p[1] + x^2 * p[2] + x^3 * p[3] + x^4 * p[4] + x^5 * p[5]

w = where(y GT 255, nw)
if (nw GT 0) then y(w) = 255

w =  where(y LT 0, nw)
if (nw GT 0) then y(w) = 0

z = congrid(y, !d.table_size-8)

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

tvlct, r, g, b, 8

if (state.invert_colormap EQ 1) then begin
    r = abs (r - 255)
    g = abs (g - 255)
    b = abs (b - 255)
endif

r_vector = temporary(r)
g_vector = temporary(g)
b_vector = temporary(b)
    
atv_stretchct, state.brightness, state.contrast

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

; Clear all plot annotations
atverase, /norefresh    ; added AJB 7/27/99

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

; Changed central x to be green always
;device, set_graphics = 10
plots, [0.46, 0.54], [0.46, 0.54], /normal, color = 2
plots, [0.46, 0.54], [0.54, 0.46], /normal, color = 2
;device, set_graphics = 3

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
common atv_color

widget_control, event.id, get_uvalue = uvalue

case uvalue of

;    'zoom_mode': state.mode = 'zoom'
;    'blink_mode': state.mode = 'blink'

    'mode': case event.index of
        0: state.mode = 'color'
        1: state.mode = 'zoom'
        2: state.mode = 'blink'
        else: print, 'Unknown mouse mode!'
    endcase

    'atv_base': begin  ; main window resize: preserve display center
        atv_resize, event
        atv_refresh
        atv_cleartext
    end

    'top_menu': begin       ; selection from menu bar
        widget_control, event.value, get_value = event_name
        
        case event_name of
            
; File menu options:
            'ReadFits': atv_readfits
            'WriteEPS' : atv_writeps
            'WriteTiff': atv_writetiff
            'Quit':     atv_shutdown
; ColorMap menu options:            
            'Grayscale': atv_getct, 0
            'Blue-White': atv_getct, 1
            'Red-Orange': atv_getct, 3
            'BGRY': atv_getct, 4
            'Rainbow': atv_getct, 13
            'Stern Special': atv_getct, 15
            'ATV Special': atv_makect, event_name
; Scaling options:
            'Linear': begin
                state.scaling = 0
                atv_displayall
                atv_cleartext
            end
            'Log': begin
                state.scaling = 1
                atv_displayall
                atv_cleartext
            end
            'HistEq': begin
                state.scaling = 2
                atv_displayall
                atv_cleartext
            end
; Label options:
            'TextLabel': atv_textlabel
            'Contour': atv_oplotcontour
            'Draw': atv_draw
            'EraseLast': atverase, 1
            'EraseAll': atverase
; Help options:            
            'ATV Help': atv_help

            else: print, 'Unknown event in file menu!'
        endcase
        
    end   ; end of file menu options




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
        
        if (event.type EQ 2) then begin   ; motion event
            case state.cstretch of
                0: begin           ;update tracking image and status bar
                    tmp_event = [event.x, event.y]            
                    state.mouse = round( (0.5 > $
                         ((tmp_event / state.zoom_factor) + state.offset) $
                         < (state.image_size - 0.5) ) - 0.5)
                    atv_gettrack
                end
                1: begin           ; update color table
                    atv_stretchct, event.x, event.y, /getmouse
                end

            endcase
                
        endif

        if (state.mode EQ 'blink' AND event.type EQ 0) then begin
            wset, state.draw_window_id
            if n_elements(blink_image) GT 1 then $
              tv, blink_image
        endif

        if (state.mode EQ 'blink' AND event.type EQ 1) then begin
            wset, state.draw_window_id
;           tv, display_image        modified AJB 7/26/99
            tv, unblink_image
        endif            
 
        if (state.mode EQ 'zoom' and event.type EQ 0) then begin
            case event.press of
                1: atv_zoom, 'in', /recenter
                2: atv_zoom, 'none', /recenter
                4: atv_zoom, 'out', /recenter
                else: print,  'trouble in atv_event, mouse zoom'
            endcase
            
        endif
                
        if (state.mode EQ 'color' AND event.type EQ 0) then begin
            state.cstretch = 1
            atv_stretchct, event.x, event.y, /getmouse
        endif
        if (state.mode EQ 'color' AND event.type EQ 1) then $
          state.cstretch = 0

        widget_control, state.keyboard_text_id, /input_focus
                    
    end

;    'brightness': atv_stretchct      ; brightness slider move
;    'contrast'  : atv_stretchct      ; contrast slider move

    'invert': begin                  ; invert the color table
        state.invert_colormap = abs(state.invert_colormap - 1)
        tvlct, r, g, b, 8, /get

        r = abs( r - 255 )
        g = abs( g - 255 )
        b = abs( b - 255 )
        r_vector = abs( r_vector - 255 )
        g_vector = abs( g_vector - 255 )
        b_vector = abs( b_vector - 255 )

        tvlct, r, g, b, 8
        
        atv_cleartext
    end

    'reset_color': begin   ; set color sliders to default positions
;        widget_control, $
;          state.brightness_slider_id, set_value = state.slidermax / 2
;        widget_control, $
;          state.contrast_slider_id, set_value = state.slidermax / 2
        state.brightness = state.slidermax / 2
        state.contrast = state.slidermax / 2
        atv_stretchct, state.brightness, state.contrast
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
        wset, state.draw_window_id
        blink_image = tvrd()
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
        widget_control, state.keyboard_text_id, /clear_events
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
common atv_pdata

if (xregistered ('atv')) then begin
    widget_control, state.base_id, /destroy
endif

; Added 8/2/99 by AJB
if (n_elements(phistory) GT 1) then begin
    atverase, /norefresh
    pdata = 0
    ptext = 0
    pcon = 0
    phistory = 0
endif

main_image = 0
display_image = 0
scaled_image = 0
blink_image = 0
unblink_image = 0
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
             top = !d.table_size-8) + 8
    
; AJB fixed following bit on 7/26/99:
    1: tmp_image = $                 ; log stretch
      bytscl( alog10 (bytscl(main_image, $                       
                             min=state.min_value, $
                             max=state.max_value) + 1),  $
            top = !d.table_size - 8) + 8
    
    2: tmp_image = $                 ; histogram equalization
      bytscl(hist_equal(main_image, $
                        minv = state.min_value, $    
                        maxv = state.max_value), $
             top = !d.table_size-8) + 8
    
endcase

scaled_image = bytarr(state.image_size[0] + 10, $
                             state.image_size[1] + 10)

scaled_image[5, 5] = temporary(tmp_image)

end

;----------------------------------------------------------------------
function atv_icolor, color

;   if (NOT keyword_set(color)) then color = !p.color

;  modified by AJB 7/29/99
;   if (NOT keyword_set(color)) then return, 1 ; Default to red
   if (n_elements(color) EQ 0) then return, 1

   ncolor = N_elements(color)

   ; If COLOR is a string or array of strings, then convert color names
   ; to integer values
   if (size(color,/tname) EQ 'STRING') then begin ; Test if COLOR is a string

      ; Detemine the default color for the current device
      if (!d.name EQ 'X') then defcolor = 7 $ ; white for X-windows
       else defcolor = 0 ; black otherwise

      icolor = 0 * (color EQ 'black') $
             + 1 * (color EQ 'red') $
             + 2 * (color EQ 'green') $
             + 3 * (color EQ 'blue') $
             + 4 * (color EQ 'cyan') $
             + 5 * (color EQ 'magenta') $
             + 6 * (color EQ 'yellow') $
             + 7 * (color EQ 'white') $
             + defcolor * (color EQ 'default')

   endif else begin
      icolor = long(color)
   endelse

   return, icolor
end 

;----------------------------------------------------------------------
pro atv_plot1plot, iplot
common atv_pdata

; Added hourglass cursor here and in other plot1 routines
; AJB 8/2/99
widget_control, /hourglass

oplot, *(pdata.x[iplot]), *(pdata.y[iplot]), $
 color=pdata.color[iplot], psym=pdata.psym[iplot], $
 symsize=pdata.symsize[iplot], thick=pdata.thick[iplot]

return
end

;----------------------------------------------------------------------
pro atv_plot1text, iplot
common atv_pdata

widget_control, /hourglass

xyouts, ptext.x[iplot], ptext.y[iplot], *(ptext.string[iplot]), $
 alignment=ptext.alignment[iplot], charsize=ptext.charsize[iplot], $
 charthick=ptext.charthick[iplot], color=ptext.color[iplot], $
 font=ptext.font[iplot], orientation=ptext.orientation[iplot]

return
end

;----------------------------------------------------------------------
pro atv_plot1contour, iplot
common atv_pdata

widget_control, /hourglass

xrange = !x.crange
yrange = !y.crange

; The following allows for 4 conditions, depending upon whether X and Y
; are set on whether LEVELS is set.
; In addition, I have commented out C_ORIENTATION and C_SPACING, since
; these seem to force FILL - is this an IDL bug?
dims = size(*(pcon.z[iplot]),/dim)
levels = *(pcon.levels[iplot])
if (size(*(pcon.x[iplot]),/N_elements) EQ dims[0] $
 AND size(*(pcon.y[iplot]),/N_elements) EQ dims[1] ) then begin
   if (N_elements(levels) GT 1) then begin
contour, *(pcon.z[iplot]), *(pcon.x[iplot]), *(pcon.y[iplot]), $
 c_annotation=*(pcon.c_annotation[iplot]), c_charsize=pcon.c_charsize[iplot], $
 c_charthick=pcon.c_charthick[iplot], c_colors=*(pcon.c_colors[iplot]), $
 c_labels=*(pcon.c_labels[iplot]), c_linestyle=*(pcon.c_linestyle[iplot]), $
; c_orientation=pcon.c_orientation[iplot], c_spacing=pcon.c_spacing[iplot], 
 c_thick=*(pcon.c_thick[iplot]), cell_fill=pcon.cell_fill[iplot], $
 closed=pcon.closed[iplot], downhill=pcon.downhill[iplot], $
 fill=pcon.fill[iplot], irregular=pcon.irregular[iplot], $
 levels=*(pcon.levels[iplot]), $
 max_value=pcon.max_value[iplot], min_value=pcon.min_value[iplot], $
 nlevels=pcon.nlevels[iplot], $
 position=[0,0,1,1], xrange=xrange, yrange=yrange, xstyle=5, ystyle=5, /noerase
   endif else begin
contour, *(pcon.z[iplot]), *(pcon.x[iplot]), *(pcon.y[iplot]), $
 c_annotation=*(pcon.c_annotation[iplot]), c_charsize=pcon.c_charsize[iplot], $
 c_charthick=pcon.c_charthick[iplot], c_colors=*(pcon.c_colors[iplot]), $
 c_labels=*(pcon.c_labels[iplot]), c_linestyle=*(pcon.c_linestyle[iplot]), $
; c_orientation=pcon.c_orientation[iplot], c_spacing=pcon.c_spacing[iplot], $
 c_thick=*(pcon.c_thick[iplot]), cell_fill=pcon.cell_fill[iplot], $
 closed=pcon.closed[iplot], downhill=pcon.downhill[iplot], $
 fill=pcon.fill[iplot], irregular=pcon.irregular[iplot], $
; levels=*(pcon.levels[iplot]), $
 max_value=pcon.max_value[iplot], min_value=pcon.min_value[iplot], $
 nlevels=pcon.nlevels[iplot], $
 position=[0,0,1,1], xrange=xrange, yrange=yrange, xstyle=5, ystyle=5, /noerase
   endelse
endif else begin
   if (N_elements(levels) GT 1) then begin
contour, *(pcon.z[iplot]), $
 c_annotation=*(pcon.c_annotation[iplot]), c_charsize=pcon.c_charsize[iplot], $
 c_charthick=pcon.c_charthick[iplot], c_colors=*(pcon.c_colors[iplot]), $
 c_labels=*(pcon.c_labels[iplot]), c_linestyle=*(pcon.c_linestyle[iplot]), $
; c_orientation=pcon.c_orientation[iplot], c_spacing=pcon.c_spacing[iplot], $
 c_thick=*(pcon.c_thick[iplot]), cell_fill=pcon.cell_fill[iplot], $
 closed=pcon.closed[iplot], downhill=pcon.downhill[iplot], $
 fill=pcon.fill[iplot], irregular=pcon.irregular[iplot], $
 levels=*(pcon.levels[iplot]), $
 max_value=pcon.max_value[iplot], min_value=pcon.min_value[iplot], $
 nlevels=pcon.nlevels[iplot], $
 position=[0,0,1,1], xrange=xrange, yrange=yrange, xstyle=5, ystyle=5, /noerase
         endif else begin
contour, *(pcon.z[iplot]), $
 c_annotation=*(pcon.c_annotation[iplot]), c_charsize=pcon.c_charsize[iplot], $
 c_charthick=pcon.c_charthick[iplot], c_colors=*(pcon.c_colors[iplot]), $
 c_labels=*(pcon.c_labels[iplot]), c_linestyle=*(pcon.c_linestyle[iplot]), $
; c_orientation=pcon.c_orientation[iplot], c_spacing=pcon.c_spacing[iplot], $
 c_thick=*(pcon.c_thick[iplot]), cell_fill=pcon.cell_fill[iplot], $
 closed=pcon.closed[iplot], downhill=pcon.downhill[iplot], $
 fill=pcon.fill[iplot], irregular=pcon.irregular[iplot], $
; levels=*(pcon.levels[iplot]), $
 max_value=pcon.max_value[iplot], min_value=pcon.min_value[iplot], $
 nlevels=pcon.nlevels[iplot], $
 position=[0,0,1,1], xrange=xrange, yrange=yrange, xstyle=5, ystyle=5, /noerase
   endelse
endelse

return
end

;----------------------------------------------------------------------
pro atv_plotwindow
common atv_state

;   wset, state.draw_window_id    commented out by AJB 7/26/99

; Set plot window
xrange=[state.offset[0], $
 state.offset[0] + state.draw_window_size[0] / state.zoom_factor] - 0.5
yrange=[state.offset[1], $
 state.offset[1] + state.draw_window_size[1] / state.zoom_factor] - 0.5

plot, [0], [0], /nodata, position=[0,0,1,1], $
 xrange=xrange, yrange=yrange, xstyle=5, ystyle=5, /noerase

return
end

;----------------------------------------------------------------------
pro atv_plotall
common atv_state
common atv_pdata

; Routine to overplot line plots from ATVPLOT and text from ATVXYOUTS

if (pdata.nplot GT 0 OR ptext.nplot GT 0 OR pcon.nplot GT 0) then begin
   atv_plotwindow

   for iplot=0, pcon.nplot-1 do $
    atv_plot1contour, iplot

   for iplot=0, pdata.nplot-1 do $
    atv_plot1plot, iplot

   for iplot=0, ptext.nplot-1 do $
    atv_plot1text, iplot

endif

end

;----------------------------------------------------------------------

pro atvplot, x, y, color=color, psym=psym, symsize=symsize, thick=thick
common atv_pdata
common atv_state

; Routine to overplot line plots

if (N_params() LT 1) then begin
   print, 'Too few parameters for ATVPLOT'
   return
endif

if (pdata.nplot LT pdata.nmax) then begin
   iplot = pdata.nplot

   if (N_params() EQ 1) then begin
      pdata.x[iplot] = ptr_new(findgen(N_elements(x)))
      pdata.y[iplot] = ptr_new(x)
   endif else begin
      pdata.x[iplot] = ptr_new(x)
      pdata.y[iplot] = ptr_new(y)
   endelse

   pdata.color[iplot] = atv_icolor(color)
   if (keyword_set(psym)) then pdata.psym[iplot] = psym $
    else pdata.psym[iplot] = 0
   if (keyword_set(symsize)) then pdata.symsize[iplot] = symsize $
    else pdata.symsize[iplot] = 1.0
   if (keyword_set(thick)) then pdata.thick[iplot] = thick $
    else pdata.thick[iplot] = 1.0

   wset, state.draw_window_id
   atv_plotwindow
   atv_plot1plot, pdata.nplot
   pdata.nplot = pdata.nplot + 1
endif else begin
   print, 'Too many calls to ATVPLOT'
endelse

phistory[pdata.nplot + ptext.nplot + pcon.nplot - 1] = 1 ; points

end

;----------------------------------------------------------------------

pro atvxyouts, x, y, string, alignment=alignment, charsize=charsize, $
 charthick=charthick, color=color, font=font, orientation=orientation
common atv_pdata
common atv_state

; Routine to overplot text

if (N_params() LT 3) then begin
   print, 'Too few parameters for ATVXYOUTS'
   return
endif

if (ptext.nplot LT ptext.nmax) then begin
   iplot = ptext.nplot

   ptext.x[iplot] = x
   ptext.y[iplot] = y
   ptext.string[iplot] = ptr_new(string)
   if (keyword_set(alignment)) then ptext.alignment[iplot] = alignment $
    else ptext.alignment[iplot] = 0.0
   if (keyword_set(charsize)) then ptext.charsize[iplot] = charsize $
    else ptext.charsize[iplot] = 1.0
   if (keyword_set(charthick)) then ptext.charthick[iplot] = charthick $
    else ptext.charthick[iplot] = 1.0
   ptext.color[iplot] = atv_icolor(color)
   if (keyword_set(font)) then ptext.font[iplot] = font $
    else ptext.font[iplot] = 1
   if (keyword_set(orientation)) then ptext.orientation[iplot] = orientation $
    else ptext.orientation[iplot] = 0.0

   wset, state.draw_window_id
   atv_plotwindow
   atv_plot1text, ptext.nplot
   ptext.nplot = ptext.nplot + 1
endif else begin
   print, 'Too many calls to ATVPLOT'
endelse

phistory[pdata.nplot + ptext.nplot + pcon.nplot - 1] = 2 ; text

end

;----------------------------------------------------------------------

pro atvcontour, z, x, y, c_annotation=c_annotation, c_charsize=c_charsize, $
 c_charthick=c_charthick, c_colors=c_colors, c_labels=c_labels, $
 c_linestyle=c_linestyle, c_orientation=c_orientation, c_spacing=c_spacing, $
 c_thick=c_thick, cell_fill=cell_fill, closed=closed, downhill=downhill, $
 fill=fill, irregular=irregular, levels=levels, max_value=max_value, $
 min_value=min_value, nlevels=nlevels
common atv_pdata
common atv_state

; Routine to overplot contours

if (N_params() LT 1) then begin
   print, 'Too few parameters for ATVCONTOUR'
   return
endif

if (pcon.nplot LT pcon.nmax) then begin
   iplot = pcon.nplot

   pcon.z[iplot] = ptr_new(z)
   if (keyword_set(x)) then pcon.x[iplot] = ptr_new(x) $
    else pcon.x[iplot] = ptr_new(0)
   if (keyword_set(y)) then pcon.y[iplot] = ptr_new(y) $
    else pcon.y[iplot] = ptr_new(0)
   if (keyword_set(c_annotation)) then $
    pcon.c_annotation[iplot] = ptr_new(c_annotation) $
    else pcon.c_annotation[iplot] = ptr_new(0)
   if (keyword_set(c_charsize)) then pcon.c_charsize[iplot] = c_charsize $
    else pcon.c_charsize[iplot] = 0
   if (keyword_set(c_charthick)) then pcon.c_charthick[iplot] = c_charthick $
    else pcon.c_charthick[iplot] = 0
   pcon.c_colors[iplot] = ptr_new(atv_icolor(c_colors))
   if (keyword_set(c_labels)) then pcon.c_labels[iplot] = ptr_new(c_labels) $
    else pcon.c_labels[iplot] = ptr_new(0)
   if (keyword_set(c_linestyle)) then $
    pcon.c_linestyle[iplot] = ptr_new(c_linestyle) $
    else pcon.c_linestyle[iplot] = ptr_new(0)
   if (keyword_set(c_orientation)) then $
    pcon.c_orientation[iplot] = c_orientation $
    else pcon.c_orientation[iplot] = 0
   if (keyword_set(c_spacing)) then pcon.c_spacing[iplot] = c_spacing $
    else pcon.c_spacing[iplot] = 0
   if (keyword_set(c_thick)) then pcon.c_thick[iplot] = ptr_new(c_thick) $
    else pcon.c_thick[iplot] = ptr_new(0)
   if (keyword_set(cell_fill)) then pcon.cell_fill[iplot] = cell_fill $
    else pcon.cell_fill[iplot] = 0
   if (keyword_set(closed)) then pcon.closed[iplot] = closed $
    else pcon.closed[iplot] = 0
   if (keyword_set(downhill)) then pcon.downhill[iplot] = downhill $
    else pcon.downhill[iplot] = 0
   if (keyword_set(fill)) then pcon.fill[iplot] = fill $
    else pcon.fill[iplot] = 0
   if (keyword_set(irregular)) then pcon.irregular[iplot] = irregular $
    else pcon.irregular[iplot] = 0
   if (keyword_set(levels)) then pcon.levels[iplot] = ptr_new(levels) $
    else pcon.levels[iplot] = ptr_new(0)
   if (keyword_set(max_value)) then pcon.max_value[iplot] = max_value $
    else pcon.max_value[iplot] = !values.d_infinity
   if (keyword_set(min_value)) then pcon.min_value[iplot] = min_value $
    else pcon.min_value[iplot] = - !values.d_infinity
   if (keyword_set(nlevels)) then pcon.nlevels[iplot] = nlevels $
    else pcon.nlevels[iplot] = 0

   wset, state.draw_window_id
   atv_plotwindow
   atv_plot1contour, pcon.nplot
   pcon.nplot = pcon.nplot + 1
endif else begin
   print, 'Too many calls to ATVCONTOUR'
endelse

phistory[pdata.nplot + ptext.nplot + pcon.nplot - 1] = 3 ; contour

end

;----------------------------------------------------------------------

pro atverase, nerase, norefresh = norefresh
common atv_pdata

; Routine to erase line plots from ATVPLOT, text from ATVXYOUTS, and
; contours from ATVCONTOUR.

; keyword norefresh added AJB 7/27/99
; The norefresh keyword is used by atv_getstats, when a new image
;   has just been read in, and by atv_shutdown.

nplotall = pdata.nplot + ptext.nplot + pcon.nplot
if (N_params() LT 1) then nerase = nplotall $
else if (nerase GT nplotall) then nerase = nplotall

for ihistory=nplotall-nerase, nplotall-1 do begin
   if (phistory[ihistory] EQ 1) then begin
      ; Erase a point plot
      pdata.nplot = pdata.nplot - 1
      iplot = pdata.nplot
      ptr_free, pdata.x[iplot], pdata.y[iplot]
   endif else if (phistory[ihistory] EQ 2) then begin
      ; Erase a text plot
      ptext.nplot = ptext.nplot - 1
      iplot = ptext.nplot
      ptr_free, ptext.string[iplot]
   endif else if (phistory[ihistory] EQ 3) then begin
      ; Erase a contour plot
      pcon.nplot = pcon.nplot - 1
      iplot = pcon.nplot
; AJB fixed following line by adding [iplot] below, 8/2/99
      ptr_free, pcon.z[iplot], pcon.x[iplot], pcon.y[iplot], $
        pcon.c_annotation[iplot], pcon.c_colors[iplot], $
        pcon.c_labels[iplot], pcon.c_linestyle[iplot], $
        pcon.c_thick[iplot], pcon.levels[iplot]
   endif
endfor

if (NOT keyword_set(norefresh) ) then atv_refresh

end

;---------------------------------------------------------------------

pro atv_getdisplay

; make the display image from the scaled image by applying the zoom
; factor and matching to the size of the draw window, and display the
; image.

common atv_state
common atv_images

widget_control, /hourglass    ; added by AJB 7/26/99

; Major change 7/26/99 AJB:
; display_image is now equal in size to the display viewport,
;   the way it should have been done in the first place.
display_image = bytarr(state.draw_window_size[0], state.draw_window_size[1])

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

; AJB modifications 7/26/99 to fit tmp_image into display_image
xmax = newsize[0] < (state.draw_window_size[0] - startpos[0])
ymax = newsize[1] < (state.draw_window_size[1] - startpos[1])

display_image[startpos[0], startpos[1]] = $
  temporary(tmp_image[0:xmax-1, 0:ymax-1])


; Display the image

wset, state.draw_window_id
erase
tv, display_image

; Overplot x,y plots from atvplot
atv_plotall

wset, state.draw_window_id
unblink_image = tvrd()     ; moved here by AJB 8/11/99

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

; Added by AJB 7/26/99 to prevent unwanted mouse clicks
widget_control, state.draw_base_id, /clear_events   

end

;--------------------------------------------------------------------

pro atv_stretchct, brightness, contrast,  getmouse = getmouse

; modified by AJB 8/18/99
; routine to change color stretch for given values of 
; brightness and contrast.
; Brightness and contrast range from 1 up to state.slidermax

common atv_state
common atv_color

if (keyword_set(getmouse)) then begin
    contrast = 0 > (contrast / float(state.draw_window_size[1]) * $
                    state.slidermax) < (state.slidermax-1)
    contrast = long(abs(state.slidermax - contrast))

    brightness = 0 > $
      (brightness / float(state.draw_window_size[0]) * state.slidermax) < $
      (state.slidermax - 1)
    brightness = long(abs(brightness-state.slidermax))
endif

d = byte(!d.table_size - 8)

maxdp = 600
mindp = 4

if (contrast LT (state.slidermax / 2)) then begin
    dp = ((d - maxdp) / float((state.slidermax / 2) - 1)) * contrast + $
      ((maxdp * state.slidermax / 2) - d) / float(state.slidermax / 2)
endif else begin
    dp = ((mindp - d) / float(state.slidermax / 2)) * contrast + $
      ((d * state.slidermax) - (mindp * state.slidermax / 2)) / $
      float(state.slidermax / 2)
endelse

dp =  fix(dp)

r = replicate(r_vector(d-1), 2*d + dp)
g = replicate(g_vector(d-1), 2*d + dp)
b = replicate(b_vector(d-1), 2*d + dp)

r[0:d-1] = r_vector(0)
g[0:d-1] = g_vector(0)
b[0:d-1] = b_vector(0)

a = findgen(d)

r[d] = congrid(r_vector, dp)
g[d] = congrid(g_vector, dp)
b[d] = congrid(b_vector, dp)

bshift = round(brightness * (d+dp) / float(state.slidermax))

rr = r[a + bshift] 
gg = g[a + bshift]
bb = b[a + bshift]

tvlct, rr, gg, bb, 8

;atv_cleartext

state.brightness = brightness
state.contrast = contrast

end


;--------------------------------------------------------------------

pro atv_getct, tablenum

; Read in a pre-defined color table, and invert if necessary.

common atv_color
common atv_state

; Load a simple color table with the basic 8 colors in the lowest 8 entries
; of the color table
rtiny   = [0, 1, 0, 0, 0, 1, 1, 1]
gtiny = [0, 0, 1, 0, 1, 0, 1, 1]
btiny  = [0, 0, 0, 1, 1, 1, 0, 1]
tvlct, 255*rtiny, 255*gtiny, 255*btiny

loadct, tablenum, /silent,  bottom=8
tvlct, r, g, b, 8, /get

if (state.invert_colormap EQ 1) then begin
    r = abs (r - 255)
    g = abs (g - 255)
    b = abs (b - 255)
endif

r_vector = r
g_vector = g
b_vector = b

atv_stretchct, state.brightness, state.contrast

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

; AJB modified 7/26/99 to test for med GT 0
state.min_value = (med - (2 * sig))  > min(main_image)
if (state.min_value LT 0 AND med GT 0) then begin
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
  ytitle = 'Pixel Value', $
  color = 7   ; added by AJB 7/26/99, and in the following 3 routines

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
  ytitle = 'Pixel Value', $
  color = 7

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
  xtitle = 'X', ytitle = 'Y', ztitle = 'Pixel Value', $
  color = 7

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
  xtitle = 'X', ytitle = 'Y', color = 7

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

h = strarr(70)
i = 0
h[i] =  'ATV HELP'
i = i + 1
h[i] =  ''
i = i + 1
h[i] =  'MENU BAR:'
i = i + 1
h[i] =  'File->ReadFits:     read in a new fits image from disk'
i = i + 1
h[i] =  'File->WriteEPS:     write an encapsulated PS file of the current display'
i = i + 1
h[i] =  'File->WriteTiff:    write a tiff image of the current display'
i = i + 1
h[i] =  'File->Quit:         quits atv'
i = i + 1
h[i] =  'ColorMap Menu:      selects color table'
i = i + 1
h[i] =  'Scaling Menu:       selects linear, log, or histogram-equalized scaling'
i = i + 1
h[i] =  'Labels->TextLabel:  Brings up a dialog box for text input'
i = i + 1
h[i] =  'Labels->Contour:    Brings up a dialog box for overplotting contours'
i = i + 1
h[i] =  'Labels->EraseLast:  Erases the most recent plot label'
i = i + 1
h[i] =  'Labels->EraseAll:   Erases all plot labels'
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
i = i + 2
h[i] = 'IDL COMMAND LINE HELP:'
i = i + 1
h[i] =  'To pass an array to atv:'
i = i + 1
h[i] =  '   atv, array_name [, options]'
i = i + 1
h[i] = 'To pass a fits filename to atv:'
i = i + 1
h[i] = '    atv, fitsfile_name [, options] (enclose filename in single quotes) '
i = i + 1
h[i] = 'To overplot a contour plot on the draw window:'
i = i + 1
h[i] = '    atvcontour, array_name [, options...]'
i = i + 1
h[i] = 'To overplot text on the draw window: '
i = i + 1
h[i] = '    atvxyouts, x, y, text_string [, options]  (enclose string in single quotes)'
i = i + 1
h[i] = 'To overplot points or lines on the current plot:'
i = i + 1
h[i] = '    atvplot, xvector, yvector [, options]'
i = i + 2
h[i] = 'The options for atvcontour, atvxyouts, and atvplot are essentially'
i = i + 1
h[i] =  'the same as those for the idl contour, xyouts, and plot commands,'
i = i + 1
h[i] = 'except that data coordinates are always used.' 
i = i + 1
h[i] = 'The default color is red for overplots done from the idl command line.'
i = i + 2
h[i] = 'Other commands:'
i = i + 1
h[i] = 'atverase [, N]:       erases all (or last N) plots and text'
i = i + 1
h[i] = 'atv_shutdown:   quits atv'
i = i + 1
h[i] = 'NOTE: If atv should crash, type atv_shutdown at the idl prompt.'

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
                            xsize = 85, $
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

;---------------------------------------------------------------------

pro atv_textlabel

; widget front end for atvxyouts, AJB 7/27/99


formdesc = ['0, text, , label_left=Text: , width=15', $
            '0, integer, 0, label_left=x: ', $
            '0, integer, 0, label_left=y: ', $
            '0, droplist, black|red|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
            '0, float, 2.0, label_left=Charsize: ', $
            '0, integer, 1, label_left=Charthick: ', $
            '0, integer, 0, label_left=Orientation: ', $
            '1, base, , row', $
            '0, button, Cancel, quit', $
            '0, button, DrawText, quit']
            
textform = cw_form(formdesc, /column, $
                   title = 'atv text label')

if (textform.tag9 EQ 1) then begin
    atvxyouts, textform.tag1, textform.tag2, textform.tag0, $
      color = textform.tag3, charsize = textform.tag4, $
      charthick = textform.tag5, orientation = textform.tag6
endif

end

;---------------------------------------------------------------------

pro atv_oplotcontour

; widget front end for atvcontour,  AJB 7/27/99

common atv_state
common atv_images

minvalstring = strcompress('0, float, ' + string(state.min_value) + $
                           ', label_left=MinValue: , width=15 ')
maxvalstring = strcompress('0, float, ' + string(state.max_value) + $
                           ', label_left=MaxValue: , width=15')

formdesc = ['0, droplist, black|red|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
;            '0, float, 1.0, label_left=Charsize: ', $
;            '0, integer, 1, label_left=Charthick: ', $
            '0, droplist, solid|dotted|dashed|dashdot|dashdotdotdot|longdash, label_left=Linestyle: , set_value=0', $
            '0, integer, 1, label_left=LineThickness: ', $
            minvalstring, $
            maxvalstring, $
            '0, integer, 6, label_left=NLevels: ', $
            '1, base, , row,', $
            '0, button, Cancel, quit', $
            '0, button, DrawContour, quit']
            
cform = cw_form(formdesc, /column, $
                   title = 'atv text label')


if (cform.tag8 EQ 1) then begin
    atvcontour, main_image, c_color = cform.tag0, $
;      c_charsize = cform.tag1, c_charthick = cform.tag2, $
      c_linestyle = cform.tag1, $
      c_thick = cform.tag2, $
      min_value = cform.tag3, max_value = cform.tag4, $, 
      nlevels = cform.tag5
endif

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

if ( (n_params() NE 0) AND (size(image, /tname) NE 'STRING') ) then begin
    if ( (size(image))[0] NE 2) then begin
        print, 'Input data must be a 2-d array!'
        retall
    endif
endif

; Added by AJB 7/27/99: if image is a string, read in the fits file
; whose name is that string.

if ( (n_params() NE 0) AND (size(image, /tname) EQ 'STRING') ) then begin
    fits_read, image, tmp_image

    if ( (size(tmp_image))[0] NE 2 ) then begin
        print, 'Error-- selected file is not a 2-D fits image!'
        junk = size( temporary(tmp_image))
        retall
    endif

    main_image = temporary(tmp_image)

endif

if ( (n_params() EQ 0) AND (not (xregistered('atv')))) then begin
;    main_image = bytscl(dist(500,500)^2 * sin(dist(500,500)/2.)^2)
    main_image = byte((findgen(500)*2-200) # (findgen(500)*2-200))
endif else begin
    scaled_image = 0
    display_image = 0
; next line modified by AJB 7/27/99
    if (size(image, /tname) NE 'STRING') then main_image = image
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

