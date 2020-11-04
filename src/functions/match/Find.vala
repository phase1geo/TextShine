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

public class Find : TextFunction {

  private MainWindow  _win;
  private Entry       _find;
  private CheckButton _case_sensitive;
  private Button      _find_btn;
  private Editor      _editor;
  private UndoItem    _undo_item;

  /* Constructor */
  public Find( MainWindow win, bool custom = false ) {

    base( "find", custom );

    _win = win;
    _win.add_widget( name, create_widget() );

  }

  protected override string get_label0() {
    return( _( "Find" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new Find( _win, custom ) );
  }

  /* Creates the search UI */
  public override Box? create_widget() {

    _find = new Entry();
    _find.placeholder_text = _( "Search Text" );
    _find.changed.connect( do_find );
    _find.activate.connect(() => {
      _find_btn.clicked();
    });
    _find.populate_popup.connect( populate_find_popup );

    _case_sensitive = new CheckButton.with_label( "Case-sensitive" );
    _case_sensitive.toggled.connect( do_find );

    if( custom ) {

      var box = new Box( Orientation.VERTICAL, 0 );
      box.pack_start( _find, false, true, 5 );
      box.pack_start( _case_sensitive, false, false, 5 );

      return( box );

    } else {

      _find_btn = new Button.with_label( _( "Find" ) );
      _find_btn.set_sensitive( false );
      _find_btn.clicked.connect( complete_find );

      var box = new Box( Orientation.HORIZONTAL, 0 );
      box.pack_start( _find,           true,  true,  5 );
      box.pack_start( _case_sensitive, false, false, 5 );
      box.pack_start( _find_btn,       false, false, 5 );

      return( box );

    }

  }

  private void add_insert( Gtk.Menu mnu, string lbl, string str ) {
    var item = new Gtk.MenuItem.with_label( lbl );
    item.activate.connect(() => {
      _find.insert_at_cursor( str );
    });
    mnu.add( item );
  }

  private void populate_find_popup( Gtk.Menu menu ) {
    menu.add( new SeparatorMenuItem() );
    add_insert( menu, _( "Insert New-line" ),   "\n" );
    add_insert( menu, _( "Insert Page Break" ), "\f" );
    menu.show_all();
  }

  private void do_find() {

    _undo_item = new UndoItem( label );

    /* Get the selected ranges and clear them */
    var ranges = new Array<Editor.Position>();
    _editor.get_ranges( ranges, false );
    _editor.remove_selected( _undo_item );

    /* If the pattern text is empty, just return now */
    if( _find.text == "" ) {
      find_changed();
      return;
    }

    var ignore_case = !_case_sensitive.get_active();
    var find_text   = ignore_case ? _find.text.down() : _find.text;
    var find_len    = find_text.char_count();

    for( int i=0; i<ranges.length; i++ ) {

      var text        = _editor.get_text( ranges.index( i ).start, ranges.index( i ).end );
      var start_index = ranges.index( i ).start.get_offset();   // In chars

      if( ignore_case ) {
        text = text.down();
      }

      var start = text.index_of( find_text, 0 );   // In bytes

      while( start != -1 ) {
        TextIter start_iter, end_iter;
        var start_chars = text.slice( 0, start ).char_count();
        _editor.buffer.get_iter_at_offset( out start_iter, start_index + start_chars );
        _editor.buffer.get_iter_at_offset( out end_iter,   start_index + (start_chars + find_len) );
        _editor.add_selected( start_iter, end_iter, _undo_item );
        start = text.index_of( find_text, (start + find_text.length) );
      }

    }

    find_changed();

  }

  public void complete_find() {
    if( _editor.is_selected() ) {
      _editor.undo_buffer.add_item( _undo_item );
    }
    _win.show_widget( "" );
    _editor.grab_focus();
  }

  /* Called when the action button is clicked.  Displays the UI. */
  public override void launch( Editor editor ) {
    _editor = editor;
    _find.text = "";
    _case_sensitive.active = false;
    _win.show_widget( name );
    _find.grab_focus();
  }

  /* Called whenever the find entry contents change */
  private void find_changed() {
    _find_btn.set_sensitive( _find.text != "" );
  }

}
