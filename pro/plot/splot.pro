;+
; NAME:
;   splot
;
; PURPOSE:
;   Interactive plotting tool for 1-D data.
;
; CALLING SEQUENCE:
;   splot, [x], y, $
;    [color=, psym=, symsize=, thick= ]
;
;   soplot, [x], y, [/autoscale], $
;    [color=, psym=, symsize=, thick= ]
;
;   sxyouts, x, y, string, [alignment=, charsize=, charthick=, color=, $
;    font=, orientation= ]
;
;   serase, [nerase, /norefresh]
;
; INPUTS:
;
; OUTPUT:
;
; COMMENTS:
;   This code is based upon Aaron Barth's ATV procedure.
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;   readfits
;
; INTERNAL SUPPORT ROUTINES:
;   gausspix
;   splot_startup
;   splot_clearkeylist
;   splot_displayall
;   splot_readfits
;   splot_writetiff
;   splot_writeeps
;   splot_cleartext
;   splot_zoom
;   splot_gettrack
;   splot_event
;   splot_shutdown
;   splot_resize
;   splot_icolor()
;   splot_plot1plot
;   splot_plot1text
;   splot_plotwindow
;   splot_plotall
;   sxyouts
;   splot_move_cursor
;   splot_set_minmax
;   splot_get_minmax
;   splot_refresh
;   splot_help
;   splot_help_event
;   serase
;   splot_autoscale
;   soplot
;   splot
;
; REVISION HISTORY:
;   28-Sep-1999  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------
; Routine to evaluate a gaussian function integrated over a pixel of width 1,
; plus any number of polynomial terms for a background level
;    A[0] = center of the Gaussian
;    A[1] = sigma width of the Ith Gaussian
;    A[2] = normalization of the Gaussian
;    A[3...] = polynomial coefficients for background terms

pro gausspix, x, a, f, pder

   ncoeff = N_elements(a)
   f = a[2] * a[1] * (gaussint((x+0.5-a[0])/a[1]) -gaussint((x-0.5-a[0])/a[1]))

   if (ncoeff GT 3) then begin
      f = f + poly(x, a[3:ncoeff-1])
   endif

   return
end

;------------------------------------------------------------------------------

pro splot_startup

   common splot_state, state
   common splot_pdata, pdata, ptext, phistory

   keylist = { key:' ', x:0.0, y:0.0 }

   state = {                     $
    base_id: 0L,                 $ ; ID of top-level base
    base_min_size: [512L, 512L], $ ; min size for top-level base
    draw_base_id: 0L           , $ ; ID of base holding draw window
    draw_window_id: 0L         , $ ; window ID of draw window
    draw_widget_id: 0L         , $ ; widget ID of draw widget
    location_bar_id: 0L        , $ ; ID of (x,y,value) label
    xrange_text_id: 0L         , $ ; ID of XRANGE= widget
    yrange_text_id: 0L         , $ ; ID of YRANGE= widget
    comments_text_id: 0L       , $ ; ID of comments output widget
    keyboard_text_id: 0L       , $ ; ID of keyboard input widget
    nkey: 0                    , $ ; Number of elements in keylist
    keylist: replicate(keylist,2), $ ; Record of keystrokes + cursor in plot
    xrange: [0.0,1.0]          , $ ; X range of plot window
    yrange: [0.0,1.0]          , $ ; Y range of plot window
    position: [0.15,0.15,0.95,0.95], $ ; POSITION for PLOT procedure
    draw_window_size: [512L, 512L], $    ; size of main draw window
    menu_ids: lonarr(25)       , $ ; list of top menu items
    mouse: [0L, 0L]            , $ ; cursor position in device coords
    mphys: [0.0, 0.0]          , $ ; cursor position in data coordinates
    base_pad: [0L, 0L]         , $ ; padding around draw base
    pad: [0L, 0L]                $ ; padding around draw widget
   }

   nmax = 5000L
   pdata = {                      $
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
   ptext = {                      $
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

   phistory = intarr(pdata.nmax + ptext.nmax)

   ; Load a simple color table with the basic 8 colors
   red   = [0, 1, 0, 0, 0, 1, 1, 1]
   green = [0, 0, 1, 0, 1, 0, 1, 1]
   blue  = [0, 0, 0, 1, 1, 1, 0, 1]
   tvlct, 255*red, 255*green, 255*blue

   ; Define the widgets.  For the widgets that need to be modified later
   ; on, save their widget ids in state variables

   base = widget_base(title = 'splot', $
    /column, /base_align_right, app_mbar = top_menu, $
    uvalue = 'splot_base', /tlb_size_events)
   state.base_id = base

   tmp_struct = {cw_pdmenu_s, flags:0, name:''}
   top_menu_desc = [ $
                  {cw_pdmenu_s, 1, 'File'}, $         ; file menu
                  {cw_pdmenu_s, 0, 'ReadFits'}, $
                  {cw_pdmenu_s, 0, 'WriteEPS'},  $
                  {cw_pdmenu_s, 0, 'WriteTiff'}, $
                  {cw_pdmenu_s, 2, 'Quit'}, $
                  {cw_pdmenu_s, 1, 'Erase'}, $        ; erase menu
                  {cw_pdmenu_s, 0, 'EraseLast'}, $
                  {cw_pdmenu_s, 2, 'EraseAll'}, $
                  {cw_pdmenu_s, 1, 'Help'}, $         ; help menu
                  {cw_pdmenu_s, 2, 'SPLOT Help'} $
                ]

   top_menu = cw_pdmenu(top_menu, top_menu_desc, $
                     ids = state.menu_ids, $
                     /mbar, $
                     /help, $
                     /return_id, $
                     uvalue = 'top_menu')

   track_base =    widget_base(base, /row)
   info_base = widget_base(track_base, /column, /base_align_right)

   state.xrange_text_id = cw_field(info_base, $
           uvalue = 'xrange_text', /string,  $
           title = 'XRANGE=', $
           value = string(state.xrange[0])+' '+string(state.xrange[1]),  $
           /return_events, $
           xsize = 25)

   state.yrange_text_id = cw_field(info_base, $
           uvalue = 'yrange_text', /string,  $
           title = 'YRANGE=', $
           value = string(state.yrange[0])+' '+string(state.yrange[1]),  $
           /return_events, $
           xsize = 25)

   button_base2 =  widget_base(base, /row, /base_align_bottom)

   state.draw_base_id = widget_base(base, $
              /column, /base_align_left, $
              /tracking_events, $
              uvalue = 'draw_base', $
              frame = 2)

   tmp_string = string('',format='(a30)')
   state.location_bar_id = widget_label(info_base, $
                value = tmp_string,  $
                uvalue = 'location_bar', frame=1)

   state.comments_text_id = widget_label(info_base, $
;           value = '', $
           value = tmp_string, $
           uvalue='comments_text', $
           xsize=state.draw_window_size[0]-20, frame=1)

   state.keyboard_text_id =  widget_text(button_base2, $
              /all_events, $
              scr_xsize = 1, $
              scr_ysize = 1, $
              units = 0, $
              uvalue = 'keyboard_text', $
              value = '')

   zoomone_button = widget_button(button_base2, $
              value = 'Zoom1', $
              uvalue = 'zoom_one')

   done_button = widget_button(button_base2, $
              value = 'Done', $
              uvalue = 'done')

   state.draw_widget_id = widget_draw(state.draw_base_id, $
              uvalue = 'draw_window', $
              /motion_events,  /button_events, $
              scr_xsize = state.draw_window_size[0], $
              scr_ysize = state.draw_window_size[1])

   ; Create the widgets on screen
   widget_control, base, /realize

   widget_control, state.draw_widget_id, get_value = tmp_value
   state.draw_window_id = tmp_value

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

   xmanager, 'splot', state.base_id, /no_block

end

;------------------------------------------------------------------------------

pro splot_clearkeylist

   common splot_state

   state.nkey = 0
   state.keylist.key = ' '
   return
end

;------------------------------------------------------------------------------

pro splot_displayall
   splot_refresh
end

;------------------------------------------------------------------------------

pro splot_readfits
; ???
end

;------------------------------------------------------------------------------

pro splot_writetiff
; ???
end

;------------------------------------------------------------------------------

pro splot_writeeps
; ???
end

;------------------------------------------------------------------------------

pro splot_cleartext

   ; Routine to clear the widget for keyboard input when the mouse is in
   ; the text window.  This de-allocates the input focus from the text
   ; input widget.

   common splot_state

   widget_control, state.draw_base_id, /clear_events
   widget_control, state.keyboard_text_id, set_value = ''

end

;------------------------------------------------------------------------------

pro splot_zoom, zchange, recenter = recenter

   common splot_state

   ; Routine to do zoom in/out and recentering of image

   case zchange of
      'in': begin
         state.xrange = state.mphys[0] $
          + [-0.25, 0.25] * (state.xrange[1] - state.xrange[0])
      end
      'out': begin
         state.xrange = state.mphys[0] $
          + [-1.0, 1.0] * (state.xrange[1] - state.xrange[0])
      end
      'one': begin
         splot_autoscale
      end
      'none': begin ; no change to zoom level: recenter on current mouse pos'n
         state.xrange = state.mphys[0] $
          + [-0.5, 0.5] * (state.xrange[1] - state.xrange[0])
      end
      else: print, 'Problem in splot_zoom!'
   endcase

   splot_refresh

end

;------------------------------------------------------------------------------

pro splot_gettrack

   common splot_state

   ; Update location bar with x, y

   xphysize = state.xrange[1] - state.xrange[0]
   xdevsize = state.draw_window_size[0] $
    * (state.position[2] - state.position[0])
   xdev0 = state.draw_window_size[0] * state.position[0]
   state.mphys[0] = $
    (state.mouse[0] - xdev0) * xphysize / xdevsize + state.xrange[0]

   yphysize = state.yrange[1] - state.yrange[0]
   ydevsize = state.draw_window_size[1] $
    * (state.position[3] - state.position[1])
   ydev0 = state.draw_window_size[1] * state.position[1]
   state.mphys[1] = $
    (state.mouse[1] - ydev0) * yphysize / ydevsize + state.yrange[0]

   loc_string = strcompress( string(state.mphys[0], state.mphys[1]) )

   widget_control, state.location_bar_id, set_value=loc_string

   return
end

;------------------------------------------------------------------------------

pro splot_event, event

  ; Main event loop for SPLOT widgets

   common splot_state

   widget_control, event.id, get_uvalue=uvalue

   case uvalue of
   'splot_base': begin  ; main window resize: preserve display range
      splot_resize, event
      splot_refresh
      splot_cleartext
   end
    'top_menu': begin       ; selection from menu bar
      widget_control, event.value, get_value = event_name

      case event_name of

         ; File menu options:
         'ReadFits'  : splot_readfits
         'WriteEPS'  : splot_writeeps
         'WriteTiff' : splot_writetiff
         'Quit'      : splot_shutdown

         ; Erase options:
         'EraseLast' : serase, 1
         'EraseAll'  : serase

         ; Help options:
         'SPLOT Help': splot_help

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
         tmp_event = [event.x, event.y]
         state.mouse = tmp_event
         splot_gettrack
      endif

      if (event.type EQ 0) then begin
         case event.press of
            1: splot_zoom, 'in', /recenter
            2: splot_zoom, 'none', /recenter
            4: splot_zoom, 'out', /recenter
            else: print,  'trouble in splot_event, mouse zoom'
         endcase
      endif

      widget_control, state.keyboard_text_id, /input_focus

   end

   'xrange_text': begin     ; text entry in 'XRANGE= ' box
      splot_get_minmax, uvalue, event.value
      splot_displayall
   end

   'yrange_text': begin     ; text entry in 'YRANGE= ' box
      splot_get_minmax, uvalue, event.value
      splot_displayall
   end

   'keyboard_text': begin  ; keyboard input with mouse in display window
      eventchar = string(event.ch)

      if (state.nkey LT N_elements(state.keylist)) then begin
         state.keylist[state.nkey].key = eventchar
         state.keylist[state.nkey].x = state.mphys[0]
         state.keylist[state.nkey].y = state.mphys[1]
         state.nkey = state.nkey + 1
      endif

      case eventchar of
         '1': splot_move_cursor, eventchar
         '2': splot_move_cursor, eventchar
         '3': splot_move_cursor, eventchar
         '4': splot_move_cursor, eventchar
         '6': splot_move_cursor, eventchar
         '7': splot_move_cursor, eventchar
         '8': splot_move_cursor, eventchar
         '9': splot_move_cursor, eventchar
         'g': splot_gaussfit
         else:  ;any other key press does nothing
      endcase
      widget_control, state.keyboard_text_id, /clear_events
   end

   'zoom_one': splot_zoom, 'one'

   'done':  splot_shutdown

   else:  print, 'No match for uvalue....'  ; bad news if this happens

   endcase

end

;------------------------------------------------------------------------------

pro splot_shutdown

   ; Routine to kill the splot window(s) and clear variables to conserve
   ; memory when quitting splot.  Since we can't delvar the splot internal
   ; variables, just set them equal to zero so they don't take up a lot
   ; of space.  Also clear the state and the color map vectors.

   common splot_state
   common splot_pdata

   if (xregistered ('splot')) then begin
      widget_control, state.base_id, /destroy
   endif

   if (n_elements(phistory) GT 1) then begin
      serase, /norefresh
      pdata = 0
      ptext = 0
      phistory = 0
   endif

   state = 0

end

;------------------------------------------------------------------------------

pro splot_resize, event

   ; Routine to resize the draw window when a top-level resize event occurs.

   common splot_state

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

;------------------------------------------------------------------------------

function splot_icolor, color

   if (n_elements(color) EQ 0) then color='default'

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

pro splot_plot1plot, iplot

   common splot_state
   common splot_pdata

   widget_control, /hourglass

   plot, *(pdata.x[iplot]), *(pdata.y[iplot]), $
    color=pdata.color[iplot], psym=pdata.psym[iplot], $
    symsize=pdata.symsize[iplot], thick=pdata.thick[iplot], $
    /noerase, xstyle=5, ystyle=5, $
    xrange=!x.crange, yrange=!y.crange

   return
end

;----------------------------------------------------------------------

pro splot_plot1text, iplot

   common splot_pdata

   widget_control, /hourglass

   xyouts, ptext.x[iplot], ptext.y[iplot], *(ptext.string[iplot]), $
    alignment=ptext.alignment[iplot], charsize=ptext.charsize[iplot], $
    charthick=ptext.charthick[iplot], color=ptext.color[iplot], $
    font=ptext.font[iplot], orientation=ptext.orientation[iplot]

   return
end

;----------------------------------------------------------------------
pro splot_plotwindow

   common splot_state
   common splot_pdata

   ; Set plot window - draw box

   !p.position = state.position ; ???
   if (pdata.nplot GT 0) then begin
      plot, *(pdata.x[0]), *(pdata.y[0]), /nodata, $
       xrange=state.xrange, yrange=state.yrange, xstyle=1, ystyle=1
   endif else begin
      plot, [0], [0], /nodata, $
       xrange=state.xrange, yrange=state.yrange, xstyle=1, ystyle=1
   endelse

   return
end

;----------------------------------------------------------------------
pro splot_plotall
   common splot_state
   common splot_pdata

   ; Routine to overplot line plots from SPLOT and text from SXYOUTS
   splot_plotwindow

   if (pdata.nplot GT 0 OR ptext.nplot GT 0) then begin

      for iplot=0, pdata.nplot-1 do $
       splot_plot1plot, iplot

      for iplot=0, ptext.nplot-1 do $
       splot_plot1text, iplot
   endif

end

;------------------------------------------------------------------------------

pro sxyouts, x, y, string, alignment=alignment, charsize=charsize, $
 charthick=charthick, color=color, font=font, orientation=orientation

   common splot_pdata
   common splot_state

   ; Routine to overplot text

   if (N_params() LT 3) then begin
      print, 'Too few parameters for SXYOUTS'
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
      ptext.color[iplot] = splot_icolor(color)
      if (keyword_set(font)) then ptext.font[iplot] = font $
       else ptext.font[iplot] = 1
      if (keyword_set(orientation)) then ptext.orientation[iplot] = orientation $
       else ptext.orientation[iplot] = 0.0

      wset, state.draw_window_id
      splot_plot1text, ptext.nplot
      ptext.nplot = ptext.nplot + 1
   endif else begin
      print, 'Too many calls to SXYOUTS'
   endelse

   phistory[pdata.nplot + ptext.nplot - 1] = 2 ; text

end

;------------------------------------------------------------------------------

pro splot_move_cursor, direction

   ; Use keypad arrow keys to step cursor one pixel at a time.
   ; Get the new track image, and update the cursor position.

   common splot_state

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

;   newpos = (state.mouse - state.offset + 0.5) * state.zoom_factor
   newpos = state.mouse + 0.5 ; ???

   wset,  state.draw_window_id
   tvcrs, newpos[0], newpos[1], /device

   splot_gettrack

   ; Prevent the cursor move from causing a mouse event in the draw window
   widget_control, state.draw_widget_id, /clear_events

end

;----------------------------------------------------------------------

pro splot_set_minmax

   ; Updates the min and max text boxes with new values.

   common splot_state

   widget_control, state.xrange_text_id, $
    set_value=string(state.xrange[0])+' '+string(state.xrange[1])
   widget_control, state.yrange_text_id, $
    set_value=string(state.yrange[0])+' '+string(state.yrange[1])

end

;----------------------------------------------------------------------

pro splot_get_minmax, uvalue, newvalue

   ; Change the min and max state variables when user inputs new numbers
   ; in the text boxes.

   common splot_state

   case uvalue of

      'xrange_text': begin
         reads, newvalue, tmp1, tmp2
         state.xrange[0] = tmp1
         state.xrange[1] = tmp2
      end

      'yrange_text': begin
         reads, newvalue, tmp1, tmp2
         state.yrange[0] = tmp1
         state.yrange[1] = tmp2
      end

   endcase

   splot_set_minmax

end

;------------------------------------------------------------------------------

pro splot_refresh
   common splot_state

   widget_control, /hourglass

   ; Display all plots
   wset, state.draw_window_id
   splot_plotall

   splot_gettrack

   ; prevent unwanted mouse clicks
   widget_control, state.draw_base_id, /clear_events

end
;------------------------------------------------------------------------------

pro splot_help
; ???
end

;------------------------------------------------------------------------------

pro splot_help_event, event

   widget_control, event.id, get_uvalue = uvalue

   case uvalue of
      'help_done': widget_control, event.top, /destroy
      else:
   endcase
end

;------------------------------------------------------------------------------

pro serase, nerase, norefresh=norefresh
   common splot_pdata

   ; Routine to erase line plots from SPLOT and text from SXYOUTS.

   ; The norefresh keyword is used  when a new image
   ; has just been read in, and by splot_shutdown.

   nplotall = pdata.nplot + ptext.nplot
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
      endif
   endfor

   if (NOT keyword_set(norefresh) ) then splot_refresh

end

;------------------------------------------------------------------------------

pro splot_gaussfit

   common splot_state
   common splot_pdata

   i = where(state.keylist.key EQ 'g', ct)
   if (ct EQ 1) then begin
      widget_control, state.comments_text_id, $
       set_value='GAUSSFIT: Press g at other side of feature to fit'
   endif else if (ct EQ 2) then begin
      ; Select all data points in the first PDATA array within the
      ; selected X boundaries.
      xmin = min([state[i].keylist.x, state[i].keylist.x])
      xmax = max([state[i].keylist.x, state[i].keylist.x])
      j = where(*(pdata.x[0]) GE xmin AND *(pdata.x[0]) LE xmax)
      if (N_elements(j) GT 3) then begin
         xtemp = (*(pdata.x[0]))[j]
         ytemp = (*(pdata.y[0]))[j]
         ymin = min(ytemp)
         ymax = max(ytemp, imax)

         ; Set initial guess for fitting coefficients
         a = [xtemp[imax], 0.2*(max(xtemp)-min(xtemp)), ymax-ymin, ymin]

         ; Fit a gaussian + a constant sky term
         yfit = curvefit(xtemp, ytemp, xtemp*0+1.0, a, $
          /noderivative, function_name='gausspix')

         out_string = 'GAUSSFIT: ' $
          + ' x0= ' + strtrim(string(a[0]),2) $
          + ' sig= ' + strtrim(string(a[1]),2) $
          + ' A= ' + strtrim(string(a[2]),2) $
          + ' sky= ' + strtrim(string(a[3]),2)
         widget_control, state.comments_text_id, set_value=out_string
         soplot, xtemp, yfit, color='red', psym=10
      endif else begin
         widget_control, state.comments_text_id, $
          set_value='GAUSSFIT: Too few points to fit'
      endelse
      splot_clearkeylist
   endif else begin
      splot_clearkeylist
   endelse

   return
end

;------------------------------------------------------------------------------

pro splot_autoscale

   common splot_state
   common splot_pdata

   ; First set default values if no data
   state.xrange[0] = 0.0
   state.xrange[1] = 1.0
   state.yrange[0] = 0.0
   state.yrange[1] = 1.0

   nplotall = pdata.nplot + ptext.nplot
   if (nplotall GT 0) then begin
      idat = where(phistory[0:nplotall-1] EQ 1)

      ; Set plotting limits for first SPLOT
      state.xrange[0] = min( *(pdata.x[idat[0]]) )
      state.xrange[1] = max( *(pdata.x[idat[0]]) )
      state.yrange[0] = min( *(pdata.y[idat[0]]) )
      state.yrange[1] = max( *(pdata.y[idat[0]]) )

      ; Enlarge plotting limits if necessary for other calls to SOPLOT
      for i=0, N_elements(idat)-1 do begin
         state.xrange[0] = min( [state.xrange[0], *(pdata.x[idat[i]])] )
         state.xrange[1] = max( [state.xrange[1], *(pdata.x[idat[i]])] )
         state.yrange[0] = min( [state.yrange[0], *(pdata.y[idat[i]])] )
         state.yrange[1] = max( [state.yrange[1], *(pdata.y[idat[i]])] )
      endfor
   endif

   splot_set_minmax

   return
end

;------------------------------------------------------------------------------

pro soplot, x, y, autoscale=autoscale, $
 color=color, psym=psym, symsize=symsize, thick=thick

   common splot_state
   common splot_pdata

   if (N_params() LT 1) then begin
      print, 'Too few parameters for SOPLOT'
      return
   endif

   if (NOT (xregistered('splot'))) then begin
      print, 'Must use SPLOT before SOPLOT'
   endif

   if (pdata.nplot LT pdata.nmax) then begin
      iplot = pdata.nplot

      if (N_params() EQ 1) then begin
         pdata.x[iplot] = ptr_new(lindgen(N_elements(x)))
         pdata.y[iplot] = ptr_new(x)
      endif else begin
         pdata.x[iplot] = ptr_new(x)
         pdata.y[iplot] = ptr_new(y)
      endelse

      pdata.color[iplot] = splot_icolor(color)
      if (keyword_set(psym)) then pdata.psym[iplot] = psym $
       else pdata.psym[iplot] = 0
      if (keyword_set(symsize)) then pdata.symsize[iplot] = symsize $
       else pdata.symsize[iplot] = 1.0
      if (keyword_set(thick)) then pdata.thick[iplot] = thick $
       else pdata.thick[iplot] = 1.0

      wset, state.draw_window_id
      pdata.nplot = pdata.nplot + 1
      phistory[pdata.nplot + ptext.nplot - 1] = 1 ; points
      if (keyword_set(autoscale)) then begin
         splot_autoscale
         splot_plotall
      endif else begin
         splot_plot1plot, pdata.nplot-1
      endelse
   endif else begin
      print, 'Too many calls to SPLOT'
   endelse

   return
end

;------------------------------------------------------------------------------

pro splot, x, y, _EXTRA=KeywordsForSOPLOT

   common splot_state
   common splot_pdata

   if (N_params() LT 1) then begin
      print, 'Too few parameters for SPLOT'
      return
   endif

   if (not (xregistered('splot'))) then splot_startup

   if (N_params() EQ 1) then begin
      xplot = lindgen(N_elements(x))
      yplot = x
   endif else begin
      xplot = x
      yplot = y
   endelse

   serase
   soplot, xplot, yplot, /autoscale, _EXTRA=KeywordsForSOPLOT

   return
end
;------------------------------------------------------------------------------
