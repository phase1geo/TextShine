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

public class ReplaceReturnSpace : TextFunction {

  /* Constructor */
  public ReplaceReturnSpace() {
    base( "replace-return-space", FunctionDirection.LEFT_TO_RIGHT );
  }

  protected override string get_label0() {
    return( _( "Return With Space" ) );
  }

  protected override string get_label1() {
    return( _( "Space With Return" ) );
  }

  public override TextFunction copy() {
    var fn = new ReplaceReturnSpace();
    fn.direction = direction;
    return( fn );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    if( direction == FunctionDirection.LEFT_TO_RIGHT ) {
      return( original.replace( "\n", " " ) );
    } else {
      return( original.replace( " ", "\n" ) );
    }
  }

}
