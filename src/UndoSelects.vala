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

using Gtk;

public class UndoSelects : UndoItem {

  private class UndoSelect {

    private bool _add;
    private int  _start;
    private int  _end;

    public UndoSelect( bool add, int start, int end ) {
      _add   = add;
      _start = start;
      _end   = end;
    }

    public void undo( Editor editor ) {
      TextIter start, end;
      editor.buffer.get_iter_at_offset( out start, _start );
      editor.buffer.get_iter_at_offset( out end,   _end );
      if( _add ) {
        editor.buffer.remove_tag_by_name( "selected", start, end );
      } else {
        editor.buffer.apply_tag_by_name( "selected", start, end );
      }
    }

    public void redo( Editor editor ) {
      TextIter start, end;
      editor.buffer.get_iter_at_offset( out start, _start );
      editor.buffer.get_iter_at_offset( out end,   _end );
      if( _add ) {
        editor.buffer.apply_tag_by_name( "selected", start, end );
      } else {
        editor.buffer.remove_tag_by_name( "selected", start, end );
      }
    }

  }

  private Array<UndoSelect> _undo_items;

  /* Default constructor */
  public UndoSelects( string name ) {
    base( name );
    _undo_items = new Array<UndoSelect>();
  }

  public void add_select( bool add, int start, int end ) {
    _undo_items.append_val( new UndoSelect( add, start, end ) );
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
