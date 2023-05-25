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
using Gee;

public class MarkdownReferences : TextFunction {

  private Regex                  _link_re;
  private Regex                  _ref_re;
  private int                    _ref_num;
  private Array<string>          _links;
  private HashMap<string,string> _link_to_ref;
  private HashMap<string,string> _old_to_new;

  /* Constructor */
  public MarkdownReferences( bool custom = false ) {
    base( "markdown-references", custom );
    try {
      _link_re = new Regex( """\[[^]]*\](\(([^\)]+)\)|\[([^]]+)\])""" );
      _ref_re  = new Regex( """^\[(.*?)\]:\s+(.*)$""" );
    } catch( RegexError e ) {}
  }

  public override string get_description() {
    return( _( "Generates Markdown references from Markdown text and appends it to the end of the document." ) );
  }

  protected override string get_label0() {
    return( _( "Generate References" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new MarkdownReferences( custom ) );
  }

  public override void launch( Editor editor ) {

    _ref_num     = 1;
    _links       = new Array<string>();
    _link_to_ref = new HashMap<string,string>();
    _old_to_new  = new HashMap<string,string>();

    var str = editor.buffer.text;

    str = parse_refs( str );
    str = parse_links( str );
    str = append_references( str ).chomp();

    TextIter start, end;
    editor.buffer.get_bounds( out start, out end );

    var undo_item = new UndoItem( name );
    editor.replace_text( start, end, str, undo_item );
    editor.undo_buffer.add_item( undo_item );

  }

  private string parse_refs( string text ) {

    MatchInfo match;
    var       str = "";

    foreach( string line in text.split( "\n" ) ) {
      if( _ref_re.match( line, 0, out match ) ) {
        var reference = match.fetch( 1 ).strip();
        var link      = match.fetch( 2 ).strip();
        _links.append_val( link );
        _link_to_ref.@set( link, _ref_num.to_string() );
        _old_to_new.@set( reference, _ref_num.to_string() );
        _ref_num++;
      } else {
        str += line + "\n";
      }
    }

    return( str.strip() );

  }

  private string parse_links( string text ) {

    MatchInfo match;
    int       start = 0;
    int       end;
    var str = "";

    try {
      foreach( string line in text.split( "\n" ) ) {
        start = 0;
        while( _link_re.match_full( line, -1, start, 0, out match ) ) {
          if( match.fetch_pos( 2, out start, out end ) && (start != -1) ) {
            var link = line.slice( start, end ).strip();
            if( !_link_to_ref.has_key( link ) ) {
              _links.append_val( link );
              _link_to_ref.@set( link, _ref_num.to_string() );
              match.fetch_pos( 1, out start, out end );
              line = line.splice( start, end, "[" + _ref_num.to_string() + "]" );
              _ref_num++;
            }
          } else if( match.fetch_pos( 3, out start, out end ) && (start != -1) ) {
            var reference = line.slice( start, end ).strip();
            if( _old_to_new.has_key( reference ) ) {
              match.fetch_pos( 1, out start, out end );
              line = line.splice( start, end, "[" + _old_to_new.@get( reference ) + "]" );
            }
          }
        }
        str += line + "\n";
      }
    } catch( RegexError e ) {}

    return( str );

  }

  private string append_references( string text ) {

    if( _ref_num == 1 ) return( text );

    /* Append the references to the end of the text */
    var str = text + "\n";
    for( int i=1; i<_ref_num; i++ ) {
      str += "[" + i.to_string() + "]: " + _links.index( i-1 ) + "\n";
    }

    return( str );

  }

}


