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

public class InsertURL : TextFunction {

  private MainWindow _win;
  private string     _url = "";

  /* Constructor */
  public InsertURL( MainWindow win, bool custom = false ) {
    base( "insert-url", custom );
    _win = win;
  }

  protected override string get_label0() {
    return( _( "Insert URL Content" ) );
  }

  public override TextFunction copy( bool custom ) {
    var tf = new InsertURL( _win, custom );
    tf._url = _url;
    return( tf );
  }

  public override bool matches( TextFunction function ) {
    if( base.matches( function ) ) {
      var func = (InsertURL)function;
      return( _url == func._url );
    }
    return( false );
  }

  private string? get_url_contents( string url ) {

    var file = File.new_for_uri( url );

    try {
      uint8[] contents;
    	file.load_contents( null, out contents, null );
      return( (string)contents );
    } catch( Error e ) {
      stdout.printf( "Unable to get URL contents\n" );
      _win.show_error( e.message );
    }

    return( null );

  }

  public override void run( Editor editor, UndoItem undo_item ) {
    insert_url( editor, undo_item );
  }

  public override void launch( Editor editor ) {
    if( custom ) {
      insert_url( editor, null );
    } else {
      Box box;
      Entry entry;
      create_widget( editor, out box, out entry );
      _win.add_widget( box, entry );
    }
  }

  private Box create_widget( Editor editor, out Box box, out Entry focus ) {

    var entry = new Entry() {
      halign = Align.FILL,
      hexpand = true,
      placeholder_text = _( "Enter URL" ),
      tooltip_text = _( "Enter URL" )
    };

    if( custom ) {

      entry.text = _url;
      entry.changed.connect(() => {
        _url = entry.text;
        custom_changed();
      });

    } else {

      entry.activate.connect(() => {
        _url = entry.text;
        var undo_item = new UndoItem( label );
        insert_url( editor, undo_item );
        editor.undo_buffer.add_item( undo_item );
        _win.remove_widget();
      });

      handle_widget_escape( entry, _win );

      focus = entry;

    }

    box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( entry );

    return( box );

  }

  public override Box? get_widget( Editor editor ) {
    Box   box;
    Entry entry;
    create_widget( editor, out box, out entry );
    return( box );
  }

  private void insert_url( Editor editor, UndoItem? undo_item ) {

    var contents = get_url_contents( _url );
    if( contents == null ) return;

    TextIter cursor;

    editor.buffer.get_iter_at_mark( out cursor, editor.buffer.get_insert() );
    editor.replace_text( cursor, cursor, contents, undo_item );

  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "url", _url );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    string? u = node->get_prop( "url" );
    if( u != null ) {
      _url = u;
    }

  }

}

