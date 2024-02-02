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

public enum RandomizeBlob {
  CHARACTER,
  WORD,
  LINE,
  SENTENCE,
  PARAGRAPH,
  NUM;

  public string to_string() {
    switch( this ) {
      case CHARACTER :  return( "char" );
      case WORD      :  return( "word" );
      case LINE      :  return( "line" );
      case SENTENCE  :  return( "sent" );
      case PARAGRAPH :  return( "para" );
      default        :  assert_not_reached();
    }
  }

  public static RandomizeBlob parse( string val ) {
    switch( val ) {
      case "char" :  return( CHARACTER );
      case "word" :  return( WORD );
      case "line" :  return( LINE );
      case "sent" :  return( SENTENCE );
      case "para" :  return( PARAGRAPH );
      default     :  return( LINE );
    }
  }

  public string label() {
    switch( this ) {
      case CHARACTER :  return( _( "Characters" ) );
      case WORD      :  return( _( "Words" ) );
      case LINE      :  return( _( "Lines" ) );
      case SENTENCE  :  return( _( "Sentences" ) );
      case PARAGRAPH :  return( _( "Paragraphs" ) );
      default        :  assert_not_reached();
    }
  }

  public bool within_word() {
    return( this == CHARACTER );
  }

  public bool within_line() {
    return( (this == CHARACTER) || (this == WORD) );
  }

  public bool within_sentence() {
    return( (this == CHARACTER) || (this == WORD) );
  }

  public bool within_paragraph() {
    return( (this == CHARACTER) || (this == WORD) || (this == LINE) || (this == SENTENCE) );
  }

  public bool within_document() {
    return( true );
  }

}

public enum RandomizeWithin {
  WORD,
  LINE,
  SENTENCE,
  PARAGRAPH,
  DOCUMENT,
  NUM;

  public string to_string() {
    switch( this ) {
      case WORD      :  return( "word" );
      case LINE      :  return( "line" );
      case SENTENCE  :  return( "sent" );
      case PARAGRAPH :  return( "para" );
      case DOCUMENT  :  return( "doc" );
      default        :  assert_not_reached();
    }
  }

  public static RandomizeWithin parse( string val ) {
    switch( val ) {
      case "word" :  return( WORD );
      case "line" :  return( LINE );
      case "sent" :  return( SENTENCE );
      case "para" :  return( PARAGRAPH );
      case "doc"  :  return( DOCUMENT );
      default     :  return( LINE );
    }
  }

  public string label() {
    switch( this ) {
      case WORD      :  return( _( "Word" ) );
      case LINE      :  return( _( "Line" ) );
      case SENTENCE  :  return( _( "Sentence" ) );
      case PARAGRAPH :  return( _( "Paragraph" ) );
      case DOCUMENT  :  return( _( "Document" ) );
      default        :  assert_not_reached();
    }
  }

  public bool allowed_blob( RandomizeBlob blob ) {
    switch( this ) {
      case WORD      :  return( blob.within_word() );
      case LINE      :  return( blob.within_line() );
      case SENTENCE  :  return( blob.within_sentence() );
      case PARAGRAPH :  return( blob.within_paragraph() );
      case DOCUMENT  :  return( blob.within_document() );
      default        :  return( false );
    }
  }

}

public class Randomize : TextFunction {

  private RandomizeBlob   _blob;
  private RandomizeWithin _within;

  /* Constructor */
  public Randomize( bool custom = false ) {
    base( "randomize", custom );
    _blob   = RandomizeBlob.LINE;
    _within = RandomizeWithin.DOCUMENT;
  }

  protected override string get_label0() {
    return( _( "Randomize %s Within %s" ).printf( _blob.label(), _within.label() ) );
  }

  public override TextFunction copy( bool custom ) {
    var fn = new Randomize( custom );
    fn._blob   = _blob;
    fn._within = _within;
    return( fn );
  }

  public override bool matches( TextFunction function ) {
    return( base.matches( function ) && (_blob == ((Randomize)function)._blob) && (_within == ((Randomize)function)._within) );
  }

  /* Randomly swap characters in the given string */
  private string randomize_characters( string orig_str ) {
    var str = orig_str;
    for( int i=0; i<str.char_count(); i++ ) {
      var rn   = Random.int_range( 0, str.char_count() );
      var from = str.index_of_nth_char( i );
      var to   = str.index_of_nth_char( rn );
      var c    = str.get_char( from );
      str = str.splice( from, str.index_of_nth_char( i + 1 ), str.get_char( to ).to_string() );
      str = str.splice( to,   str.index_of_nth_char( rn + 1 ), c.to_string() );
    }
    return( str );
  }

  public override void launch( Editor editor ) {

    /* If we cannot do the required action, just return and do nothing */
    if( !_within.allowed_blob( _blob ) ) {
      return;
    }

    var within_ranges = new Array<Editor.Position>();

    if( _within == DOCUMENT ) {
      editor.get_ranges( within_ranges, true );
    } else {
      var ranges = new Array<Editor.Position>();
      editor.get_ranges( ranges, true );
      switch( _within ) {
        case RandomizeWithin.WORD      :  editor.get_words( ranges, within_ranges );       break;
        case RandomizeWithin.LINE      :  editor.get_lines( ranges, within_ranges );       break;
        case RandomizeWithin.SENTENCE  :  editor.get_sentences( ranges, within_ranges );   break;
        case RandomizeWithin.PARAGRAPH :  editor.get_paragraphs( ranges, within_ranges );  break;
      }
    }

    if( _blob == RandomizeBlob.CHARACTER ) {
      for( int i=(int)(within_ranges.length - 1); i>=0; i-- ) {
        var pos     = within_ranges.index( i );
        var replace = randomize_characters( editor.get_text( pos.start, pos.end ) );
        editor.replace_text( pos.start, pos.end, replace, null );
      }
    } else {
      for( int i=(int)(within_ranges.length - 1); i>=0; i-- ) {
        var pos         = within_ranges.index( i );
        var blob_ranges = new Array<Editor.Position>();
        var from_range  = new Array<Editor.Position>();
        from_range.append_val( new Editor.Position( pos.start, pos.end ) );
        switch( _blob ) {
          case RandomizeBlob.WORD      :  editor.get_words( from_range, blob_ranges );       break;
          case RandomizeBlob.LINE      :  editor.get_lines( from_range, blob_ranges );       break;
          case RandomizeBlob.SENTENCE  :  editor.get_sentences( from_range, blob_ranges );   break;
          case RandomizeBlob.PARAGRAPH :  editor.get_paragraphs( from_range, blob_ranges );  break;
        }
        var blobs = new Array<string>();
        for( int j=0; j<blob_ranges.length; j++ ) {
          var blob_pos = blob_ranges.index( j );
          blobs.append_val( editor.get_text( blob_pos.start, blob_pos.end ) );
        }
        blobs.sort((a, b) => {
          return( Random.int_range(-1,2) );
        });
        for( int j=(int)(blob_ranges.length - 1); j>=0; j-- ) {
          var blob_pos = blob_ranges.index( j );
          editor.replace_text( blob_pos.start, blob_pos.end, blobs.index( j ), null );
        }
      }
    }

  }

  public override bool settings_available() {
    return( true );
  }

  public override void add_settings( Grid grid ) {

    add_menubutton_setting( grid, 0, _( "Randomize" ), _blob, RandomizeBlob.NUM, (value) => {
      var blob = (RandomizeBlob)value;
      return( blob.label() );
    },
    (value) => {
      _blob = (RandomizeBlob)value;
      update_button_label();
    });

    add_menubutton_setting( grid, 1, _( "Within" ), _within, RandomizeWithin.NUM, (value) => {
      var within = (RandomizeWithin)value;
      return( within.label() );
    },
    (value) => {
      _within = (RandomizeWithin)value;
      update_button_label();
    });

  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "blob", _blob.to_string() );
    node->set_prop( "within", _within.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    var b = node->get_prop( "blob" );
    if( b != null ) {
      _blob = RandomizeBlob.parse( b );
    }
    var w = node->get_prop( "within" );
    if( w != null ) {
      _within = RandomizeWithin.parse( w );
    }
  }

}
