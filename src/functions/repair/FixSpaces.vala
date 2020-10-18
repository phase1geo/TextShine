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

public class FixSpaces : TextFunction {

  private Regex _extra_re;
  private Regex _missing_pre_re;
  private Regex _missing_post_re;

  /* Constructor */
  public FixSpaces() {
    base( "fix-spaces" );
    try {
      _extra_re        = new Regex( """ {2,}""" );
      _missing_pre_re  = new Regex( """[^ ]([\(\{\[])""" );
      _missing_post_re = new Regex( """[],.?!\)\}:;%&*-]([^ ])""" );
    } catch( RegexError e ) {}
  }

  protected override string get_label0() {
    return( _( "Fix Spaces" ) );
  }

  public override TextFunction copy() {
    return( new FixSpaces() );
  }

  public override string transform_text( string original, int cursor_pos ) {

    MatchInfo match;
    int       start, end;
    var       str = "";

    foreach( string line in original.split( "\n" ) ) {

      /* Remove extra spaces */
      while( _extra_re.match( line, 0, out match ) ) {
        match.fetch_pos( 0, out start, out end );
        line = line.splice( start, end, " " );
      }

      /* Add spaces if they are missing */
      while( _missing_pre_re.match( line, 0, out match ) ) {
        match.fetch_pos( 1, out start, out end );
        line = line.splice( start, start, " " );
      }
      while( _missing_post_re.match( line, 0, out match ) ) {
        match.fetch_pos( 1, out start, out end );
        line = line.splice( start, start, " " );
      }

      str += line + "\n";

    }

    return( str );

  }

}

