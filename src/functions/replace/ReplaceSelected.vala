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
    _replace.populate_popup.connect( populate_replace_popup );

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

  private string replace_date( string value ) {
    var now = new DateTime.now_local();
    return( now.format( value ) );
  }

  private void add_submenu( Gtk.Menu menu, string name, out Gtk.Menu submenu ) {
    submenu = new Gtk.Menu();
    var item = new Gtk.MenuItem.with_label( name );
    item.submenu = submenu;
    menu.add( item );
  }

  private void add_pattern( Gtk.Menu mnu, string lbl, string pattern ) {
    var label = (pattern.length < 5) ? (lbl + " - <b>" + pattern + "</b>") : lbl;
    var item = new Gtk.MenuItem.with_label( label );
    (item.get_child() as Label).use_markup = true;
    item.activate.connect(() => {
      _replace.insert_at_cursor( pattern );
    });
    mnu.add( item );
  }

  private void populate_replace_popup( Gtk.Menu menu ) {

    Gtk.Menu date, time;

    menu.add( new SeparatorMenuItem() );
    add_pattern( menu, _( "Insert New-line" ),   "\n" );
    add_pattern( menu, _( "Insert Page Break" ), "\f" );
    add_pattern( menu, _( "Insert Percent Sign" ), "%%" );

    add_submenu( menu, _( "Insert Date" ), out date );
    add_pattern( date, _( "Standard Date" ), "%x" );
    date.add( new SeparatorMenuItem() );
    add_pattern( date, _( "Day of Month (1-31)" ), "%e" );
    add_pattern( date, _( "Day of Month (01-31)" ), "%d" );
    add_pattern( date, _( "Month (01-12)" ), "%m" );
    add_pattern( date, _( "Year (YYYY)" ), "%Y" );
    add_pattern( date, _( "Year (YY)" ), "%y" );
    add_pattern( date, _( "Day of Week" ), "%A" );
    add_pattern( date, _( "Day of Week (Abbreviated)" ), "%a" );
    add_pattern( date, _( "Name of Month" ), "%B" );
    add_pattern( date, _( "Name of Month (Abbreviated)" ), "%b" );

    add_submenu( menu, _( "Insert Time" ), out time );
    add_pattern( time, _( "Standard Time" ), "%X" );
    time.add( new SeparatorMenuItem() );
    add_pattern( time, _( "Seconds (00-59)" ), "%S" );
    add_pattern( time, _( "Minutes (00-59)" ), "%M" );
    add_pattern( time, _( "Hours (00-12)" ), "%H" );
    add_pattern( time, _( "Hours (00-23)" ), "%I" );
    add_pattern( time, _( "AM/PM" ), "%p" );
    add_pattern( time, _( "Timezone" ), "%Z" );

    menu.show_all();

  }

  /* Replace all matches with the replacement text */
  private void do_replace() {

    var ranges       = new Array<Editor.Position>();
    var replace_text = replace_date( _replace.text );
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
