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

using Xml;

public class IndentXML : TextFunction {

  /* Constructor */
  public IndentXML() {
    base( "indent-xml", _( "Indent XML" ) );
  }

  /* Perform the transformation */
  public override string transform_text( string original ) {
    var doc = Xml.Parser.read_memory( original, original.length );
    var len = 0;
    var str = "";
    if( doc == null ) {
      return( original );
    }
    doc->dump_memory_format( out str, out len, true );
    delete doc;
    return( str );
  }

}
