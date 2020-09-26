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

public class RegExpr : TextFunction {

  private MainWindow  _win;
  private SearchEntry _pattern;
  private Entry       _replace;
  private Editor      _editor;

  /* Constructor */
  public RegExpr( MainWindow win ) {

    base( "regexpr", _( "Regular Expression" ) );

    _win = win;
    _win.add_widget( "reg-expr", create_widget() );

  }

  /* Creates the search UI */
  private Box create_widget() {

    var box = new Box( Orientation.HORIZONTAL, 5 );

    _pattern = new SearchEntry();
    _pattern.placeholder_text = _( "Regular Expression" );
    _pattern.next_match.connect( do_search );

    _replace = new Entry();
    _replace.placeholder_text = _( "Replace With" );

    box.pack_start( _pattern, false, false, 10 );
    box.pack_start( _replace, false, false, 10 );

    return( box );

  }

  /* Perform search and replacement */
  private void do_search() {
    run( _editor );
  }

  public override void launch( Editor editor ) {
    _editor = editor;
    _win.show_widget( "reg-expr" );
  }

  public override string transform_text( string original, int cursor_pos ) {
    stdout.printf( "In transform_text\n" );
    Regex re;
    var   new_text = original;
    try {
      re = new Regex( _pattern.text );
    } catch( RegexError e ) {
      _win.show_error( _( "Bad regular expression syntax" ) );
      return( new_text );
    }
    try {
      new_text = re.replace( original, original.length, 0, _replace.text );
    } catch( RegexError e ) {
      _win.show_error( _( "Error in text replacement" ) );
      return( new_text );
    }
    return( new_text );
  }

}
