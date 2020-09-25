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

public class CaseLower : TextFunction {

  /* Constructor */
  public CaseLower() {
    base( "case-lower", _( "Lower Case" ) );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    string[] parts;
    string   orig;
    if( CaseCamel.is_camel_case( original, out parts ) ) {
      stdout.printf( "Found camel case, parts[0]: %s\n", parts[0] );
      orig = string.joinv( " ", parts );
      stdout.printf( "  orig: %s\n", orig );
    } else if( CaseSnake.is_snake_case( original, out parts ) ) {
      orig = string.joinv( " ", parts );
    } else {
      orig = original;
    }
    return( orig.ascii_down() );
  }

}
