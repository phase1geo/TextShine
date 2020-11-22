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

public class InsertLineStart : TextFunction {

  private MainWindow _win;
  private Editor     _editor;
  private string     _insert_text = "";

  /* Constructor */
  public InsertLineStart( MainWindow win, bool custom = false ) {

    base( "insert-line-start", custom );

    _win = win;

  }

  protected override string get_label0() {
    return( _( "Insert At Line Start" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new InsertLineStart( _win, custom ) );
  }

  public override void run( Editor editor, UndoItem undo_item ) {
    _editor = editor;
    do_insert( undo_item );
  }

  /* Called when the action button is clicked.  Displays the UI. */
  public override void launch( Editor editor ) {
    _editor = editor;
    if( custom ) {
      do_insert( null );
    } else {
      _win.add_widget( create_widget() );
    }
  }

  private Box create_widget() {

    var insert = new Entry();
    insert.placeholder_text = _( "Inserted Text" );
    insert.populate_popup.connect((mnu) => {
      Utils.populate_insert_popup( mnu, insert );
    });

    if( custom ) {

      insert.text = _insert_text;
      insert.changed.connect(() => {
        _insert_text = insert.text;
        custom_changed();
      });

    } else {

      insert.activate.connect(() => {
        _insert_text = insert.text;
        var undo_item = new UndoItem( label );
        do_insert( undo_item );
        _editor.undo_buffer.add_item( undo_item );
      });
      insert.grab_focus();

    }

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.pack_start( insert, true,  true, 0 );

    return( box );

  }

  public override Box? get_widget() {
    return( create_widget() );
  }

  private void do_insert( UndoItem? undo_item ) {

    var ranges      = new Array<Editor.Position>();
    var insert_text = Utils.replace_date( _insert_text );

    _editor.get_ranges( ranges );

    for( int j=0; j<ranges.length; j++ ) {
      var range = ranges.index( j );
      var text  = _editor.get_text( range.start, range.end );
      var lines = text.split( "\n" );
      for( int i=0; i<lines.length; i++ ) {
        lines[i] = insert_text + lines[i];
      }
      _editor.replace_text( range.start, range.end, string.joinv( "\n", lines ), undo_item );
    }

    _win.remove_widget();

  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "insert", _insert_text );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    string? i = node->get_prop( "insert" );
    if( i != null ) {
      _insert_text = i;
    }
  }

}

