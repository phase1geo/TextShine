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

public class UndoBuffer : Object {

  protected Editor          _editor;
  protected Array<UndoItem> _undo_buffer;
  protected Array<UndoItem> _redo_buffer;
  private   bool            _debug = false;
  private   static int      _current_id = 0;

  public signal void buffer_changed( UndoBuffer buf );

  /* Default constructor */
  public UndoBuffer( Editor editor ) {
    _editor      = editor;
    _undo_buffer = new Array<UndoItem>();
    _redo_buffer = new Array<UndoItem>();
  }

  /* Clear the undo/redo buffers */
  public void clear() {
    _undo_buffer.remove_range( 0, _undo_buffer.length );
    _redo_buffer.remove_range( 0, _redo_buffer.length );
    buffer_changed( this );
  }

  /* Returns true if we can perform an undo action */
  public bool undoable() {
    return( _undo_buffer.length > 0 );
  }

  /* Returns true if we can perform a redo action */
  public bool redoable() {
    return( _redo_buffer.length > 0 );
  }

  /* Performs the next undo action in the buffer */
  public virtual void undo() {
    if( undoable() ) {
      UndoItem item = _undo_buffer.index( _undo_buffer.length - 1 );
      item.undo( _editor );
      _undo_buffer.remove_index( _undo_buffer.length - 1 );
      _redo_buffer.append_val( item );
      buffer_changed( this );
    }
    output( "AFTER UNDO" );
  }

  /* Performs the next redo action in the buffer */
  public virtual void redo() {
    if( redoable() ) {
      UndoItem item = _redo_buffer.index( _redo_buffer.length - 1 );
      item.redo( _editor );
      _redo_buffer.remove_index( _redo_buffer.length - 1 );
      _undo_buffer.append_val( item );
      buffer_changed( this );
    }
    output( "AFTER REDO" );
  }

  /* Returns the undo tooltip */
  public string undo_tooltip() {
    if( _undo_buffer.length == 0 ) return( _( "Undo" ) );
    return( _( "Undo " ) + _undo_buffer.index( _undo_buffer.length - 1 ).name );
  }

  /* Returns the undo tooltip */
  public string redo_tooltip() {
    if( _redo_buffer.length == 0 ) return( _( "Redo" ) );
    return( _( "Redo " ) + _redo_buffer.index( _redo_buffer.length - 1 ).name );
  }

  /* Adds a new undo item to the undo buffer.  Clears the redo buffer. */
  public void add_item( UndoItem item ) {
    item.id = _current_id++;
    _undo_buffer.append_val( item );
    _redo_buffer.remove_range( 0, _redo_buffer.length );
    buffer_changed( this );
    output( "ITEM ADDED" );
  }

  /*
   Returns a handle to the last item in the undo buffer if it is considered to be
   mergeable with an edit insert or delete operation; otherwise, returns null.
  */
  public UndoItem? get_mergeable( bool insert, int start, int end ) {
    if( _undo_buffer.length == 0 ) return( null );
    var last = _undo_buffer.index( _undo_buffer.length - 1 );
    return( last.mergeable( insert, start, end ) ? last : null );
  }

  /* Outputs the state of the undo and redo buffers to standard output */
  public void output( string msg = "BUFFER STATE" ) {
    if( _debug ) {
      stdout.printf( "%s\n  Undo Buffer\n-----------\n", msg );
      for( int i=0; i<_undo_buffer.length; i++ ) {
        stdout.printf( "    %s\n", _undo_buffer.index( i ).to_string() );
      }
      stdout.printf( "  Redo Buffer\n-----------\n" );
      for( int i=0; i<_redo_buffer.length; i++ ) {
        stdout.printf( "    %s\n", _redo_buffer.index( i ).to_string() );
      }
    }
  }

}
