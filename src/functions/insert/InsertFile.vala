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

  /* Constructor */
  public InsertFile( MainWindow win ) {
    base( "insert-file" );
    _win = win;
  }

  protected override string get_label0() {
    return( _( "Insert File Text" ) );
  }

  public override TextFunction copy() {
    var fn = new InsertFile( _win );
    return( fn );
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

  public override void launch( Editor editor ) {

    var filename = get_file();
    if( filename == null ) return;

    var contents = get_file_contents( filename );
    if( contents == null ) return;

    TextIter cursor;
    var undo_item = new UndoItem( label );

    editor.buffer.get_iter_at_mark( out cursor, editor.buffer.get_insert() );
    editor.replace_text( cursor, cursor, contents, undo_item );
    editor.undo_buffer.add_item( undo_item );

  }

}

