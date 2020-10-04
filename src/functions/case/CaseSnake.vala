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

public class CaseSnake : TextFunction {

  private static Regex _is;

  /* Constructor */
  public CaseSnake() {
    base( "case-snake" );
    try {
      _is = new Regex( "^[a-z_]+$" );
    } catch( RegexError e ) {}
  }

  protected override string get_label0() {
    return( _( "Snake Case" ) );
  }

  public override TextFunction copy() {
    return( new CaseSnake() );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    string[] parts;
    string   orig = original.ascii_down();
    if( CaseCamel.is_camel_case( original, out parts ) ) {
      orig = string.joinv( " ", parts );
    }
    return( orig.replace( " ", "_" ) );
  }

  /*
   Returns true if the given string is in camel case; otherwise, returns false.
   If true is returned, the camel case string is broken into its parts and returned
   for further processing.
  */
  public static bool is_snake_case( string text, out string[] parts ) {
    parts = {};
    if( _is.match( text ) ) {
      parts = text.ascii_down().split( "_" );
      return( true );
    }
    return( false );
  }

}
