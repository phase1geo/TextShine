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

    var box = new Box( Orientation.VERTICAL, 0 );

    /* Create the entry box */
    var ebox = new Box( Orientation.HORIZONTAL, 0 );
    ebox.border_width = 5;

    _pattern = new SearchEntry();
    _pattern.placeholder_text = _( "Regular Expression" );
    _pattern.search_changed.connect( do_search );

    _replace = new Entry();
    _replace.placeholder_text = _( "Replace With" );
    _replace.changed.connect( replace_changed );
    _replace.activate.connect(() => {
      _replace_btn.clicked();
    });

    ebox.pack_start( _pattern, true, true, 5 );
    ebox.pack_start( _replace, true, true, 5 );

    /* Create the button box */
    var bbox = new Box( Orientation.HORIZONTAL, 0 );
    bbox.border_width = 5;

    var cmb = new MenuButton();
    cmb.label = _( "Character Patterns" );

    var amb = new MenuButton();
    amb.label = _( "Advanced Patterns" );

    _replace_btn = new Button.with_label( _( "Replace" ) );
    _replace_btn.set_sensitive( false );
    _replace_btn.clicked.connect( do_replace );

    bbox.pack_start( cmb,          false, false, 5 );
    bbox.pack_start( amb,          false, false, 5 );
    bbox.pack_end(   _replace_btn, false, false, 5 );

    box.pack_start( ebox, false, false, 0 );
    box.pack_start( bbox, false, false, 0 );

    return( box );

  }

  /* Perform search and replacement */
  private void do_search() {

    /* Clear the tags */
    _editor.remove_tag( "regex" );
    _tags_exist = false;

    /* If the pattern text is empty, just return now */
    if( _pattern.text == "" ) {
      update_replace_btn_state();
      return;
    }

    Regex     re;
    TextIter  start_iter, end_iter;
    MatchInfo match;
    var       text = _editor.get_current_text();

    _editor.get_range( out start_iter, out end_iter );
    var start_index = start_iter.get_offset();

    try {
      re = new Regex( _pattern.text );
    } catch( RegexError e ) {
      return;
    }

    while( re.match( text, 0, out match ) ) {
      int start, end;
      match.fetch_pos( 0, out start, out end );
      _editor.buffer.get_iter_at_offset( out start_iter, start_index + start );
      _editor.buffer.get_iter_at_offset( out end_iter,   start_index + end );
      _editor.add_tag( "regex", start_iter, end_iter );
      _tags_exist = true;
      text = text.splice( 0, end );
      start_index += end;
    }

    update_replace_btn_state();

  }

  /* Replace all matches with the replacement text */
  private void do_replace() {

    TextIter iter;
    var tag  = _editor.buffer.tag_table.lookup( "regex" );
    var text = _replace.text;

    _editor.buffer.get_start_iter( out iter );

    while( iter.forward_to_tag_toggle( tag ) ) {
      if( iter.starts_tag( tag ) ) {
        var end = iter.copy();
        end.forward_to_tag_toggle( tag );
        _editor.buffer.delete( ref iter, ref end );
        _editor.buffer.insert( ref iter, text, text.length );
      }
    }

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
