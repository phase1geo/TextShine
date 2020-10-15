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
using Gdk;

public class Editor : SourceView {

  /* Structure to hold absolute position */
  public class Position {

    private TextBuffer _buf;
    private int        _start;
    private int        _end;

    public TextIter start {
      get {
        TextIter iter;
        _buf.get_iter_at_offset( out iter, _start );
        return( iter );
      }
    }
    public TextIter end {
      get {
        TextIter iter;
        _buf.get_iter_at_offset( out iter, _end );
        return( iter );
      }
    }

    /* Constructor */
    public Position( TextIter s, TextIter e ) {
      _buf   = s.get_buffer();
      _start = s.get_offset();
      _end   = e.get_offset();
    }

  }

  private UndoBuffer _undo_buffer;

  public UndoBuffer undo_buffer {
    get {
      return( _undo_buffer );
    }
  }

  public signal void buffer_changed( UndoBuffer buf );

  /* Constructor */
  public Editor( MainWindow win ) {

    /* TBD - We may want to make this a preference */
    wrap_mode = WrapMode.WORD;

    /* Add the undo_buffer */
    _undo_buffer = new UndoBuffer( this );
    _undo_buffer.buffer_changed.connect((buf) => {
      buffer_changed( buf );
    });

    /* Set a CSS style class so that we can adjust the font */
    get_style_context().add_class( "editor" );

    /* Set the default font */
    var font_name = TextShine.settings.get_string( "default-font-family" );
    var font_size = TextShine.settings.get_int( "default-font-size" );
    change_name_font( font_name, font_size );

    /* Handle changes to the buffer */
    buffer.insert_text.connect((ref pos, new_text, new_text_length) => {
      var start     = pos.get_offset();
      var undo_item = undo_buffer.get_mergeable( true, start, (start + new_text.char_count()) );
      if( undo_item == null ) {
        stdout.printf( "Adding new undo item!\n" );
        undo_item = new UndoItem( "edit" );
        undo_buffer.add_item( undo_item );
      }
      undo_item.add_edit( true, start, new_text );
    });
    buffer.delete_range.connect((start, end) => {
      var undo_item = undo_buffer.get_mergeable( true, start.get_offset(), end.get_offset() );
      if( undo_item == null ) {
        undo_item = new UndoItem( "edit" );
        undo_buffer.add_item( undo_item );
      }
      undo_item.add_edit( false, start.get_offset(), start.get_text( end ) );
    });

  }

  /* Updates the font theme */
  public void change_name_font( string name, int size ) {

    var provider = new CssProvider();

    try {
      var css_data = ".editor { font: " + size.to_string() + "px \"" + name + "\"; }";
      provider.load_from_data( css_data );
    } catch( GLib.Error e ) {
      stdout.printf( "Unable to change font: %s\n", e.message );
    }

    /* Set the CSS */
    get_style_context().add_provider(
      provider,
      STYLE_PROVIDER_PRIORITY_APPLICATION
    );

  }

  /* Returns the current range of text that will be transformed */
  public void get_ranges( Array<Position> ranges, bool include_selected = true ) {

    TextIter start, end;
    var tag  = buffer.tag_table.lookup( "selected" );

    if( (tag != null) && include_selected ) {
      buffer.get_start_iter( out start );
      while( start.starts_tag( tag ) || start.forward_to_tag_toggle( tag ) ) {
        if( start.starts_tag( tag ) ) {
          end = start.copy();
          end.forward_to_tag_toggle( tag );
          ranges.append_val( new Position( start, end ) );
          start = end.copy();
        }
      }
    }

    if( ranges.length == 0 ) {
      if( buffer.get_selection_bounds( out start, out end ) ) {
        ranges.append_val( new Position( start, end ) );
      } else {
        buffer.get_bounds( out start, out end );
        ranges.append_val( new Position( start, end ) );
      }
    }

  }

  /* Returns the current range of text that will be transformed */
  public string get_text( TextIter start, TextIter end ) {
    return( buffer.get_text( start, end, false ) );
  }

  /*
   Returns the cursor position relative to the selected text.  If the cursorcr
   position is outside of the selected text range, return -1.
  */
  public int get_cursor_pos( TextIter start, TextIter end ) {
    if( (buffer.cursor_position < start.get_offset()) ||
        (buffer.cursor_position > end.get_offset()) ) {
      return( -1 );
    }
    return( buffer.cursor_position - start.get_offset() );
  }

  /* Replaces all ranges with the specified text */
  public void replace_text( TextIter start, TextIter end, string text, UndoItem undo_item ) {
    var old_text = start.get_slice( end );
    undo_item.add_replacement( start.get_offset(), old_text, text );
    if( start.compare( end ) != 0 ) {
      buffer.delete( ref start, ref end );
    }
    buffer.insert( ref start, text, text.length );
  }

  /* Copies the selected text (if selected) or the entire buffer contents */
  public void copy_to_clipboard( Clipboard clipboard ) {
    TextIter start, end;
    if( buffer.get_selection_bounds( out start, out end ) ) {
      buffer.copy_clipboard( clipboard );
    } else {
      clipboard.clear();
      clipboard.set_text( buffer.text, buffer.text.length );
    }
  }

  /* Clears the text in the buffer */
  public void clear() {
    TextIter start, end;
    buffer.get_bounds( out start, out end );
    if( start.compare( end ) != 0 ) {
      buffer.delete_range( start, end );
    }
    undo_buffer.clear();
  }

  /* Clears the selection */
  public void clear_selection() {
    TextIter ins;
    buffer.get_iter_at_mark( out ins, buffer.get_insert() );
    buffer.select_range( ins, ins );
  }

  /* Returns true if any text is selected */
  public bool is_selected() {
    TextIter iter;
    buffer.get_start_iter( out iter );
    var tag = buffer.tag_table.lookup( "selected" );
    return( (tag != null) && iter.forward_to_tag_toggle( tag ) );
  }

  /* Adds a new tag by the given name */
  public void add_selected( TextIter start, TextIter end, UndoItem undo_item ) {
    clear_selection();
    if( buffer.tag_table.lookup( "selected" ) == null ) {
      buffer.create_tag( "selected", "background", "Yellow", "foreground", "Black", null );
    }
    buffer.apply_tag_by_name( "selected", start, end );
    undo_item.add_select( true, start.get_offset(), end.get_offset() );
  }

  /* Removes the tag specified by the given name */
  public void remove_selected( UndoItem undo_item ) {
    if( buffer.tag_table.lookup( "selected" ) == null ) return;
    var ranges = new Array<Editor.Position>();
    get_ranges( ranges );
    for( int i=0; i<ranges.length; i++ ) {
      var range = ranges.index( i );
      undo_item.add_select( false, range.start.get_offset(), range.end.get_offset() );
    }
    TextIter start, end;
    buffer.get_bounds( out start, out end );
    buffer.remove_tag_by_name( "selected", start, end );
  }

}
