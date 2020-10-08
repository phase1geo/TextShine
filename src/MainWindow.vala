/*
* Copyright (c) 2020 (https://github.com/phase1geo/TextShine)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

using Gtk;
using Gee;

public class MainWindow : ApplicationWindow {

  private const string DESKTOP_SCHEMA = "io.elementary.desktop";
  private const string DARK_KEY       = "prefer-dark";

  private HeaderBar                _header;
  private Editor                   _editor;
  private Button                   _clear_btn;
  private Button                   _open_btn;
  private Button                   _save_btn;
  private Button                   _paste_btn;
  private Button                   _copy_btn;
  private Button                   _undo_btn;
  private Button                   _redo_btn;
  private Button                   _record_btn;
  private MenuButton               _prop_btn;
  private FontButton               _font;
  private Sidebar                  _sidebar;
  private Box                      _widget_box;
  private InfoBar                  _info;
  private HashMap<string,Revealer> _widgets;
  private TextFunctions            _functions;
  private CustomFunction           _custom;
  private bool                     _recording;
  private string?                  _current_file = null;

  private const GLib.ActionEntry[] action_entries = {
    { "action_clear", do_clear },
    { "action_open",  do_open },
    { "action_save",  do_save },
    { "action_quit",  do_quit },
    { "action_paste", do_paste },
    { "action_copy",  do_copy },
    { "action_undo",  do_undo },
    { "action_redo",  do_redo }
  };

  public TextFunctions functions {
    get {
      return( _functions );
    }
  }

  /* Constructor */
  public MainWindow( Gtk.Application app ) {

    Object( application: app );

    _recording = false;
    _custom    = new CustomFunction();

    var box = new Box( Orientation.HORIZONTAL, 0 );

    /* Handle any changes to the dark mode preference setting */
    handle_prefer_dark_changes();

    /* Position the window size and position */
    position_window();

    /* Create the header */
    create_header();

    /* Create editor */
    _editor = new Editor( this );

    var sw = new ScrolledWindow( null, null );
    sw.min_content_width  = 600;
    sw.min_content_height = 400;
    sw.add( _editor );

    var ebox = new Box( Orientation.VERTICAL, 0 );

    /* Create widget bar */
    _widget_box = new Box( Orientation.VERTICAL, 0 );

    _info = new InfoBar();
    _info.revealed = false;
    _info.get_content_area().add( new Label( "" ) );
    _info.close.connect( close_error );

    ebox.pack_start( _widget_box, false, true, 0 );
    ebox.pack_start( _info,       false, true, 0 );
    ebox.pack_start( sw,          true,  true, 0 );

    /* Create the widgets and functions after we have added some of the UI elements */
    _widgets   = new HashMap<string,Revealer>();
    _functions = new TextFunctions( this );

    /* Create sidebar */
    var sidebar = create_sidebar();

    box.pack_start( ebox,    true,  true,  5 );
    box.pack_start( sidebar, false, false, 5 );

    add( box );
    show_all();

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "win", actions );

    /* Add keyboard shortcuts */
    add_keyboard_shortcuts( app );

    /* Handle the application closing */
    destroy.connect( Gtk.main_quit );

  }

  /* Adds keyboard shortcuts for the menu actions */
  private void add_keyboard_shortcuts( Gtk.Application app ) {
    app.set_accels_for_action( "win.action_clear",         { "<Control>BackSpace" } );
    app.set_accels_for_action( "win.action_open",          { "<Control>o" } );
    app.set_accels_for_action( "win.action_save",          { "<Control>s" } );
    app.set_accels_for_action( "win.action_quit",          { "<Control>q" } );
    app.set_accels_for_action( "win.action_paste",         { "<Control>v" } );
    app.set_accels_for_action( "win.action_copy",          { "<Control>c" } );
    app.set_accels_for_action( "win.action_undo",          { "<Control>z" } );
    app.set_accels_for_action( "win.action_redo",          { "<Control><Shift>z" } );
  }

  private void action_applied( TextFunction function ) {
    if( _recording ) {
      _custom.functions.append_val( function );
    }
  }

  /* Handles any changes to the dark mode preference gsettings for the desktop */
  private void handle_prefer_dark_changes() {
    var lookup = SettingsSchemaSource.get_default().lookup( DESKTOP_SCHEMA, false );
    if( lookup != null ) {
      var desktop_settings = new GLib.Settings( DESKTOP_SCHEMA );
      change_dark_mode( desktop_settings.get_boolean( DARK_KEY ) );
      desktop_settings.changed.connect(() => {
        change_dark_mode( desktop_settings.get_boolean( DARK_KEY ) );
      });
    }
  }

  /* Sets the dark mode to the preferred scheme */
  private void change_dark_mode( bool dark ) {
    Gtk.Settings? settings = Gtk.Settings.get_default();
    if( settings != null ) {
      settings.gtk_application_prefer_dark_theme = dark;
    }
  }

  /* Positions the window based on the settings */
  private void position_window() {

    var window_x = TextShine.settings.get_int( "window-x" );
    var window_y = TextShine.settings.get_int( "window-y" );
    var window_w = TextShine.settings.get_int( "window-w" );
    var window_h = TextShine.settings.get_int( "window-h" );

    /* Set the main window data */
    if( (window_x == -1) && (window_y == -1) ) {
      set_position( Gtk.WindowPosition.CENTER );
    } else {
      move( window_x, window_y );
    }
    set_default_size( window_w, window_h );
    set_border_width( 2 );

  }

  /* Create the header bar */
  private void create_header() {

    _header = new HeaderBar();
    _header.set_show_close_button( true );

    _clear_btn = new Button.from_icon_name( "edit-clear", IconSize.LARGE_TOOLBAR );
    _clear_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Clear Text" ), "<Control>BackSpace" ) );
    _clear_btn.clicked.connect( do_clear );
    _header.pack_start( _clear_btn );

    _open_btn = new Button.from_icon_name( "document-open", IconSize.LARGE_TOOLBAR );
    _open_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Open File" ), "<Control>o" ) );
    _open_btn.clicked.connect( do_open );
    _header.pack_start( _open_btn );

    _save_btn = new Button.from_icon_name( "document-save", IconSize.LARGE_TOOLBAR );
    _save_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Save File" ), "<Control>s" ) );
    _save_btn.clicked.connect( do_save );
    _header.pack_start( _save_btn );

    _paste_btn = new Button.from_icon_name( "edit-paste", IconSize.LARGE_TOOLBAR );
    _paste_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Paste Text" ), "<Control>v" ) );
    _paste_btn.clicked.connect( do_paste );
    _header.pack_start( _paste_btn );

    _copy_btn = new Button.from_icon_name( "edit-copy", IconSize.LARGE_TOOLBAR );
    _copy_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Copy Text" ), "<Control>c" ) );
    _copy_btn.clicked.connect( do_copy );
    _header.pack_start( _copy_btn );

    _undo_btn = new Button.from_icon_name( "edit-undo", IconSize.LARGE_TOOLBAR );
    _undo_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Undo" ), "<Control>z" ) );
    _undo_btn.set_sensitive( false );
    _undo_btn.clicked.connect( do_undo );
    _header.pack_start( _undo_btn );

    _redo_btn = new Button.from_icon_name( "edit-redo", IconSize.LARGE_TOOLBAR );
    _redo_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Redo" ), "<Control><Shift>z" ) );
    _redo_btn.set_sensitive( false );
    _redo_btn.clicked.connect( do_redo );
    _header.pack_start( _redo_btn );

    _header.pack_end( add_properties_button() );

    _record_btn = new Button.from_icon_name( "media-record", IconSize.LARGE_TOOLBAR );
    _record_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Record Custom Action" ), "<Control>r" ) );
    _record_btn.clicked.connect( toggle_record );
    _header.pack_end( _record_btn );

    set_titlebar( _header );

  }

  /* Adds the property button and associated popover */
  private Button add_properties_button() {

    _prop_btn = new MenuButton();
    _prop_btn.set_image( new Image.from_icon_name( "open-menu", IconSize.LARGE_TOOLBAR ) );
    _prop_btn.set_tooltip_text( _( "Properties" ) );
    _prop_btn.clicked.connect( properties_clicked );

    var box = new Box( Orientation.VERTICAL, 0 );

    /* Add the properties items */
    box.pack_start( create_font_selection(), false, false, 10 );

    box.show_all();

    /* Create the popover and associate it with the menu button */
    var prop_popover = new Popover( null );
    prop_popover.add( box );
    _prop_btn.popover = prop_popover;

    return( _prop_btn );

  }

  /* Create font selection box */
  private Box create_font_selection() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "Font:" ) );

    _font = new FontButton();
    _font.show_style = false;
    _font.set_filter_func( (family, face) => {
      var fd     = face.describe();
      var weight = fd.get_weight();
      var style  = fd.get_style();
      return( (weight == Pango.Weight.NORMAL) && (style == Pango.Style.NORMAL) );
    });
    _font.font_set.connect(() => {
      var name = _font.get_font_family().get_name();
      var size = _font.get_font_size() / Pango.SCALE;
      _editor.change_name_font( name, size );
      TextShine.settings.set_string( "default-font-family", name );
      TextShine.settings.set_int( "default-font-size", size );
    });

    /* Set the font button defaults */
    var fd = _font.get_font_desc();
    fd.set_family( TextShine.settings.get_string( "default-font-family" ) );
    fd.set_size( TextShine.settings.get_int( "default-font-size" ) * Pango.SCALE );
    _font.set_font_desc( fd );

    box.pack_start( lbl,   false, false, 10 );
    box.pack_end(   _font, false, false, 10 );

    return( box );

  }

  /* Called when the properties button is clicked.  Sets the state of the popover contents. */
  private void properties_clicked() {

    /* TBD - State properties item states here */

  }

  /* Create list of transformation buttons */
  private Box create_sidebar() {

    var box = new Box( Orientation.VERTICAL, 0 );

    _sidebar = new Sidebar( this, _editor, box );
    _sidebar.action_applied.connect( action_applied );

    return( box );

  }

  /* Clears the buffer for reuse */
  private void do_clear() {
    _current_file = null;
    _editor.clear();
    _custom.clear();
    _editor.grab_focus();
  }

  private void do_open() {
    // TBD
    _editor.grab_focus();
  }

  private void do_save() {

    if( _current_file == null ) {
      var dialog = new FileChooserNative( _( "Save File" ), this, FileChooserAction.SAVE, _( "Save" ), _( "Cancel" ) );
      if( dialog.run() != ResponseType.ACCEPT ) return;
      _current_file = dialog.get_filename();
    }

    var file = File.new_for_path( _current_file );

    try {
      var os = file.replace( null, false, FileCreateFlags.NONE );
      os.write( _editor.buffer.text.data );
      os.close();
    } catch( Error e ) {
      show_error( e.message );
    }

    _editor.grab_focus();

  }

  /* Quits the application */
  private void do_quit() {
    destroy();
  }

  /* Pastes the contents of the clipboard to the editor */
  private void do_paste() {
    var clipboard = Clipboard.get_default( Gdk.Display.get_default() );
    _editor.buffer.paste_clipboard( clipboard, null, true );
    _editor.grab_focus();
  }

  /* Copies the contents of editor to the clipboard */
  private void do_copy() {
    var clipboard = Clipboard.get_default( Gdk.Display.get_default() );
    _editor.copy_to_clipboard( clipboard );
    _editor.grab_focus();
  }

  /* Performs an undo operation */
  private void do_undo() {
    // TODO
    _editor.grab_focus();
  }

  /* Performs a redo operation */
  private void do_redo() {
    // TODO
    _editor.grab_focus();
  }

  /* Toggles the record status */
  private void toggle_record() {
    if( _recording ) {
      _record_btn.image = new Image.from_icon_name( "media-record", IconSize.LARGE_TOOLBAR );
      _recording        = false;
      var popover = _custom.show_ui( _record_btn, save_new_custom );
      popover.position = PositionType.LEFT;
    } else {
      _record_btn.image = new Image.from_icon_name( "media-playback-stop", IconSize.LARGE_TOOLBAR );
      _recording        = true;
      _custom.functions.remove_range( 0, _custom.functions.length );
    }
  }

  private void save_new_custom( CustomFunction function ) {
    var fn = function.copy();
    _sidebar.add_custom_function( (CustomFunction)fn );
    functions.add_function( "custom", fn );
    functions.save_custom();
  }

  /* Adds the given widget to the widgets box */
  public void add_widget( string name, Widget w ) {

    var revealer = new Revealer();
    revealer.add( w );
    revealer.reveal_child = false;
    revealer.border_width = 5;

    _widget_box.pack_start( revealer, true, true, 0 );

    _widgets.@set( name, revealer );

  }

  /* Displays the specified widget */
  public void show_widget( string name ) {
    _widgets.values.@foreach((w) => {
      w.reveal_child = false;
      return( true );
    });
    if( _widgets.has_key( name ) ) {
      _widgets.@get( name ).reveal_child = true;
    }
  }

  /* Displays the given error message */
  public void show_error( string msg ) {
    var lbl = (Label)_info.get_content_area().get_children().nth_data( 0 );
    lbl.label = msg;
    _info.message_type      = MessageType.ERROR;
    _info.show_close_button = true;
    _info.revealed          = true;
  }

  /* Closes the error information bar */
  public void close_error() {
    _info.revealed = false;
  }

}
