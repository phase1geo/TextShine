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

public class UndoCustomBuffer : Object {

  protected SidebarCustom         _sidebar;
  protected Array<UndoCustomItem> _undo_buffer;
  protected Array<UndoCustomItem> _redo_buffer;

  public signal void buffer_changed( UndoCustomBuffer buf );

  /* Default constructor */
  public UndoCustomBuffer( SidebarCustom sidebar ) {
    _sidebar     = sidebar;
    _undo_buffer = new Array<UndoCustomItem>();
    _redo_buffer = new Array<UndoCustomItem>();
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
      UndoCustomItem item = _undo_buffer.index( _undo_buffer.length - 1 );
      item.undo( _sidebar );
      _undo_buffer.remove_index( _undo_buffer.length - 1 );
      _redo_buffer.append_val( item );
      buffer_changed( this );
    }
  }

  /* Performs the next redo action in the buffer */
  public virtual void redo() {
    if( redoable() ) {
      UndoCustomItem item = _redo_buffer.index( _redo_buffer.length - 1 );
      item.redo( _sidebar );
      _redo_buffer.remove_index( _redo_buffer.length - 1 );
      _undo_buffer.append_val( item );
      buffer_changed( this );
    }
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
  public void add_item( UndoCustomItem item ) {
    _undo_buffer.append_val( item );
    _redo_buffer.remove_range( 0, _redo_buffer.length );
    buffer_changed( this );
  }

}
