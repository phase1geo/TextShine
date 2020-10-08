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

public class Functions {
  private TextFunction _func;
  private Revealer     _revealer;
  private Expander     _exp;
  public TextFunction func {
    get {
      return( _func );
    }
  }
  public Functions( TextFunction func, Revealer revealer, Expander exp ) {
    _func     = func;
    _revealer = revealer;
    _exp      = exp;
  }
  public void reveal( string value ) {
    var contains = _func.label.down().contains( value );
    _revealer.reveal_child = contains;
    if( contains ) {
      _exp.expanded = true;
    }
  }
}

public class Category {
  private string   _name;
  private Expander _exp;
  public Category( string name, Expander exp ) {
    _name = name;
    _exp  = exp;
  }
  public void show( bool value ) {
    _exp.expanded = value ? TextShine.settings.get_boolean( _name ) : false;
  }
}

public class Sidebar {

  private MainWindow          _win;
  private Editor              _editor;
  private Array<Functions>    _functions;
  private Array<Category>     _categories;
  private Array<TextChange>   _undo;
  private Array<TextChange>   _redo;
  private Button              _record;
  private SearchEntry         _search;
  private Box                 _box;
  private Box                 _favorite_box;
  private Box                 _custom_box;
  private CustomFunction?     _custom;

  public signal void action_applied( TextFunction function );

  /* Constructor */
  public Sidebar( MainWindow win, Editor editor, Box box ) {

    _win        = win;
    _editor     = editor;
    _functions  = new Array<Functions>();
    _categories = new Array<Category>();
    _undo       = new Array<TextChange>();
    _redo       = new Array<TextChange>();

    box.set_size_request( 300, 600 );

    /* Create custom recording button */
    _record = new Button.from_icon_name( "media-record", IconSize.LARGE_TOOLBAR );
    _record.set_relief( ReliefStyle.NONE );
    _record.set_tooltip_markup( Utils.tooltip_with_accel( _( "Record Custom Action" ), "<Control>r" ) );
    _record.clicked.connect( toggle_record );

    /* Create search box */
    _search = new SearchEntry();
    _search.placeholder_text = _( "Search Actions" );
    _search.search_changed.connect( search_functions );

    var sbox = new Box( Orientation.HORIZONTAL, 5 );
    sbox.pack_start( _record, false, false, 0 );
    sbox.pack_start( _search, true,  true,  0 );

    /* Create scrolled box */
    var cbox = new Box( Orientation.VERTICAL, 0 );
    var sw   = new ScrolledWindow( null, null );
    var vp   = new Viewport( null, null );
    vp.set_size_request( 300, 600 );
    vp.add( cbox );
    sw.add( vp );

    /* Add widgets to box */
    cbox.pack_start( create_category( "favorites",      _( "Favorites" ) ),          false, false, 5 );
    cbox.pack_start( create_category( "case",           _( "Change Case" ) ),        false, false, 5 );
    cbox.pack_start( create_category( "remove",         _( "Remove" ) ),             false, false, 5 );
    cbox.pack_start( create_category( "replace",        _( "Replace" ) ),            false, false, 5 );
    cbox.pack_start( create_category( "sort",           _( "Sort" ) ),               false, false, 5 );
    cbox.pack_start( create_category( "indent",         _( "Indentation" ) ),        false, false, 5 );
    cbox.pack_start( create_category( "search-replace", _( "Search and Replace" ) ), false, false, 5 );
    cbox.pack_start( create_category( "custom",         _( "Custom" ) ),             false, false, 5 );

    box.pack_start( sbox, false, true, 10 );
    box.pack_start( sw,   true,  true, 10 );

    _box = box;

  }

  /* Toggles the record status */
  private void toggle_record() {
    if( _custom != null ) {
      _record.image    = new Image.from_icon_name( "media-record", IconSize.LARGE_TOOLBAR );
      if( _custom.functions.length > 0 ) {
        var popover      = _custom.show_ui( _record, save_new_custom );
        popover.position = PositionType.LEFT;
      }
    } else {
      _record.image = new Image.from_icon_name( "media-playback-stop", IconSize.LARGE_TOOLBAR );
      _custom       = new CustomFunction();
    }
  }

  /* Saves a new custom action set */
  private void save_new_custom( CustomFunction function ) {
    var fn = function.copy();
    add_custom_function( (CustomFunction)fn );
    _win.functions.add_function( "custom", fn );
    _win.functions.save_custom();
    _custom = null;
  }

  /* Performs search of all text functions, displaying only those functions which match the search text */
  private void search_functions() {

    var value = _search.text.down();
    var empty = (value == "");

    for( int i=0; i<_categories.length; i++ ) {
      _categories.index( i ).show( empty );
    }

    for( int i=0; i<_functions.length; i++ ) {
      _functions.index( i ).reveal( value );
    }

  }

  /* Creates category returning expander and item box */
  private Expander create_category( string name, string label ) {

    var setting = "category-" + name + "-expanded";

    /* Create expander */
    var exp = new Expander( "  " + Utils.make_title( label ) );
    exp.use_markup = true;
    exp.expanded   = TextShine.settings.get_boolean( setting );
    exp.activate.connect(() => {
      TextShine.settings.set_boolean( setting, !exp.expanded );
    });

    var item_box = new Box( Orientation.VERTICAL, 0 );
    item_box.border_width = 10;

    exp.add( item_box );

    /* Populate item_box with functions */
    var functions = _win.functions.get_category_functions( name );
    for( int i=0; i<functions.length; i++ ) {
      add_function( name, item_box, exp, functions.index( i ) );
    }

    _categories.append_val( new Category( setting, exp ) );

    switch( name ) {
      case "favorites" :  _favorite_box = item_box;  break;
      case "custom"    :  _custom_box   = item_box;  break;
    }

    return( exp );

  }

  /* Adds a function button to the given category item box */
  public void add_function( string category, Box box, Expander? exp, TextFunction function ) {

    var fbox = new Box( Orientation.HORIZONTAL, 5 );

    var button = new Button.with_label( function.label );
    button.halign = Align.START;
    button.set_relief( ReliefStyle.NONE );
    button.clicked.connect(() => {
      _win.show_widget( "" );
      _editor.grab_focus();
      function.launch( _editor );
      _undo.append_val( function.get_change() );
      action_applied( function );
    });

    var grid = new Grid();
    add_favorite_button(  grid, function );

    switch( category ) {
      case "favorites" :  break;
      case "custom"    :
        add_edit_button( fbox, grid, function );
        break;
      default          :
        add_direction_button( grid, button, function );
        add_settings_button(  grid, function );
        break;
    }

    fbox.pack_start( button, false, true,  0 );
    fbox.pack_end(   grid,   false, false, 0 );

    var revealer = new Revealer();
    revealer.add( fbox );
    revealer.border_width = 5;
    revealer.reveal_child = true;

    box.pack_start( revealer, false, false, 0 );

    if( exp != null ) {
      _functions.append_val( new Functions( function, revealer, exp ) );
      function.update_button_label.connect(() => {
        button.label = function.label;
      });
    }

  }

  /* Creates the direction button (if necessary) and adds it to the given box */
  private void add_direction_button( Grid grid, Button btn, TextFunction function ) {

    if( function.direction == FunctionDirection.NONE ) return;

    var icon_name = function.direction.is_vertical() ? "object-flip-vertical-symbolic" : "media-playlist-repeat-symbolic";
    var tooltip   = function.direction.is_vertical() ? _( "Switch Direction" ) : _( "Swap Order" );

    var direction = new Button.from_icon_name( icon_name, IconSize.SMALL_TOOLBAR );
    direction.halign = Align.START;
    direction.relief = ReliefStyle.NONE;
    direction.set_tooltip_text( tooltip );
    direction.clicked.connect(() => {
      switch( function.direction ) {
        case FunctionDirection.TOP_DOWN :
          function.direction = FunctionDirection.BOTTOM_UP;
          break;
        case FunctionDirection.BOTTOM_UP :
          function.direction = FunctionDirection.TOP_DOWN;
          break;
        case FunctionDirection.LEFT_TO_RIGHT :
          function.direction = FunctionDirection.RIGHT_TO_LEFT;
          break;
        case FunctionDirection.RIGHT_TO_LEFT :
          function.direction = FunctionDirection.LEFT_TO_RIGHT;
          break;
      }
      btn.label = function.label;
    });

    grid.attach( direction, 1, 0 );

  }

  private bool is_favorite( TextFunction function ) {
    var functions = _win.functions.get_category_functions( "favorites" );
    for( int i=0; i<functions.length; i++ ) {
      if( functions.index( i ) == function ) {
        return( true );
      }
    }
    return( false );
  }

  private void add_favorite_button( Grid grid, TextFunction function ) {

    var favorited = is_favorite( function );
    var icon_name = favorited ? "starred-symbolic" : "non-starred-symbolic";
    var tooltip   = favorited ? _( "Unfavorite" )  : _( "Favorite" );

    var favorite = new Button.from_icon_name( icon_name, IconSize.SMALL_TOOLBAR );
    favorite.relief = ReliefStyle.NONE;
    favorite.set_tooltip_text( tooltip );
    favorite.clicked.connect(() => {
      toggle_favorite( favorite, function );
    });

    grid.attach( favorite, 2, 0 );

  }

  /* Toggles the favorite status */
  private void toggle_favorite( Button button, TextFunction function ) {

    if( is_favorite( function ) ) {
      unfavorite_function( function );
      button.image = new Image.from_icon_name( "non-starred-symbolic", IconSize.SMALL_TOOLBAR );
      button.set_tooltip_text( _( "Favorite" ) );
    } else {
      favorite_function( function.copy() );
      button.image = new Image.from_icon_name( "starred-symbolic", IconSize.SMALL_TOOLBAR );
      button.set_tooltip_text( _( "Unfavorite" ) );
    }

  }

  /* Add the given function to the favorite list */
  private void favorite_function( TextFunction function ) {

    var fn = function.copy();

    /* Mark the function as a favorite */
    _win.functions.favorite_function( fn );

    add_function( "favorites", _favorite_box, null, fn );
    _favorite_box.show_all();

  }

  /* Removes the given function from the favorite list */
  private void unfavorite_function( TextFunction function ) {

    /* Remove the function as a favorite */
    var index  = _win.functions.unfavorite_function( function );
    var reveal = (Revealer)_favorite_box.get_children().nth_data( index );

    /* Wait until idle to remove the widget so that we avoid an error */
    Idle.add(() => {
      _favorite_box.remove( reveal );
      return( Source.REMOVE );
    });

  }

  public void add_custom_function( CustomFunction function ) {
    add_function( "custom", _custom_box, null, function );
    _custom_box.show_all();
  }

  public void delete_custom_function( CustomFunction function ) {
    // FOOBAR
  }

  /* Adds the settings button to the text function */
  private void add_settings_button( Grid grid, TextFunction function ) {

    if( !function.settings_available() ) return;

    var settings = new MenuButton();
    settings.image  = new Image.from_icon_name( "open-menu-symbolic", IconSize.SMALL_TOOLBAR );
    settings.relief = ReliefStyle.NONE;
    settings.popover   = new Popover( null );
    settings.set_tooltip_text( _( "Settings" ) );

    var box = new Box( Orientation.VERTICAL, 0 );

    function.add_settings( box, 5 );

    settings.popover.add( box );
    box.show_all();

    grid.attach( settings, 0, 0 );

  }

  /* Adds the edit button to the custom function */
  private void add_edit_button( Box fbox, Grid grid, TextFunction function ) {

    var edit = new Button.from_icon_name( "edit-symbolic", IconSize.SMALL_TOOLBAR );
    edit.relief = ReliefStyle.NONE;
    edit.set_tooltip_text( _( "Edit Action" ) );
    edit.clicked.connect(() => {
      var popover = (function as CustomFunction).show_ui( fbox, save_existing_custom, delete_custom );
      popover.position = PositionType.LEFT;
    });

    grid.attach( edit, 0, 0 );

  }

  private void save_existing_custom( CustomFunction function ) {
    // TBD
    _win.functions.save_custom();
  }

  private void delete_custom( CustomFunction function ) {
    // TBD
    _win.functions.save_custom();
  }

  /* Returns true if we can be undone */
  public bool undoable() {
    return( _undo.length > 0 );
  }

  /* Returns true if we can be redone */
  public bool redoable() {
    return( _redo.length > 0 );
  }

  /* Undoes the last change */
  public void undo() {
    if( undoable() ) {
      var change = _undo.index( _undo.length - 1 );
      _undo.remove_index( _undo.length - 1 );
      _redo.append_val( change );
    }
  }

  /* Redoes the last undone change */
  public void redo() {
    if( redoable() ) {
      var change = _redo.index( _undo.length - 1 );
      _redo.remove_index( _redo.length - 1 );
      _undo.append_val( change );
    }
  }

}

