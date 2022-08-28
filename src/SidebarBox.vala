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

public class SidebarBox : Box {

  protected MainWindow win;
  protected Editor     editor;
  protected const int  width  = 380;
  protected const int  height = 600;

  public signal void action_applied( TextFunction function );
  public signal void switch_stack( SwitchStackReason reason, TextFunction? function );

  /* Constructor */
  public SidebarBox( MainWindow win, Editor editor ) {

    Object( orientation: Orientation.VERTICAL, spacing: 0 );

    set_size_request( width, height );

    this.win    = win;
    this.editor = editor;

  }

  /* Called by sidebar when the stack switches to display this element */
  public virtual void displayed( SwitchStackReason reason, TextFunction? function ) {}

}

