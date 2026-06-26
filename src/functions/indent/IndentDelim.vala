/*
* Copyright (c) 2020-2026 (https://github.com/phase1geo/TextShine)
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
using Xml;

public class IndentDelim : TextFunction {

  private string[] _start_delims  = { "{", "[" };
  private string[] _end_delims    = { "}", "]" };
  private string[] _ignore_delims = { "\"", "'" };

  //-------------------------------------------------------------
  // Constructor
  public IndentDelim( bool custom = false ) {
    base( "indent-delim", custom );
  }

  protected override string get_label0() {
    return( _( "Indent With Custom Delimiters" ) );
  }

  public override TextFunction copy( bool custom ) {
    var copy = new IndentDelim( custom );
    copy._start_delims  = _start_delims;
    copy._end_delims    = _end_delims;
    copy._ignore_delims = _ignore_delims;
    return( copy );
  }

  public override bool settings_available() {
    return( true );
  }

  //-------------------------------------------------------------
  // Populates the given popover with the settings
  public override void add_settings( Grid grid ) {
    add_string_setting( grid, 0, _( "Indent delimiters" ), string.joinv( ",", _start_delims ), (value) => {
      _start_delims = value.split( "," );
    });
    add_string_setting( grid, 1, _( "Unindent delimiters" ), string.joinv( ",", _end_delims ), (value) => {
      _end_delims = value.split( "," );
    });
    add_string_setting( grid, 2, _( "Ignore delimiters" ), string.joinv( ",", _ignore_delims ), (value) => {
      _ignore_delims = value.split( "," );
    });
  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "indent",   string.joinv( ",", _start_delims ) );
    node->set_prop( "unindent", string.joinv( ",", _end_delims ) );
    node->set_prop( "ignore",   string.joinv( ",", _ignore_delims ) );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    var i = node->get_prop( "indent" );
    if( i != null ) {
      _start_delims = i.split( "," );
    }
    var u = node->get_prop( "unindent" );
    if( u != null ) {
      _end_delims = u.split( "," );
    }
    var ignore = node->get_prop( "ignore" );
    if( ignore != null ) {
      _ignore_delims = ignore.split( "," );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the given text string contains an ignore
  // delimiter.
  private bool ends_with_delims( string text, ref string[] delims, out string matched ) {
    matched = "";
    foreach( var delim in delims ) {
      if( text.has_suffix( delim ) ) {
        matched = delim;
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Perform the transformation
  public override string transform_text( string original, int cursor_pos ) {

    var new_text     = new StringBuilder();
    var indent       = 0;
    var escaped      = false;
    var ignored      = false;
    var ignore_delim = "";
    var nl_added     = false;

    foreach( var line in original.split( "\n" ) ) {

      var curr_line = "";
      var trimmed   = line.strip();

      if( indent > 0 ) {
        new_text.append( string.nfill( indent, '\t' ) );
      }

      for( int i=0; i<trimmed.length; i++ ) {

        if( !trimmed.valid_char( i ) ) {
          continue;
        }

        var ch = trimmed.get_char( i );

        stdout.printf( "curr_line: %s (%s)\n", curr_line, ch.to_string() );

        if( nl_added ) {
          nl_added = false;
        }

        if( escaped ) {
          escaped = false;
          curr_line += ch.to_string();
          continue;
        }

        if( ch == '\\' ) {
          escaped = true;
          curr_line += ch.to_string();
          continue;
        }

        var str     = curr_line + ch.to_string();
        var matched = "";

        if( ends_with_delims( str, ref _ignore_delims, out matched ) && (!ignored || (ignore_delim == matched)) ) {
          ignored = !ignored;
          ignore_delim = matched;
          curr_line += ch.to_string();
          continue;
        }

        if( ignored ) {
          curr_line += ch.to_string();
          continue;
        }

        if( ends_with_delims( str, ref _start_delims, out matched ) ) {
          indent++;
          new_text.append( str.slice( 0, (str.length - matched.length) ) + matched + "\n" + string.nfill( indent, '\t' ) );
          curr_line = "";
          nl_added  = true;
          continue;
        }

        if( ends_with_delims( str, ref _end_delims, out matched ) ) {
          indent--;
          new_text.append( str.slice( 0, (str.length - matched.length) ) + "\n" + string.nfill( indent, '\t' ) + matched );
          curr_line = "";
          nl_added = true;
          continue;
        }

        curr_line = str;

      }

      if( nl_added ) {
        nl_added = false;
      } else {
        new_text.append( curr_line + "\n" );
      }

    }

    return( new_text.str );

  }

}
