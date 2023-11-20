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
  private string     _replace_text = "";
  private Entry      _replace;

  private const GLib.ActionEntry action_entries[] = {
    { "action_insert_replace", action_insert_replace, "s" },
  };

  /* Constructor */
  public ReplaceSelected( MainWindow win, bool custom = false ) {

    base( "replace-selected", custom );

    _win = win;

  }

  protected override string get_label0() {
    return( _( "Replace Matched Text" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new ReplaceSelected( _win, custom ) );
  }

  public override bool matches( TextFunction function ) {
    return( base.matches( function ) && (_replace_text == ((ReplaceSelected)function)._replace_text) );
  }

  /* Returns true if matched text exists in the editor */
  public override bool launchable( Editor editor ) {
    return( editor.is_selected() );
  }

  /* Inserts the given string at the current insertion point */
  private void action_insert_replace( SimpleAction action, Variant? variant ) {
    var str = variant.get_string();
    if( str != null ) {
      var pos = _replace.cursor_position;
      _replace.do_insert_text( str, str.length, ref pos );
    }
  }

  /* Creates the search UI */
  private void create_widget( Editor editor, out Box box, out Entry entry ) {

    _replace = new Entry() {
      halign = Align.FILL,
      hexpand = true,
      placeholder_text = _( "Replace With" ),
      extra_menu = new GLib.Menu()
    };
    Utils.populate_insert_popup( (GLib.Menu)_replace.extra_menu, "replace_sel.action_insert_replace" );

    if( custom ) {

      _replace.text = _replace_text;
      _replace.changed.connect(() => {
        _replace_text = _replace.text;
        custom_changed();
      });

    } else {

      _replace.activate.connect(() => {
        _replace_text = _replace.text;
        var undo_item = new UndoItem( label );
        do_replace( editor, undo_item );
        editor.undo_buffer.add_item( undo_item );
      });

      handle_widget_escape( _replace, _win );

      entry = _replace;

    }

    box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( _replace );

    /* Add the menu actions */
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    box.insert_action_group( "replace_sel", actions );

  }

  public override Box? get_widget( Editor editor ) {
    Box   box;
    Entry entry;
    create_widget( editor, out box, out entry );
    return( box );
  }

  /* Replace all matches with the replacement text */
  private void do_replace( Editor editor, UndoItem? undo_item ) {

    var ranges       = new Array<Editor.Position>();
    var replace_text = Utils.replace_date( _replace_text );
    var int_value    = 1;

    editor.get_ranges( ranges );

    for( int i=((int)ranges.length - 1); i>=0; i-- ) {
      var range = ranges.index( i );
      editor.replace_text( range.start, range.end, Utils.replace_index( replace_text, ref int_value ), undo_item );
    }

    /* Hide the widget */
    _win.remove_widget();

  }

  public override void run( Editor editor, UndoItem undo_item ) {
    do_replace( editor, undo_item );
  }

  /* Called when the action button is clicked.  Displays the UI. */
  public override void launch( Editor editor ) {
    if( custom ) {
      do_replace( editor, null );
    } else {
      Box   box;
      Entry entry;
      create_widget( editor, out box, out entry );
      _win.add_widget( box, entry );
    }
  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "replace", _replace_text );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    string? r = node->get_prop( "replace" );
    if( r != null ) {
      _replace_text = r;
    }
  }

}
