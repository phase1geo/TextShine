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

public class InvertSelected : TextFunction {

  /* Constructor */
  public InvertSelected( bool custom = false ) {
    base( "invert-selected", custom );
  }

  public override string get_description() {
    return( _( "Highlights all text that is currently not highlighted and clears the originally highlight text." ) );
  }

  protected override string get_label0() {
    return( _( "Invert Matched Text" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new InvertSelected( custom ) );
  }

  /* Returns true if there is matched text within the editor */
  public override bool launchable( Editor editor ) {
    return( editor.is_selected() );
  }

  /* Called when the action button is clicked.  Displays the UI. */
  public override void launch( Editor editor ) {

    var undo_item = new UndoItem( name );
    var ranges    = new Array<Editor.Position>();
    editor.get_ranges( ranges );

    TextIter first, last;
    editor.buffer.get_bounds( out first, out last );
    editor.remove_selected( undo_item );

    for( int i=0; i<ranges.length; i++ ) {
      var range = ranges.index( i );
      if( !first.equal( range.start ) ) {
        editor.add_selected( first, range.start, undo_item );
      }
      first = range.end;
    }

    if( !first.equal( last ) ) {
      editor.add_selected( first, last, undo_item );
    }

    editor.undo_buffer.add_item( undo_item );

  }

}
