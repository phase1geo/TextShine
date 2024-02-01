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
  private UndoItem    _undo_item;
  private string      _find_text      = "";
  private bool        _case_sensitive = false;
  private bool        _highlight_line = false;
  private Entry       _find;

  private const GLib.ActionEntry action_entries[] = {
    { "action_insert_find", action_insert_find, "s" },
  };

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

  public override bool matches( TextFunction function ) {
    if( base.matches( function ) ) {
      var func = (Find)function;
      return(
        (_find_text == func._find_text) &&
        (_case_sensitive == func._case_sensitive) &&
        (_highlight_line == func._highlight_line)
      );
    }
    return( false );
  }

  /* Inserts the given string into the find entry at the current insertion point */
  private void action_insert_find( SimpleAction action, Variant? variant ) {
    var str = variant.get_string();
    if( str != null ) {
      var pos = _find.cursor_position;
      _find.do_insert_text( str, str.length, ref pos );
    }
  }

  /* Creates the search UI */
  private void create_widget( Editor editor, out Box box, out Entry entry ) {

    _find = new Entry() {
      halign = Align.FILL,
      hexpand = true,
      placeholder_text = _( "Search Text" ),
      tooltip_text = _( "Search Text" ),
      extra_menu = new GLib.Menu()
    };
    populate_find_popup( (GLib.Menu)_find.extra_menu );

    var case_sensitive = new CheckButton.with_label( _( "Case-sensitive" ) );
    var highlight_line = new CheckButton.with_label( _( "Highlight Line" ) );

    if( custom ) {

      _find.text = _find_text;
      _find.changed.connect(() => {
        _find_text = _find.text;
        custom_changed();
      });

      case_sensitive.active = _case_sensitive;
      case_sensitive.toggled.connect(() => {
        _case_sensitive = case_sensitive.get_active();
        custom_changed();
      });

      highlight_line.active = _highlight_line;
      highlight_line.toggled.connect(() => {
        _highlight_line = highlight_line.get_active();
        custom_changed();
      });

      var cbox = new Box( Orientation.HORIZONTAL, 10 );
      cbox.append( case_sensitive );
      cbox.append( highlight_line );

      box = new Box( Orientation.VERTICAL, 10 ) {
        margin_start  = 10,
        margin_end    = 10,
        margin_top    = 10,
        margin_bottom = 10
      };
      box.append( _find );
      box.append( cbox );

    } else {

      _find.changed.connect(() => {
        _find_text = _find.text;
        _undo_item = new UndoItem( label );
        do_find( editor, _undo_item );
      });
      _find.activate.connect(() => {
        complete_find( editor );
      });

      case_sensitive.toggled.connect(() => {
        _case_sensitive = case_sensitive.active;
        _undo_item = new UndoItem( label );
        do_find( editor, _undo_item );
      });

      highlight_line.toggled.connect(() => {
        _highlight_line = highlight_line.active;
        _undo_item = new UndoItem( label );
        do_find( editor, _undo_item );
      });

      handle_widget_escape( _find, _win );
      handle_widget_escape( case_sensitive, _win );

      entry = _find;

      box = new Box( Orientation.HORIZONTAL, 10 ) {
        margin_start  = 10,
        margin_end    = 10,
        margin_top    = 10,
        margin_bottom = 10
      };
      box.append( _find );
      box.append( case_sensitive );
      box.append( highlight_line );

    }

    /* Add the menu actions */
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    box.insert_action_group( "find", actions );

  }

  public override Box? get_widget( Editor editor ) {
    Box   box;
    Entry entry;
    create_widget( editor, out box, out entry );
    return( box );
  }

  private void populate_find_popup( GLib.Menu menu ) {
    var section = new GLib.Menu();
    section.append( _( "Insert New-line" ),   "find.action_insert_find('\\n')" );
    section.append( _( "Insert Page Break" ), "find.action_insert_find('\\f')" );
    menu.append_section( null, section );
  }

  private void do_find( Editor editor, UndoItem? undo_item ) {

    /* Get the selected ranges and clear them */
    var ranges = new Array<Editor.Position>();
    editor.get_ranges( ranges, false );
    editor.remove_selected( undo_item );

    /* If the pattern text is empty, just return now */
    if( _find_text == "" ) {
      return;
    }

    var ignore_case = !_case_sensitive;
    var find_text   = ignore_case ? _find_text.down() : _find_text;
    var find_len    = find_text.char_count();

    for( int i=0; i<ranges.length; i++ ) {

      var text        = editor.get_text( ranges.index( i ).start, ranges.index( i ).end );
      var start_index = ranges.index( i ).start.get_offset();   // In chars

      if( ignore_case ) {
        text = text.down();
      }

      var start = text.index_of( find_text, 0 );   // In bytes

      while( start != -1 ) {
        TextIter start_iter, end_iter;
        var start_chars = text.slice( 0, start ).char_count();
        editor.buffer.get_iter_at_offset( out start_iter, start_index + start_chars );
        editor.buffer.get_iter_at_offset( out end_iter,   start_index + (start_chars + find_len) );
        if( _highlight_line ) {
          start_iter.set_line( start_iter.get_line() );
          end_iter.forward_line();
        }
        editor.add_selected( start_iter, end_iter, undo_item );
        start = text.index_of( find_text, (start + find_text.length) );
      }

    }

  }

  public void complete_find( Editor editor ) {
    if( editor.is_selected() ) {
      editor.undo_buffer.add_item( _undo_item );
    }
    _win.remove_widget();
    editor.grab_focus();
  }

  public override void run( Editor editor, UndoItem undo_item ) {
    do_find( editor, undo_item );
  }

  /* Called when the action button is clicked.  Displays the UI. */
  public override void launch( Editor editor ) {
    if( custom ) {
      do_find( editor, null );
    } else {
      Box   box;
      Entry entry;
      create_widget( editor, out box, out entry );
      _win.add_widget( box, entry );
    }
  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "find", _find_text );
    node->set_prop( "case-sensitive", _case_sensitive.to_string() );
    node->set_prop( "highlight-line", _highlight_line.to_string() );
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
    string? hl = node->get_prop( "highlight-line" );
    if( hl != null ) {
      _highlight_line = bool.parse( hl );
    }
  }
}
