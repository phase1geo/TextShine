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

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    var indent      = 0;
    var line_indent = 0;
    var in_tag      = false;
    var in_ds       = false;
    var in_ss       = false;
    var saw_first   = false;
    var pos         = 0;
    var begin_pos   = 0;
    var slash_pos   = 0;
    var start_found = false;
    var str         = "";
    var line        = "";
    for( int i=0; i<original.length; i++ ) {
      if( original.valid_char( i ) ) {
        var c = original.get_char( i ).to_string();
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
              if( (begin_pos + 1) == slash_pos ) {
                line_indent--;
              } else if( (slash_pos + 1) != pos ) {
                if( !start_found ) {
                  str += string.nfill( (indent + line_indent), '\t' );
                }
                line_indent++;
                start_found = true;
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
            indent += line_indent;
            if( !start_found ) {
              str += string.nfill( indent, '\t' );
            }
            str += line + "\n";
            line = "";
            line_indent = 0;
            start_found = false;
            saw_first = false;
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
    }
    if( !start_found ) {
      str += string.nfill( (indent + line_indent), '\t' );
    }
    str += line;
    return( str );
  }

}
