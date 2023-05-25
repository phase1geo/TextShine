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
using Gdk;
using GLib;

public class TextShine : Granite.Application {

  private static bool       show_version   = false;
  private static bool       show_functions = false;
  public  static string[]?  functions      = null;
  private        MainWindow appwin;

  public  static GLib.Settings settings;
  public  static bool          use_clipboard = false;
  public  static string        version       = "1.2.0";

  public TextShine () {

    Object( application_id: "com.github.phase1geo.textshine", flags: ApplicationFlags.HANDLES_OPEN );

    /* Allow application to be translated */
    Intl.setlocale( LocaleCategory.ALL, "" );
    Intl.bindtextdomain( GETTEXT_PACKAGE, LOCALEDIR );
    Intl.bind_textdomain_codeset( GETTEXT_PACKAGE, "UTF-8" );
    Intl.textdomain( GETTEXT_PACKAGE );

    startup.connect( start_application );
    open.connect( open_files );

  }

  /* First method called in the startup process */
  private void start_application() {

    /* Initialize the settings */
    settings = new GLib.Settings( "com.github.phase1geo.textshine" );

    /* Add the application-specific icons */
    weak IconTheme default_theme = IconTheme.get_default();
    default_theme.add_resource_path( "/com/github/phase1geo/textshine" );

    /* Create the main window */
    appwin = new MainWindow( this );

    /* If we need to display the available functions, do that and exit the application */
    if( show_functions ) {
      show_all_functions();
      Process.exit( 0 );
    }

    /* Initialize the editor with the clipboard contents */
    if( use_clipboard ) {
      appwin.do_paste_over();
    }

    /* Handle any changes to the position of the window */
    appwin.configure_event.connect(() => {
      int root_x, root_y;
      int size_w, size_h;
      appwin.get_position( out root_x, out root_y );
      appwin.get_size( out size_w, out size_h );
      settings.set_int( "window-x", root_x );
      settings.set_int( "window-y", root_y );
      settings.set_int( "window-w", size_w );
      settings.set_int( "window-h", size_h );
      return( false );
    });

  }

  /* Called whenever files need to be opened */
  private void open_files( File[] files, string hint ) {
    hold();
    foreach( File open_file in files ) {
      var file = open_file.get_path();
      appwin.notification( _( "Opening file" ), file );
      if( !appwin.open_file( file ) ) {
        stdout.printf( "ERROR:  Unable to open file '%s'\n", file );
      }
    }
    Gtk.main();
    release();
  }

  /* Called if we have no files to open */
  protected override void activate() {
    hold();
    Gtk.main();
    release();
  }

  /* Line wraps the description string to fit on screen */
  private string format_description( string description, int left_chars ) {

    var max_chars  = 80;
    var left_space = "\n" + string.nfill( (left_chars + 2), ' ' );
    var str        = "";
    var line_len   = 0;
    
    for( int i=0; i<description.char_count(); i++ ) {
      var ch = description.get_char( description.index_of_nth_char( i ) );
      if( ((line_len + left_chars) >= max_chars) && ((ch == '\n') || (ch == ' ') || (ch == '\t')) ) {
        str += "\n";
        line_len = 0;
      } else {
        str += ch.to_string();
        line_len++;
      }
    }

    return( str.replace( "\n", left_space ) );

  }

  /* Displays the list of all available functions */
  private void show_all_functions() {

    var max_count = 0;
    var functions = appwin.functions.functions;

    for( int i=0; i<functions.length; i++ ) {
      var function = functions.index( i );
      if( function.name.char_count() > max_count ) {
        max_count = function.name.char_count();
      }
    }

    stdout.printf( _( "Available Conversion Functions:\n" ) );

    for( int i=0; i<functions.length; i++ ) {
      var function = functions.index( i );
      stdout.printf( "  %%-%ds  %%s\n".printf( max_count ), function.name, format_description( function.get_description(), (max_count + 4) ) );
    }

  }

  /* Parse the command-line arguments */
  private void parse_arguments( ref unowned string[] args ) {

    var context = new OptionContext( "- TextShine Options" );
    var options = new OptionEntry[5];

    /* Create the command-line options */
    options[0] = {"version",        0, 0, OptionArg.NONE,         ref show_version,   _( "Display version number" ), null};
    options[1] = {"use-clipboard",  0, 0, OptionArg.NONE,         ref use_clipboard,  _( "Transform clipboard text" ), null};
    options[2] = {"show-functions", 0, 0, OptionArg.NONE,         ref show_functions, _( "Show available conversion functions" ), null};
    options[3] = {"convert-with",   0, 0, OptionArg.STRING_ARRAY, ref functions,      _( "Convert with text functions" ), _( "FUNCTION..." )};
    options[4] = {null};

    /* Parse the arguments */
    try {
      context.set_help_enabled( true );
      context.add_main_entries( options, null );
      context.parse( ref args );
    } catch( OptionError e ) {
      stdout.printf( "ERROR: %s\n", e.message );
      stdout.printf( "Run '%s --help' to see valid options\n", args[0] );
      Process.exit( 1 );
    }

    /* If the version was specified, output it and then exit */
    if( show_version ) {
      stdout.printf( version + "\n" );
      Process.exit( 0 );
    }

  }

  /* Creates the home directory and returns it */
  public static string get_home_dir() {
    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "textshine" );
    DirUtils.create_with_parents( dir, 0775 );
    return( dir );
  }

  /* Main routine which gets everything started */
  public static int main( string[] args ) {

    var app = new TextShine();
    app.parse_arguments( ref args );

    return( app.run( args ) );

  }

}
