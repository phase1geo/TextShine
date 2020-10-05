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

public class CustomFunction : TextFunction {

  private Array<TextFunction> _functions;
  private string              _label;

  public Array<TextFunction> functions {
    get {
      return( _functions );
    }
  }

  /* Constructor */
  public CustomFunction( string name, string label ) {
    base( name );
    _label     = label;
    _functions = new Array<TextFunction>();
  }

  protected override string get_label0() {
    return( _label );
  }

  /*
   This is the main function which will be called from the UI to perform the
   transformation action.  By default, we will run the transformation one time,
   but the text function can override this if it is providing a UI element
   that the user needs to add input to prior to the transformation.
  */
  public override void launch( Editor editor ) {
    for( int i=0; i<_functions.length; i++ ) {
      _functions.index( i ).run( editor );
    }
  }

  /* Returns true if settings are available */
  public override bool settings_available() {
    return( false );
  }

  /* Called to save this text function in XML format */
  public override Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "custom" );
    node->set_prop( "name",  name );
    node->set_prop( "label", _label );
    for( int i=0; i<_functions.length; i++ ) {
      node->add_child( _functions.index( i ).save() );
    }
    return( node );
  }

  /* Loads the contents of this text function */
  public override void load( Xml.Node* node, TextFunctions functions ) {
    for( Xml.Node* it=node->children; it!=null; it=it->next ) {
      if( (it->type == Xml.Node.ELEMENT_NODE) && (it->name == "function") ) {
        var function = functions.get_function_by_name( it->get_prop( "name" ) ).copy();
        function.load( it, functions );
        _functions.append_val( function );
      }
    }
  }

}

