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

public class ClearSelected : TextFunction {

  /* Constructor */
  public ClearSelected( bool custom = false ) {
    base( "clear-selected", custom );
  }

  protected override string get_label0() {
    return( _( "Clear Match Highlight" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new ClearSelected( custom ) );
  }

  /* Returns true if there is matched text within the editor */
  public override bool launchable( Editor editor ) {
    return( editor.is_selected() );
  }

  /* Called when the action button is clicked.  Displays the UI. */
  public override void launch( Editor editor ) {
    var undo_item = new UndoItem( name );
    editor.remove_selected( undo_item );
    editor.undo_buffer.add_item( undo_item );
  }

}
