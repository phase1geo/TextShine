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

public class RemoveLineNumbers : TextFunction {

  private Regex _re;

  public RemoveLineNumbers() {
    base( "remove-line-numbers", _( "Remove Line Numbers" ) );
    try {
      _re = new Regex( """^\s*\d+[^a-zA-Z_\s]?(.*)$""" );
    } catch( RegexError e ) {}
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    var str = "";
    foreach( string line in original.split( "\n" ) ) {
      MatchInfo match;
      if( _re.match( line, 0, out match ) ) {
        str += match.fetch( 1 ) + "\n";
      } else {
        str += line + "\n";
      }
    }
    return( str );
  }

}
