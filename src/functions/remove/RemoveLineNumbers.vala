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

  public RemoveLineNumbers( bool custom = false ) {
    base( "remove-line-numbers", custom );
    try {
      _re = new Regex( """^\s*\d+[^a-zA-Z_\s]?(.*)$""" );
    } catch( RegexError e ) {}
  }

  protected override string get_label0() {
    return( _( "Remove Line Numbers" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new RemoveLineNumbers( custom ) );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    string[] lines = {};
    foreach( string line in original.split( "\n" ) ) {
      MatchInfo match;
      if( _re.match( line, 0, out match ) ) {
        lines += match.fetch( 1 );
      } else {
        lines += line;
      }
    }
    return( string.joinv( "\n", lines ) );
  }

}
