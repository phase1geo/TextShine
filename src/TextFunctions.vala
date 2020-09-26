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
    var contains = _func.label0.down().contains( value );
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

  private Array<Functions>  _functions;
  private Array<Category>   _categories;
  private Array<TextChange> _undo;
  private Array<TextChange> _redo;
  private SearchEntry       _search;
  private Revealer          _custom;
  private Box               _box;

  /* Constructor */
  public TextFunctions( MainWindow win, Editor editor, Box box ) {

    _functions  = new Array<Functions>();
    _categories = new Array<Category>();
    _undo       = new Array<TextChange>();
    _redo       = new Array<TextChange>();

    box.set_size_request( 250, 600 );

    /* Create search box */
    _search = new SearchEntry();
    _search.placeholder_text = _( "Search Actions" );
    _search.search_changed.connect( search_functions );

    /* Create scrolled box */
    var cbox = new Box( Orientation.VERTICAL, 0 );
    var sw   = new ScrolledWindow( null, null );
    var vp   = new Viewport( null, null );
    vp.set_size_request( 200, 600 );
    vp.add( cbox );
    sw.add( vp );

    /* Add widgets to box */
    cbox.pack_start( create_custom( editor ),              false, false, 5 );
    cbox.pack_start( create_case( editor ),                false, false, 5 );
    cbox.pack_start( create_remove( editor ),              false, false, 5 );
    cbox.pack_start( create_replace( editor ),             false, false, 5 );
    cbox.pack_start( create_sort( editor ),                false, false, 5 );
    cbox.pack_start( create_indent( editor ),              false, false, 5 );
    cbox.pack_start( create_search_replace( editor, win ), false, false, 5 );

    box.pack_start( _search, false, false, 10 );
    box.pack_start( sw,      true,  true,  10 );

    _box = cbox;

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
  private void add_function( Box box, Expander exp, Editor editor, TextFunction function ) {

    var button = new Button.with_label( function.label0 );
    button.xalign = (float)0;
    button.set_relief( ReliefStyle.NONE );
    button.clicked.connect(() => {
      function.launch( editor );
      _undo.append_val( function.get_change() );
      editor.grab_focus();
    });

    var revealer = new Revealer();
    revealer.add( button );
    revealer.border_width = 5;
    revealer.reveal_child = true;

    box.pack_start( revealer, false, false, 0 );

    _functions.append_val( new Functions( function, revealer, exp ) );

  }

  /* Adds sort function */
  private void add_sort_function( Box box, Expander exp, Editor editor, TextFunction function ) {

    var reveal = new Revealer();
    var ebox   = new EventBox();
    ebox.enter_notify_event.connect((e) => {
      reveal.reveal_child = true;
      return( false );
    });
    ebox.leave_notify_event.connect((e) => {
      if( e.detail != NotifyType.INFERIOR ) {
        reveal.reveal_child = false;
      }
      return( false );
    });
    var fbox   = new Box( Orientation.HORIZONTAL, 0 );
    ebox.add( fbox );
    var button = new Button.with_label( function.label0 );
    button.xalign = (float)0;
    button.set_relief( ReliefStyle.NONE );
    button.clicked.connect(() => {
      function.launch( editor );
      _undo.append_val( function.get_change() );
      editor.grab_focus();
    });
    var direction = new Button.from_icon_name( "object-flip-vertical-symbolic", IconSize.SMALL_TOOLBAR );
    direction.set_tooltip_text( _( "Switch Direction" ) );
    direction.clicked.connect(() => {
      if( function.direction == FunctionDirection.TOP_DOWN ) {
        function.direction = FunctionDirection.BOTTOM_UP;
        button.label       = function.label1;
      } else {
        function.direction = FunctionDirection.TOP_DOWN;
        button.label       = function.label0;
      }
    });

    reveal.transition_type = RevealerTransitionType.NONE;
    reveal.add( direction );

    fbox.pack_start( button, false, false, 0 );
    fbox.pack_end(   reveal, false, false, 0 );

    var revealer = new Revealer();
    revealer.add( ebox );
    revealer.border_width = 5;
    revealer.reveal_child = true;

    box.pack_start( revealer, false, false, 0 );

    _functions.append_val( new Functions( function, revealer, exp ) );

  }

  /* Adds a transformation button to the bar */
  private void add_transform_function( Box box, Expander exp, Editor editor, TextFunction function ) {

    var reveal = new Revealer();
    var ebox   = new EventBox();
    ebox.enter_notify_event.connect((e) => {
      reveal.reveal_child = true;
      return( false );
    });
    ebox.leave_notify_event.connect((e) => {
      if( e.detail != NotifyType.INFERIOR ) {
        reveal.reveal_child = false;
      }
      return( false );
    });
    var fbox   = new Box( Orientation.HORIZONTAL, 0 );
    ebox.add( fbox );
    var button = new Button.with_label( function.label0 );
    button.xalign = (float)0;
    button.set_relief( ReliefStyle.NONE );
    button.clicked.connect(() => {
      function.launch( editor );
      _undo.append_val( function.get_change() );
      editor.grab_focus();
    });
    var change = new Button.from_icon_name( "object-flip-horizontal-symbolic", IconSize.SMALL_TOOLBAR );
    change.set_tooltip_text( _( "Switch Order" ) );
    change.clicked.connect(() => {
      if( function.direction == FunctionDirection.LEFT_TO_RIGHT ) {
        button.label       = function.label1;
        function.direction = FunctionDirection.RIGHT_TO_LEFT;
      } else {
        button.label       = function.label0;
        function.direction = FunctionDirection.LEFT_TO_RIGHT;
      }
    });

    reveal.transition_type = RevealerTransitionType.NONE;
    reveal.add( change );

    fbox.pack_start( button, false, false, 0 );
    fbox.pack_end(   reveal, false, false, 0 );

    var revealer = new Revealer();
    revealer.add( ebox );
    revealer.border_width = 5;
    revealer.reveal_child = true;

    box.pack_start( revealer, false, false, 0 );

    _functions.append_val( new Functions( function, revealer, exp ) );

  }

  private Expander create_custom( Editor editor ) {

    Box box;
    var exp = create_category( "custom", _( "Custom" ), out box );

    /* Add button customization option */
    var custom = new Button.with_label( _( "Create custom action" ) );
    custom.xalign = (float)0;
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

  /* Adds the case changing functions */
  private Expander create_case( Editor editor ) {
    Box box;
    var exp = create_category( "case", _( "Change Case" ), out box );
    add_function( box, exp, editor, new CaseCamel() );
    add_function( box, exp, editor, new CaseLower() );
    add_function( box, exp, editor, new CaseSentence() );
    add_function( box, exp, editor, new CaseSnake() );
    add_function( box, exp, editor, new CaseTitle() );
    add_function( box, exp, editor, new CaseUpper() );
    return( exp );
  }

  /* Adds string removal functions */
  private Expander create_remove( Editor editor ) {
    Box box;
    var exp = create_category( "remove", _( "Remove" ), out box );
    add_function( box, exp, editor, new RemoveBlankLines() );
    add_function( box, exp, editor, new RemoveDuplicateLines() );
    add_function( box, exp, editor, new RemoveLeadingWhitespace() );
    add_function( box, exp, editor, new RemoveTrailingWhitespace() );
    add_function( box, exp, editor, new RemoveLineNumbers() );
    return( exp );
  }

  /* Add replacement functions */
  private Expander create_replace( Editor editor ) {
    Box box;
    var exp = create_category( "replace", _( "Replace" ), out box );
    add_transform_function( box, exp, editor, new ReplaceTabsSpaces() );
    add_transform_function( box, exp, editor, new ReplaceTabsSpaces4() );
    add_transform_function( box, exp, editor, new ReplacePeriodsEllipsis() );
    return( exp );
  }

  /* Adds the sorting functions */
  private Expander create_sort( Editor editor ) {
    Box box;
    var exp = create_category( "sort", _( "Sort" ), out box );
    add_sort_function( box, exp, editor, new SortLines() );
    add_function( box, exp, editor, new SortReverseChars() );
    return( exp );
  }

  /* Adds the indentation functions */
  private Expander create_indent( Editor editor ) {
    Box box;
    var exp = create_category( "indent", _( "Indentation" ), out box );
    add_function( box, exp, editor, new IndentXML() );
    return( exp );
  }

  /* Adds the search and replace functions */
  private Expander create_search_replace( Editor editor, MainWindow win ) {
    Box box;
    var exp = create_category( "search-replace", _( "Search and Replace" ), out box );
    add_function( box, exp, editor, new RegExpr( win ) );
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

}

