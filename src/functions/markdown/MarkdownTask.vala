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

public class MarkdownTask : TextFunction {

  Regex _complete_re;
  Regex _incomplete_re;

  /* Constructor */
  public MarkdownTask( bool custom = false ) {
    base( "markdown-task", custom, FunctionDirection.LEFT_TO_RIGHT );
    try {
      _complete_re   = new Regex( """^(\s*)\[[xX]\] (.*)$""" );
      _incomplete_re = new Regex( """^(\s*)\[ \] (.*)$""" );
    } catch( RegexError e ) {}
  }

  protected override string get_label0() {
    return( _( "Mark Tasks Complete" ) );
  }

  protected override string get_label1() {
    return( _( "Mark Tasks Incomplete" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new MarkdownTask( custom ) );
  }

  private string mark_tasks_complete( string original ) {
    var str   = "";
    var first = true;
    MatchInfo match;
    foreach( string line in original.split( "\n" ) ) {
      if( first ) {
        first = false;
      } else {
        str += "\n";
      }
      if( _incomplete_re.match( line, 0, out match ) ) {
        str += match.fetch( 1 ) + "[x] " + match.fetch( 2 );
      } else {
        str += line;
      }
    }
    return( str );
  }

  private string mark_tasks_incomplete( string original ) {
    var str   = "";
    var first = true;
    MatchInfo match;
    foreach( string line in original.split( "\n" ) ) {
      if( first ) {
        first = false;
      } else {
        str += "\n";
      }
      if( _complete_re.match( line, 0, out match ) ) {
        str += match.fetch( 1 ) + "[ ] " + match.fetch( 2 );
      } else {
        str += line;
      }
    }
    return( str );
  }

  public override string transform_text( string original, int cursor_pos ) {
    if( direction == FunctionDirection.LEFT_TO_RIGHT ) {
      return( mark_tasks_complete( original ) );
    } else {
      return( mark_tasks_incomplete( original ) );
    }
  }

}


