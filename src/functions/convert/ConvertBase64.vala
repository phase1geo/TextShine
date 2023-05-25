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

public class ConvertBase64 : TextFunction {

  /* Constructor */
  public ConvertBase64( bool custom = false ) {
    base( "convert-base64", custom, FunctionDirection.LEFT_TO_RIGHT );
  }

  public override string get_description() {
    return( _( "Encodes/Decodes the text to/from base64 encoded format." ) );
  }

  protected override string get_label0() {
    return( _( "Encode To Base64" ) );
  }

  protected override string get_label1() {
    return( _( "Decode From Base64" ) );
  }

  public override TextFunction copy( bool custom ) {
    var fn = new ConvertBase64( custom );
    fn.direction = direction;
    return( fn );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    string str;
    if( direction == FunctionDirection.LEFT_TO_RIGHT ) {
      str = Base64.encode( (uchar[])original.data );
    } else {
      str = (string)Base64.decode( original );
    }
    return( str.validate() ? str : original );
  }

}
