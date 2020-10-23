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
using Gdk;
using Gee;

public class SidebarCustom : SidebarBox {

  private Array<Functions> _functions;
  private Entry            _name;
  private SearchEntry      _search;
  private CustomFunction?  _custom;
  private Popover          _popover;
  private Revealer         _delete_reveal;
  private Button           _save;
  private Label            _new_action_label;
  private Box              _cbox;
  private Box              _pbox;
  private int              _insert_index;

  /* Constructor */
  public SidebarCustom( MainWindow win, Editor editor ) {

    base( win, editor );

    _functions = new Array<Functions>();

    var nlbl = new Label( _( "Name:" ) );

    _name = new Entry();

    var add = new Button.from_icon_name( "list-add-symbolic", IconSize.SMALL_TOOLBAR );
    add.tooltip_text = _( "Add new function" );
    add.clicked.connect(() => {
      insert_new_action( -1 );
    });

    var nbox = new Box( Orientation.HORIZONTAL, 0 );
    nbox.pack_start( nlbl, false, false, 5 );
    nbox.pack_start( _name, true, true, 5 );
    nbox.pack_end( add, false, false, 5 );

    /* Create scrolled box */
    _cbox  = new Box( Orientation.VERTICAL, 0 );
    var sw = new ScrolledWindow( null, null );
    var vp = new Viewport( null, null );
    vp.set_size_request( 300, 600 );
    vp.add( _cbox );
    sw.add( vp );

    var del = new Button.with_label( _( "Delete" ) );
    del.get_style_context().add_class( "destructive-action" );
    del.clicked.connect( delete_custom );

    var cancel = new Button.with_label( _( "Cancel" ) );
    cancel.clicked.connect(() => {
      switch_stack( SwitchStackReason.NONE, null );
    });

    _save = new Button.with_label( _( "Save" ) );
    _save.get_style_context().add_class( "suggested-action" );
    _save.clicked.connect( save_custom );

    _delete_reveal = new Revealer();
    _delete_reveal.reveal_child    = true;
    _delete_reveal.transition_type = RevealerTransitionType.NONE;
    _delete_reveal.add( del );

    var bbox = new Box( Orientation.HORIZONTAL, 0 );
    bbox.pack_start( _delete_reveal, false, false, 5 );
    bbox.pack_end(   _save,          false, false, 5 );
    bbox.pack_end(   cancel,         false, false, 5 );

    pack_start( nbox, false, true, 5 );
    pack_start( sw,   true,  true, 5 );
    pack_start( bbox, false, true, 5 );

    /* Create the action insertion popover */
    create_popover();

  }

  /* Called when we get displayed */
  public override void displayed( SwitchStackReason reason, TextFunction? function ) {

    switch( reason ) {
      case SwitchStackReason.NEW :
        _custom = new CustomFunction();
        _delete_reveal.reveal_child = false;
        break;
      case SwitchStackReason.EDIT :
        _custom = (CustomFunction)function;
        _delete_reveal.reveal_child = true;
        insert_actions();
        break;
    }

  }

  /* Inserts the current custom actions */
  private void insert_actions() {
    for( int i=0; i<_custom.functions.length; i++ ) {
      add_function( _custom.functions.index( i ) );
    }
  }

  /* Adds a function button to the given category item box */
  public Box add_function( TextFunction function ) {

    var fbox = new Box( Orientation.HORIZONTAL, 5 );

    var button = new Button.with_label( function.label );
    button.halign = Align.START;
    button.set_relief( ReliefStyle.NONE );
    button.clicked.connect(() => {
      editor.grab_focus();
      if( function.launchable( editor ) ) {
        win.show_widget( "" );
        function.launch( editor );
        action_applied( function );
      }
    });

    var grid = new Grid();
    add_direction_button( grid, button, function );
    add_settings_button(  grid, function );

    fbox.pack_start( button, false, true,  0 );
    fbox.pack_end(   grid,   false, false, 0 );

    _cbox.pack_start( fbox, false, false, 0 );

    function.update_button_label.connect(() => {
      button.label = function.label;
    });

    return( fbox );

  }

  /* Inserts the new action label in the given position */
  private void insert_new_action( int index ) {
    var num_funcs = (int)_custom.functions.length;
    _insert_index = (index == -1) ? num_funcs : index;
    _cbox.pack_start( _new_action_label, false, true, 5 );
    if( num_funcs != index ) {
      _cbox.reorder_child( _new_action_label, index );
    }
    _cbox.show_all();
    _popover.popup();
  }

  /*
   Inserts the given text function into the custom function at the previously
   calculated insert index.  Updates the internal custom function contents.
  */
  private void insert_function( TextFunction function ) {
    var fbox = add_function( function );
    _cbox.reorder_child( fbox, _insert_index );
    _cbox.show_all();
    _custom.functions.insert_val( _insert_index, function );
  }

  /* Saves a new custom action set */
  /*
  private void save_new_custom( CustomFunction function ) {
    var fn = function.copy();
    add_custom_function( (CustomFunction)fn );
    win.functions.add_function( "custom", fn );
    win.functions.save_custom();
    _custom = null;
  }
  */

  //----------------------------------------------------------------------------
  //  POPOVER
  //----------------------------------------------------------------------------

  private void create_popover() {

    _functions = new Array<Functions>();

    _new_action_label = new Label( _( "Select Action..." ) );
    _new_action_label.halign = Align.START;

    /* Create search box */
    _search = new SearchEntry();
    _search.placeholder_text = _( "Search Actions" );
    _search.search_changed.connect( search_functions );

    /* Create scrolled box */
    _pbox = new Box( Orientation.VERTICAL, 0 );
    var sw   = new ScrolledWindow( null, null );
    var vp   = new Viewport( null, null );
    vp.set_size_request( 300, 600 );
    vp.add( _pbox );
    sw.add( vp );

    var box = new Box( Orientation.VERTICAL, 0 );
    box.set_size_request( 300, 500 );
    box.pack_start( _search, false, true, 5 );
    box.pack_start( sw,      true,  true, 5 );

    box.show_all();

    _popover = new Popover( null );
    _popover.modal = true;
    _popover.relative_to = _new_action_label;
    _popover.position    = PositionType.LEFT;
    _popover.add( box );
    _popover.realize.connect( popover_opened );
    _popover.closed.connect( popover_closed );

  }

  private void popover_opened() {

    /* Clear the contents */
    _pbox.get_children().foreach((w) => {
      _pbox.remove( w );
    });

    /* Insert the new elements */
    var functions = win.functions.functions;
    for( int i=0; i<functions.length; i++ ) {
      add_popup_function( functions.index( i ) );
    }

    _pbox.show_all();

  }

  private void popover_closed() {
    _cbox.remove( _new_action_label );
  }

  /* Performs search of all text functions, displaying only those functions which match the search text */
  private void search_functions() {

    var value = _search.text.down();
    var empty = (value == "");

    for( int i=0; i<_functions.length; i++ ) {
      _functions.index( i ).reveal( value );
    }

  }

  /* Adds a function button to the popup box */
  public void add_popup_function( TextFunction function ) {

    var label = win.functions.get_category_label_for_function( function ) + " - " + function.label;

    var button = new Button.with_label( label );
    button.halign = Align.START;
    button.set_relief( ReliefStyle.NONE );
    button.clicked.connect(() => {
      insert_function( function );
      _popover.popdown();
    });

    var reveal = new Revealer();
    reveal.reveal_child = true;
    reveal.add( button );

    _pbox.pack_start( reveal, false, true, 0 );

    /* Add the function so that we can hide it while searching */
    _functions.append_val( new Functions( function, reveal ) );

  }

  /* Creates the direction button (if necessary) and adds it to the given box */
  private void add_direction_button( Grid grid, Button btn, TextFunction function ) {

    if( function.direction == FunctionDirection.NONE ) return;

    var icon_name = "media-playlist-repeat-symbolic";
    var tooltip   = function.direction.is_vertical() ? _( "Switch Direction" ) : _( "Swap Order" );

    var direction = new Button.from_icon_name( icon_name, IconSize.SMALL_TOOLBAR );
    direction.halign = Align.START;
    direction.relief = ReliefStyle.NONE;
    direction.set_tooltip_text( tooltip );
    direction.clicked.connect(() => {
      switch( function.direction ) {
        case FunctionDirection.TOP_DOWN :
          function.direction = FunctionDirection.BOTTOM_UP;
          win.functions.save_functions();
          break;
        case FunctionDirection.BOTTOM_UP :
          function.direction = FunctionDirection.TOP_DOWN;
          win.functions.save_functions();
          break;
        case FunctionDirection.LEFT_TO_RIGHT :
          function.direction = FunctionDirection.RIGHT_TO_LEFT;
          win.functions.save_functions();
          break;
        case FunctionDirection.RIGHT_TO_LEFT :
          function.direction = FunctionDirection.LEFT_TO_RIGHT;
          win.functions.save_functions();
          break;
      }
      btn.label = function.label;
    });

    grid.attach( direction, 1, 0 );

  }

  /* Adds the settings button to the text function */
  private void add_settings_button( Grid grid, TextFunction function ) {

    if( !function.settings_available() ) return;

    var settings = new MenuButton();
    settings.image   = new Image.from_icon_name( "open-menu-symbolic", IconSize.SMALL_TOOLBAR );
    settings.relief  = ReliefStyle.NONE;
    settings.popover = new Popover( null );
    settings.set_tooltip_text( _( "Settings" ) );

    settings.popover.show.connect(() => {
      on_settings_show( settings.popover, function );
    });

    grid.attach( settings, 0, 0 );

  }

  private void on_settings_show( Popover popover, TextFunction function ) {

    var child = popover.get_child();
    if( child != null ) {
      popover.remove( child );
    }

    var grid = new Grid();
    grid.border_width   = 5;
    grid.row_spacing    = 5;
    grid.column_spacing = 5;
    grid.column_homogeneous = false;

    function.add_settings( grid );
    grid.show_all();

    popover.add( grid );

  }

  private void save_custom() {
    // _custom
    win.functions.save_custom();
    switch_stack( SwitchStackReason.ADD, _custom );
  }

  private void delete_custom() {
    // _custom
    win.functions.save_custom();
    switch_stack( SwitchStackReason.DELETE, null );
  }

}

