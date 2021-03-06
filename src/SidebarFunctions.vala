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

public class Category {
  private string   _name;
  private Expander _exp;
  private Revealer _rev;
  public Category( string name, Expander exp, Revealer rev ) {
    _name = name;
    _exp  = exp;
    _rev  = rev;
  }
  public void show( bool value ) {
    _exp.expanded = value ? TextShine.settings.get_boolean( _name ) : false;
  }
  public void hide() {
    _rev.reveal_child = _exp.expanded;
  }
}

public class SidebarFunctions : SidebarBox {

  private Array<Functions> _functions;
  private Array<Category>  _categories;
  private SearchEntry      _search;
  private Box              _favorite_box;
  private Box              _custom_box;
  private Revealer         _custom_revealer;
  private Box              _edit_fbox;

  /* Constructor */
  public SidebarFunctions( MainWindow win, Editor editor ) {

    base( win, editor );

    _functions  = new Array<Functions>();
    _categories = new Array<Category>();

    /* Create search box */
    _search = new SearchEntry();
    _search.placeholder_text = _( "Search Actions" );
    _search.search_changed.connect( search_functions );

    var sbox = new Box( Orientation.HORIZONTAL, 5 );
    sbox.pack_start( _search, true,  true,  0 );

    /* Create scrolled box */
    var cbox = new Box( Orientation.VERTICAL, 0 );
    var sw   = new ScrolledWindow( null, null );
    var vp   = new Viewport( null, null );
    vp.set_size_request( width, height );
    vp.add( cbox );
    sw.add( vp );

    /* Add widgets to box */
    var functions = win.functions;
    for( int i=0; i<functions.categories.length; i++ ) {
      var category = functions.categories.index( i );
      cbox.pack_start( create_category( category, functions.get_category_label( category ) ), false, false, 0 );
    }

    pack_start( sbox, false, true, 10 );
    pack_start( sw,   true,  true, 10 );

  }

  /* Performs search of all text functions, displaying only those functions which match the search text */
  private void search_functions() {

    var value = _search.text.down();
    var empty = (value == "");

    for( int i=0; i<_categories.length; i++ ) {
      _categories.index( i ).show( empty );
    }

    _custom_revealer.reveal_child = empty;

    for( int i=0; i<_functions.length; i++ ) {
      _functions.index( i ).reveal( value );
    }

    for( int i=0; i<_categories.length; i++ ) {
      _categories.index( i ).hide();
    }

  }

  /* Creates category returning expander and item box */
  private Revealer create_category( string name, string label ) {

    var setting = "category-" + name + "-expanded";

    /* Create expander */
    var exp = new Expander( "  " + Utils.make_title( label ) );
    exp.margin_top = 5;
    exp.use_markup = true;
    exp.expanded   = TextShine.settings.get_boolean( setting );
    exp.activate.connect(() => {
      TextShine.settings.set_boolean( setting, !exp.expanded );
    });

    var ibox = new Box( Orientation.VERTICAL, 0 );
    ibox.border_width = 10;

    exp.add( ibox );

    var rev = new Revealer();
    rev.add( exp );
    rev.reveal_child = true;

    _categories.append_val( new Category( setting, exp, rev ) );

    switch( name ) {
      case "favorites" :
        _favorite_box = ibox;
        break;
      case "custom" :
        _custom_box = ibox;
        add_create_custom();
        break;
    }

    /* Populate item_box with functions */
    var functions = win.functions.get_category_functions( name );
    for( int i=0; i<functions.length; i++ ) {
      add_function( name, ibox, exp, functions.index( i ) );
    }

    return( rev );

  }

  /* Adds the create custom button */
  private void add_create_custom() {

    var fbox = new Box( Orientation.HORIZONTAL, 5 );

    var button = new Button.with_label( "Create Custom Action..." );
    button.halign = Align.START;
    button.set_relief( ReliefStyle.NONE );
    button.clicked.connect(() => {
      switch_stack( SwitchStackReason.NEW, null );
    });

    fbox.pack_start( button, false, true, 0 );

    _custom_revealer = new Revealer();
    _custom_revealer.add( fbox );
    _custom_revealer.border_width = 5;
    _custom_revealer.reveal_child = true;

    _custom_box.pack_start( _custom_revealer, false, false, 0 );

  }

  /* Adds a function button to the given category item box */
  public void add_function( string category, Box box, Expander? exp, TextFunction function ) {

    var fbox = new Box( Orientation.HORIZONTAL, 5 );

    var button = new Button.with_label( function.label );
    button.halign = Align.START;
    button.set_relief( ReliefStyle.NONE );
    button.clicked.connect(() => {
      editor.grab_focus();
      if( function.launchable( editor ) ) {
        win.remove_widget();
        function.launch( editor );
        action_applied( function );
      }
    });

    var grid = new Grid();
    var fav  = add_favorite_button(  grid, function );

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
      _functions.append_val( new Functions( function, fav, revealer, null, exp ) );
      function.update_button_label.connect(() => {
        button.label = function.label;
      });
    }

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

  private bool is_favorite( TextFunction function ) {
    var functions = win.functions.get_category_functions( "favorites" );
    for( int i=0; i<functions.length; i++ ) {
      if( functions.index( i ) == function ) {
        return( true );
      }
    }
    return( false );
  }

  private Button add_favorite_button( Grid grid, TextFunction function ) {

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

    return( favorite );

  }

  /* Toggles the favorite status */
  private void toggle_favorite( Button button, TextFunction function ) {

    if( is_favorite( function ) ) {
      unfavorite_function( function );
      button.image = new Image.from_icon_name( "non-starred-symbolic", IconSize.SMALL_TOOLBAR );
      button.set_tooltip_text( _( "Favorite" ) );
    } else {
      favorite_function( function.copy( false ) );
      button.image = new Image.from_icon_name( "starred-symbolic", IconSize.SMALL_TOOLBAR );
      button.set_tooltip_text( _( "Unfavorite" ) );
    }

  }

  /* Add the given function to the favorite list */
  private void favorite_function( TextFunction function ) {

    var fn = function.copy( false );

    /* Mark the function as a favorite */
    win.functions.favorite_function( fn );

    add_function( "favorites", _favorite_box, null, fn );
    _favorite_box.show_all();

  }

  /* Removes the given function from the favorite list */
  private void unfavorite_function( TextFunction function ) {

    /* Clear the function indicator in the sidebar */
    for( int i=0; i<_functions.length; i++ ) {
      if( _functions.index( i ).unfavorite( function ) ) {
        break;
      }
    }

    /* Remove the function as a favorite */
    var index  = win.functions.unfavorite_function( function );
    var reveal = (Revealer)_favorite_box.get_children().nth_data( index );

    /* Wait until idle to remove the widget so that we avoid an error */
    Idle.add(() => {
      _favorite_box.remove( reveal );
      return( Source.REMOVE );
    });

  }

  /* Adds a new custom function to the sidebar */
  public void add_custom_function( CustomFunction function ) {
    add_function( "custom", _custom_box, null, function );
    _custom_box.show_all();
  }

  /* Deletes an existing custom function from the sidebar */
  public void delete_custom_function( CustomFunction function ) {
    _custom_box.get_children().@foreach((w) => {
      _custom_box.remove( w );
    });
    var functions = win.functions.get_category_functions( "custom" );
    add_create_custom();
    for( int i=0; i<functions.length; i++ ) {
      add_custom_function( (CustomFunction)functions.index( i ) );
    }
    _custom_box.show_all();
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

  /* Adds the edit button to the custom function */
  private void add_edit_button( Box fbox, Grid grid, TextFunction function ) {

    var edit = new Button.from_icon_name( "edit-symbolic", IconSize.SMALL_TOOLBAR );
    edit.relief = ReliefStyle.NONE;
    edit.set_tooltip_text( _( "Edit Action" ) );
    edit.clicked.connect(() => {
      _edit_fbox = fbox;
      switch_stack( SwitchStackReason.EDIT, function );
    });

    grid.attach( edit, 0, 0 );

  }

  /* Updates the custom button name that was being edited */
  private void update_custom_name( TextFunction function ) {

    var btn = (Button)_edit_fbox.get_children().nth_data( 0 );
    btn.label = function.label;

  }

  /* Called when this panel is displayed */
  public void displayed( SwitchStackReason reason, TextFunction? function ) {
    switch( reason ) {
      case SwitchStackReason.ADD    :  add_custom_function( (CustomFunction)function );     break;
      case SwitchStackReason.EDIT   :  update_custom_name( function );                      break;
      case SwitchStackReason.DELETE :  delete_custom_function( (CustomFunction)function );  break;
    }
  }

}

