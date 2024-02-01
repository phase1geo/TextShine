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

public class ConvertMarkdownTable : TextFunction {

  public enum MarkdownAlignment {
    NONE,
    LEFT,
    RIGHT,
    CENTER,
    NUM;

    public string to_string() {
      switch( this ) {
        case NONE   :  return( "none" );
        case LEFT   :  return( "left" );
        case RIGHT  :  return( "right" );
        case CENTER :  return( "center" );
        default     :  assert_not_reached();
      }
    }

    public string label() {
      switch( this ) {
        case NONE   :  return( _( "None" ) );
        case LEFT   :  return( _( "Left" ) );
        case RIGHT  :  return( _( "Right" ) );
        case CENTER :  return( _( "Center" ) );
        default     :  assert_not_reached();
      }
    }

    public string line() {
      switch( this ) {
        case NONE   :  return( "---" );
        case LEFT   :  return( ":---" );
        case RIGHT  :  return( "---:" );
        case CENTER :  return( ":---:" );
        default     :  assert_not_reached();
      }
    }

    public static MarkdownAlignment parse( string value ) {
      switch( value ) {
        case "none"   :  return( NONE );
        case "left"   :  return( LEFT );
        case "right"  :  return( RIGHT );
        case "center" :  return( CENTER );
        default       :  assert_not_reached();
      }
    }

  }

  public enum QuoteMode {
    NEVER,
    AUTO,
    ALWAYS,
    NUM;

    public string to_string() {
      switch( this ) {
        case NEVER  :  return( "never" );
        case AUTO   :  return( "auto" );
        case ALWAYS :  return( "always" );
        default     :  assert_not_reached();
      }
    }

    public string label() {
      switch( this ) {
        case NEVER  :  return( _( "Never" ) );
        case AUTO   :  return( _( "Automatic" ) );
        case ALWAYS :  return( _( "Always" ) );
        default     :  assert_not_reached();
      }
    }

    private bool add_quote( string str, string separator, string quote_char ) {
      return( str.contains( separator ) || str.contains( quote_char ) || str.contains( "\n" ) );
    }

    private string quote_string( string str, string quote_char ) {
      return( quote_char + str.replace( "\"", "\"\"" ) + quote_char );
    }

    public string quote( string str, string separator, string quote_char ) {
      switch( this ) {
        case NEVER  :  return( str );
        case AUTO   :  return( add_quote( str, separator, quote_char ) ? quote_string( str, quote_char ) : str );
        case ALWAYS :  return( quote_string( str, quote_char ) );
        default     :  assert_not_reached();
      }
    }

    public static QuoteMode parse( string value ) {
      switch( value ) {
        case "never"  :  return( NEVER );
        case "auto"   :  return( AUTO );
        case "always" :  return( ALWAYS );
        default       :  assert_not_reached();
      }
    }

  }

  private string            _csv_delim      = ",";
  private string            _csv_quote      = "\"";
  private QuoteMode         _csv_quote_mode = QuoteMode.NEVER;
  private MarkdownAlignment _align          = MarkdownAlignment.NONE;

  /* Constructor */
  public ConvertMarkdownTable( bool custom = false ) {
    base( "convert-md-table", custom, FunctionDirection.LEFT_TO_RIGHT );
  }

  protected override string get_label0() {
    return( _( "CSV to Markdown Table" ) );
  }

  protected override string get_label1() {
    return( _( "Markdown Table to CSV" ) );
  }

  public override TextFunction copy( bool custom ) {
    var tf = new ConvertMarkdownTable( custom );
    tf._csv_delim      = _csv_delim;
    tf._csv_quote      = _csv_quote;
    tf._csv_quote_mode = _csv_quote_mode;
    tf._align          = _align;
    tf.direction       = direction;
    return( tf );
  }

  public override bool matches( TextFunction function ) {
    if( base.matches( function ) ) {
      var fn = (ConvertMarkdownTable)function;
      return( (_csv_delim == fn._csv_delim) &&
              (_csv_quote == fn._csv_quote) &&
              (_csv_quote_mode == fn._csv_quote_mode) && 
              (_align == fn._align) );
    }
    return( false );
  }

  public override bool settings_available() {
    return( true );
  }

  /* Populates the given popover with the settings */
  public override void add_settings( Grid grid ) {

    var delim = add_string_setting( grid, 1, _( "CSV Column Separator" ), _csv_delim, (value) => {
      _csv_delim = value;
    });
    delim.max_length = 1;

    var quote = add_string_setting( grid, 2, _( "CSV Quote Character" ), _csv_quote, (value) => {
      _csv_quote = value;
    });
    quote.max_length = 1;

    if( direction == FunctionDirection.RIGHT_TO_LEFT ) {
      add_menubutton_setting( grid, 3, _( "Quote Column Text" ), _csv_quote_mode.label(), QuoteMode.NUM, (value) => {
        var mode = (QuoteMode)value;
        return( mode.label() );
      }, (value) => {
        _csv_quote_mode = (QuoteMode)value;
        update_button_label();
      });
    }

    if( direction == FunctionDirection.LEFT_TO_RIGHT ) {
      add_menubutton_setting( grid, 4, _( "Column Alignment" ), _align.label(), MarkdownAlignment.NUM, (value) => {
        var align = (MarkdownAlignment)value;
        return( align.label() );
      }, (value) => {
        _align = (MarkdownAlignment)value;
        update_button_label();
      });
    }

  }

  /* Parses the given CSV line to convert it into a list of column strings */
  private void parse_csv_line( string line, ref string[] cols, ref string col, ref bool in_quote ) {
    string[] lcols = cols;
    for( int i=0; i<line.char_count(); i++ ) {
      var c  = line.get_char( line.index_of_nth_char( i ) ).to_string();
      var nc = ((i + 1) < line.char_count()) ? line.get_char( line.index_of_nth_char( i + 1 ) ).to_string() : "";
      if( c == _csv_quote ) {
        if( !in_quote && (col == "") ) {
          in_quote = true;
        } else if( in_quote && ((nc == _csv_delim) || (nc == "")) ) {
          in_quote = false;
        } else if( in_quote && (nc != _csv_quote) ) {
          col += c;
        }
      } else if( c == _csv_delim ) {
        if( !in_quote ) {
          lcols += col;
          col = "";
        } else {
          col += c;
        }
      } else if( c == "|" ) {
        col += "&#124;";
      } else {
        col += c;
      }
    }
    if( !in_quote ) {
      lcols += col;
      col = "";
    }
    cols = lcols;
  }

  /* Convert CSV data to Markdown table format */
  private string convert_csv_to_markdown( string original ) {
    var str       = "";
    var first     = true;
    var col       = "";
    var in_quote  = false;
    string[] cols = {};
    foreach( string line in original.split( "\n" ) ) {
      parse_csv_line( line, ref cols, ref col, ref in_quote );
      if( !in_quote ) {
        if( cols.length > 0 ) {
          str += "|" + string.joinv( "|", cols ) + "|\n";
          if( first ) {
            str += "|";
            for( int i=0; i<cols.length; i++ ) {
              str += _align.line() + "|";
            }
            str += "\n";
          }
        }
        cols = {};
      } else {
        col += "<br/>";
      }
      first = false;
    }
    return( str );
  }

  private string condition_csv( string str ) {
    return( str.replace( "&#124;", "|" ).replace( "<br/>", "\n" ) );
  }

  private string convert_markdown_to_csv( string original ) {
    var str = "";
    foreach( string line in original.split( "\n" ) ) {
      var cols = line.split( "|" );
      if( cols.length > 1 ) {
        if( cols[1].has_prefix( ":-" ) || cols[1].has_suffix( "-:" ) || cols[1].has_prefix( "-" ) ) {
          // This is a header line so ignore it
        } else {
          string[] csv_cols = {};
          for( int i=1; i<(cols.length - 1); i++ ) {
            csv_cols += _csv_quote_mode.quote( condition_csv( cols[i] ), _csv_delim, _csv_quote );
          }
          str += string.joinv( _csv_delim, csv_cols ) + "\n";
        }
      }
    }
    return( str );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    if( direction == FunctionDirection.LEFT_TO_RIGHT ) {
      return( convert_csv_to_markdown( original ) );
    } else {
      return( convert_markdown_to_csv( original ) );
    }
  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "delim", _csv_delim );
    node->set_prop( "quote", _csv_quote );
    node->set_prop( "quote-mode", _csv_quote_mode.to_string() );
    node->set_prop( "align", _align.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    var d = node->get_prop( "delim" );
    if( d != null ) {
      _csv_delim = d;
    }
    var q = node->get_prop( "quote" );
    if( q != null ) {
      _csv_quote = q;
    }
    var qm = node->get_prop( "quote-mode" );
    if( qm != null ) {
      _csv_quote_mode = QuoteMode.parse( qm );
    }
    var a = node->get_prop( "align" );
    if( a != null ) {
      _align = MarkdownAlignment.parse( a );
    }
    update_button_label();
  }

}
