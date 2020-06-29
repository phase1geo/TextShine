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

public class MainWindow : ApplicationWindow {

  Editor _editor;
  
  /* Constructor */
  public MainWindow() {
    
    var box = new Box( Orientation.HORIZONTAL, 0 );
    
    /* Create editor */
    _editor = new Editor( this );
    
    /* Create sidebar */
    var sidebar = create_sidebar();
    
    box.pack_start( _editor, true,  true,  5 );
    box.pack_start( sidebar, false, false, 5 );
    
    add( box );
    show_all();
    
  }
  
  /* Create list of transformation buttons */
  private Box create_sidebar() {
    
    var box = new Box( Orientation.VERTICAL, 0 );
    
    return( box );
    
  }
  
}
