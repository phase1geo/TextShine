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

using Gee;

public class RemoveLeadingWhitespace : TextFunction {

  public RemoveLeadingWhitespace() {
    base( "remove-leading-whitespace" );
  }

  protected override string get_label0() {
    return( _( "Remove Leading Whitespace" ) );
  }

  public override TextFunction copy() {
    return( new RemoveLeadingWhitespace() );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    string[] lines = {};
    foreach( string line in original.split( "\n" ) ) {
      lines += line.chug();
    }
    return( string.joinv( "\n", lines ) );
  }

}
