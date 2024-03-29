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

public class TextShine : Gtk.Application {

  private static bool       show_version  = false;
  private        MainWindow appwin;

  public  static GLib.Settings settings;
  public  static bool          use_clipboard = false;
  public  static string        version       = "2.0";

  public TextShine () {

    Object( application_id: "com.github.phase1geo.textshine", flags: ApplicationFlags.HANDLES_OPEN );

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
    weak IconTheme default_theme = IconTheme.get_for_display( Display.get_default() );
    default_theme.add_resource_path( "/com/github/phase1geo/textshine" );

    /* Create the main window */
    appwin = new MainWindow( this );

    /* Initialize the editor with the clipboard contents */
    if( use_clipboard ) {
      appwin.do_paste_over();
    }

  }

  /* Called whenever files need to be opened */
  private void open_files( File[] files, string hint ) {
    foreach( File open_file in files ) {
      var file = open_file.get_path();
      appwin.notification( _( "Opening file" ), file );
      if( !appwin.open_file( file ) ) {
        stdout.printf( "ERROR:  Unable to open file '%s'\n", file );
      }
    }
  }

  /* Called if we have no files to open */
  protected override void activate() {}

  /* Parse the command-line arguments */
  private void parse_arguments( ref unowned string[] args ) {

    var context = new OptionContext( "- TextShine Options" );
    var options = new OptionEntry[3];

    /* Create the command-line options */
    options[0] = {"version",       0, 0, OptionArg.NONE, ref show_version, _( "Display version number" ), null};
    options[1] = {"use-clipboard", 0, 0, OptionArg.NONE, ref use_clipboard, _( "Transform clipboard text" ), null};
    options[2] = {null};

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
