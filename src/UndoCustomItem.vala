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
using Gtk;

public class UndoCustomItem : GLib.Object {
  private string _name;
  public string name {
    get {
      return( _name );
    }
  }
  public UndoCustomItem( string name) {
    _name = name;
  }
  public virtual void undo( SidebarCustom sidebar ) {}
  public virtual void redo( SidebarCustom sidebar ) {}
}

public class UndoCustomAddItem : UndoCustomItem {
  private TextFunction _function;
  private int          _index;
  public UndoCustomAddItem( TextFunction function, int index ) {
    base( _( "Action Add" ) );
    _function = function;
    _index    = index;
  }
  public override void undo( SidebarCustom sidebar ) {
    sidebar.delete_function( _index );
  }
  public override void redo( SidebarCustom sidebar ) {
    sidebar.insert_function( _function, _index );
  }
}

public class UndoCustomDeleteItem : UndoCustomItem {
  private TextFunction _function;
  private int          _index;
  public UndoCustomDeleteItem( TextFunction function, int index ) {
    base( _( "Action Remove" ) );
    _function = function;
    _index    = index;
  }
  public override void undo( SidebarCustom sidebar ) {
    sidebar.insert_function( _function, _index );
  }
  public override void redo( SidebarCustom sidebar ) {
    sidebar.delete_function( _index );
  }
}

public class UndoCustomMoveItem : UndoCustomItem {
  private int _old_index;
  private int _new_index;
  public UndoCustomMoveItem( int old_index, int new_index ) {
    base( _( "Action Move" ) );
    _old_index = old_index;
    _new_index = new_index;
  }
  public override void undo( SidebarCustom sidebar ) {
    sidebar.move_function( _new_index, _old_index );
  }
  public override void redo( SidebarCustom sidebar ) {
    sidebar.move_function( _old_index, _new_index );
  }
}

