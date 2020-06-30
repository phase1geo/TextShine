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

  Regex _re;

  /* Constructor */
  public CaseCamel() {
    base( "case-camel", _( "Camel Case" ) );
    try {
      _re = new Regex( "[a-zA-Z]( )([a-z])" );
    } catch( RegexError e ) {}
  }

  /* Perform the transformation */
  public override string transform_text( string original ) {
    MatchInfo matches;
    var       orig = original.ascii_down();
    while( _re.match( orig, 0, out matches ) ) {
      int start1, end1, start2, end2;
      matches.fetch_pos( 1, out start1, out end1 );
      matches.fetch_pos( 2, out start2, out end2 );
      orig = orig.splice( start2, end2, orig.slice( start2, end2 ).ascii_up() ).splice( start1, end1 );
    }
    return( orig );
  }

}
