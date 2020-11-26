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

public class InsertText : TextFunction {

  private enum InsertLocation {
    LINE_START,
    LINE_END,
    PARA_START,
    PARA_END,
    DOC_START,
    DOC_END,
    FIRST_CHAR,
    LENGTH;

    /* Returns the label to display for this value */
    public string label() {
      switch( this ) {
        case LINE_START :  return( _( "Start of Line" ) );
        case LINE_END   :  return( _( "End of Line" ) );
        case DOC_START  :  return( _( "Start of Document" ) );
        case DOC_END    :  return( _( "End of Document" ) );
        case PARA_START :  return( _( "Start of Paragraph" ) );
        case PARA_END   :  return( _( "End of Paragraphs" ) );
        case FIRST_CHAR :  return( _( "Before First Line Character" ) );
        default         :  assert_not_reached();
      }
    }

    /* Returns the compare string that is stored in the XML */
    public string to_string() {
      switch( this ) {
        case LINE_START :  return( "line-start" );
        case LINE_END   :  return( "line-end" );
        case DOC_START  :  return( "doc-start" );
        case DOC_END    :  return( "doc-end" );
        case PARA_START :  return( "para-start" );
        case PARA_END   :  return( "para-end" );
        case FIRST_CHAR :  return( "first-char" );
        default         :  assert_not_reached();
      }
    }

    /* Returns the InsertLocation value associated with the given string value */
    public static InsertLocation parse( string val ) {
      switch( val ) {
        case "line-start" :  return( LINE_START );
        case "line-end"   :  return( LINE_END );
        case "doc-start"  :  return( DOC_START );
        case "doc-end"    :  return( DOC_END );
        case "para-start" :  return( PARA_START );
        case "para-end"   :  return( PARA_END );
        case "first-char" :  return( FIRST_CHAR );
        default           :  assert_not_reached();
      }
    }

  }

  private MainWindow     _win;
  private InsertLocation _insert_loc = InsertLocation.LINE_START;
  private string         _insert_text = "";
  private Regex          _first_char_re;

  /* Constructor */
  public InsertText( MainWindow win, bool custom = false ) {

    base( "insert-text", custom );

    _win = win;

    try {
      _first_char_re = new Regex( """^(\s*)(.*)$""" );
    } catch( RegexError e ) {}

  }

  protected override string get_label0() {
    return( _( "Insert Text (%s)".printf( _insert_loc.label() ) ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new InsertText( _win, custom ) );
  }

  public override bool matches( TextFunction function ) {
    if( base.matches( function ) ) {
      var func = (InsertText)function;
      return(
        (_insert_text == func._insert_text) &&
        (_insert_loc  == func._insert_loc)
      );
    }
    return( false );
  }

  public override void run( Editor editor, UndoItem undo_item ) {
    do_insert( editor, undo_item );
  }

  /* Called when the action button is clicked.  Displays the UI. */
  public override void launch( Editor editor ) {
    if( custom ) {
      do_insert( editor, null );
    } else {
      Box   box;
      Entry entry;
      create_widget( editor, out box, out entry );
      _win.add_widget( box, entry );
    }
  }

  private void create_widget( Editor editor, out Box box, out Entry focus ) {

    var insert = new Entry();
    insert.placeholder_text = _( "Inserted Text" );
    insert.populate_popup.connect((mnu) => {
      Utils.populate_insert_popup( mnu, insert );
    });

    if( custom ) {

      insert.text = _insert_text;
      insert.changed.connect(() => {
        _insert_text = insert.text;
        custom_changed();
      });

    } else {

      insert.activate.connect(() => {
        _insert_text = insert.text;
        var undo_item = new UndoItem( label );
        do_insert( editor, undo_item );
        editor.undo_buffer.add_item( undo_item );
      });
      insert.grab_focus();

      focus = insert;

    }

    box = new Box( Orientation.HORIZONTAL, 5 );
    box.pack_start( insert, true,  true, 0 );

  }

  public override Box? get_widget( Editor editor ) {
    Box   box;
    Entry entry;
    create_widget( editor, out box, out entry );
    return( box );
  }

  /* Specify that we have settings to display */
  public override bool settings_available() {
    return( true );
  }

  /* Populates the given popover with the settings */
  public override void add_settings( Grid grid ) {

    add_menubutton_setting( grid, 0, _( "Insert At" ), _insert_loc.label(), InsertLocation.LENGTH, (value) => {
      var loc = (InsertLocation)value;
      return( loc.label() );
    }, (value) => {
      _insert_loc = (InsertLocation)value;
      update_button_label();
    });

  }

  private void do_insert( Editor editor, UndoItem? undo_item ) {

    var ranges = new Array<Editor.Position>();
    var text   = Utils.replace_date( _insert_text );

    editor.get_ranges( ranges );

    switch( _insert_loc ) {
      case LINE_START :  do_insert_line_start( editor, text, ranges, undo_item );  break;
      case LINE_END   :  do_insert_line_end(   editor, text, ranges, undo_item );  break;
      case DOC_START  :  do_insert_doc_start(  editor, text, ranges, undo_item );  break;
      case DOC_END    :  do_insert_doc_end(    editor, text, ranges, undo_item );  break;
      case PARA_START :  do_insert_para_start( editor, text, ranges, undo_item );  break;
      case PARA_END   :  do_insert_para_end(   editor, text, ranges, undo_item );  break;
      case FIRST_CHAR :  do_insert_first_char( editor, text, ranges, undo_item );  break;
    }

    _win.remove_widget();

  }

  private void do_insert_line_start( Editor editor, string insert, Array<Editor.Position> ranges, UndoItem? undo_item ) {
    var int_value = 1;
    for( int j=0; j<ranges.length; j++ ) {
      var range = ranges.index( j );
      var text  = editor.get_text( range.start, range.end );
      var lines = text.split( "\n" );
      for( int i=0; i<lines.length; i++ ) {
        lines[i] = Utils.replace_index( insert, ref int_value ) + lines[i];
      }
      editor.replace_text( range.start, range.end, string.joinv( "\n", lines ), undo_item );
    }
  }

  private void do_insert_line_end( Editor editor, string insert, Array<Editor.Position> ranges, UndoItem? undo_item ) {
    var int_value = 1;
    for( int j=0; j<ranges.length; j++ ) {
      var range = ranges.index( j );
      var text  = editor.get_text( range.start, range.end );
      var lines = text.split( "\n" );
      for( int i=0; i<lines.length; i++ ) {
        lines[i] = lines[i] + Utils.replace_index( insert, ref int_value );
      }
      editor.replace_text( range.start, range.end, string.joinv( "\n", lines ), undo_item );
    }
  }

  private void do_insert_doc_start( Editor editor, string insert, Array<Editor.Position> ranges, UndoItem? undo_item ) {
    TextIter start;
    var int_value = 1;
    editor.buffer.get_start_iter( out start );
    editor.replace_text( start, start, Utils.replace_index( insert, ref int_value ), undo_item );
  }

  private void do_insert_doc_end( Editor editor, string insert, Array<Editor.Position> ranges, UndoItem? undo_item ) {
    TextIter end;
    int int_value = 1;
    editor.buffer.get_end_iter( out end );
    editor.replace_text( end, end, Utils.replace_index( insert, ref int_value ), undo_item );
  }

  private void do_insert_para_start( Editor editor, string insert, Array<Editor.Position> ranges, UndoItem? undo_item ) {
    var int_value = 1;
    for( int j=0; j<ranges.length; j++ ) {
      var range = ranges.index( j );
      var text  = editor.get_text( range.start, range.end );
      var lines = text.split( "\n" );
      var blank_found = true;
      for( int i=0; i<lines.length; i++ ) {
        if( lines[i].strip() == "" ) {
          blank_found = true;
        } else if( blank_found ) {
          lines[i] = Utils.replace_index( insert, ref int_value ) + lines[i];
          blank_found = false;
        }
      }
      editor.replace_text( range.start, range.end, string.joinv( "\n", lines ), undo_item );
    }
  }

  private void do_insert_para_end( Editor editor, string insert, Array<Editor.Position> ranges, UndoItem? undo_item ) {
    var int_value = 1;
    for( int j=0; j<ranges.length; j++ ) {
      var range = ranges.index( j );
      var text  = editor.get_text( range.start, range.end );
      var lines = text.split( "\n" );
      var blank_found = true;
      for( int i=0; i<lines.length; i++ ) {
        if( lines[i].strip() != "" ) {
          blank_found = false;
        } else if( !blank_found ) {
          lines[i-1] = lines[i-1] + Utils.replace_index( insert, ref int_value );
          blank_found = true;
        }
      }
      editor.replace_text( range.start, range.end, string.joinv( "\n", lines ), undo_item );
    }
  }

  private void do_insert_first_char( Editor editor, string insert, Array<Editor.Position> ranges, UndoItem? undo_item ) {
    var int_value = 1;
    for( int j=0; j<ranges.length; j++ ) {
      var range = ranges.index( j );
      var text  = editor.get_text( range.start, range.end );
      var lines = text.split( "\n" );
      for( int i=0; i<lines.length; i++ ) {
        MatchInfo match;
        if( _first_char_re.match( lines[i], 0, out match ) ) {
          var pre  = match.fetch( 1 );
          var rest = match.fetch( 2 );
          lines[i] = pre + Utils.replace_index( insert, ref int_value ) + rest;
        }
      }
      editor.replace_text( range.start, range.end, string.joinv( "\n", lines ), undo_item );
    }
  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "text", _insert_text );
    node->set_prop( "location", _insert_loc.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    string? t = node->get_prop( "text" );
    if( t != null ) {
      _insert_text = t;
    }
    string? l = node->get_prop( "location" );
    if( l != null ) {
      _insert_loc = InsertLocation.parse( l );
    }
    update_button_label();
  }

}

