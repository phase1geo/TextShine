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
  private Editor      _editor;
  private UndoItem    _undo_item;
  private string      _find_text = "";
  private bool        _case_sensitive = false;

  /* Constructor */
  public Find( MainWindow win, bool custom = false ) {

    base( "find", custom );

    _win = win;

  }

  protected override string get_label0() {
    return( _( "Find" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new Find( _win, custom ) );
  }

  /* Creates the search UI */
  private Box create_widget() {

    var find = new Entry();
    find.placeholder_text = _( "Search Text" );
    find.populate_popup.connect((menu) => {
      populate_find_popup( menu, find );
    });

    var case_sensitive = new CheckButton.with_label( "Case-sensitive" );

    if( custom ) {

      find.text = _find_text;
      find.changed.connect(() => {
        _find_text = find.text;
        custom_changed();
      });

      case_sensitive.active = _case_sensitive;
      case_sensitive.toggled.connect(() => {
        _case_sensitive = case_sensitive.get_active();
        custom_changed();
      });

    } else {

      find.changed.connect(() => {
        _find_text = find.text;
        _undo_item = new UndoItem( label );
        do_find( _undo_item );
      });
      find.activate.connect( complete_find );
      find.grab_focus();

      case_sensitive.toggled.connect(() => {
        _case_sensitive = case_sensitive.active;
        _undo_item = new UndoItem( label );
        do_find( _undo_item );
      });

    }

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.pack_start( find,           true,  true,  5 );
    box.pack_start( case_sensitive, false, false, 5 );

    return( box );

  }

  public override Box? get_widget() {
    return( create_widget() );
  }

  private void add_insert( Gtk.Menu mnu, Entry entry, string lbl, string str ) {
    var item = new Gtk.MenuItem.with_label( lbl );
    item.activate.connect(() => {
      entry.insert_at_cursor( str );
    });
    mnu.add( item );
  }

  private void populate_find_popup( Gtk.Menu menu, Entry entry ) {
    menu.add( new SeparatorMenuItem() );
    add_insert( menu, entry, _( "Insert New-line" ),   "\n" );
    add_insert( menu, entry, _( "Insert Page Break" ), "\f" );
    menu.show_all();
  }

  private void do_find( UndoItem? undo_item ) {

    /* Get the selected ranges and clear them */
    var ranges = new Array<Editor.Position>();
    _editor.get_ranges( ranges, false );
    _editor.remove_selected( undo_item );

    /* If the pattern text is empty, just return now */
    if( _find_text == "" ) {
      return;
    }

    var ignore_case = !_case_sensitive;
    var find_text   = ignore_case ? _find_text.down() : _find_text;
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
        _editor.add_selected( start_iter, end_iter, undo_item );
        start = text.index_of( find_text, (start + find_text.length) );
      }

    }

  }

  public void complete_find() {
    if( _editor.is_selected() ) {
      _editor.undo_buffer.add_item( _undo_item );
    }
    _win.remove_widget();
    _editor.grab_focus();
  }

  /* Called when the action button is clicked.  Displays the UI. */
  public override void launch( Editor editor ) {
    _editor = editor;
    if( custom ) {
      do_find( null );
    } else {
      _win.add_widget( create_widget() );
    }
  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "find", _find_text );
    node->set_prop( "case-sensitive", _case_sensitive.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    string? f = node->get_prop( "find" );
    if( f != null ) {
      _find_text = f;
    }
    string? c = node->get_prop( "case-sensitive" );
    if( c != null ) {
      _case_sensitive = bool.parse( c );
    }
  }
}
