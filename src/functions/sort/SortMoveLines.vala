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

public class SortMoveLines : TextFunction {

  private int _count;

  /* Constructor */
  public SortMoveLines() {
    base( "sort-move-lines", FunctionDirection.TOP_DOWN );
    _count = 1;
  }

  protected override string get_label0() {
    return( _( "Move %d Lines Down" ).printf( _count ) );
  }

  protected override string get_label1() {
    return( _( "Move %d Lines Up" ).printf( _count ) );
  }

  public override TextFunction copy() {
    var fn = new SortMoveLines();
    fn._count = _count;
    return( fn );
  }

  public override void launch( Editor editor ) {

    TextIter start, end, first, last, cursor;
    string   text = "";

    var buf      = editor.buffer;
    var selected = buf.has_selection;
    var down     = (direction == FunctionDirection.TOP_DOWN);

    buf.get_iter_at_mark( out cursor, buf.get_insert() );
    var cursor_line = cursor.get_line();
    var cursor_col  = cursor.get_line_offset();

    /* Get the lines that need to be moved */
    if( !buf.get_selection_bounds( out start, out end ) ) {
      buf.get_iter_at_mark( out start, buf.get_insert() );
      end = start;
    }

    var start_line = start.get_line();
    var start_col  = start.get_line_offset();
    var end_line   = end.get_line();
    var end_col    = end.get_line_offset();

    /* Adjust the start and end iterators so that they encompass the entire line */
    buf.get_iter_at_line( out start, start.get_line() );
    if( !end.ends_line() ) end.forward_to_line_end();

    text  = start.get_slice( end );
    first = start;
    last  = end;

    if( down ) {
      if( !last.forward_lines( _count ) ) return;
      last.forward_to_line_end();
      end.forward_char();
      text = end.get_slice( last ) + "\n" + text;
    } else {
      if( !first.backward_lines( _count ) ) return;
      start.backward_char();
      text = text + "\n" + first.get_slice( start );
    }

    /* Adjust the text */
    editor.replace_text( first, last, text );

    var adjust = down ? _count : (0 - _count);

    /* Adjust the selection, if necessary */
    if( selected ) {
      buf.get_iter_at_line_offset( out start, (start_line + adjust), start_col );
      buf.get_iter_at_line_offset( out end,   (end_line   + adjust), end_col );
      buf.select_range( start, end );
    }

    /* Adjust the cursor */
    buf.get_iter_at_line_offset( out start, (cursor_line + adjust), cursor_col );
    buf.place_cursor( start );

  }

  public override bool settings_available() {
    return( true );
  }

  public override void add_settings( Grid grid ) {

    add_range_setting( grid, 0, _( "Lines" ), 1, 20, 1, _count, (value) => {
      _count = value;
      update_button_label();
    });

  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "count", _count.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    var c = node->get_prop( "count" );
    if( c != null ) {
      _count = int.parse( c );
    }
  }

}
