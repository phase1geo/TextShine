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
  private int                 _insert_index;

  public Array<TextFunction> functions {
    get {
      return( _functions );
    }
  }

  /* Constructor */
  public CustomFunction() {
    base( "custom-%d".printf( custom_id ) );
    _label     = "Custom #%d".printf( custom_id++ );
    _functions = new Array<TextFunction>();
  }

  /* Creates a copy of this custom function and returns it to the caller */
  public override TextFunction copy() {
    var fn = new CustomFunction();
    fn._label = _label;
    for( int i=0; i<_functions.length; i++ ) {
      fn._functions.append_val( _functions.index( i ).copy() );
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
    var undo_item = new UndoItem( label );
    for( int i=0; i<_functions.length; i++ ) {
      _functions.index( i ).run( editor, undo_item );
    }
    editor.undo_buffer.add_item( undo_item );
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
        var function = functions.get_function_by_name( it->get_prop( "name" ) ).copy();
        function.load( it, functions );
        _functions.append_val( function );
      }
    }
  }

  /* Displays the edit UI for this custom action */
  public Popover show_ui( Widget? parent, CustomSaveFunc? save_func = null, CustomDeleteFunc? delete_func = null ) {

    var popover = new Popover( parent );
    var box = new Box( Orientation.VERTICAL, 5 );
    box.border_width = 5;
    box.set_size_request( 300, 600 );

    var lbox = new Box( Orientation.HORIZONTAL, 5 );
    var llbl = new Label( _( "Name:" ) );
    var le   = new Entry();

    lbox.pack_start( llbl, false, false, 0 );
    lbox.pack_start( le,   true, true,  0 );

    /* Create scrolled box */
    var abox = new Box( Orientation.VERTICAL, 5 );
    var asw  = new ScrolledWindow( null, null );
    var avp  = new Viewport( null, null );
    avp.set_size_request( 300, 600 );
    avp.add( abox );
    asw.add( avp );

    var bbox = new Box( Orientation.HORIZONTAL, 5 );

    var bdel = new Button.with_label( _( "Delete" ) );
    bdel.get_style_context().add_class( "destructive-action" );
    bdel.clicked.connect(() => {
      delete_func( this );
      popover.popdown();
    });
    var bcan = new Button.with_label( _( "Cancel" ) );
    bcan.clicked.connect(() => {
      popover.popdown();
    });
    var bsav = new Button.with_label( _( "Save" ) );
    bsav.get_style_context().add_class( "suggested-action" );
    bsav.clicked.connect(() => {
      _label = le.text;
      save_func( this );
      popover.popdown();
    });

    if( delete_func != null ) {
      bbox.pack_start( bdel, false, false, 0 );
    }
    if( save_func != null ) {
      bbox.pack_end( bsav, false, false, 0 );
      bbox.pack_end( bcan, false, false, 0 );
    } else {
      bcan.label = _( "Close" );
      bbox.pack_end( bcan, false, false, 0 );
    }

    box.pack_start( lbox, false, true, 0 );
    box.pack_start( asw,  true,  true, 0 );
    box.pack_start( bbox, false, true, 0 );

    /* Populate the UI */
    le.text = _label;
    for( int i=0; i<_functions.length; i++ ) {
      add_function( abox, i, functions.index( i ) );
    }

    popover.add( box );
    popover.modal = false;
    popover.show_all();

    return( popover );

  }

  private void add_function( Box box, int index, TextFunction function ) {

    var drag = new Image.from_icon_name( "format-justify-fill", IconSize.SMALL_TOOLBAR );
    var fbox = new Box( Orientation.HORIZONTAL, 5 );
    fbox.border_width = 5;

    var lbl = new Label( function.label );
    lbl.halign = Align.START;

    var del = new Button.from_icon_name( "list-remove-symbolic", IconSize.SMALL_TOOLBAR );
    del.set_relief( ReliefStyle.NONE );
    del.clicked.connect(() => {
      _functions.remove_index( index );
      Idle.add(() => {
        box.remove( fbox );
        return( Source.REMOVE );
      });
    });

    var add = new Button.from_icon_name( "list-add-symbolic", IconSize.SMALL_TOOLBAR );
    add.set_relief( ReliefStyle.NONE );
    add.clicked.connect(() => {
      _insert_index = index + 1;
    });

    fbox.pack_start( drag, false, false, 0 );
    fbox.pack_start( lbl,  false, true,  0 );
    fbox.pack_end(   del,  false, false, 0 );
    fbox.pack_end(   add,  false, false, 0 );

    box.pack_start( fbox, false, true, 0 );

  }

}

