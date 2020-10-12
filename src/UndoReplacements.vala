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

public class UndoReplacements : UndoItem {

  private class UndoReplacement {

    private int    _start;
    private string _old_text;
    private string _new_text;

    public UndoReplacement( int start, string old_text, string new_text ) {
      _start    = start;
      _old_text = old_text;
      _new_text = new_text;
    }

    private void replace( Editor editor, string curr, string prev ) {
      TextIter start, end;
      editor.buffer.get_iter_at_offset( out start, _start );
      if( curr.length > 0 ) {
        editor.buffer.get_iter_at_offset( out end, (_start + curr.char_count()) );
        editor.buffer.delete( ref start, ref end );
      }
      editor.buffer.insert( ref start, prev, prev.length );
    }

    public void undo( Editor editor ) {
      replace( editor, _new_text, _old_text );
    }

    public void redo( Editor editor ) {
      replace( editor, _old_text, _new_text );
    }

  }

  private Array<UndoReplacement> _undo_items;

  /* Default constructor */
  public UndoReplacements( string name ) {
    base( name );
  }

  public void add_replacement( int start, string old_string, string new_string ) {
    _undo_items.append_val( new UndoReplacement( start, old_string, new_string ) );
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
