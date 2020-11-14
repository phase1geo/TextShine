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

public class ReplaceSelected : TextFunction {

  private MainWindow _win;
  private Entry      _replace;
  private Button     _replace_btn;
  private Editor     _editor;
  private Box        _wbox;

  /* Constructor */
  public ReplaceSelected( MainWindow win, bool custom = false ) {

    base( "replace-selected", custom );

    _win  = win;
    _wbox = create_widget();

    if( !custom ) {
      _win.add_widget( name, _wbox );
    }

  }

  protected override string get_label0() {
    return( _( "Replace Matched Text" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new ReplaceSelected( _win, custom ) );
  }

  /* Returns true if matched text exists in the editor */
  public override bool launchable( Editor editor ) {
    return( editor.is_selected() );
  }

  /* Creates the search UI */
  private Box create_widget() {

    _replace = new Entry();
    _replace.placeholder_text = _( "Replace With" );
    _replace.populate_popup.connect((mnu) => {
      Utils.populate_insert_popup( mnu, _replace );
    });

    if( custom ) {

      _replace.changed.connect(() => {
        custom_changed();
      });

      var box = new Box( Orientation.VERTICAL, 0 );
      box.pack_start( _replace, false, true, 5 );

      return( box );

    } else {

      _replace.changed.connect( replace_changed );
      _replace.activate.connect(() => {
        _replace_btn.clicked();
      });

      _replace_btn = new Button.with_label( _( "Replace" ) );
      _replace_btn.set_sensitive( false );
      _replace_btn.clicked.connect( do_replace );

      var box = new Box( Orientation.HORIZONTAL, 0 );
      box.pack_start( _replace,     true,  true, 5 );
      box.pack_start( _replace_btn, false, true, 5 );

      return( box );

    }

  }

  public override Box? get_widget() {
    _wbox.unparent();
    return( _wbox );
  }

  /* Replace all matches with the replacement text */
  private void do_replace() {

    var ranges       = new Array<Editor.Position>();
    var replace_text = Utils.replace_date( _replace.text );
    var undo_item    = new UndoItem( label );

    _editor.get_ranges( ranges );

    for( int i=((int)ranges.length - 1); i>=0; i-- ) {
      var range = ranges.index( i );
      _editor.replace_text( range.start, range.end, replace_text, undo_item );
    }

    _editor.undo_buffer.add_item( undo_item );

    /* Hide the widget */
    _win.show_widget( "" );

  }

  /* Called when the action button is clicked.  Displays the UI. */
  public override void launch( Editor editor ) {
    _editor = editor;
    if( custom ) {
      do_replace();
    } else {
      _replace.text = "";
      _win.show_widget( name );
      _replace.grab_focus();
    }
  }

  /* Called whenever the replace entry contents change */
  private void replace_changed() {
    _replace_btn.set_sensitive( _replace.text != "" );
  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "replace", _replace.text );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    string? r = node->get_prop( "replace" );
    if( r != null ) {
      _replace.text = r;
    }
  }

}
