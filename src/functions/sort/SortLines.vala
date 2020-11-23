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

public class SortLines : TextFunction {

  /* Constructor */
  public SortLines( bool custom = false ) {
    base( "sort-lines", custom, FunctionDirection.TOP_DOWN );
  }

  protected override string get_label0() {
    return( _( "Sort Lines" ) );
  }

  protected override string get_label1() {
    return( _( "Sort Lines Reversed" ) );
  }

  public override TextFunction copy( bool custom ) {
    var fn = new SortLines( custom );
    fn.direction = direction;
    return( fn );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    var list  = new List<string>();
    var lines = "";
    foreach( string str in original.split( "\n" ) ) {
      list.append( str );
    }
    list.sort( strcmp );
    if( direction == FunctionDirection.BOTTOM_UP ) {
      list.reverse();
    }
    list.foreach( (item) => {
      lines += item + "\n";
    });
    return( lines.chomp() );
  }

}
