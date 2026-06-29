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

public class InsertNewline : TextFunction {

  private bool           _after = true;
  private string         _delim = "";
  private bool           _skip_comments = false;
  private bool           _skip_strings  = false;
  private GlobalSettings _settings;

  //-------------------------------------------------------------
  // Constructor
  public InsertNewline( bool custom = false ) {
    base( "insert-newline", custom );
  }

  protected override string get_label0() {
    var delim_str = (_delim == "") ? _( "Delimiter" ) : "'%s'".printf( _delim );
    return( _after ? _( "Insert Newline After %s" ).printf( delim_str ) :
                     _( "Insert Newline Before %s" ).printf( delim_str ) );
  }

  public override TextFunction copy( bool custom ) {
    var copy = new InsertNewline( custom );
    copy._after = _after;
    copy._delim = _delim;
    copy._skip_comments = _skip_comments;
    copy._skip_strings  = _skip_strings;
    return( copy );
  }

  public override bool matches( TextFunction function ) {
    if( base.matches( function ) ) {
      var func = (InsertNewline)function;
      return(
        (_after == func._after) &&
        (_delim == func._delim) &&
        (_skip_comments == func._skip_comments) &&
        (_skip_strings  == func._skip_strings)
      );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Specify that we have settings to display
  public override bool settings_available() {
    return( true );
  }

  //-------------------------------------------------------------
  // Populates the given popover with the settings
  public override void add_settings( Grid grid ) {

    add_menubutton_setting( grid, 0, _( "Newline Location" ), (int)_after, 2, (value) => {
      return( (value == 0) ? _( "Before" ) : _( "After" ) );
    }, (value) => {
      _after = (value == 1);
      update_button_label();
    });

    add_string_setting( grid, 1, _( "Delimiter" ), _delim, (value) => {
      _delim = value;
      update_button_label();
    });

    add_bool_setting( grid, 2, _( "Skip delimiters in comments" ), _skip_comments, (value) => {
      _skip_comments = value;
    });

    add_bool_setting( grid, 3, _( "Skip delimiters in strings" ), _skip_strings, (value) => {
      _skip_strings = value;
    });

  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "after", _after.to_string() );
    node->set_prop( "delim", _delim );
    node->set_prop( "skip-comments", _skip_comments.to_string() );
    node->set_prop( "skip-strings",  _skip_strings.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions, GlobalSettings settings ) {
    base.load( node, functions, settings );
    _settings = settings;
    var a = node->get_prop( "after" );
    if( a != null ) {
      _after = bool.parse( a );
    }
    var d = node->get_prop( "delim" );
    if( d != null ) {
      _delim = d;
    }
    var c = node->get_prop( "skip-comments" );
    if( c != null ) {
      _skip_comments = bool.parse( c );
    }
    var s = node->get_prop( "skip-strings" );
    if( s != null ) {
      _skip_strings = bool.parse( s );
    }
    update_button_label();
  }

  //-------------------------------------------------------------
  // Perform the text transformation.
  public override string transform_text( string original, int cursor_pos ) {
    if( !_skip_comments && !_skip_strings ) {
      var chunks = original.split( _delim );
      return(
        _after ? string.joinv( "%s\n".printf( _delim ), chunks ) :
                 string.joinv( "\n%s".printf( _delim ), chunks )
      );
    } else {
      string[] new_lines = {};
      var new_line       = "";
      var escaped        = false;
      var code           = new CodeHandler( _settings, _skip_comments, _skip_strings );
      for( int i=0; i<original.length; i++ ) {
        if( !original.valid_char( i ) ) {
          continue;
        }
        var ch = original.get_char( i );
        if( ch == '\n' ) {
          new_lines += new_line;
          new_line = "";
          escaped = false;
          code.handle_newline();
        }
        if( escaped ) {
          escaped = false;
          continue;
        }
        if( ch == '\\' ) {
          escaped = true;
          continue;
        }
        var str     = new_line + ch.to_string();
        var matched = "";
        if( code.check_for_ignored_text( str ) || code.ignored() ) {
          continue;
        }
        if( str.has_suffix( _delim ) ) {
          if( _after ) {
            new_lines += str;
            new_line = "";
          } else {
            new_lines += str.splice( 0, (str.length - _delim.length) );
            new_line = _delim;
          }
          continue;
        }
        new_line = str;
      }
      if( new_line != "" ) {
        new_lines += new_line;
      }
      return( string.joinv( "\n", new_lines ) );
    }
  }

}

