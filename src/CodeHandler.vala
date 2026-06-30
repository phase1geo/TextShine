/*
* Copyright (c) 2026 (https://github.com/phase1geo/TextShine)
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

public class CodeHandler {

  private BlockCommentSetting _block_settings;
  private LineCommentSetting  _line_settings;
  private StringSetting       _string_settings;
  private bool                _skip_comments = false;
  private bool                _skip_strings  = false;
  private int                 _ignored       = -1;

  //-------------------------------------------------------------
  // Constructor
  public CodeHandler( GlobalSettings settings, bool skip_comments, bool skip_strings ) {
    _block_settings  = (BlockCommentSetting)settings.find_setting( "block" );
    _line_settings   = (LineCommentSetting)settings.find_setting( "line" );
    _string_settings = (StringSetting)settings.find_setting( "string" );
    _skip_comments   = skip_comments && (_block_settings.enabled || _line_settings.enabled);
    _skip_strings    = skip_strings  && _string_settings.enabled;
  }

  //-------------------------------------------------------------
  // Returns true if we are in an ignored block of text.
  public bool ignored() {
    return( _ignored != -1 );
  }

  //-------------------------------------------------------------
  // Called when a newline character is found.
  public void handle_newline() {
    if( (_ignored >= 20) && (_ignored < 30) ) {
      _ignored = -1;
    }
  }

  //-------------------------------------------------------------
  // Looks at the current line and determines if we have just
  // entered
  public bool check_for_ignored_text( string line ) {

    // If we are not currently within a string or comment block, check the current line
    // to see if we are in one.
    if( _ignored == -1 ) {

      if( _skip_strings ) {
        for( int i=0; i<_string_settings.size(); i++ ) {
          var delim = _string_settings.get_delim( i );
          if( line.has_suffix( delim ) ) {
            _ignored = i;
            return( true );
          }
        }
      }

      if( _skip_comments ) {
        if( _block_settings.enabled ) {
          for( int i=0; i<_block_settings.size(); i++ ) {
            var delim = _block_settings.start_string( i );
            if( (delim != "") && line.has_suffix( delim ) ) {
              _ignored = i + 10;
              return( true );
            }
          }
        }
        if( _line_settings.enabled ) {
          for( int i=0; i<_line_settings.size(); i++ ) {
            var delim = _line_settings.start_string( i );
            if( (delim != "") && line.has_suffix( delim ) ) {
              _ignored = i + 20;
              return( true );
            }
          }
        }
      }

    } else if( _ignored < 10 ) {

      var delim = _string_settings.get_delim( _ignored ); 
      if( line.has_suffix( delim ) ) {
        _ignored = -1;
        return( true );
      }

    } else if( _ignored < 20 ) {

      var delim = _block_settings.end_string( _ignored - 10 );
      if( line.has_suffix( delim ) ) {
        _ignored = -1;
        return( true );
      }

    }

    return( false );

  }


}
