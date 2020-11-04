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

public class InsertLineEnd : TextFunction {

  private MainWindow _win;
  private Editor     _editor;
  private Entry      _insert;
  private Button     _insert_btn;

  /* Constructor */
  public InsertLineEnd( MainWindow win, bool custom = false ) {
    base( "insert-line-end", custom );
    _win = win;
    _win.add_widget( "insert-line-end", create_widget() );
  }

  protected override string get_label0() {
    return( _( "Insert At Line End" ) );
  }

  public override TextFunction copy( bool custom ) {
    var fn = new InsertLineEnd( _win, custom );
    return( fn );
  }

  /* Called when the action button is clicked.  Displays the UI. */
  public override void launch( Editor editor ) {
    _editor = editor;
    _insert.text = "";
    _win.show_widget( "insert-line-end" );
    _insert.grab_focus();
  }

  private Box create_widget() {

    _insert = new Entry();
    _insert.placeholder_text = _( "Inserted Text" );
    _insert.changed.connect(() => {
      _insert_btn.set_sensitive( _insert.text != "" );
    });
    _insert.activate.connect(() => {
      _insert_btn.clicked();
    });

    _insert_btn = new Button.with_label( _( "Insert" ) );
    _insert_btn.set_sensitive( false );
    _insert_btn.clicked.connect(() => {
      do_insert();
    });

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.pack_start( _insert,     true,  true,  0 );
    box.pack_start( _insert_btn, false, false, 0 );

    return( box );

  }

  private void do_insert() {

    var ranges      = new Array<Editor.Position>();
    var insert_text = _insert.text;
    var undo_item   = new UndoItem( label );

    _editor.get_ranges( ranges );

    for( int j=0; j<ranges.length; j++ ) {
      var range = ranges.index( j );
      var text  = _editor.get_text( range.start, range.end );
      var lines = text.split( "\n" );
      for( int i=0; i<lines.length; i++ ) {
        lines[i] = lines[i] + insert_text;
      }
      _editor.replace_text( range.start, range.end, string.joinv( "\n", lines ), undo_item );
    }

    /* Add the changes to the undo buffer */
    _editor.undo_buffer.add_item( undo_item );

    _win.show_widget( "" );

  }

}

