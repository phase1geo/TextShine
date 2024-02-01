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
  private Expander         _custom_exp;
  private Revealer         _custom_revealer;
  private Box              _edit_fbox;

  /* Constructor */
  public SidebarFunctions( MainWindow win, Editor editor ) {

    base( win, editor );

    _functions  = new Array<Functions>();
    _categories = new Array<Category>();

    /* Create search entry */
    _search = new SearchEntry() {
      halign = Align.FILL,
      hexpand = true,
      placeholder_text = _( "Search Actions" )
    };
    _search.search_changed.connect( search_functions );

    /* Create new custom function button */
    var custom = new Button.from_icon_name( "list-add-symbolic" ) {
      halign = Align.END,
      tooltip_text = _( "Add Custom Action" )
    };
    custom.clicked.connect(() => {
      switch_stack( SwitchStackReason.NEW, null );
    });

    var tbox = new Box( Orientation.HORIZONTAL, 5 ) {
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      halign = Align.FILL,
      hexpand = true
    };
    tbox.append( _search );
    tbox.append( custom );

    /* Create scrolled box */
    var cbox = new Box( Orientation.VERTICAL, 0 );
    var vp   = new Viewport( null, null ) {
      child = cbox
    };
    vp.set_size_request( width, height );

    var sw = new ScrolledWindow() {
      valign  = Align.FILL,
      vexpand = true,
      child   = vp
    };

    /* Add widgets to box */
    var functions = win.functions;
    for( int i=0; i<functions.categories.length; i++ ) {
      var category = functions.categories.index( i );
      cbox.append( create_category( category, functions.get_category_label( category ) ) );
    }

    append( tbox );
    append( sw );

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

    for( int i=0; i<_categories.length; i++ ) {
      _categories.index( i ).hide();
    }

  }

  /* Creates category returning expander and item box */
  private Revealer create_category( string name, string label ) {

    var setting = "category-" + name + "-expanded";

    var ibox = new Box( Orientation.VERTICAL, 10 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };

    /* Create expander */
    var exp = new Expander( "  " + Utils.make_title( label ) ) {
      margin_top = 5,
      use_markup = true,
      expanded   = TextShine.settings.get_boolean( setting ),
      child      = ibox
    };
    exp.activate.connect(() => {
      TextShine.settings.set_boolean( setting, !exp.expanded );
    });

    var rev = new Revealer() {
      reveal_child = true,
      child = exp
    };

    _categories.append_val( new Category( setting, exp, rev ) );

    switch( name ) {
      case "favorites" :
        _favorite_box = ibox;
        break;
      case "custom" :
        _custom_box = ibox;
        _custom_exp = exp;
        break;
    }

    /* Populate item_box with functions */
    var functions = win.functions.get_category_functions( name );
    for( int i=0; i<functions.length; i++ ) {
      add_function( name, ibox, exp, functions.index( i ) );
    }

    return( rev );

  }

  /* Adds a function button to the given category item box */
  public void add_function( string category, Box box, Expander? exp, TextFunction function ) {

    var fbox = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    var tbox = new Box( Orientation.HORIZONTAL, 5 );

    var button = new Button.with_label( function.label ) {
      halign = Align.START,
      hexpand = true,
      has_frame = false
    };
    button.clicked.connect(() => {
      editor.grab_focus();
      if( function.launchable( editor ) ) {
        win.remove_widget();
        function.launch( editor );
        action_applied( function );
      }
    });

    var grid = new Grid() {
      halign = Align.END,
      column_homogeneous = true
    };

    Button fav;

    fbox.append( tbox );

    switch( category ) {
      case "favorites" :
        fav = add_unfavorite_button( grid, function );
        break;
      case "custom"    :
        add_blank( grid, 0 );
        add_edit_button( fbox, grid, function );
        fav = add_favorite_button( grid, function );
        break;
      default          :
        add_direction_button( grid, button, function );
        add_settings_button( fbox, grid, function );
        fav = add_favorite_button( grid, function );
        break;
    }

    tbox.append( button );
    tbox.append( grid );

    box.append( fbox );

    if( exp != null ) {
      _functions.append_val( new Functions( function, fav, fbox, null, exp ) );
      function.update_button_label.connect(() => {
        button.label = function.label;
      });
      function.direction_changed.connect(() => {
        update_favorite_state( function, fav );
      });
      function.settings_changed.connect(() => {
        update_favorite_state( function, fav );
      });
    }

  }

  private void update_favorite_state( TextFunction function, Button fav ) {
    if( get_favorite( function ) != null ) {
      favorite_button_state( fav );
    } else {
      unfavorite_button_state( fav );
    }
  }

  private void add_blank( Grid grid, int column ) {
    var lbl = new Label( "" );
    grid.attach( lbl, column, 0 );
  }

  /* Creates the direction button (if necessary) and adds it to the given box */
  private void add_direction_button( Grid grid, Button btn, TextFunction function ) {

    if( function.direction == FunctionDirection.NONE ) return;

    var icon_name = "media-playlist-repeat-symbolic";
    var tooltip   = function.direction.is_vertical() ? _( "Switch Direction" ) : _( "Swap Order" );

    var direction = new Button.from_icon_name( icon_name ) {
      halign = Align.START,
      has_frame = false,
      tooltip_text = tooltip
    };

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

    grid.attach( direction, 0, 0 );

  }

  private TextFunction? get_favorite( TextFunction function ) {
    var functions = win.functions.get_category_functions( "favorites" );
    for( int i=0; i<functions.length; i++ ) {
      if( functions.index( i ).matches( function ) ) {
        return( functions.index( i ) );
      }
    }
    return( null );
  }

  private Button add_favorite_button( Grid grid, TextFunction function ) {

    var button = new Button() {
      has_frame = false
    };
    button.clicked.connect(() => {
      favorite_function( button, function );
    });

    update_favorite_state( function, button );

    grid.attach( button, 2, 0 );

    return( button );

  }

  private Button add_unfavorite_button( Grid grid, TextFunction function ) {

    var button = new Button.from_icon_name( "starred-symbolic" ) {
      has_frame = false,
      tooltip_text = _( "Unfavorite" )
    };
    button.clicked.connect(() => {
      unfavorite_function( button, function );
    });

    grid.attach( button, 2, 0 );

    return( button );

  }

  /* Removes the given favorite function from the list of available functions */
  private void remove_favorite( TextFunction function ) {

    /* Remove the function as a favorite */
    var index  = win.functions.unfavorite_function( function );
    var reveal = (Revealer)Utils.get_child_at_index( _favorite_box, index );

    /* Wait until idle to remove the widget so that we avoid an error */
    Idle.add(() => {
      _favorite_box.remove( reveal );
      return( Source.REMOVE );
    });

  }

  /* Sets the state of the specified favorite button to indicate that it is currently favorited */
  public void favorite_button_state( Button button ) {
    button.icon_name = "starred-symbolic";
    button.set_tooltip_text( _( "Unfavorite" ) );
  }

  /* Sets the state of the specified favorite button to indicate that it is currently unfavorited */
  public void unfavorite_button_state( Button button ) {
    button.icon_name = "non-starred-symbolic";
    button.set_tooltip_text( _( "Favorite" ) );
  }

  /*
   Add the given function to the favorite list.  Called when the user
   clicks on the favorite button for an origianl function.
  */
  private void favorite_function( Button button, TextFunction function ) {

    var favorited = get_favorite( function );

    /* If there is a favorited button for our function, remove it and update ourselves */
    if( favorited != null ) {

      /* Remove the favorited item */
      remove_favorite( favorited );

      /* Mark our button as unfavorited */
      unfavorite_button_state( button );

    /* Otherwise, add the favorited function */
    } else {

      var fn = function.copy( false );

      /* Mark the function as a favorite */
      win.functions.favorite_function( fn );

      add_function( "favorites", _favorite_box, null, fn );

      favorite_button_state( button );

    }

  }

  /*
   Removes the given favorited function from the favorite list.  Called when
   the user clicks on the favorite button for a favorited item.
  */
  private void unfavorite_function( Button button, TextFunction function ) {

    /* Set the original function button to unstarred if it currently matches */
    for( int i=0; i<_functions.length; i++ ) {
      if( _functions.index( i ).unfavorite( function, unfavorite_button_state ) ) {
        break;
      }
    }

    /* Remove the favorited function */
    remove_favorite( function );

  }

  /* Adds a new custom function to the sidebar */
  public void add_custom_function( CustomFunction function ) {
    add_function( "custom", _custom_box, _custom_exp, function );
  }

  /* Deletes an existing custom function from the sidebar */
  public void delete_custom_function( CustomFunction function ) {
    while( _custom_box.get_first_child() != null ) {
      _custom_box.remove( _custom_box.get_first_child() );
    }
    var functions = win.functions.get_category_functions( "custom" );
    for( int i=0; i<functions.length; i++ ) {
      add_custom_function( (CustomFunction)functions.index( i ) );
    }
  }

  /* Adds the settings button to the text function */
  private void add_settings_button( Box rowbox, Grid grid, TextFunction function ) {

    if( !function.settings_available() ) {
      add_blank( grid, 1 );
      return;
    }

    var settings = new Button.from_icon_name( "open-menu-symbolic" ) {
      has_frame = false,
      tooltip_text = _( "Settings" )
    };

    settings.clicked.connect(() => {
      if( rowbox.get_last_child().visible ) {
        rowbox.get_last_child().hide();
      } else {
        rowbox.get_last_child().show();
      }
    });

    var settings_grid = new Grid() {
      margin_start   = 5,
      margin_end     = 5,
      margin_top     = 5,
      margin_bottom  = 5,
      row_spacing    = 5,
      column_spacing = 5,
      column_homogeneous = false
    };

    var settings_frame = new Frame( null ) {
      margin_start = 25,
      visible      = false,
      child        = settings_grid
    };

    function.add_settings( settings_grid );

    rowbox.append( settings_frame );

    grid.attach( settings, 1, 0 );

  }

  /* Adds the edit button to the custom function */
  private void add_edit_button( Box fbox, Grid grid, TextFunction function ) {

    var edit = new Button.from_icon_name( "edit-symbolic" ) {
      has_frame = false,
      tooltip_text = _( "Edit Action" )
    };
    edit.clicked.connect(() => {
      _edit_fbox = fbox;
      switch_stack( SwitchStackReason.EDIT, function );
    });

    grid.attach( edit, 1, 0 );

  }

  /* Updates the custom button name that was being edited */
  private void update_custom_name( TextFunction function ) {

    var btn = (Button)Utils.get_child_at_index( _edit_fbox, 0 );
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

