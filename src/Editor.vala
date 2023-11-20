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

public class Editor : GtkSource.View {

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

  private UndoBuffer   _undo_buffer;
  private bool         _ignore_edit = false;
  private string       _lang_dict;
  private SpellChecker _spell = null;

  public UndoBuffer undo_buffer {
    get {
      return( _undo_buffer );
    }
  }

  public signal void buffer_changed( UndoBuffer buf );

  /* Constructor */
  public Editor( MainWindow win ) {

    /* TBD - We may want to make this a preference */
    wrap_mode    = WrapMode.WORD;
    // show_line_numbers = true;
    // show_line_marks   = true;
    // highlight_current_line = true;
    top_margin   = 20;
    left_margin  = 10;
    right_margin = 10;

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
      if( _ignore_edit ) return;
      var start     = pos.get_offset();
      var undo_item = undo_buffer.get_mergeable( true, start, (start + new_text.char_count()) );
      if( undo_item == null ) {
        undo_item = new UndoItem( "edit" );
        undo_buffer.add_item( undo_item );
      }
      undo_item.add_edit( true, start, new_text );
    });
    buffer.delete_range.connect((start, end) => {
      if( _ignore_edit ) return;
      var undo_item = undo_buffer.get_mergeable( true, start.get_offset(), end.get_offset() );
      if( undo_item == null ) {
        undo_item = new UndoItem( "edit" );
        undo_buffer.add_item( undo_item );
      }
      undo_item.add_edit( false, start.get_offset(), start.get_text( end ) );
    });

    /* Connect spell checker */
    connect_spell_checker();

  }

  /* Updates the font theme */
  public void change_name_font( string name, int size ) {

    var provider = new CssProvider();

    try {
      var css_data = ".editor { font: " + size.to_string() + "px \"" + name + "\"; }";
      provider.load_from_data( css_data.data );
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

  /*
   This should be called whenever library code need to insert text as it avoids
   placing the change in the undo buffer.
  */
  public void insert_text( ref TextIter pos, string text ) {
    _ignore_edit = true;
    buffer.insert( ref pos, text, text.length );
    _ignore_edit = false;
  }

  /*
   This should be called whenever library code need to delete text as it avoids
   placing the change in the undo buffer.
  */
  public void delete_text( ref TextIter start, ref TextIter end ) {
    _ignore_edit = true;
    buffer.delete( ref start, ref end );
    _ignore_edit = false;
  }

  /* Replaces all ranges with the specified text */
  public void replace_text( TextIter start, TextIter end, string text, UndoItem? undo_item ) {
    var old_text = start.get_slice( end );
    if( undo_item != null ) {
      undo_item.add_replacement( start.get_offset(), old_text, text );
    }
    if( start.compare( end ) != 0 ) {
      delete_text( ref start, ref end );
    }
    insert_text( ref start, text );
  }

  /* Copies the entire buffer contents, regardless of selection */
  public void copy_all_to_clipboard( Clipboard clipboard ) {
    clipboard.set_text( buffer.text );
  }

  /* Copies the selected text (if selected) or the entire buffer contents */
  public void copy_to_clipboard( Clipboard clipboard ) {
    TextIter start, end;
    if( buffer.get_selection_bounds( out start, out end ) ) {
      buffer.copy_clipboard( clipboard );
    } else {
      clipboard.set_text( buffer.text );
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

  private int num_tagged( string tag_name ) {

    var count = 0;
    var tag   = buffer.tag_table.lookup( tag_name );

    if( tag != null ) {
      TextIter end;
      buffer.get_start_iter( out end );
      while( end.forward_to_tag_toggle( tag ) ) {
        if( end.ends_tag( tag ) ) {
          count++;
        }
      }
    }

    return( count );

  }

  /* Returns the number of matches currenly highlighted in the text */
  public int num_selected() {
    return( num_tagged( "selected" ) );
  }

  /* Returns the number of spelling errors in the highlighted text */
  public int num_spelling_errors() {
    return( num_tagged( "gtkspell-misspelled" ) );
  }

  /* Adds a new tag by the given name */
  public void add_selected( TextIter start, TextIter end, UndoItem? undo_item ) {
    clear_selection();
    if( buffer.tag_table.lookup( "selected" ) == null ) {
      buffer.create_tag( "selected", "background", "Yellow", "foreground", "Black", null );
    }
    buffer.apply_tag_by_name( "selected", start, end );
    if( undo_item != null ) {
      undo_item.add_select( true, start.get_offset(), end.get_offset() );
    }
  }

  /* Removes the tag specified by the given name */
  public void remove_selected( UndoItem? undo_item ) {
    if( buffer.tag_table.lookup( "selected" ) == null ) return;
    if( undo_item != null ) {
      var ranges = new Array<Editor.Position>();
      get_ranges( ranges );
      for( int i=0; i<ranges.length; i++ ) {
        var range = ranges.index( i );
        undo_item.add_select( false, range.start.get_offset(), range.end.get_offset() );
      }
    }
    TextIter start, end;
    buffer.get_bounds( out start, out end );
    buffer.remove_tag_by_name( "selected", start, end );
  }

  private void connect_spell_checker() {

    _lang_dict = TextShine.settings.get_string( "spell-language" );
    _spell     = new SpellChecker();

    try {
      var lang_exists = false;
      var lang_list   = new Gee.ArrayList<string>();
      _spell.get_language_list( lang_list );
      foreach( var elem in lang_list ) {
        if( _lang_dict == elem ) {
          lang_exists = true;
          _spell.set_language( _lang_dict );
          break;
        }
      }
      if( lang_list.size == 0 ) {
        _spell.set_language( null );
      } else if( !lang_exists ) {
        _lang_dict = lang_list.first();
        _spell.set_language( _lang_dict );
      }
    } catch( Error e ) {
      warning( e.message );
    }

    _spell.language_changed.connect((lang_dict) => {
      _lang_dict = lang_dict;
    });

    if( TextShine.settings.get_boolean( "enable-spell-checking" ) ) {
      activate_spell_checking();
    }

  }

  /* Enables the spell checker */
  public void activate_spell_checking() {
    _spell.attach( this );
  }

  /* Disables the spell checker */
  public void deactivate_spell_checking() {
    _spell.detach();
  }

}
