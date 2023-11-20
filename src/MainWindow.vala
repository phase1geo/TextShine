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

public class MainWindow : Gtk.ApplicationWindow {

  private const string DESKTOP_SCHEMA = "io.elementary.desktop";
  private const string DARK_KEY       = "prefer-dark";

  private HeaderBar      _header;
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
  private Box               _widget_box;
  private GLib.List<Widget> _widget_items;
  private InfoBar        _info;
  private Label          _info_label;
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

  private bool on_elementary = Gtk.Settings.get_default().gtk_icon_theme_name == "elementary";

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
    StyleContext.add_provider_for_display( get_display(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION );

    _custom = new CustomFunction();

    var box = new Box( Orientation.HORIZONTAL, 5 );

    /* Handle any changes to the dark mode preference setting */
    handle_prefer_dark_changes();

    /* Position the window size and position */
    position_window();

    /* Create the header */
    create_header();

    /* Create editor */
    _editor = new Editor( this );
    _editor.buffer_changed.connect( do_buffer_changed );

    var sw = new ScrolledWindow() {
      valign = Align.FILL,
      vexpand = true,
      min_content_width = 600,
      min_content_height = 400,
      child = _editor
    };

    var ebox = new Box( Orientation.VERTICAL, 0 ) {
      halign  = Align.FILL,
      hexpand = true
    };

    /* Create widget bar */
    _widget_box = new Box( Orientation.VERTICAL, 0 ) {
      valign = Align.FILL
    };
    _widget_items = new GLib.List<Widget>();

    _info_label = new Label( "" );
    _info = new InfoBar() {
      valign = Align.FILL,
      revealed = false
    };
    _info.add_child( _info_label );
    _info.close.connect( close_error );

    ebox.append( _widget_box );
    ebox.append( _info );
    ebox.append( sw );

    /* Create the widgets and functions after we have added some of the UI elements */
    _functions = new TextFunctions( this );

    /* Create sidebar */
    var sidebar = create_sidebar();

    box.append( ebox );
    box.append( sidebar );

    child = box;

    show();

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "win", actions );

    /* Add keyboard shortcuts */
    add_keyboard_shortcuts( app );

    /* Make sure that the editor has input focus */
    _editor.grab_focus();

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

    /*
     * TODO - I don't think this code will port over
    var window_x = TextShine.settings.get_int( "window-x" );
    var window_y = TextShine.settings.get_int( "window-y" );
    var window_w = TextShine.settings.get_int( "window-w" );
    var window_h = TextShine.settings.get_int( "window-h" );

    // Set the main window data
    if( (window_x == -1) && (window_y == -1) ) {
      set_position( Gtk.WindowPosition.CENTER );
    } else {
      move( window_x, window_y );
    }
    set_default_size( window_w, window_h );
    */

  }

  /* Returns the name of the icon to use based on if we are running elementary */
  private string get_icon_name( string icon_name ) {
    return "%s%s".printf( icon_name, (on_elementary ? "" : "-symbolic") );
  }

  /* Create the header bar */
  private void create_header() {

    _header = new HeaderBar() {
      show_title_buttons = true
    };

    _clear_btn = new Button.from_icon_name( get_icon_name( "document-new" ) );
    _clear_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "New Workspace" ), "<Control>n" ) );
    _clear_btn.clicked.connect( do_new );
    _header.pack_start( _clear_btn );

    _open_btn = new Button.from_icon_name( get_icon_name( "document-open" ) );
    _open_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Open File" ), "<Control>o" ) );
    _open_btn.clicked.connect( do_open );
    _header.pack_start( _open_btn );

    _save_btn = new Button.from_icon_name( get_icon_name( "document-save" ) );
    _save_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Save File" ), "<Control>s" ) );
    _save_btn.clicked.connect( do_save );
    _header.pack_start( _save_btn );

    _paste_btn = new Button.from_icon_name( get_icon_name( "edit-paste" ) );
    _paste_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Paste Over" ), "<Shift><Control>v" ) );
    _paste_btn.clicked.connect( do_paste_over );
    _header.pack_start( _paste_btn );

    _copy_btn = new Button.from_icon_name( get_icon_name( "edit-copy" ) );
    _copy_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Copy All" ), "<Shift><Control>c" ) );
    _copy_btn.clicked.connect( do_copy_all );
    _header.pack_start( _copy_btn );

    _undo_btn = new Button.from_icon_name( get_icon_name( "edit-undo" ) );
    _undo_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Undo" ), "<Control>z" ) );
    _undo_btn.set_sensitive( false );
    _undo_btn.clicked.connect( do_undo );
    _header.pack_start( _undo_btn );

    _redo_btn = new Button.from_icon_name( get_icon_name( "edit-redo" ) );
    _redo_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Redo" ), "<Control><Shift>z" ) );
    _redo_btn.set_sensitive( false );
    _redo_btn.clicked.connect( do_redo );
    _header.pack_start( _redo_btn );

    _header.pack_end( add_properties_button() );
    _header.pack_end( add_stats_button() );

    set_title( _( "TextShine" ) );
    set_titlebar( _header );

  }

  /* Adds the statistics functionality */
  private MenuButton add_stats_button() {

    var stats_btn = new MenuButton() {
      icon_name = get_icon_name( "org.gnome.PowerStats" ),
      tooltip_markup = _( "Statistics" )
    };

    stats_btn.activate.connect( stats_clicked );

    var grid = new Grid() {
      margin_start   = 10,
      margin_end     = 10,
      margin_top     = 10,
      margin_bottom  = 10,
      row_spacing    = 10,
      column_spacing = 10
    };

    var lmargin = "    ";

    var group_text = new Label( _( "<b>Text Statistics</b>" ) ) {
      xalign     = 0,
      use_markup = true
    };

    var lbl_chars = new Label( lmargin + _( "Characters:") ) {
      xalign = 0
    };
    _stats_chars = new Label( "0" ) {
      xalign = 0
    };

    var lbl_words = new Label( lmargin + _( "Words:" ) ) {
      xalign = 0
    };
    _stats_words = new Label( "0" ) {
      xalign = 0
    };

    var lbl_lines = new Label( lmargin + _( "Lines:") ) {
      xalign = 0
    };
    _stats_lines = new Label( "0" ) {
      xalign = 0
    };

    var lbl_matches = new Label( lmargin + _( "Matches:") ) {
      xalign = 0
    };
    _stats_matches = new Label( "0" ) {
      xalign = 0
    };

    var lbl_spell = new Label( lmargin + _( "Spelling Errors:" ) ) {
      xalign = 0
    };
    _stats_spell = new Label( "0" ) {
      xalign = 0
    };

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

    /* Create the popover and associate it with the menu button */
    stats_btn.popover = new Popover() {
      child = grid
    };

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
  private MenuButton add_properties_button() {

    var box = new Box( Orientation.VERTICAL, 10 );

    /* Add the properties items */
    box.append( create_font_selection() );
    box.append( create_spell_checker() );

    /* Create the popover and associate it with the menu button */
    var prop_popover = new Popover() {
      child = box
    };

    _prop_btn = new MenuButton() {
      icon_name = get_icon_name( "open-menu" ),
      tooltip_text = _( "Properties" ),
      child = prop_popover
    };

    _prop_btn.activate.connect( properties_clicked );

    return( _prop_btn );

  }

  /* Create font selection box */
  private Box create_font_selection() {

    var lbl = new Label( _( "Font:" ) ) {
      halign = Align.START,
      hexpand = true
    };

    _font = new FontButton() {
      halign = Align.END,
      hexpand = true
    };

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

    var box = new Box( Orientation.HORIZONTAL, 10 );
    box.append( lbl );
    box.append( _font );

    return( box );

  }

  private Box create_spell_checker() {

    var lbl = new Label( _( "Enable Spell Checker" ) ) {
      halign = Align.START,
      hexpand = true
    };

    var sw = new Switch() {
      halign = Align.END,
      hexpand = true,
      active = TextShine.settings.get_boolean( "enable-spell-checking" )
    };

    sw.state_set.connect((state) => {
      if( state ) {
        _editor.activate_spell_checking();
      } else {
        _editor.deactivate_spell_checking();
      }
      TextShine.settings.set_boolean( "enable-spell-checking", state );
      return( true );
    });

    var box = new Box( Orientation.HORIZONTAL, 10 );
    box.append( lbl );
    box.append( sw );

    return( box );

  }

  /* Called when the properties button is clicked.  Sets the state of the popover contents. */
  private void properties_clicked() {

    /* TBD - State properties item states here */

  }

  /* Create list of transformation buttons */
  private Box create_sidebar() {

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

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        open_file( dialog.get_file().get_path() );
      }
      dialog.destroy();
    });

    dialog.show();

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
      dialog.response.connect((id) => {
        if( id == ResponseType.ACCEPT ) {
          _current_file = dialog.get_file().get_path();
        }
        dialog.destroy();
      });
      dialog.show();
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
    var clipboard = Gdk.Display.get_default().get_clipboard();
    _editor.buffer.paste_clipboard( clipboard, null, true );
    _editor.grab_focus();
  }

  /* Copies the entire contents of the editor to the clipboard */
  public void do_copy_all() {
    var clipboard = Gdk.Display.get_default().get_clipboard();
    _editor.copy_all_to_clipboard( clipboard );
    _editor.grab_focus();
  }

  /* Copies the contents of editor to the clipboard */
  private void do_copy() {
    var clipboard = Gdk.Display.get_default().get_clipboard();
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

    var revealer = new Revealer() {
      child         = w,
      reveal_child  = true,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    _widget_box.append( revealer );
    _widget_items.append( revealer );

    if( focus_widget != null ) {
      focus_widget.grab_focus();
    }

  }

  /* Removes the given widget from the widget box */
  public void remove_widget() {
    if( _widget_items.length() > 0 ) {
      var widget = _widget_items.nth_data( 0 );
      _widget_box.remove( widget );
      _widget_items.remove( widget );
      widget.destroy();
    }
    _editor.grab_focus();
  }

  /* Displays the given error message */
  public void show_error( string msg ) {
    _info_label.label       = msg;
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
