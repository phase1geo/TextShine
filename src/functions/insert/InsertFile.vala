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

public class InsertFile : TextFunction {

  private MainWindow _win;
  private string     _filename = "";

  /* Constructor */
  public InsertFile( MainWindow win, bool custom = false ) {
    base( "insert-file", custom );
    _win = win;
  }

  public override string get_description() {
    return( _( "Inserts the contents of a file." ) );
  }

  protected override string get_label0() {
    return( _( "Insert File Text" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new InsertFile( _win, custom ) );
  }

  private string? get_file() {
    var dialog = new FileChooserNative( _( "Insert File" ), _win, FileChooserAction.OPEN, _( "Open" ), _( "Cancel" ) );
    if( dialog.run() == ResponseType.ACCEPT ) {
      return( dialog.get_filename() );
    }
    return( null );
  }

  private string? get_file_contents( string filename ) {

    var file = File.new_for_path( filename );

    try {
      uint8[] contents;
    		file.load_contents( null, out contents, null );
    		return( (string)contents );
    } catch( Error e ) {
      _win.show_error( e.message );
    }

    return( null );

  }

  public override void run( Editor editor, UndoItem undo_item ) {
    insert_file( editor, undo_item );
  }

  public override void launch( Editor editor ) {

    if( custom ) {

      insert_file( editor, null );

    } else {

      _filename = get_file();
      if( _filename == null ) return;

      var undo_item = new UndoItem( label );
      insert_file( editor, undo_item );
      editor.undo_buffer.add_item( undo_item );

    }

  }

  private Box create_widget( Editor editor ) {

    var chooser = new FileChooserButton( _( "Insert File" ), FileChooserAction.OPEN );
    chooser.file_set.connect(() => {
      _filename = chooser.get_filename();
    });
    chooser.set_filename( _filename );

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.pack_start( chooser, true, true, 0 );

    return( box );

  }

  public override Box? get_widget( Editor editor ) {
    return( create_widget( editor ) );
  }

  private void insert_file( Editor editor, UndoItem? undo_item ) {

    var contents = get_file_contents( _filename );
    if( contents == null ) return;

    TextIter cursor;

    editor.buffer.get_iter_at_mark( out cursor, editor.buffer.get_insert() );
    editor.replace_text( cursor, cursor, contents, undo_item );

  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "filename", _filename );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    string? f = node->get_prop( "filename" );
    if( f != null ) {
      _filename = f;
    }

  }

}

