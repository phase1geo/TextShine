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

public class RegExpr : TextFunction {

  private MainWindow  _win;
  private Regex       _re;
  private SearchEntry _pattern;
  private Entry       _replace;
  private Button      _find_btn;
  private Button      _replace_btn;
  private Editor      _editor;
  private bool        _tags_exist = false;
  private UndoItem    _undo_item;

  /* Constructor */
  public RegExpr( MainWindow win ) {

    base( "regexpr" );

    _re  = null;
    _win = win;
    _win.add_widget( "reg-expr", create_widget() );

  }

  protected override string get_label0() {
    return( _( "Regular Expression" ) );
  }

  public override TextFunction copy() {
    return( new RegExpr( _win ) );
  }

  /* Creates the search UI */
  private Box create_widget() {

    _pattern = new SearchEntry();
    _pattern.placeholder_text = _( "Regular Expression" );
    _pattern.search_changed.connect( do_search );
    _pattern.activate.connect( do_search );
    _pattern.populate_popup.connect( populate_pattern_popup );

    _replace = new Entry();
    _replace.placeholder_text = _( "Replace With" );
    _replace.changed.connect( replace_changed );
    _replace.activate.connect(() => {
      _replace_btn.clicked();
    });
    _replace.populate_popup.connect( populate_replace_popup );

    var ebox = new Box( Orientation.VERTICAL, 0 );
    ebox.pack_start( _pattern, false, true, 5 );
    ebox.pack_start( _replace, false, true, 5 );

    _find_btn = new Button.with_label( _( "End Search" ) );
    _find_btn.set_sensitive( false );
    _find_btn.clicked.connect( end_search );

    _replace_btn = new Button.with_label( _( "Replace" ) );
    _replace_btn.set_sensitive( false );
    _replace_btn.clicked.connect( do_replace );

    var bbox = new Box( Orientation.VERTICAL, 0 );
    bbox.pack_start( _find_btn,    false, true, 5 );
    bbox.pack_start( _replace_btn, false, true, 5 );

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.pack_start( ebox, true,  true,  0 );
    box.pack_start( bbox, false, false, 0 );

    return( box );

  }

  private void populate_pattern_popup( Gtk.Menu menu ) {
    menu.add( new SeparatorMenuItem() );
    add_character_patterns( menu );
    add_iteration_patterns( menu );
    add_location_patterns( menu );
    add_advanced_patterns( menu );
    menu.show_all();
  }

  private void populate_replace_popup( Gtk.Menu menu ) {
    if( _tags_exist ) {
      menu.add( new SeparatorMenuItem() );
      add_case_patterns( menu );
      add_position_patterns( menu );
      menu.show_all();
    }
  }

  private void add_submenu( Gtk.Menu menu, string name, out Gtk.Menu submenu ) {
    submenu = new Gtk.Menu();
    var item = new Gtk.MenuItem.with_label( name );
    item.submenu = submenu;
    menu.add( item );
  }

  private void add_pattern( Gtk.Menu mnu, string lbl, string pattern ) {
    var label = (pattern.length < 5) ? (lbl + " - <b>" + pattern + "</b>") : lbl;
    var item = new Gtk.MenuItem.with_label( label );
    (item.get_child() as Label).use_markup = true;
    item.activate.connect(() => {
      _pattern.insert_at_cursor( pattern );
    });
    mnu.add( item );
  }

  private void add_character_patterns( Gtk.Menu menu ) {
    Gtk.Menu submenu;
    add_submenu( menu, _( "Character Patterns" ), out submenu );
    add_pattern( submenu, _( "Digit" ),          """\d""" );
    add_pattern( submenu, _( "Non-Digit" ),      """\D""" );
    add_pattern( submenu, _( "New-line" ),       """\n""" );
    add_pattern( submenu, _( "Non-New-line" ),   """\N""" );
    add_pattern( submenu, _( "Tab" ),            """\t""" );
    add_pattern( submenu, _( "Page Break" ),     """\f""" );
    add_pattern( submenu, _( "Whitespace" ),     """\s""" );
    add_pattern( submenu, _( "Non-Whitespace" ), """\S""" );
    add_pattern( submenu, _( "Word" ),           """\w""" );
    add_pattern( submenu, _( "Non-Word" ),       """\W""" );
    add_pattern( submenu, _( "Any character" ),  "." );
  }

  private void add_location_patterns( Gtk.Menu menu ) {
    Gtk.Menu submenu;
    add_submenu( menu, _( "Location Patterns" ), out submenu );
    add_pattern( submenu, _( "Word Boundary" ),     """\b""" );
    add_pattern( submenu, _( "Non-Word Boundary" ), """\B""" );
    add_pattern( submenu, _( "Start Of Line" ),     "^" );
    add_pattern( submenu, _( "End Of Line" ),       "$" );
  }

  private void add_iteration_patterns( Gtk.Menu menu ) {
    Gtk.Menu submenu;
    add_submenu( menu, _( "Iteration Patterns" ), out submenu );
    add_pattern( submenu, _( "0 or 1 Times" ),    "?" );
    add_pattern( submenu, _( "0 or More Times" ), "*" );
    add_pattern( submenu, _( "1 or More Times" ), "+" );
  }

  private void add_advanced_patterns( Gtk.Menu menu ) {
    Gtk.Menu submenu;
    add_submenu( menu, _( "Advanced Patterns" ), out submenu );
    add_pattern( submenu, _( "Word" ),         """\w+""" );
    add_pattern( submenu, _( "Number" ),       """\d+""" );
    add_pattern( submenu, _( "URL" ),          """(https?://(?:www\.|(?!www))[^\s\.]+\.\S{2,}|www\.\S+\.\S{2,})""" );
    add_pattern( submenu, _( "E-mail" ),       """([a-z0-9_\.-]+)@([\da-z\.-]+)\.([a-z\.]{2,6})""" );
    add_pattern( submenu, _( "Date" ),         """[0-3]?[0-9].[0-3]?[0-9].(?:[0-9]{2})?[0-9]{2}""" );
    add_pattern( submenu, _( "Phone Number" ), """\d?(\s?|-?|\+?|\.?)((\(\d{1,4}\))|(\d{1,3})|\s?)(\s?|-?|\.?)((\(\d{1,3}\))|(\d{1,3})|\s?)(\s?|-?|\.?)((\(\d{1,3}\))|(\d{1,3})|\s?)(\s?|-?|\.?)\d{3}(-|\.|\s)\d{4}""" );
    add_pattern( submenu, _( "HTML Tag" ),     """<("[^"]*"|'[^']*'|[^'">])*>""" );
  }

  private void add_replace( Gtk.Menu mnu, string lbl, string pattern ) {
    var label = (pattern.length < 5) ? (lbl + " - <b>" + pattern + "</b>") : lbl;
    var item = new Gtk.MenuItem.with_label( label );
    (item.get_child() as Label).use_markup = true;
    item.activate.connect(() => {
      _replace.insert_at_cursor( pattern );
    });
    mnu.add( item );
  }

  private void add_case_patterns( Gtk.Menu menu ) {
    Gtk.Menu submenu;
    add_submenu( menu, _( "Case Patterns" ), out submenu );
    add_replace( submenu, _( "Uppercase Next Character" ), """\u""" );
    add_replace( submenu, _( "Lowercase Next Character" ), """\l""" );
    add_replace( submenu, _( "Start Uppercase Change" ),   """\U""" );
    add_replace( submenu, _( "Start Lowercase Change" ),   """\L""" );
    add_replace( submenu, _( "End Case Change" ),          """\E""" );
  }

  private void add_position_patterns( Gtk.Menu menu ) {
    var captured = (_re.get_capture_count() > 9) ? 9 : _re.get_capture_count();
    if( captured == 0 ) return;
    Gtk.Menu submenu;
    add_submenu( menu, _( "Positional Patterns" ), out submenu );
    add_replace( submenu, _( "Matched Pattern" ), """\0""" );
    for( int i=0; i<captured; i++ ) {
      add_replace( submenu, _( "Subpattern %d" ).printf( i + 1 ), ( """\%d""" ).printf( i + 1 ) );
    }
  }

  /* Perform search and replacement */
  private void do_search() {

    _undo_item = new UndoItem( label );

    /* Get the selected ranges and clear them */
    var ranges = new Array<Editor.Position>();
    _editor.get_ranges( ranges, false );
    _editor.remove_selected( _undo_item );

    /* Clear the tags */
    _tags_exist = false;

    /* If the pattern text is empty, just return now */
    if( _pattern.text == "" ) {
      update_replace_btn_state();
      return;
    }

    MatchInfo match;

    try {
      _re = new Regex( _pattern.text );
    } catch( RegexError e ) {
      return;
    }

    for( int i=0; i<ranges.length; i++ ) {

      var text        = _editor.get_text( ranges.index( i ).start, ranges.index( i ).end );
      var start_index = ranges.index( i ).start.get_offset();

      while( _re.match( text, 0, out match ) ) {
        TextIter start_iter, end_iter;
        int start, end;
        match.fetch_pos( 0, out start, out end );
        _editor.buffer.get_iter_at_offset( out start_iter, start_index + start );
        _editor.buffer.get_iter_at_offset( out end_iter,   start_index + end );
        _editor.add_selected( start_iter, end_iter, _undo_item );
        _tags_exist = true;
        text = text.splice( 0, end );
        start_index += end;
      }

    }

    update_replace_btn_state();

  }

  /* Finalizes the search operation (TBD) */
  private void end_search() {

    /* Add the undo_item to the buffer */
    _editor.undo_buffer.add_item( _undo_item );

    /* Close the error display */
    _win.close_error();

    /* Hide the widget */
    _win.show_widget( "" );

  }

  /* Replace all matches with the replacement text */
  private void do_replace() {

    var ranges       = new Array<Editor.Position>();
    var replace_text = _replace.text;

    _editor.get_ranges( ranges );
    // _editor.remove_selected();

    try {

      var re        = new Regex( _pattern.text );
      var undo_item = new UndoItem( label );

      for( int i=((int)ranges.length - 1); i>=0; i-- ) {
        var range    = ranges.index( i );
        var text     = _editor.get_text( range.start, range.end );
        var new_text = re.replace( text, text.length, 0, replace_text );
        _editor.replace_text( range.start, range.end, new_text, undo_item );
      }

      _editor.undo_buffer.add_item( undo_item );

    } catch( RegexError e ) {
      _win.show_error( e.message );
      return;
    }

    /* Hide the error message */
    _win.close_error();

    /* Hide the widget */
    _win.show_widget( "" );

  }

  /* Called when the action button is clicked.  Displays the UI. */
  public override void launch( Editor editor ) {
    _editor = editor;
    _pattern.text = "";
    _replace.text = "";
    _win.show_widget( "reg-expr" );
    _pattern.grab_focus();
  }

  private void update_replace_btn_state() {
    _replace_btn.set_sensitive( _tags_exist && (_replace.text != "") );
  }

  /* Called whenever the replace entry contents change */
  private void replace_changed() {
    update_replace_btn_state();
  }

}
