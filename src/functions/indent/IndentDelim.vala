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

  private string[]       _start_delims  = { "{", "[" };
  private string[]       _end_delims    = { "}", "]" };
  private bool           _skip_comments;
  private bool           _skip_strings;
  private GlobalSettings _settings;

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
    copy._skip_comments = _skip_comments;
    copy._skip_strings  = _skip_strings;
    return( copy );
  }

  public override bool matches( TextFunction function ) {
    if( base.matches( function ) ) {
      var func = (IndentDelim)function;
      return(
        (_start_delims  == func._start_delims)  &&
        (_end_delims    == func._end_delims)    &&
        (_skip_comments == func._skip_comments) &&
        (_skip_strings  == func._skip_strings)
      );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Sets the global settings to this value.
  public override void set_global_settings( GlobalSettings settings ) {
    _settings = settings;
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
    add_bool_setting( grid, 2, _( "Skip delimiters in comments" ), _skip_comments, (value) => {
      _skip_comments = value;
    });
    add_bool_setting( grid, 3, _( "Skip delimiters in strings" ), _skip_strings, (value) => {
      _skip_strings = value;
    });
  }

  //-------------------------------------------------------------
  // Saves the contents of this function to XML format
  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "indent",   string.joinv( ",", _start_delims ) );
    node->set_prop( "unindent", string.joinv( ",", _end_delims ) );
    node->set_prop( "skip-comments", _skip_comments.to_string() );
    node->set_prop( "skip-strings",  _skip_strings.to_string() );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the contents of this function from XML format.
  public override void load( Xml.Node* node, TextFunctions functions, GlobalSettings settings ) {
    base.load( node, functions, settings );
    _settings = settings;
    var i = node->get_prop( "indent" );
    if( i != null ) {
      _start_delims = i.split( "," );
    }
    var u = node->get_prop( "unindent" );
    if( u != null ) {
      _end_delims = u.split( "," );
    }
    var c = node->get_prop( "skip-comments" );
    if( c != null ) {
      _skip_comments = bool.parse( c );
    }
    var s = node->get_prop( "skip-strings" );
    if( s != null ) {
      _skip_strings = bool.parse( s );
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

    var new_text = new StringBuilder();
    var indent   = 0;
    var escaped  = false;
    var code     = new CodeHandler( _settings, _skip_comments, _skip_strings );

    foreach( var line in original.split( "\n" ) ) {

      var trimmed = line.strip();
      var start_idx = 0;

      foreach( var delim in _end_delims ) {
        if( trimmed.has_prefix( delim ) ) {
          indent = (indent == 0) ? 0 : (indent - 1);
          start_idx = 1;
          break;
        }
      }

      if( indent > 0 ) {
        new_text.append( string.nfill( indent, '\t' ) );
      }

      new_text.append( trimmed + "\n" );

      for( int i=start_idx; i<trimmed.length; i++ ) {

        if( !trimmed.valid_char( i ) ) {
          continue;
        }

        var ch = trimmed.get_char( i );

        if( escaped ) {
          escaped = false;
          continue;
        }

        if( ch == '\\' ) {
          escaped = true;
          continue;
        }

        var str     = trimmed.slice( 0, i ) + ch.to_string();
        var matched = "";

        if( code.check_for_ignored_text( str ) || code.ignored() ) {
          continue;
        }

        if( ends_with_delims( str, ref _start_delims, out matched ) ) {
          indent++;
          continue;
        }

        if( ends_with_delims( str, ref _end_delims, out matched ) ) {
          indent--;
          continue;
        }

      }

      code.handle_newline();

    }

    return( new_text.str );

  }

}
