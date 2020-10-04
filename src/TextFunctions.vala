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

public class TextFunctions {

  private MainWindow          _win;
  private Editor              _editor;
  private Array<Functions>    _functions;
  private Array<TextFunction> _favorites;
  private Array<Category>     _categories;
  private Array<TextChange>   _undo;
  private Array<TextChange>   _redo;
  private SearchEntry         _search;
  private Revealer            _custom;
  private Box                 _box;
  private Box                 _favorite_box;

  /* Constructor */
  public TextFunctions( MainWindow win, Editor editor, Box box ) {

    _win        = win;
    _editor     = editor;

    _functions  = new Array<Functions>();
    _favorites  = new Array<TextFunction>();
    _categories = new Array<Category>();
    _undo       = new Array<TextChange>();
    _redo       = new Array<TextChange>();

    box.set_size_request( 300, 600 );

    /* Create search box */
    _search = new SearchEntry();
    _search.placeholder_text = _( "Search Actions" );
    _search.search_changed.connect( search_functions );

    /* Create scrolled box */
    var cbox = new Box( Orientation.VERTICAL, 0 );
    var sw   = new ScrolledWindow( null, null );
    var vp   = new Viewport( null, null );
    vp.set_size_request( 300, 600 );
    vp.add( cbox );
    sw.add( vp );

    /* Add widgets to box */
    cbox.pack_start( create_favorites(),      false, false, 5 );
    cbox.pack_start( create_case(),           false, false, 5 );
    cbox.pack_start( create_remove(),         false, false, 5 );
    cbox.pack_start( create_replace(),        false, false, 5 );
    cbox.pack_start( create_sort(),           false, false, 5 );
    cbox.pack_start( create_indent(),         false, false, 5 );
    cbox.pack_start( create_search_replace(), false, false, 5 );
    cbox.pack_start( create_custom(),         false, false, 5 );

    box.pack_start( _search, false, false, 10 );
    box.pack_start( sw,      true,  true,  10 );

    _box = cbox;

    /* Load the favorites information */
    load_favorites();

  }

  /* Performs search of all text functions, displaying only those functions which match the search text */
  private void search_functions() {

    var value = _search.text.down();
    var empty = (value == "");

    _custom.reveal_child = empty;

    for( int i=0; i<_categories.length; i++ ) {
      _categories.index( i ).show( empty );
    }

    for( int i=0; i<_functions.length; i++ ) {
      _functions.index( i ).reveal( value );
    }

  }

  /* Creates category returning expander and item box */
  private Expander create_category( string name, string label, out Box item_box ) {

    var setting = "category-" + name + "-expanded";

    /* Create expander */
    var exp = new Expander( "  " + Utils.make_title( label ) );
    exp.use_markup = true;
    exp.expanded   = TextShine.settings.get_boolean( setting );
    exp.activate.connect(() => {
      TextShine.settings.set_boolean( setting, !exp.expanded );
    });

    item_box = new Box( Orientation.VERTICAL, 0 );
    item_box.border_width = 10;

    exp.add( item_box );

    _categories.append_val( new Category( setting, exp ) );

    return( exp );

  }

  /* Adds a function button to the given category item box */
  private void add_function( Box box, Expander? exp, TextFunction function ) {

    var fbox = new Box( Orientation.HORIZONTAL, 5 );

    var button = new Button.with_label( function.label );
    button.halign = Align.START;
    button.set_relief( ReliefStyle.NONE );
    button.clicked.connect(() => {
      _win.show_widget( "" );
      _editor.grab_focus();
      function.launch( _editor );
      _undo.append_val( function.get_change() );
    });

    var grid = new Grid();
    add_settings_button(  grid, function );
    add_favorite_button(  grid, function );
    add_direction_button( grid, button, function );

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

    grid.attach( direction, 0, 0 );

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

    grid.attach( favorite, 1, 0 );

  }

  private void add_settings_button( Grid grid, TextFunction function ) {

    if( !function.settings_available() ) return;

    var settings = new MenuButton();
    settings.image  = new Image.from_icon_name( "view-more-symbolic", IconSize.SMALL_TOOLBAR );
    settings.relief = ReliefStyle.NONE;
    settings.popover   = new Popover( null );
    settings.set_tooltip_text( _( "Settings" ) );

    var box = new Box( Orientation.VERTICAL, 0 );

    function.add_settings( box, 5 );

    settings.popover.add( box );
    box.show_all();

    grid.attach( settings, 2, 0 );

  }

  /*
   Index of favorite in the list.  If the function is not favorited, a value
   of -1 is returned.
  */
  private int favorite_index( TextFunction function ) {
    for( int i=0; i<_favorites.length; i++ ) {
      if( _favorites.index( i ) == function ) {
        return( i );
      }
    }
    return( -1 );
  }

  /* Returns favorited status */
  private bool is_favorite( TextFunction function ) {
    return( favorite_index( function ) != -1 );
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

    _favorites.append_val( function );

    add_function( _favorite_box, null, function );

    _favorite_box.show_all();

    /* Save the favorites changes */
    save_favorites();

  }

  /* Removes the given function from the favorite list */
  private void unfavorite_function( TextFunction function ) {

    var index  = favorite_index( function );
    var reveal = (Revealer)_favorite_box.get_children().nth_data( index );

    _favorites.remove_index( index );

    /* Wait until idle to remove the widget so that we avoid an error */
    Idle.add(() => {
      _favorite_box.remove( reveal );
      return( Source.REMOVE );
    });

    /* Save the favorites changes */
    save_favorites();

  }

  /* Adds the favorites functions */
  private Expander create_favorites() {

    var exp = create_category( "favorites", _( "Favorites" ), out _favorite_box );

    for( int i=0; i<_favorites.length; i++ ) {
      add_function( _favorite_box, null, _favorites.index( i ).copy() );
    }

    return( exp );

  }

  /* Adds the case changing functions */
  private Expander create_case() {
    Box box;
    var exp = create_category( "case", _( "Change Case" ), out box );
    add_function( box, exp, new CaseCamel() );
    add_function( box, exp, new CaseLower() );
    add_function( box, exp, new CaseSentence() );
    add_function( box, exp, new CaseSnake() );
    add_function( box, exp, new CaseTitle() );
    add_function( box, exp, new CaseUpper() );
    return( exp );
  }

  /* Adds string removal functions */
  private Expander create_remove() {
    Box box;
    var exp = create_category( "remove", _( "Remove" ), out box );
    add_function( box, exp, new RemoveBlankLines() );
    add_function( box, exp, new RemoveDuplicateLines() );
    add_function( box, exp, new RemoveLeadingWhitespace() );
    add_function( box, exp, new RemoveTrailingWhitespace() );
    add_function( box, exp, new RemoveLineNumbers() );
    return( exp );
  }

  /* Add replacement functions */
  private Expander create_replace() {
    Box box;
    var exp = create_category( "replace", _( "Replace" ), out box );
    add_function( box, exp, new ReplaceTabsSpaces() );
    add_function( box, exp, new ReplacePeriodsEllipsis() );
    return( exp );
  }

  /* Adds the sorting functions */
  private Expander create_sort() {
    Box box;
    var exp = create_category( "sort", _( "Sort" ), out box );
    add_function( box, exp, new SortLines() );
    add_function( box, exp, new SortReverseChars() );
    return( exp );
  }

  /* Adds the indentation functions */
  private Expander create_indent() {
    Box box;
    var exp = create_category( "indent", _( "Indentation" ), out box );
    add_function( box, exp, new IndentXML() );
    return( exp );
  }

  /* Adds the search and replace functions */
  private Expander create_search_replace() {
    Box box;
    var exp = create_category( "search-replace", _( "Search and Replace" ), out box );
    add_function( box, exp, new RegExpr( _win ) );
    return( exp );
  }

  /* Adds the custom functions */
  private Expander create_custom() {

    Box box;
    var exp = create_category( "custom", _( "Custom" ), out box );

    /* Add button customization option */
    var custom = new Button.with_label( _( "Create custom action" ) );
    custom.halign = Align.START;
    custom.set_relief( ReliefStyle.NONE );
    custom.clicked.connect(() => {
      // TBD - Show customization UI
    });

    _custom = new Revealer();
    _custom.add( custom );
    _custom.border_width = 5;
    _custom.reveal_child = true;

    box.pack_start( _custom, false, false, 0 );

    return( exp );

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

  /* Returns the name of the favorites filename */
  private string get_favorites_file() {
    return( GLib.Path.build_filename( TextShine.get_home_dir(), "favorites.xml" ) );
  }

  /* Save the favorites to the XML file */
  private void save_favorites() {

    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "favorites" );
    root->set_prop( "version", TextShine.version );

    for( int i=0; i<_favorites.length; i++ ) {
      root->add_child( _favorites.index( i ).save() );
    }

    doc->set_root_element( root );
    doc->save_format_file( get_favorites_file(), 1 );

    delete doc;

  }

  /* Load the favorites to the XML file */
  private void load_favorites() {

    Xml.Doc* doc = Xml.Parser.read_file( get_favorites_file(), null, Xml.ParserOption.HUGE );
    if( doc == null ) {
      return;
    }

    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( (it->type == Xml.Node.ELEMENT_NODE) && (it->name == "function") ) {
        var name = it->get_prop( "name" );
        for( int i=0; i<_functions.length; i++ ) {
          if( _functions.index( i ).func.name == name ) {
            var fn = _functions.index( i ).func.copy();
            fn.load( it );
            break;
          }
        }
      }
    }

    delete doc;

  }

}

