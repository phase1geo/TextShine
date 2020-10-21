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

  /* Constructor */
  public ReplaceSelected( MainWindow win ) {

    base( "replace-selected" );

    _win = win;
    _win.add_widget( name, create_widget() );

  }

  protected override string get_label0() {
    return( _( "Replace Matched Text" ) );
  }

  public override TextFunction copy() {
    return( new ReplaceSelected( _win ) );
  }

  /* Returns true if matched text exists in the editor */
  public override bool launchable( Editor editor ) {
    return( editor.is_selected() );
  }

  /* Creates the search UI */
  private Box create_widget() {

    _replace = new Entry();
    _replace.placeholder_text = _( "Replace With" );
    _replace.changed.connect( replace_changed );
    _replace.activate.connect(() => {
      _replace_btn.clicked();
    });
    _replace.populate_popup.connect( populate_replace_popup );

    _replace_btn = new Button.with_label( _( "Replace" ) );
    _replace_btn.set_sensitive( false );
    _replace_btn.clicked.connect( do_replace );

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.pack_start( _replace,     true,  true, 5 );
    box.pack_start( _replace_btn, false, true, 5 );

    return( box );

  }

  private void add_insert( Gtk.Menu mnu, string lbl, string str ) {
    var item = new Gtk.MenuItem.with_label( lbl );
    item.activate.connect(() => {
      _replace.insert_at_cursor( str );
    });
    mnu.add( item );
  }

  private void populate_replace_popup( Gtk.Menu menu ) {
    menu.add( new SeparatorMenuItem() );
    add_insert( menu, _( "Insert New-line" ),   "\n" );
    add_insert( menu, _( "Insert Page Break" ), "\f" );
    menu.show_all();
  }

  /* Replace all matches with the replacement text */
  private void do_replace() {

    var ranges       = new Array<Editor.Position>();
    var replace_text = _replace.text;
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
    _editor       = editor;
    _replace.text = "";
    _win.show_widget( name );
    _replace.grab_focus();
  }

  /* Called whenever the replace entry contents change */
  private void replace_changed() {
    _replace_btn.set_sensitive( _replace.text != "" );
  }

}