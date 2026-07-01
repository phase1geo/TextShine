/*
* Copyright (c) 2020-2026 (https://github.com/phase1geo/TextShine)
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
  private GlobalSettings      _settings;

  public string user_label {
    get {
      return( _label );
    }
    set {
      _label = value;
    }
  }
  public int breakpoint {
    get {
      return( _breakpoint );
    }
    set {
      _breakpoint = (value < _functions.length) ? value : -1;
    }
  }
  public GlobalSettings global_settings {
    get {
      return( _settings );
    }
  }

  //-------------------------------------------------------------
  // Constructor
  public CustomFunction( GlobalSettings settings, bool custom = false ) {
    base( "custom-%d".printf( custom_id ), custom );
    _label      = "Custom #%d".printf( custom_id++ );
    _settings   = new GlobalSettings.copy( settings );
    _functions  = new Array<TextFunction>();
    _breakpoint = -1;
  }

  //-------------------------------------------------------------
  // Copy constructor
  public CustomFunction.copy_function( CustomFunction func ) {
    base( func.name, true );
    _label = func.user_label;
    _settings = new GlobalSettings.copy( func._settings );
    _functions = new Array<TextFunction>();
    for( int i=0; i<func.size(); i++ ) {
      _functions.append_val( func.get_function( i ).copy( true ) );
    }
  }

  //-------------------------------------------------------------
  // Creates a copy of this custom function and returns it to the
  // caller
  public override TextFunction copy( bool custom ) {
    return( new CustomFunction.copy_function( this ) );
  }

  protected override string get_label0() {
    return( _label );
  }

  //-------------------------------------------------------------
  // Returns the number of stored functions.
  public int size() {
    return( (int)_functions.length );
  }

  //-------------------------------------------------------------
  // Returns the function at the given index.
  public TextFunction get_function( int index ) {
    return( _functions.index( index ) );
  }

  //-------------------------------------------------------------
  // Adds the function at the given index.
  public void add_function( TextFunction function, int index = -1 ) {
    function.set_global_settings( _settings );
    if( index == -1 ) {
      _functions.append_val( function );
    } else {
      _functions.insert_val( index, function );
    }
  }

  //-------------------------------------------------------------
  // Deletes the function at the given index.
  public void delete_function( int index ) {
    _functions.remove_index( index );
  }

  //-------------------------------------------------------------
  // Moves the function from the given index to the new index.
  public void move_function( int old_index, int new_index ) {
    var fn = _functions.remove_index( old_index );
    _functions.insert_val( new_index, fn );
  }

  //-------------------------------------------------------------
  // Clears the contents of this function
  public void clear() {
    _functions.remove_range( 0, _functions.length );
  }

  //-------------------------------------------------------------
  // This is the main function which will be called from the UI
  // to perform the transformation action.  By default, we will
  // run the transformation one time, but the text function can
  // override this if it is providing a UI element that the user
  // needs to add input to prior to the transformation.
  public override void launch( Editor editor ) {
    var undo_item = new UndoItem( _label );
    for( int i=0; i<_functions.length; i++ ) {
      if( _functions.index( i ).launchable( editor ) ) {
        _functions.index( i ).run( editor, undo_item );
      }
    }
    editor.undo_buffer.add_item( undo_item );
  }

  //-------------------------------------------------------------
  // Plays the custom function until we have hit the breakpoint.
  public void test( Editor editor, UndoItem undo_item ) {
    var func_len = (_breakpoint == -1) ? _functions.length : (_breakpoint + 1);
    for( int i=0; i<func_len; i++ ) {
      if( _functions.index( i ).launchable( editor ) ) {
        _functions.index( i ).run( editor, undo_item );
      }
    }
  }

  //-------------------------------------------------------------
  // Returns true if settings are available
  public override bool settings_available() {
    return( false );
  }

  //-------------------------------------------------------------
  // Called to save this text function in XML format
  public override Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "custom" );
    node->set_prop( "name",  name );
    node->set_prop( "label", _label );
    node->set_prop( "description", description );
    node->add_child( _settings.save() );
    for( int i=0; i<_functions.length; i++ ) {
      node->add_child( _functions.index( i ).save() );
    }
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the contents of this text function
  public override void load( Xml.Node* node, TextFunctions functions, GlobalSettings settings ) {
    _label = node->get_prop( "label" );
    description = node->get_prop( "description" );
    for( Xml.Node* it=node->children; it!=null; it=it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        if( it->name == "function" ) {
          var function = functions.get_function_by_name( it->get_prop( "name" ) ).copy( true );
          function.load( it, functions, _settings );
          _functions.append_val( function );
        } else if( it->name == "settings" ) {
          _settings = new GlobalSettings.from_xml( it );
        }
      }
    }
  }

}

