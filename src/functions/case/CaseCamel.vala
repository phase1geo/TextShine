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

public class CaseCamel : TextFunction {

  private Regex        _re;
  private static Regex _is;

  /* Constructor */
  public CaseCamel( bool custom = false ) {
    base( "case-camel", custom );
    try {
      _re = new Regex( "[a-zA-Z]( )([a-z])" );
      _is = new Regex( "(^|[A-Z])[a-z]*" );
    } catch( RegexError e ) {}
  }

  protected override string get_label0() {
    return( _( "Camel Case" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new CaseCamel( custom ) );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    string[] parts;
    string   orig = original.ascii_down();
    if( CaseSnake.is_snake_case( original, out parts ) ) {
      orig = string.joinv( " ", parts );
    }
    MatchInfo matches;
    while( _re.match( orig, 0, out matches ) ) {
      int start1, end1, start2, end2;
      matches.fetch_pos( 1, out start1, out end1 );
      matches.fetch_pos( 2, out start2, out end2 );
      orig = orig.splice( start2, end2, orig.slice( start2, end2 ).ascii_up() ).splice( start1, end1 );
    }
    return( orig );
  }

  /*
   Returns true if the given string is in camel case; otherwise, returns false.
   If true is returned, the camel case string is broken into its parts and returned
   for further processing.
  */
  public static bool is_camel_case( string text, out string[] parts ) {
    MatchInfo matches;
    parts = {};
    try {
      if( _is.match( text, 0, out matches ) ) {
        var arr = new Array<string>();
        int start, end = 0;
        while( matches.matches() ) {
          var str = matches.fetch( 0 ).ascii_down();
          matches.fetch_pos( 0, out start, out end );
          arr.append_val( str );
          matches.next();
        }
        if( end == text.length ) {
          parts = arr.data;
          return( true );
        }
      }
    } catch( RegexError e ) {}
    return( false );
  }

}
