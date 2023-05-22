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

using Xml;

public class IndentXML : TextFunction {

  /* Constructor */
  public IndentXML( bool custom = false ) {
    base( "indent-xml", custom );
  }

  protected override string get_label0() {
    return( _( "Indent XML" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new IndentXML( custom ) );
  }

  private bool next_char_is( string str, int start, string match_char ) {
    for( int i=start; i<str.char_count(); i++ ) {
      var c = str.get_char( str.index_of_nth_char( i ) ).to_string();
      if( c == match_char ) {
        return( true );
      } else if( (c != " ") && (c != "\t") ) {
        return( false );
      }
    }
    return( false );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    var orig        = original;
    var indent      = 0;
    var line_indent = 0;
    var in_tag      = false;  // Set when we are within a tag
    var in_ds       = false;  // Set when we are in a double-quoted string
    var in_ss       = false;  // Set when we are in a single-quoted string
    var saw_first   = false;  // Set when we have found the first character in a line
    var pos         = 0;
    var begin_pos   = 0;      // Position of the beginning tag char
    var slash_pos   = 0;      // Position of the slash char
    var start_found = false;  // Set when an opening tag is found on the current line
    var str         = "";
    var line        = "";
    for( int i=0; i<orig.char_count(); i++ ) {
      var c = orig.get_char( orig.index_of_nth_char( i ) ).to_string();
      switch( c ) {
        case "<"  :
          if( !in_ds && !in_ss && !in_tag ) {
            in_tag = true;
            begin_pos = pos;
          }
          saw_first = true;
          break;
        case ">"  :
          if( in_tag ) {
            if( (begin_pos + 1) == slash_pos ) {   // If this is an closing tag
              line_indent--;
              if( !next_char_is( orig, (i + 1), "\n" ) ) {
                var ins_index = orig.index_of_nth_char( i + 1 );
                orig = orig.splice( ins_index, ins_index, "\n" );
              }
            } else if( (slash_pos + 1) != pos ) {  // If this is an opening tag
              line_indent++;
              start_found = true;
              if( next_char_is( orig, (i + 1), "<" ) ) {
                var ins_index = orig.index_of_nth_char( i + 1 );
                orig = orig.splice( ins_index, ins_index, "\n" );
              }
            } else {  // End of an opening/closing tag
              if( !next_char_is( orig, (i + 1), "\n" ) ) {
                var ins_index = orig.index_of_nth_char( i + 1 );
                orig = orig.splice( ins_index, ins_index, "\n" );
              }
            }
            in_tag = false;
          }
          saw_first = true;
          break;
        case "/"  :
          if( in_tag ) {
            slash_pos = pos;
          }
          saw_first = true;
          break;
        case "\"" :
          if( in_tag && !in_ss ) {
            in_ds = !in_ds;
          }
          saw_first = true;
          break;
        case "'"  :
          if( in_tag && !in_ds ) {
            in_ss = !in_ss;
          }
          saw_first = true;
          break;
        case " "  :
        case "\t" :
          break;
        case "\n" :
          if( start_found ) {
            if( indent > 0 ) {
              str += string.nfill( indent, '\t' );
            }
            indent += line_indent;
          } else {
            indent += line_indent;
            if( indent > 0 ) {
              str += string.nfill( indent, '\t' );
            }
          }
          str += line + "\n";
          line = "";
          line_indent = 0;
          saw_first   = false;
          start_found = false;
          break;
        default :
          saw_first = true;
          break;
      }
      if( saw_first ) {
        line += c;
      }
      pos++;
    }
    if( (indent + line_indent) > 0 ) {
      str += string.nfill( (indent + line_indent), '\t' );
    }
    str += line;
    return( str );
  }

}
