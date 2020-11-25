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

using Gdk;

public class ConvertROT13 : TextFunction {

  /* Constructor */
  public ConvertROT13( bool custom = false ) {
    base( "convert-rot13", custom );
  }

  protected override string get_label0() {
    return( _( "ROT 13" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new ConvertROT13( custom ) );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    var str = "";
    for( int i=0; i<original.char_count(); i++ ) {
      var ch = original.get_char( original.index_of_nth_char( i ) );
      if( ch.isalpha() ) {
        var offset = ch.islower() ? Key.a : Key.A;
        ch = (((ch - offset) + 13) % 26) + offset;
      }
      str += ch.to_string();
    }
    return( str );
  }

}
