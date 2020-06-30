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

public class TextChange {

  private TextFunction _function;

  public string label {
    get {
      return( _function.label );
    }
  }

  /* Constructor */
  public TextChange( TextFunction function ) {
    _function = function;
  }

  /* Called to save this text function */
  public Xml.Node* save() {
    Xml.Node* n = new Xml.Node( null, "function" );
    n->set_prop( "name",      _function.name );
    n->set_prop( "direction", _function.direction.to_string() );
    save_contents( n );
    return( n );
  }

  /* Loads the contents of this Xml node */
  public void load( Xml.Node* n ) {
    load_contents( n );
  }

  /* Loads the contents of this node */
  protected virtual void save_contents( Xml.Node* n ) {}

  /* Saves the contents of this node */
  protected virtual void load_contents( Xml.Node* n ) {}

}

