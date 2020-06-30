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

public class CaseSentence : TextFunction {

  Regex _re;

  /* Constructor */
  public CaseSentence() {
    base( "case-sentence", _( "Sentence Case" ) );
    try {
      _re = new Regex( "(^\\s*|[.!?]\\s+)([a-z])" );
    } catch( RegexError e ) {}
  }

  /* Perform the transformation */
  public override string transform_text( string original ) {
    MatchInfo matches;
    int       start, end;
    var       orig = original.ascii_down();
    while( _re.match( orig, 0, out matches ) ) {
      matches.fetch_pos( 2, out start, out end );
      orig = orig.splice( start, end, orig.slice( start, end ).ascii_up() );
    }
    return( orig );
  }

}
