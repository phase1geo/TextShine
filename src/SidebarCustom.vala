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
  private Revealer?        _break_reveal = null;
  private UndoCustomBuffer _undo_buffer;
  private Button           _undo;
  private Button           _redo;

  static TargetEntry[] entries = {
    { "TEXTSHINE_CUSTOM_ROW", TargetFlags.SAME_APP, 0 }
  };

  /* Constructor */
  public SidebarCustom( MainWindow win, Editor editor ) {

    base( win, editor );

    _functions   = new Array<Functions>();
    _undo_buffer = new UndoCustomBuffer( this );
    _undo_buffer.buffer_changed.connect( do_buffer_changed );

    var nlbl = new Label( Utils.make_title( _( "Name:" ) ) );
    nlbl.use_markup = true;

    _name = new Entry();

    var nbox = new Box( Orientation.HORIZONTAL, 0 );
    nbox.pack_start( nlbl,            false, false, 5 );
    nbox.pack_start( _name,           true,  true,  5 );

    _undo = new Button.from_icon_name( "edit-undo-symbolic", IconSize.SMALL_TOOLBAR );
    _undo.set_relief( ReliefStyle.NONE );
    _undo.set_sensitive( false );
    _undo.clicked.connect(() => {
      _undo_buffer.undo();
    });

    _redo = new Button.from_icon_name( "edit-redo-symbolic", IconSize.SMALL_TOOLBAR );
    _redo.set_relief( ReliefStyle.NONE );
    _redo.set_sensitive( false );
    _redo.clicked.connect(() => {
      _undo_buffer.redo();
    });

    _play = new Button.from_icon_name( "media-playback-start-symbolic", IconSize.SMALL_TOOLBAR );
    _play.set_relief( ReliefStyle.NONE );
    _play.set_sensitive( false );
    _play.tooltip_text = _( "Test run custom actions" );
    _play.clicked.connect( play_refresh );

    var abox = new Box( Orientation.HORIZONTAL, 0 );
    abox.pack_start( _undo, false, false, 5 );
    abox.pack_start( _redo, false, false, 5 );
    abox.pack_end(   _play, false, false, 5 );

    /* Create scrolled box */
    _lb = new ListBox();
    _lb.selection_mode = SelectionMode.NONE;

    var sw = new ScrolledWindow( null, null );
    var vp = new Viewport( null, null );
    vp.set_size_request( width, height );
    vp.add( _lb );
    sw.add( vp );

    var add = new Button.with_label( _( "Add New Action" ) );
    add.set_relief( ReliefStyle.NONE );
    add.clicked.connect(() => {
      insert_new_action( null, 0 );
    });

    var ins = new Label( " " );
    var stack = new Stack();
    stack.add_named( add, "add" );
    stack.add_named( ins, "ins" );

    _add_revealer = new Revealer();
    _add_revealer.reveal_child = true;
    _add_revealer.add( stack );

    var del = new Button.with_label( _( "Delete" ) );
    del.get_style_context().add_class( "destructive-action" );
    del.clicked.connect( delete_custom );

    var done = new Button.with_label( _( "Done" ) );
    done.get_style_context().add_class( "suggested-action" );
    done.clicked.connect( save_custom );

    _delete_reveal = new Revealer();
    _delete_reveal.reveal_child    = true;
    _delete_reveal.transition_type = RevealerTransitionType.NONE;
    _delete_reveal.add( del );

    var bbox = new Box( Orientation.HORIZONTAL, 0 );
    bbox.pack_start( _delete_reveal, false, false, 5 );
    bbox.pack_end( done, false, false, 5 );

    pack_start( abox,          false, true, 5 );
    pack_start( nbox,          false, true, 5 );
    pack_start( _add_revealer, false, true, 5 );
    pack_start( sw,            true,  true, 5 );
    pack_start( bbox,          false, true, 5 );

    /* Create the action insertion popover */
    create_popover();

  }

  private void play_refresh() {
    var play_img    = "media-playback-start-symbolic";
    var refresh_img = "view-refresh-symbolic";
    var img         = (Gtk.Image)_play.image;
    if( img.icon_name == play_img ) {
      _play.image = new Image.from_icon_name( refresh_img, IconSize.SMALL_TOOLBAR );
      _play.tooltip_text = _( "Refresh text" );
      play_action();
    } else {
      _play.image = new Image.from_icon_name( play_img, IconSize.SMALL_TOOLBAR );
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
    _lb.get_children().@foreach((w) => {
      _lb.remove( w );
    });
  }

  /* Inserts the current custom actions */
  private void insert_actions() {
    for( int i=0; i<_custom.functions.length; i++ ) {
      var fn = _custom.functions.index( i );
      add_function( fn );
      _add_revealer.reveal_child = false;
    }
    _lb.show_all();
  }

  /* Adds a function button to the given category item box */
  public Box add_function( TextFunction function, int index = -1 ) {

    var box = new Box( Orientation.VERTICAL, 0 );

    var label = new Label( Utils.make_title( function.label ) );
    label.halign = Align.START;
    label.use_markup = true;

    var grid = new Grid();
    add_direction_button( grid, label, function );
    add_settings_button(  grid, function );

    var breakpoint = new Image.from_icon_name( "media-playback-stop-symbolic", IconSize.SMALL_TOOLBAR );
    breakpoint.tooltip_text = _( "Test run stops after this action" );

    var break_reveal = new Revealer();
    break_reveal.add( breakpoint );
    break_reveal.transition_type = RevealerTransitionType.NONE;

    var more = new Button.from_icon_name( "view-more-symbolic", IconSize.SMALL_TOOLBAR );
    more.relief = ReliefStyle.NONE;
    more.clicked.connect(() => {
      show_action_menu( box, more, break_reveal );
    });

    var lbox = new Box( Orientation.HORIZONTAL, 0 );
    lbox.pack_start( label, false, true,  5 );
    lbox.pack_end(   grid,  false, false, 0 );

    var lbbox = new Box( Orientation.HORIZONTAL, 0 );
    lbbox.pack_start( lbox, true,  true,  2 );
    lbbox.pack_end(   more, false, false, 2 );
    lbbox.pack_end(   break_reveal, false, false, 0 );

    var ebox = new EventBox();

    var wbox = function.get_widget( editor );
    if( wbox != null ) {
      var lbw = new Box( Orientation.VERTICAL, 0 );
      lbw.pack_start( lbbox, false, true, 5 );
      lbw.pack_start( wbox,  false, true, 5 );
      ebox.add( lbw );
    } else {
      ebox.add( lbbox );
    }

    var move_mask = ModifierType.BUTTON1_MASK;
    var copy_mask = (ModifierType.BUTTON1_MASK | ModifierType.CONTROL_MASK);

    Gtk.drag_source_set( ebox, move_mask, entries, Gdk.DragAction.MOVE );
    Gtk.drag_source_set( ebox, copy_mask, entries, Gdk.DragAction.COPY );
    Gtk.drag_dest_set( ebox, DestDefaults.ALL, entries, (Gdk.DragAction.MOVE | Gdk.DragAction.COPY) );

    var fbox  = new Box( Orientation.VERTICAL, 0 );
    fbox.margin_top    = 10;
    fbox.margin_bottom = 10;
    fbox.margin_left   = 5;
    fbox.margin_right  = 5;
    fbox.pack_start( ebox, false, true, 5 );

    var frame = new Frame( null );
    frame.shadow_type = ShadowType.ETCHED_OUT;
    frame.margin = 4;
    frame.add( fbox );

    ebox.drag_begin.connect((ctx) => {
      Allocation alloc;
      box.get_allocation( out alloc );
      var surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, alloc.width, alloc.height );
      var cr      = new Cairo.Context( surface );
      box.draw( cr );
      drag_set_icon_surface( ctx, surface );
      _drag_box = box;
    });

    ebox.drag_end.connect((ctx) => {
      _drag_box = null;
    });

    ebox.drag_drop.connect((ctx, x, y, time_) => {
      if( box == _drag_box ) return( false );
      var box_index  = get_action_index( box );
      var drag_index = get_action_index( _drag_box );
      _undo_buffer.add_item( new UndoCustomMoveItem( drag_index, box_index ) );
      move_function( drag_index, box_index );
      return( true );
    });

    var add_placeholder = new Label( _( "Add New Action" ) );
    var ins_placeholder = new Label( " " );
    var placeholder_stack = new Stack();
    placeholder_stack.add_named( add_placeholder, "add" );
    placeholder_stack.add_named( ins_placeholder, "ins" );
    var add_revealer = new Revealer();
    add_revealer.reveal_child = false;
    add_revealer.add( placeholder_stack );

    box.pack_start( frame,        false, true, 0 );
    box.pack_start( add_revealer, false, true, 0 );
    box.show_all();

    _lb.insert( box, index );
    _play.set_sensitive( true );

    function.update_button_label.connect(() => {
      label.label = Utils.make_title( function.label );
    });

    return( box );

  }

  /* Adds the action menu */
  private void show_action_menu( Box box, Button btn, Revealer break_reveal ) {

    var index  = get_action_index( box );
    var bpoint = _custom.breakpoint == index;
    var mnu    = new Gtk.Menu();

    var add_above = new Gtk.MenuItem.with_label( _( "Add Action Above" ) );
    add_above.activate.connect(() => {
      insert_new_action( box, 0 );
    });

    var add_below = new Gtk.MenuItem.with_label( _( "Add Action Below" ) );
    add_below.activate.connect(() => {
      insert_new_action( box, 1 );
    });

    var del = new Gtk.MenuItem.with_label( _( "Remove Action" ) );
    del.activate.connect(() => {
      var idx = get_action_index( box );
      var fn  = _custom.functions.index( idx );
      _undo_buffer.add_item( new UndoCustomDeleteItem( fn, idx ) );
      delete_function( idx );
    });

    var breakpoint = new Gtk.MenuItem.with_label( bpoint ? _( "Remove Breakpoint" ) : _( "Set Breakpoint" ) );
    breakpoint.activate.connect(() => {
      handle_breakpoint( box, breakpoint, break_reveal );
    });

    mnu.add( add_above );
    mnu.add( add_below );
    mnu.add( new Gtk.SeparatorMenuItem() );
    mnu.add( del );
    mnu.add( new Gtk.SeparatorMenuItem() );
    mnu.add( breakpoint );

    mnu.show_all();
    mnu.popup_at_widget( btn, Gravity.CENTER, Gravity.NORTH_EAST );

  }

  /* Returns the index of the given action box */
  private int get_action_index( Box box ) {

    var index = 0;
    var i     = 0;

    _lb.get_children().@foreach((w) => {
      var row = (ListBoxRow)w;
      var b   = (Box)row.get_children().nth_data( 0 );
      if( b == box ) {
        index = i;
      }
      i++;
    });

    return( index );

  }

  /* Returns the revealer at the given index */
  private Revealer get_revealer( int index ) {
    if( index == 0 ) {
      return( _add_revealer );
    } else {
      var row = (ListBoxRow)_lb.get_children().nth_data( _insert_index - 1 );
      var box = (Box)row.get_children().nth_data( 0 );
      return( (Revealer)box.get_children().nth_data( 1 ) );
    }
  }

  /* Inserts the new action label in the given position */
  private void insert_new_action( Box? box, int add_to_index ) {

    /* Figure out what index we are going to insert at */
    _insert_index = (box == null) ? 0 : (get_action_index( box ) + add_to_index);

    var revealer = get_revealer( _insert_index );
    revealer.reveal_child = true;

    _popover.relative_to = revealer;
    _popover.popup();

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

    _lb.remove( _lb.get_children().nth_data( index ) );
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

  private void handle_breakpoint( Box box, Gtk.MenuItem menu_item, Revealer break_reveal ) {
    if( menu_item.label == _( "Set Breakpoint" ) ) {
      set_breakpoint( box );
      break_reveal.reveal_child = true;
      if( _break_reveal != null ) {
        _break_reveal.reveal_child = false;
      }
      _break_reveal = break_reveal;
    } else {
      clear_breakpoint();
      _break_reveal.reveal_child = false;
      _break_reveal = null;
    }
  }

  /* Sets the given box as a breakpoint */
  private void set_breakpoint( Box box ) {
    _custom.breakpoint = get_action_index( box );
  }

  /* Clears the breakpoint */
  private void clear_breakpoint() {
    _custom.breakpoint = -1;
  }

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
    _search.margin = 5;
    _search.search_changed.connect( search_functions );

    /* Create scrolled box */
    _pbox = new Grid();
    _pbox.border_width = 5;
    var sw   = new ScrolledWindow( null, null );
    var vp   = new Viewport( null, null );
    vp.set_size_request( width, height );
    vp.add( _pbox );
    sw.add( vp );

    var box = new Box( Orientation.VERTICAL, 0 );
    box.set_size_request( 350, 500 );
    box.pack_start( _search, false, true, 0 );
    box.pack_start( sw,      true,  true, 0 );

    box.show_all();

    _popover = new Popover( null );
    _popover.modal = true;
    _popover.relative_to = _new_action_label;
    _popover.position    = PositionType.LEFT;
    _popover.add( box );
    _popover.show.connect( popover_opened );
    _popover.closed.connect( popover_closed );

  }

  /*
   Called when the function popover is displayed.  Populates the popover with
   the current list of available functions.
  */
  private void popover_opened() {

    /* Clear the contents */
    _pbox.get_children().foreach((w) => {
      _pbox.remove( w );
    });

    /* Insert the new elements */
    var functions = win.functions.functions;
    for( int i=0; i<functions.length; i++ ) {
      add_popup_function( i, functions.index( i ) );
    }

    _pbox.show_all();

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

    var label = new Label( win.functions.get_category_label_for_function( function ).up() + ": " );
    label.xalign = (float)0;

    var lreveal = new Revealer();
    lreveal.reveal_child = true;
    lreveal.add( label );

    var button = new Button.with_label( function.label );
    button.halign = Align.START;
    button.set_relief( ReliefStyle.NONE );
    button.clicked.connect(() => {
      _undo_buffer.add_item( new UndoCustomAddItem( function, _insert_index ) );
      insert_function( function, _insert_index );
      _popover.popdown();
    });

    var breveal = new Revealer();
    breveal.reveal_child = true;
    breveal.add( button );

    _pbox.attach( lreveal, 0, row );
    _pbox.attach( breveal, 1, row );

    /* Add the function so that we can hide it while searching */
    _functions.append_val( new Functions( function, null, lreveal, breveal ) );

  }

  /* Creates the direction button (if necessary) and adds it to the given box */
  private void add_direction_button( Grid grid, Label lbl, TextFunction function ) {

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
      lbl.label = function.label;
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

  /* Populates the settings popover with the list of options from the function */
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

  private void cleanup() {

    /* If we tested the actions, make sure that we revert our changes */
    if( _test_undo != null ) {
      _test_undo.undo( editor );
    }

    _custom.breakpoint = -1;
    _break_reveal = null;

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

    if( dialog.run() == ResponseType.ACCEPT ) {
      cleanup();
      win.functions.remove_function( _custom );
      win.functions.save_custom();
      switch_stack( SwitchStackReason.DELETE, _custom );
    }

    dialog.close();

  }

  /* Called whenever the editor buffer changes */
  private void do_buffer_changed( UndoCustomBuffer buffer ) {
    _undo.set_sensitive( buffer.undoable() );
    _redo.set_sensitive( buffer.redoable() );
    _undo.tooltip_text = buffer.undo_tooltip();
    _redo.tooltip_text = buffer.redo_tooltip();
  }

}

