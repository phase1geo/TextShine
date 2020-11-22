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

public delegate void CustomDeleteFunc( CustomFunction function );
public delegate void CustomSaveFunc( CustomFunction function );

public class CustomFunction : TextFunction {

  private static int custom_id = 1;

  private Array<TextFunction> _functions;
  private string              _label;
  private int                 _breakpoint;

  public Array<TextFunction> functions {
    get {
      return( _functions );
    }
  }
  public string label {
    get {
      return( _label );
    }
    set {
      _label = value;
    }
  }

  /* Constructor */
  public CustomFunction( bool custom = false ) {
    base( "custom-%d".printf( custom_id ), custom );
    _label      = "Custom #%d".printf( custom_id++ );
    _functions  = new Array<TextFunction>();
    _breakpoint = -1;
  }

  /* Creates a copy of this custom function and returns it to the caller */
  public override TextFunction copy( bool custom ) {
    var fn = new CustomFunction( custom );
    fn._label = _label;
    for( int i=0; i<_functions.length; i++ ) {
      fn._functions.append_val( _functions.index( i ).copy( true ) );
    }
    return( fn );
  }

  protected override string get_label0() {
    return( _label );
  }

  /* Clears the contents of this function */
  public void clear() {
    _functions.remove_range( 0, _functions.length );
  }

  /*
   This is the main function which will be called from the UI to perform the
   transformation action.  By default, we will run the transformation one time,
   but the text function can override this if it is providing a UI element
   that the user needs to add input to prior to the transformation.
  */
  public override void launch( Editor editor ) {
    var undo_item = new UndoItem( _label );
    for( int i=0; i<_functions.length; i++ ) {
      _functions.index( i ).run( editor, undo_item );
    }
    editor.undo_buffer.add_item( undo_item );
  }

  /*
   Plays the custom function until we have hit the breakpoint.
  */
  public void test( Editor editor, UndoItem undo_item ) {
    var func_len = (_breakpoint == -1) ? _functions.length : _breakpoint;
    for( int i=0; i<func_len; i++ ) {
      _functions.index( i ).run( editor, undo_item );
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
    _label = node->get_prop( "label" );
    for( Xml.Node* it=node->children; it!=null; it=it->next ) {
      if( (it->type == Xml.Node.ELEMENT_NODE) && (it->name == "function") ) {
        var function = functions.get_function_by_name( it->get_prop( "name" ) ).copy( true );
        function.load( it, functions );
        _functions.append_val( function );
      }
    }
  }

}

