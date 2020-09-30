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
  private SearchEntry _pattern;
  private Entry       _replace;
  private Button      _replace_btn;
  private Editor      _editor;
  private bool        _tags_exist = false;

  /* Constructor */
  public RegExpr( MainWindow win ) {

    base( "regexpr", _( "Regular Expression" ) );

    _win = win;
    _win.add_widget( "reg-expr", create_widget() );

  }

  /* Creates the search UI */
  private Box create_widget() {

    var box = new Box( Orientation.HORIZONTAL, 0 );

    var grid = new Grid();

    _pattern = new SearchEntry();
    _pattern.placeholder_text = _( "Regular Expression" );
    _pattern.search_changed.connect( do_search );

    var cmb = new MenuButton();
    cmb.label = _( "Character Patterns" );
    cmb.popup = new Gtk.Menu();
    add_character_patterns( cmb );

    var imb = new MenuButton();
    imb.label = _( "Repeat Patterns" );
    imb.popup = new Gtk.Menu();
    add_iteration_patterns( imb );

    var lmb = new MenuButton();
    lmb.label = _( "Location Patterns" );
    lmb.popup = new Gtk.Menu();
    add_location_patterns( lmb );

    var amb = new MenuButton();
    amb.label = _( "Advanced Patterns" );
    amb.popup = new Gtk.Menu();
    add_advanced_patterns( amb );

    _replace = new Entry();
    _replace.placeholder_text = _( "Replace With" );
    _replace.changed.connect( replace_changed );
    _replace.activate.connect(() => {
      _replace_btn.clicked();
    });

    _replace_btn = new Button.with_label( _( "Replace" ) );
    _replace_btn.set_sensitive( false );
    _replace_btn.clicked.connect( do_replace );

    grid.column_spacing     = 5;
    grid.column_homogeneous = true;
    grid.row_spacing        = 5;
    grid.attach( _pattern,     0, 0, 5 );
    grid.attach( _replace,     6, 0, 2 );
    grid.attach( cmb,          0, 1 );
    grid.attach( imb,          1, 1 );
    grid.attach( lmb,          2, 1 );
    grid.attach( amb,          3, 1 );
    grid.attach( _replace_btn, 7, 1 );

    box.pack_start( grid, true, true, 0 );

    return( box );

  }

  private void add_pattern( MenuButton mb, string lbl, string pattern ) {
    var item = new Gtk.MenuItem.with_label( lbl );
    item.activate.connect(() => {
      _pattern.insert_at_cursor( pattern );
      _pattern.grab_focus();
    });
    mb.popup.add( item );
  }

  private void add_character_patterns( MenuButton mb ) {
    add_pattern( mb, _( "Digit" ),          "\\d" );
    add_pattern( mb, _( "Non-Digit" ),      "\\D" );
    add_pattern( mb, _( "New-line" ),       "\\n" );
    add_pattern( mb, _( "Non-New-line" ),   "\\N" );
    add_pattern( mb, _( "Tab" ),            "\\t" );
    add_pattern( mb, _( "Page Break" ),     "\\f" );
    add_pattern( mb, _( "Whitespace" ),     "\\s" );
    add_pattern( mb, _( "Non-Whitespace" ), "\\S" );
    add_pattern( mb, _( "Word" ),           "\\w" );
    add_pattern( mb, _( "Non-Word" ),       "\\W" );
    add_pattern( mb, _( "Any character" ),  "." );
    mb.popup.show_all();
  }

  private void add_location_patterns( MenuButton mb ) {
    add_pattern( mb, _( "Word Boundary" ),     "\\b" );
    add_pattern( mb, _( "Non-Word Boundary" ), "\\B" );
    add_pattern( mb, _( "Start Of Line" ),     "^" );
    add_pattern( mb, _( "End Of Line" ),       "$" );
    mb.popup.show_all();
  }

  private void add_iteration_patterns( MenuButton mb ) {
    add_pattern( mb, _( "0 or 1 Times" ),    "?" );
    add_pattern( mb, _( "0 or More Times" ), "*" );
    add_pattern( mb, _( "1 or More Times" ), "+" );
    mb.popup.show_all();
  }

  private void add_advanced_patterns( MenuButton mb ) {
    add_pattern( mb, _( "Word" ),     "\\w+" );
    add_pattern( mb, _( "Number" ),   "\\d+" );
    add_pattern( mb, _( "URL" ),      """(https?://(?:www\.|(?!www))[^\s\.]+\.\S{2,}|www\.\S+\.\S{2,})""" );
    add_pattern( mb, _( "E-mail" ),   """([a-z0-9_\.-]+)@([\da-z\.-]+)\.([a-z\.]{2,6})""" );
    add_pattern( mb, _( "Date" ),     """[0-3]?[0-9].[0-3]?[0-9].(?:[0-9]{2})?[0-9]{2}""" );
    add_pattern( mb, _( "HTML Tag" ), """<("[^"]*"|'[^']*'|[^'">])*>""" );
    mb.popup.show_all();
  }

  /* Perform search and replacement */
  private void do_search() {

    /* Get the selected ranges and clear them */
    var ranges = new Array<Editor.Position>();
    _editor.get_ranges( ranges );
    _editor.remove_selected();

    stdout.printf( "In do_search, ranges: %u\n", ranges.length );

    /* Clear the tags */
    _tags_exist = false;

    /* If the pattern text is empty, just return now */
    if( _pattern.text == "" ) {
      update_replace_btn_state();
      return;
    }

    Regex     re;
    MatchInfo match;

    try {
      re = new Regex( _pattern.text );
    } catch( RegexError e ) {
      return;
    }

    for( int i=0; i<ranges.length; i++ ) {

      var text        = _editor.get_text( ranges.index( i ).start, ranges.index( i ).end );
      var start_index = ranges.index( i ).start.get_offset();

      while( re.match( text, 0, out match ) ) {
        TextIter start_iter, end_iter;
        int start, end;
        match.fetch_pos( 0, out start, out end );
        _editor.buffer.get_iter_at_offset( out start_iter, start_index + start );
        _editor.buffer.get_iter_at_offset( out end_iter,   start_index + end );
        _editor.add_selected( start_iter, end_iter );
        _tags_exist = true;
        text = text.splice( 0, end );
        start_index += end;
      }

    }

    update_replace_btn_state();

  }

  /* Replace all matches with the replacement text */
  private void do_replace() {

    var ranges = new Array<Editor.Position>();
    var text   = _replace.text;

    _editor.get_ranges( ranges );
    _editor.remove_selected();

    for( int i=((int)ranges.length - 1); i>=0; i-- ) {
      _editor.replace_text( ranges.index( i ).start, ranges.index( i ).end, text );
    }

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
