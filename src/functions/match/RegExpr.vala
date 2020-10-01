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

    var box = new Box( Orientation.HORIZONTAL, 5 );

    var ebox = new Box( Orientation.VERTICAL, 0 );

    _pattern = new SearchEntry();
    _pattern.placeholder_text = _( "Regular Expression" );
    _pattern.search_changed.connect( do_search );

    _replace = new Entry();
    _replace.placeholder_text = _( "Replace With" );
    _replace.changed.connect( replace_changed );
    _replace.activate.connect(() => {
      _replace_btn.clicked();
    });

    ebox.pack_start( _pattern, false, true, 5 );
    ebox.pack_start( _replace, false, true, 5 );

    var bbox = new Box( Orientation.VERTICAL, 0 );

    var mb = new MenuButton();
    mb.label = _( "Insert Patterns" );
    mb.popup = new Gtk.Menu();
    add_character_patterns( mb );
    add_iteration_patterns( mb );
    add_location_patterns( mb );
    add_advanced_patterns( mb );
    mb.popup.show_all();

    _replace_btn = new Button.with_label( _( "Replace" ) );
    _replace_btn.set_sensitive( false );
    _replace_btn.clicked.connect( do_replace );

    bbox.pack_start( mb, false, true, 5 );
    bbox.pack_start( _replace_btn, false, true, 5 );

    box.pack_start( ebox, true,  true,  0 );
    box.pack_start( bbox, false, false, 0 );

    return( box );

  }

  private void add_pattern_submenu( MenuButton mb, string name, out Gtk.Menu mnu ) {
    mnu = new Gtk.Menu();
    var item = new Gtk.MenuItem.with_label( name );
    item.submenu = mnu;
    mb.popup.add( item );
  }

  private void add_pattern( Gtk.Menu mnu, string lbl, string pattern ) {
    var label = (pattern.length < 5) ? (lbl + " - <b>" + pattern + "</b>") : lbl;
    var item = new Gtk.MenuItem.with_label( label );
    (item.get_child() as Label).use_markup = true;
    item.activate.connect(() => {
      _pattern.insert_at_cursor( pattern );
      _pattern.grab_focus();
    });
    mnu.add( item );
  }

  private void add_character_patterns( MenuButton mb ) {
    Gtk.Menu mnu;
    add_pattern_submenu( mb, _( "Character Patterns" ), out mnu );
    add_pattern( mnu, _( "Digit" ),          "\\d" );
    add_pattern( mnu, _( "Non-Digit" ),      "\\D" );
    add_pattern( mnu, _( "New-line" ),       "\\n" );
    add_pattern( mnu, _( "Non-New-line" ),   "\\N" );
    add_pattern( mnu, _( "Tab" ),            "\\t" );
    add_pattern( mnu, _( "Page Break" ),     "\\f" );
    add_pattern( mnu, _( "Whitespace" ),     "\\s" );
    add_pattern( mnu, _( "Non-Whitespace" ), "\\S" );
    add_pattern( mnu, _( "Word" ),           "\\w" );
    add_pattern( mnu, _( "Non-Word" ),       "\\W" );
    add_pattern( mnu, _( "Any character" ),  "." );
  }

  private void add_location_patterns( MenuButton mb ) {
    Gtk.Menu mnu;
    add_pattern_submenu( mb, _( "Location Patterns" ), out mnu );
    add_pattern( mnu, _( "Word Boundary" ),     "\\b" );
    add_pattern( mnu, _( "Non-Word Boundary" ), "\\B" );
    add_pattern( mnu, _( "Start Of Line" ),     "^" );
    add_pattern( mnu, _( "End Of Line" ),       "$" );
  }

  private void add_iteration_patterns( MenuButton mb ) {
    Gtk.Menu mnu;
    add_pattern_submenu( mb, _( "Iteration Patterns" ), out mnu );
    add_pattern( mnu, _( "0 or 1 Times" ),    "?" );
    add_pattern( mnu, _( "0 or More Times" ), "*" );
    add_pattern( mnu, _( "1 or More Times" ), "+" );
  }

  private void add_advanced_patterns( MenuButton mb ) {
    Gtk.Menu mnu;
    add_pattern_submenu( mb, _( "Advanced Patterns" ), out mnu );
    add_pattern( mnu, _( "Word" ),         "\\w+" );
    add_pattern( mnu, _( "Number" ),       "\\d+" );
    add_pattern( mnu, _( "URL" ),          """(https?://(?:www\.|(?!www))[^\s\.]+\.\S{2,}|www\.\S+\.\S{2,})""" );
    add_pattern( mnu, _( "E-mail" ),       """([a-z0-9_\.-]+)@([\da-z\.-]+)\.([a-z\.]{2,6})""" );
    add_pattern( mnu, _( "Date" ),         """[0-3]?[0-9].[0-3]?[0-9].(?:[0-9]{2})?[0-9]{2}""" );
    add_pattern( mnu, _( "Phone Number" ), """\d?(\s?|-?|\+?|\.?)((\(\d{1,4}\))|(\d{1,3})|\s?)(\s?|-?|\.?)((\(\d{1,3}\))|(\d{1,3})|\s?)(\s?|-?|\.?)((\(\d{1,3}\))|(\d{1,3})|\s?)(\s?|-?|\.?)\d{3}(-|\.|\s)\d{4}""" );
    add_pattern( mnu, _( "HTML Tag" ),     """<("[^"]*"|'[^']*'|[^'">])*>""" );
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
