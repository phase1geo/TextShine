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
  private Revealer         _add_revealer;
  private SearchEntry      _search;
  private CustomFunction?  _custom;
  private Popover          _popover;
  private Revealer         _delete_reveal;
  private Label            _new_action_label;
  private ListBox          _lb;
  private Grid             _pbox;
  private int              _insert_index;
  private Box?             _drag_box;
  private Button           _play;
  private UndoItem?        _test_undo = null;
  private UndoCustomBuffer _undo_buffer;
  private Button           _undo;
  private Button           _redo;
  private int              _next_box_id = 0;

  private const GLib.ActionEntry action_entries[] = {
    { "action_insert_new_action", action_insert_new_action, "s" },
    { "action_delete_action", action_delete_action, "s" },
    { "action_breakpoint", action_breakpoint, "s" },
    { "action_edit_description", action_edit_description, "s" },
  };

  /* Constructor */
  public SidebarCustom( MainWindow win, Editor editor ) {

    base( win, editor );

    _functions   = new Array<Functions>();
    _undo_buffer = new UndoCustomBuffer( this );
    _undo_buffer.buffer_changed.connect( do_buffer_changed );

    var nlbl = new Label( Utils.make_title( _( "Name:" ) ) ) {
      use_markup = true
    };

    _name = new Entry() {
      halign = Align.FILL,
      hexpand = true
    };

    var nbox = new Box( Orientation.HORIZONTAL, 5 ) {
      margin_start = 5,
      margin_end   = 5
    };
    nbox.append( nlbl );
    nbox.append( _name );

    _undo = new Button.from_icon_name( "edit-undo-symbolic" ) {
      halign    = Align.START,
      has_frame = false,
      sensitive = false
    };
    _undo.clicked.connect(() => {
      _undo_buffer.undo();
    });

    _redo = new Button.from_icon_name( "edit-redo-symbolic" ) {
      halign    = Align.START,
      hexpand   = true,
      has_frame = false,
      sensitive = false
    };
    _redo.clicked.connect(() => {
      _undo_buffer.redo();
    });

    _play = new Button.from_icon_name( "media-playback-start-symbolic" ) {
      halign    = Align.END,
      has_frame = false,
      sensitive = false,
      tooltip_text = _( "Test run custom actions" )
    };
    _play.clicked.connect( play_refresh );

    var abox = new Box( Orientation.HORIZONTAL, 5 );
    abox.append( _undo );
    abox.append( _redo );
    abox.append( _play );

    /* Create scrolled box */
    var drag_source = new DragSource();
    var drop_target = new DropTarget( Type.OBJECT, (DragAction.COPY | DragAction.MOVE) );
    _lb = new ListBox() {
      selection_mode = SelectionMode.NONE
    };
    _lb.add_controller( drag_source );
    _lb.add_controller( drop_target );

    drag_source.prepare.connect((x, y) => {
      var row = _lb.get_row_at_y( (int)y );
      if( row != null ) {
        _drag_box = (Box)row.child;
        var val = new Value( typeof(Object) );
        val.set_object( _drag_box );
        var content = new ContentProvider.for_value( val );
        return( content );
      }
      return( null );
    });
    drag_source.drag_begin.connect((drag) => {
      if( _drag_box != null ) {
        double hotspot_x, hotspot_y;
        var snapshot = new Gtk.Snapshot();
        var rect     = Utils.get_rect_for_widget( _drag_box );

        var cr = snapshot.append_cairo( rect );
        win.get_style_context().render_background( cr, 0, 0, rect.size.width, rect.size.height );
        _drag_box.snapshot( snapshot );

        Utils.get_relative_coordinates( _drag_box, out hotspot_x, out hotspot_y );
        // snapshot.append_color( bg, rect );
        DragIcon.set_from_paintable( drag, snapshot.free_to_paintable( null ), (int)hotspot_x, (int)hotspot_y );
      }
    });
    drag_source.drag_end.connect((drag) => {
      if( (_drag_box != null) && (drag.actions == DragAction.MOVE) ) {
        delete_action( _drag_box.name );
      }
      _drag_box = null;
    });
    drop_target.accept.connect((drop) => {
      return( _drag_box != null );
    });
    drop_target.drop.connect((val, x, y) => {
      if( _drag_box != null ) {
        var row = _lb.get_row_at_y( (int)y );
        if( row != null ) {
          var box = (Box)row.child;
          if( box == _drag_box ) return( false );
          var box_index  = get_action_index( box.name );
          var drag_index = get_action_index( _drag_box.name );
          _undo_buffer.add_item( new UndoCustomMoveItem( drag_index, box_index ) );
          move_function( drag_index, box_index );
          return( true );
        }
      }
      return( false );
    });

    var vp = new Viewport( null, null ) {
      child = _lb
    };
    vp.set_size_request( width, height );

    var sw = new ScrolledWindow() {
      valign = Align.FILL,
      vexpand = true,
      child = vp
    };

    var add = new Button.with_label( _( "Add New Action" ) ) {
      has_frame = false
    };
    add.clicked.connect(() => {
      insert_new_action( 0 );
    });

    var ins = new Label( " " );
    var stack = new Stack();
    stack.add_named( add, "add" );
    stack.add_named( ins, "ins" );

    _add_revealer = new Revealer() {
      reveal_child = true,
      child = stack
    };

    var del = new Button.with_label( _( "Delete" ) );
    del.get_style_context().add_class( "destructive-action" );
    del.clicked.connect( delete_custom );

    var done = new Button.with_label( _( "Done" ) ) {
      halign = Align.END
    };
    done.get_style_context().add_class( "suggested-action" );
    done.clicked.connect( save_custom );

    _delete_reveal = new Revealer() {
      halign = Align.START,
      hexpand = true,
      reveal_child = true,
      transition_type = RevealerTransitionType.NONE,
      child = del
    };

    var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };
    bbox.append( _delete_reveal );
    bbox.append( done );

    append( abox );
    append( nbox );
    append( _add_revealer );
    append( sw );
    append( bbox );

    /* Create the action insertion popover */
    create_popover();

    /* Add the menu actions */
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "custom", actions );

  }

  private void play_refresh() {
    var play_img    = "media-playback-start-symbolic";
    var refresh_img = "view-refresh-symbolic";
    if( _play.icon_name == play_img ) {
      _play.icon_name = refresh_img;
      _play.tooltip_text = _( "Refresh text" );
      play_action();
    } else {
      _play.icon_name = play_img;
      _play.tooltip_text = _( "Test run custom actions" );
      refresh_text();
    }
  }

  private void play_action() {
    _test_undo = new UndoItem( "" );
    _custom.test( editor, _test_undo );
  }

  private void refresh_text() {
    _test_undo.undo( editor );
    _test_undo = null;
  }

  /* Called when we get displayed */
  public override void displayed( SwitchStackReason reason, TextFunction? function ) {

    clear_actions();
    _undo_buffer.clear();

    switch( reason ) {

      case SwitchStackReason.NEW :
        _custom    = new CustomFunction();
        _name.text = _custom.label;
        _name.grab_focus();
        _delete_reveal.reveal_child = false;
        break;

      case SwitchStackReason.EDIT :
        _custom    = (CustomFunction)function;
        _name.text = _custom.label;
        _delete_reveal.reveal_child = true;
        insert_actions();
        break;

    }

  }

  private void clear_actions() {

    _add_revealer.reveal_child = true;

    /* Remove all of the rows from the listbox */
    var row = _lb.get_row_at_index( 0 );
    while( row != null ) {
      _lb.remove( row );
      row = _lb.get_row_at_index( 0 );
    }

    _next_box_id = 0;

  }

  /* Inserts the current custom actions */
  private void insert_actions() {
    for( int i=0; i<_custom.functions.length; i++ ) {
      var fn = _custom.functions.index( i );
      add_function( fn );
      _add_revealer.reveal_child = false;
    }
  }

  /* Adds a function button to the given category item box */
  public Box add_function( TextFunction function, int index = -1 ) {

    // Box containing the function frame
    var box = new Box( Orientation.VERTICAL, 0 ) {
      name = "fbox%d".printf( _next_box_id++ )
    };

    var label = new Label( Utils.make_title( function.label ) ) {
      halign = Align.START,
      hexpand = true,
      use_markup = true
    };

    // Grid contains all of the function buttons (direction, settings)
    var grid = new Grid() {
      halign = Align.END,
      column_homogeneous = true
    };
    add_direction_button( grid, label, function );

    var breakpoint = new Image.from_icon_name( "media-playback-stop-symbolic" ) {
      tooltip_text = _( "Test run stops after this action" )
    };

    var break_reveal = new Revealer() {
      halign = Align.END,
      transition_type = RevealerTransitionType.NONE,
      child = breakpoint
    };

    // Contains right-most menu to add a function above/below/etc.
    var more = new MenuButton() {
      icon_name = "view-more-symbolic",
      halign = Align.END,
      has_frame = false
    };
    show_action_menu( box, more );

    // Contains the function label and the grid
    var lbox = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL
    };
    lbox.append( label );
    lbox.append( grid );

    // Contains the elements of the top-most row of the function
    var lbbox = new Box( Orientation.HORIZONTAL, 2 );
    lbbox.append( lbox );
    lbbox.append( more );
    lbbox.append( break_reveal );

    var dentry = new Entry() {
      halign  = Align.FILL,
      xalign  = 0,
      text    = function.description,
      visible = false
    };

    var dlabel = new Label( function.description ) {
      halign = Align.FILL,
      xalign = 0,
      wrap   = true
    };

    var dsep = new Separator( Orientation.HORIZONTAL ) {
      halign = Align.FILL
    };

    // Contains the description elements
    var dbox = new Box( Orientation.VERTICAL, 5 ) {
      halign = Align.FILL
    };
    dbox.append( dsep );
    dbox.append( dentry );
    dbox.append( dlabel );

    if( function.description == "" ) {
      dbox.hide();
    }

    dentry.activate.connect(() => {
      function.description = dentry.text;
      if( dentry.text == "" ) {
        dbox.hide();
      }
      dentry.hide();
      dlabel.label = dentry.text;
      dlabel.show();
      more.grab_focus();
    });

    // Contains the first row, settings options and description
    var lbw = new Box( Orientation.VERTICAL, 5 );
    lbw.append( lbbox );

    add_settings_button( lbw, grid, function );

    var wbox = function.get_widget( editor );
    if( wbox != null ) {
      lbw.append( wbox );
    }

    lbw.append( dbox );

    // Not actually necessary but exists for some reason
    var fbox = new Box( Orientation.VERTICAL, 5 ) {
      margin_top    = 10,
      margin_bottom = 10,
      margin_start  = 5,
      margin_end    = 5
    };
    fbox.append( lbw );

    // Draws nameless frame around the function contents
    var frame = new Frame( null ) {
      margin_start  = 4,
      margin_end    = 4,
      margin_top    = 4,
      margin_bottom = 4,
      child = fbox
    };

    var add_placeholder = new Label( _( "Add New Action" ) );
    var ins_placeholder = new Label( " " );
    var placeholder_stack = new Stack();
    placeholder_stack.add_named( add_placeholder, "add" );
    placeholder_stack.add_named( ins_placeholder, "ins" );

    var add_revealer = new Revealer() {
      reveal_child = false,
      child = placeholder_stack
    };

    box.append( frame );
    box.append( add_revealer );

    _lb.insert( box, index );
    _play.set_sensitive( true );

    function.update_button_label.connect(() => {
      label.label = Utils.make_title( function.label );
    });

    return( box );

  }

  /* Adds the action menu */
  private void show_action_menu( Box box, MenuButton btn ) {

    var var0 = new Variant( "(ss)", box.name, 0.to_string() );
    var var1 = new Variant( "(ss)", box.name, 1.to_string() );

    var add_submenu = new GLib.Menu();
    add_submenu.append( _( "Add Action Above" ), "custom.action_insert_new_action(\"%s\")".printf( var0.print( true ) ) );
    add_submenu.append( _( "Add Action Below" ), "custom.action_insert_new_action(\"%s\")".printf( var1.print( true ) ) );

    var del_submenu = new GLib.Menu();
    del_submenu.append( _( "Remove Action" ), "custom.action_delete_action('%s')".printf( box.name ) );

    var break_submenu = new GLib.Menu();
    break_submenu.append( _( "Toggle Breakpoint" ), "custom.action_breakpoint('%s')".printf( box.name ) );

    var description_submenu = new GLib.Menu();
    description_submenu.append( _( "Edit Description" ), "custom.action_edit_description('%s')".printf( box.name ) );

    var mnu = new GLib.Menu();
    mnu.append_section( null, add_submenu );
    mnu.append_section( null, del_submenu );
    mnu.append_section( null, break_submenu );
    mnu.append_section( null, description_submenu );

    btn.menu_model = mnu;

  }

  /* Returns the index of the given action box */
  private int get_action_index( string name ) {

    var i   = 0;
    var row = _lb.get_row_at_index( i );

    while( row != null ) {
      if( row.child.name == name ) {
        return( i );
      }
      row = _lb.get_row_at_index( ++i );
    }

    return( -1 );

  }

  /* Returns the revealer at the given index */
  private Revealer get_revealer( int index ) {
    if( index == 0 ) {
      return( _add_revealer );
    } else {
      var row = _lb.get_row_at_index( _insert_index - 1 );
      return( (Revealer)Utils.get_child_at_index( row.child, 1 ) );
    }
  }

  /* Inserts the new action label in the given position */
  private void action_insert_new_action( SimpleAction action, Variant? variant ) {  // Box? box, int add_to_index ) {

    if( variant != null ) {

      string? box_name = null;
      string? add_to_index = null;
      Variant v;

      try {
        v = Variant.parse( null, variant.get_string() );
      } catch( VariantParseError e ) {
        return;
      }

      var iter = v.iterator();
      iter.next( "s", out box_name );
      iter.next( "s", out add_to_index );

      if( (box_name != null) && (add_to_index != null) ) {
        var index = get_action_index( box_name );
        insert_new_action( (index == -1) ? -1 : (index + int.parse( add_to_index )) );
      }

    }

  }

  private void insert_new_action( int index ) {

    _insert_index = (index == -1) ? 0 : index;

    var revealer = get_revealer( _insert_index );
    revealer.reveal_child = true;

    _popover.unparent();
    _popover.set_parent( revealer );
    _popover.popup();

  }

  private void action_delete_action( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      delete_action( variant.get_string() );
    }
  }

  private void delete_action( string box_name ) {
    var idx = get_action_index( box_name );
    var fn  = _custom.functions.index( idx );
    _undo_buffer.add_item( new UndoCustomDeleteItem( fn, idx ) );
    delete_function( idx );
  }

  /*
   Inserts the given text function into the custom function at the previously
   calculated insert index.  Updates the internal custom function contents.
  */
  public void insert_function( TextFunction function, int index ) {

    get_revealer( index ).reveal_child = false;

    var fn  = function.copy( true );
    var box = add_function( fn, index );

    _custom.functions.insert_val( index, fn );

  }

  /* Removes the action at the given index */
  public void delete_function( int index ) {

    var fn = _custom.functions.index( index );

    _lb.remove( _lb.get_row_at_index( index ) );
    _custom.functions.remove_index( index );

    if( _custom.functions.length == 0 ) {
      _add_revealer.reveal_child = true;
    }

  }

  /* Movew a function from one index to another */
  public void move_function( int old_index, int new_index ) {

    var db_row = _lb.get_row_at_index( old_index );

    db_row.ref();
    _lb.remove( db_row );
    _lb.insert( db_row, new_index );
    db_row.unref();

    var fn = _custom.functions.remove_index( old_index );
    _custom.functions.insert_val( new_index, fn );

  }

  /* Handles a code breakpoint */
  private void action_breakpoint( SimpleAction action, Variant? variant ) {

    if( variant != null ) {

      var box_name     = variant.get_string();
      var index        = get_action_index( box_name );
      var bpoint       = (index == _custom.breakpoint);
      var row          = _lb.get_row_at_index( index );
      var box          = (Box)row.child;
      var frame        = (Frame)Utils.get_child_at_index( box, 0 );
      var fbox         = (Box)frame.child;
      var lbw          = (Box)Utils.get_child_at_index( fbox, 0 );
      var lbbox        = (Box)Utils.get_child_at_index( lbw, 0 );
      var break_reveal = (Revealer)Utils.get_child_at_index( lbbox, 2 );

      if( !break_reveal.reveal_child ) {
        set_breakpoint( box );
        break_reveal.reveal_child = true;
      } else {
        clear_breakpoint();
        break_reveal.reveal_child = false;
      }

    }

  }

  /* Sets the given box as a breakpoint */
  private void set_breakpoint( Box box ) {
    _custom.breakpoint = get_action_index( box.name );
  }

  /* Clears the breakpoint */
  private void clear_breakpoint() {
    _custom.breakpoint = -1;
  }

  /* Allows the user to edit the description */
  private void action_edit_description( SimpleAction action, Variant? variant ) {

    if( variant != null ) {

      var box_name = variant.get_string();
      var index    = get_action_index( box_name );
      var row      = _lb.get_row_at_index( index );
      var box      = (Box)row.child;
      var frame    = (Frame)Utils.get_child_at_index( box, 0 );
      var fbox     = (Box)frame.child;
      var lbw      = (Box)Utils.get_child_at_index( fbox, 0 );
      var dbox     = (Box)lbw.get_last_child();
      var dentry   = (Entry)Utils.get_child_at_index( dbox, 1 );
      var dlabel   = (Label)Utils.get_child_at_index( dbox, 2 );

      if( (dentry != null) && (dlabel != null) ) {
        dentry.show();
        dlabel.hide();
        dbox.show();
        dentry.grab_focus();
      }

    }

  }

  //----------------------------------------------------------------------------
  //  POPOVER
  //----------------------------------------------------------------------------

  private void create_popover() {

    _functions = new Array<Functions>();

    _new_action_label = new Label( _( "Select Action..." ) ) {
      halign = Align.START
    };

    /* Create search box */
    _search = new SearchEntry() {
      halign = Align.FILL,
      hexpand = true,
      placeholder_text = _( "Search Actions" ),
      margin_start     = 5,
      margin_end       = 5,
      margin_top       = 5,
      margin_bottom    = 5
    };
    _search.search_changed.connect( search_functions );

    /* Create scrolled box */
    _pbox = new Grid() {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    var vp = new Viewport( null, null ) {
      child = _pbox
    };
    vp.set_size_request( width, height );
    var sw   = new ScrolledWindow() {
      halign = Align.FILL,
      hexpand = true,
      valign = Align.FILL,
      vexpand = true,
      child   = vp
    };

    var box = new Box( Orientation.VERTICAL, 0 );
    box.set_size_request( 350, 500 );
    box.append( _search );
    box.append( sw );

    _popover = new Popover() {
      position = PositionType.LEFT,
      autohide = true,
      child    = box
    };
    _popover.set_parent( _new_action_label );
    _popover.show.connect( popover_opened );
    _popover.closed.connect( popover_closed );

  }

  /*
   Called when the function popover is displayed.  Populates the popover with
   the current list of available functions.
  */
  private void popover_opened() {

    /* Clear the search field */
    _search.text = "";

    /* Clear the contents */
    while( _pbox.get_first_child() != null ) {
      _pbox.remove( _pbox.get_first_child() );
    }

    /* Insert the new elements */
    var functions = win.functions.functions;
    for( int i=0; i<functions.length; i++ ) {
      add_popup_function( i, functions.index( i ) );
    }

  }

  /* Called whenever the popover is closed */
  private void popover_closed() {

    if( _custom.functions.length > 0 ) {
      get_revealer( _insert_index ).reveal_child = false;
    }

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
  public void add_popup_function( int row, TextFunction function ) {

    var label = new Label( win.functions.get_category_label_for_function( function ).up() + ": " ) {
      xalign = 0
    };

    var button = new Button.with_label( function.label ) {
      halign = Align.START,
      has_frame = false
    };
    button.clicked.connect(() => {
      _undo_buffer.add_item( new UndoCustomAddItem( function, _insert_index ) );
      insert_function( function, _insert_index );
      _popover.popdown();
    });

    _pbox.attach( label, 0, row );
    _pbox.attach( button, 1, row );

    /* Add the function so that we can hide it while searching */
    _functions.append_val( new Functions( function, null, label, button ) );

  }

  private void add_blank( Grid grid, int column ) {
    var lbl = new Label( "" );
    grid.attach( lbl, column, 0 );
  }

  /* Creates the direction button (if necessary) and adds it to the given box */
  private void add_direction_button( Grid grid, Label lbl, TextFunction function ) {

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
      lbl.label = function.label;
    });

    grid.attach( direction, 0, 0 );

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

    var settings_grid = new Grid() {
      margin_start   = 5,
      margin_end     = 5,
      margin_top     = 5,
      margin_bottom  = 5,
      row_spacing    = 5,
      column_spacing = 5,
      column_homogeneous = false,
      visible = false
    };

    /*
    var settings_frame = new Frame( null ) {
      margin_start = 25,
      visible      = false,
      child        = settings_grid
    };
    */

    function.add_settings( settings_grid );

    settings.clicked.connect(() => {
      if( settings_grid.visible ) {
        settings_grid.hide();
      } else {
        settings_grid.show();
      }
    });

    rowbox.append( settings_grid );

    grid.attach( settings, 1, 0 );

  }

  /* Populates the settings popover with the list of options from the function */
  private void on_settings_show( Popover popover, TextFunction function ) {

    if( popover.child != null ) {
      popover.child.destroy();
    }

    var grid = new Grid() {
      margin_start   = 5,
      margin_end     = 5,
      margin_top     = 5,
      margin_bottom  = 5,
      row_spacing    = 5,
      column_spacing = 5,
      column_homogeneous = false
    };

    function.add_settings( grid );

    popover.child = grid;

  }

  private void cleanup() {

    /* If we tested the actions, make sure that we revert our changes */
    if( _test_undo != null ) {
      _test_undo.undo( editor );
    }

    _custom.breakpoint = -1;

  }

  /* Saves the current custom function */
  private void save_custom() {

    var edit  = _delete_reveal.reveal_child;
    var empty = _custom.functions.length == 0;

    cleanup();

    _custom.label = _name.text;

    if( edit ) {
      win.functions.save_custom();
      switch_stack( SwitchStackReason.EDIT, _custom );
    } else if( !empty ) {
      win.functions.add_function( "custom", _custom );
      win.functions.save_custom();
      switch_stack( SwitchStackReason.ADD, _custom );
    } else {
      switch_stack( SwitchStackReason.NONE, _custom );
    }

  }

  /* Deletes the current custom function */
  private void delete_custom() {

    var flags  = DialogFlags.MODAL | DialogFlags.DESTROY_WITH_PARENT;
    var dialog = new MessageDialog( win, flags, MessageType.WARNING, ButtonsType.NONE, null );
    dialog.set_markup( Utils.make_title( _( "Delete Custom Action?") ) );
    dialog.format_secondary_text( _( "Deleting a custom action cannot be undone." ) );
    var del = dialog.add_button( _( "Delete Action" ), ResponseType.ACCEPT );
    var can = dialog.add_button( _( "Cancel" ),        ResponseType.REJECT );

    del.get_style_context().add_class( "destructive-action" );
    can.grab_focus();

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        cleanup();
        win.functions.remove_function( _custom );
        win.functions.save_custom();
        switch_stack( SwitchStackReason.DELETE, _custom );
      }
      dialog.destroy();
    });

    dialog.show();

  }

  /* Called whenever the editor buffer changes */
  private void do_buffer_changed( UndoCustomBuffer buffer ) {
    _undo.set_sensitive( buffer.undoable() );
    _redo.set_sensitive( buffer.redoable() );
    _undo.tooltip_text = buffer.undo_tooltip();
    _redo.tooltip_text = buffer.redo_tooltip();
  }

}

