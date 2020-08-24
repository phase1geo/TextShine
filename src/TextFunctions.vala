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

public class TextFunctions {

  private Array<TextFunction> _functions;
  private Array<TextChange>   _undo;
  private Array<TextChange>   _redo;

  /* Constructor */
  public TextFunctions( Editor editor, Box box ) {

    _functions = new Array<TextFunction>();
    _undo      = new Array<TextChange>();
    _redo      = new Array<TextChange>();

    box.set_size_request( 250, 600 );

    /* Create scrolled box */
    var cbox = new Box( Orientation.VERTICAL, 0 );
    var sw   = new ScrolledWindow( null, null );
    var vp   = new Viewport( null, null );
    vp.set_size_request( 200, 600 );
    vp.add( cbox );
    sw.add( vp );

    /* Add widgets to box */
    cbox.pack_start( create_case( editor ),           false, false, 5 );
    cbox.pack_start( create_replace( editor ),        false, false, 5 );
    cbox.pack_start( create_sort( editor ),           false, false, 5 );
    cbox.pack_start( create_indent( editor ),         false, false, 5 );
    cbox.pack_start( create_search_replace( editor ), false, false, 5 );

    box.pack_start( sw, true, true, 10 );

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

    item_box = new Box( Orientation.VERTICAL, 10 );
    item_box.border_width = 10;

    exp.add( item_box );

    return( exp );

  }

  /* Adds a function button to the given category item box */
  private void add_function( Box box, Editor editor, TextFunction function ) {

    _functions.append_val( function );

    var button = new Button.with_label( function.label0 );
    button.xalign = (float)0;
    button.set_relief( ReliefStyle.NONE );
    button.clicked.connect(() => {
      function.launch( editor );
      _undo.append_val( function.get_change() );
    });

    box.pack_start( button, false, false, 0 );

  }

  /* Adds sort function */
  private void add_sort_function( Box box, Editor editor, TextFunction function ) {

    _functions.append_val( function );

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
    reveal.add( direction );

    fbox.pack_start( button, false, false, 0 );
    fbox.pack_end(   reveal, false, false, 0 );

    box.pack_start( ebox, false, false, 0 );

  }

  /* Adds a transformation button to the bar */
  private void add_transform_function( Box box, Editor editor, TextFunction function ) {

    _functions.append_val( function );

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
    reveal.add( change );

    fbox.pack_start( button, false, false, 0 );
    fbox.pack_end(   reveal, false, false, 0 );

    box.pack_start( ebox, false, false, 0 );

  }

  /* Adds the case changing functions */
  private Expander create_case( Editor editor ) {
    Box box;
    var exp = create_category( "case", _( "Change Case" ), out box );
    add_function( box, editor, new CaseCamel() );
    add_function( box, editor, new CaseLower() );
    add_function( box, editor, new CaseSentence() );
    add_function( box, editor, new CaseTitle() );
    add_function( box, editor, new CaseUpper() );
    return( exp );
  }

  private Expander create_replace( Editor editor ) {
    Box box;
    var exp = create_category( "replace", _( "Replace" ), out box );
    add_transform_function( box, editor, new ReplaceTabsSpaces() );
    add_transform_function( box, editor, new ReplaceTabsSpaces4() );
    add_transform_function( box, editor, new ReplacePeriodsEllipsis() );
    return( exp );
  }

  /* Adds the sorting functions */
  private Expander create_sort( Editor editor ) {
    Box box;
    var exp = create_category( "sort", _( "Sort" ), out box );
    add_sort_function( box, editor, new SortLines() );
    add_function( box, editor, new SortReverseChars() );
    return( exp );
  }

  /* Adds the indentation functions */
  private Expander create_indent( Editor editor ) {
    Box box;
    var exp = create_category( "indent", _( "Indentation" ), out box );
    add_function( box, editor, new IndentXML() );
    return( exp );
  }

  /* Adds the search and replace functions */
  private Expander create_search_replace( Editor editor ) {
    Box box;
    var exp = create_category( "search-replace", _( "Search and Replace" ), out box );
    add_function( box, editor, new RegExpr() );
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

