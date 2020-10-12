/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
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

using GLib;

public class UndoCustom : UndoItem {

  private Array<UndoItem> _undo_items;

  /* Default constructor */
  public UndoCustom( string name ) {
    base( name );
    _undo_items = new Array<UndoItem>();
  }

  public void add_item( UndoItem undo_item ) {
    _undo_items.append_val( undo_item );
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( Editor editor ) {
    for( int i=((int)_undo_items.length - 1); i>=0; i-- ) {
      _undo_items.index( i ).undo( editor );
    }
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( Editor editor ) {
    for( int i=0; i<_undo_items.length; i++ ) {
      _undo_items.index( i ).redo( editor );
    }
  }

}
