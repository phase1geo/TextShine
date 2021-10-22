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

public class MainWindow : Hdy.ApplicationWindow {

  private const string DESKTOP_SCHEMA = "io.elementary.desktop";
  private const string DARK_KEY       = "prefer-dark";

  private Hdy.HeaderBar  _header;
  private Editor         _editor;
  private Button         _clear_btn;
  private Button         _open_btn;
  private Button         _save_btn;
  private Button         _paste_btn;
  private Button         _copy_btn;
  private Button         _undo_btn;
  private Button         _redo_btn;
  private MenuButton     _prop_btn;
  private FontButton     _font;
  private Sidebar        _sidebar;
  private Box            _widget_box;
  private InfoBar        _info;
  private TextFunctions  _functions;
  private CustomFunction _custom;
  private string?        _current_file = null;
  private Label          _stats_chars;
  private Label          _stats_words;
  private Label          _stats_lines;
  private Label          _stats_matches;
  private Label          _stats_spell;

  private const GLib.ActionEntry[] action_entries = {
    { "action_new",        do_new },
    { "action_open",       do_open },
    { "action_save",       do_save },
    { "action_quit",       do_quit },
    { "action_paste_over", do_paste_over },
    { "action_copy_all",   do_copy_all },
    { "action_paste",      do_paste },
    { "action_copy",       do_copy },
    { "action_undo",       do_undo },
    { "action_redo",       do_redo }
  };

  public TextFunctions functions {
    get {
      return( _functions );
    }
  }

  /* Constructor */
  public MainWindow( Gtk.Application app ) {

    Object( application: app );

    /* Add the application CSS */
    var provider = new Gtk.CssProvider ();
    provider.load_from_resource( "/com/github/phase1geo/textshine/css/style.css" );
    StyleContext.add_provider_for_screen( Gdk.Screen.get_default(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION );

    _custom = new CustomFunction();

    var box = new Box( Orientation.HORIZONTAL, 0 );

    /* Handle any changes to the dark mode preference setting */
    handle_prefer_dark_changes();

    /* Position the window size and position */
    position_window();

    /* Create the header */
    create_header();

    /* Create editor */
    _editor = new Editor( this );
    _editor.buffer_changed.connect( do_buffer_changed );

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
    _functions = new TextFunctions( this );

    /* Create sidebar */
    var sidebar = create_sidebar();

    box.pack_start( ebox,    true,  true,  5 );
    box.pack_start( sidebar, false, false, 5 );

    var top_box = new Box( Orientation.VERTICAL, 0 );
    top_box.pack_start( _header, false, true, 0 );
    top_box.pack_start( box, true, true, 0 );

    add( top_box );
    show_all();

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "win", actions );

    /* Add keyboard shortcuts */
    add_keyboard_shortcuts( app );

    /* Make sure that the editor has input focus */
    _editor.grab_focus();

    /* Handle the application closing */
    destroy.connect( Gtk.main_quit );

  }

  static construct {
    Hdy.init();
  }

  /* Adds keyboard shortcuts for the menu actions */
  private void add_keyboard_shortcuts( Gtk.Application app ) {
    app.set_accels_for_action( "win.action_new",        { "<Control>n" } );
    app.set_accels_for_action( "win.action_open",       { "<Control>o" } );
    app.set_accels_for_action( "win.action_save",       { "<Control>s" } );
    app.set_accels_for_action( "win.action_quit",       { "<Control>q" } );
    app.set_accels_for_action( "win.action_paste_over", { "<Shift><Control>v" } );
    app.set_accels_for_action( "win.action_copy_all",   { "<Shift><Control>c" } );
    app.set_accels_for_action( "win.action_paste",      { "<Control>v" } );
    app.set_accels_for_action( "win.action_copy",       { "<Control>c" } );
    app.set_accels_for_action( "win.action_undo",       { "<Control>z" } );
    app.set_accels_for_action( "win.action_redo",       { "<Control><Shift>z" } );
  }

  private void action_applied( TextFunction function ) {
    // TBD
  }

  /* Handles any changes to the dark mode preference gsettings for the desktop */
  private void handle_prefer_dark_changes() {
    var granite_settings = Granite.Settings.get_default();
    var gtk_settings     = Gtk.Settings.get_default();
    gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
    granite_settings.notify["prefers-color-scheme"].connect (() => {
      gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
    });
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

  }

  /* Create the header bar */
  private void create_header() {

    _header = new Hdy.HeaderBar();
    _header.set_show_close_button( true );

    _clear_btn = new Button.from_icon_name( "document-new", IconSize.LARGE_TOOLBAR );
    _clear_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "New Workspace" ), "<Control>n" ) );
    _clear_btn.clicked.connect( do_new );
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
    _paste_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Paste Over" ), "<Shift><Control>v" ) );
    _paste_btn.clicked.connect( do_paste_over );
    _header.pack_start( _paste_btn );

    _copy_btn = new Button.from_icon_name( "edit-copy", IconSize.LARGE_TOOLBAR );
    _copy_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Copy All" ), "<Shift><Control>c" ) );
    _copy_btn.clicked.connect( do_copy_all );
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
    _header.pack_end( add_stats_button() );

    set_title( _( "TextShine" ) );

  }

  /* Adds the statistics functionality */
  private Button add_stats_button() {

    var stats_btn = new MenuButton();
    stats_btn.set_image( new Image.from_icon_name( "org.gnome.PowerStats", IconSize.LARGE_TOOLBAR ) );
    stats_btn.set_tooltip_markup( _( "Statistics" ) );
    stats_btn.clicked.connect( stats_clicked );

    var grid = new Grid();
    grid.border_width   = 10;
    grid.row_spacing    = 10;
    grid.column_spacing = 10;

    var lmargin = "    ";

    var group_text = new Label( _( "<b>Text Statistics</b>" ) );
    group_text.xalign     = 0;
    group_text.use_markup = true;

    var lbl_chars = new Label( lmargin + _( "Characters:") );
    lbl_chars.xalign = 0;
    _stats_chars = new Label( "0" );
    _stats_chars.xalign = 0;

    var lbl_words = new Label( lmargin + _( "Words:" ) );
    lbl_words.xalign = 0;
    _stats_words = new Label( "0" );
    _stats_words.xalign = 0;

    var lbl_lines = new Label( lmargin + _( "Lines:") );
    lbl_lines.xalign = 0;
    _stats_lines = new Label( "0" );
    _stats_lines.xalign = 0;

    var lbl_matches = new Label( lmargin + _( "Matches:") );
    lbl_matches.xalign = 0;
    _stats_matches = new Label( "0" );
    _stats_matches.xalign = 0;

    var lbl_spell = new Label( lmargin + _( "Spelling Errors:" ) );
    lbl_spell.xalign = 0;
    _stats_spell = new Label( "0" );
    _stats_spell.xalign = 0;

    grid.attach( group_text,     0, 0, 2 );
    grid.attach( lbl_chars,      0, 1 );
    grid.attach( _stats_chars,   1, 1 );
    grid.attach( lbl_words,      0, 2 );
    grid.attach( _stats_words,   1, 2 );
    grid.attach( lbl_lines,      0, 3 );
    grid.attach( _stats_lines,   1, 3 );
    grid.attach( lbl_matches,    0, 4 );
    grid.attach( _stats_matches, 1, 4 );
    grid.attach( lbl_spell,      0, 5 );
    grid.attach( _stats_spell,   1, 5 );
    grid.show_all();

    /* Create the popover and associate it with the menu button */
    stats_btn.popover = new Popover( null );
    stats_btn.popover.add( grid );

    return( stats_btn );

  }

  /* Toggle the statistics bar */
  private void stats_clicked() {

    var text        = _editor.buffer.text;
    var char_count  = text.char_count();
    var word_count  = text.strip().split_set( " \t\r\n" ).length;
    var line_count  = text.strip().split_set( "\n" ).length;
    var match_count = _editor.num_selected();
    var spell_count = _editor.num_spelling_errors();

    _stats_chars.label   = char_count.to_string();
    _stats_words.label   = word_count.to_string();
    _stats_lines.label   = line_count.to_string();
    _stats_matches.label = match_count.to_string();
    _stats_spell.label   = spell_count.to_string();

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
    box.pack_start( create_spell_checker(),  false, false, 10 );

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

  private Box create_spell_checker() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "Enable Spell Checker" ) );

    var sw = new Switch();
    sw.active = TextShine.settings.get_boolean( "enable-spell-checking" );
    sw.state_set.connect((state) => {
      if( state ) {
        _editor.activate_spell_checking();
      } else {
        _editor.deactivate_spell_checking();
      }
      TextShine.settings.set_boolean( "enable-spell-checking", state );
      return( true );
    });

    box.pack_start( lbl, false, false, 10 );
    box.pack_end(   sw,  false, false, 10 );

    return( box );

  }

  /* Called when the properties button is clicked.  Sets the state of the popover contents. */
  private void properties_clicked() {

    /* TBD - State properties item states here */

  }

  /* Create list of transformation buttons */
  private Stack create_sidebar() {

    _sidebar = new Sidebar( this, _editor );
    _sidebar.action_applied.connect( action_applied );

    return( _sidebar );

  }

  /* Clears the buffer for reuse */
  public void do_new() {
    _current_file = null;
    _editor.clear();
    _custom.clear();
    _editor.grab_focus();
  }

  private void do_open() {

    var dialog = new FileChooserNative( _( "Open File" ), this, FileChooserAction.OPEN, _( "Open" ), _( "Cancel" ) );
    if( dialog.run() != ResponseType.ACCEPT ) return;

    open_file( dialog.get_filename() );

  }

  public bool open_file( string filepath ) {

    _current_file = filepath;

    var file = File.new_for_path( _current_file );

    try {
      uint8[] contents;
    		file.load_contents( null, out contents, null );
    		_editor.clear();
    		_editor.buffer.text = (string)contents;
    } catch( Error e ) {
      show_error( e.message );
      return( false );
    }

    _editor.grab_focus();

    return( true );

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

  public void do_paste_over() {
    do_new();
    do_paste();
  }

  /* Pastes the contents of the clipboard to the editor */
  private void do_paste() {
    var clipboard = Clipboard.get_default( Gdk.Display.get_default() );
    _editor.buffer.paste_clipboard( clipboard, null, true );
    _editor.grab_focus();
  }

  /* Copies the entire contents of the editor to the clipboard */
  public void do_copy_all() {
    var clipboard = Clipboard.get_default( Gdk.Display.get_default() );
    _editor.copy_all_to_clipboard( clipboard );
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
    _editor.undo_buffer.undo();
    _editor.grab_focus();
  }

  /* Performs a redo operation */
  private void do_redo() {
    _editor.undo_buffer.redo();
    _editor.grab_focus();
  }

  private void save_new_custom( CustomFunction function ) {
    var fn = function.copy( false );
    // TBD - _sidebar.add_custom_function( (CustomFunction)fn );
    functions.add_function( "custom", fn );
    functions.save_custom();
  }

  /* Adds the given widget to the widgets box */
  public void add_widget( Widget w, Widget? focus_widget = null ) {

    var revealer = new Revealer();
    revealer.add( w );
    revealer.reveal_child = false;
    revealer.border_width = 5;

    _widget_box.pack_start( revealer, true, true, 0 );
    _widget_box.show_all();

    revealer.reveal_child = true;

    if( focus_widget != null ) {
      focus_widget.grab_focus();
    }

  }

  /* Removes the given widget from the widget box */
  public void remove_widget() {
    if( _widget_box.get_children().length() > 0 ) {
      _widget_box.remove( _widget_box.get_children().nth_data( 0 ) );
    }
    _editor.grab_focus();
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

  /* Called whenever the editor buffer changes */
  private void do_buffer_changed( UndoBuffer buffer ) {
    _undo_btn.set_sensitive( buffer.undoable() );
    _redo_btn.set_sensitive( buffer.redoable() );
  }

  /* Generate a notification */
  public void notification( string title, string msg, NotificationPriority priority = NotificationPriority.NORMAL ) {
    GLib.Application? app = null;
    @get( "application", ref app );
    if( app != null ) {
      var notification = new Notification( title );
      notification.set_body( msg );
      notification.set_priority( priority );
      app.send_notification( "com.github.phase1geo.minder", notification );
    }
  }

}
