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

public class Editor : SourceView {

  /* Constructor */
  public Editor( MainWindow win ) {

    wrap_mode = WrapMode.WORD;

    /* Set a CSS style class so that we can adjust the font */
    get_style_context().add_class( "editor" );

    /* Set the default font */
    var font_name = TextShine.settings.get_string( "default-font-family" );
    var font_size = TextShine.settings.get_int( "default-font-size" );
    change_name_font( font_name, font_size );

  }

  /* Updates the font theme */
  public void change_name_font( string name, int size ) {

    var provider = new CssProvider();

    try {
      var css_data = ".editor { font: " + size.to_string() + "px \"" + name + "\"; }";
      provider.load_from_data( css_data );
    } catch( GLib.Error e ) {
      stdout.printf( "Unable to change font: %s\n", e.message );
    }

    /* Set the CSS */
    get_style_context().add_provider(
      provider,
      STYLE_PROVIDER_PRIORITY_APPLICATION
    );

  }

  /* Returns the current range of text that will be transformed */
  public void get_range( out TextIter start, out TextIter end ) {
    if( !buffer.get_selection_bounds( out start, out end ) ) {
      buffer.get_start_iter( out start );
      buffer.get_end_iter( out end );
    }
  }

  /* Returns the current range of text that will be transformed */
  public string get_current_text() {
    TextIter start, end;
    get_range( out start, out end );
    return( buffer.get_text( start, end, false ) );
  }

  /* Replaces the given range with the specified text */
  public void replace_text( string text ) {
    TextIter start, end;
    get_range( out start, out end );
    if( start.compare( end ) != 0 ) {
      buffer.delete( ref start, ref end );
      buffer.insert( ref start, text, text.length );
    }
  }

}
