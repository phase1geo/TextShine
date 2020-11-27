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

public class ConvertHardWrap : TextFunction {

  private enum HardWrapType {
    CHAR,
    WORD,
    LENGTH;

    public string label() {
      switch( this ) {
        case CHAR :  return( _( "Character" ) );
        case WORD :  return( _( "Word" ) );
        default   :  assert_not_reached();
      }
    }

    public string to_string() {
      switch( this ) {
        case CHAR :  return( "char" );
        case WORD :  return( "word" );
        default   :  assert_not_reached();
      }
    }

    public static HardWrapType parse( string val ) {
      switch( val ) {
        case "char" :  return( CHAR );
        case "word" :  return( WORD );
        default     :  assert_not_reached();
      }
    }
  }

  private int          _col_width = 80;
  private HardWrapType _wrap_type = HardWrapType.WORD;

  /* Constructor */
  public ConvertHardWrap( bool custom = false ) {
    base( "convert-hard-wrap", custom );
  }

  protected override string get_label0() {
    return( _( "Hard Wrap At %d Characters" ).printf( _col_width ) );
  }

  public override TextFunction copy( bool custom ) {
    var fn = new ConvertHardWrap( custom );
    fn._col_width = _col_width;
    fn._wrap_type = _wrap_type;
    return( fn );
  }

  public override bool matches( TextFunction function ) {
    if( base.matches( function ) ) {
      var fn = (ConvertHardWrap)function;
      return(
        (_col_width == fn._col_width) &&
        (_wrap_type == fn._wrap_type)
      );
    }
    return( false );
  }

  public override bool settings_available() {
    return( true );
  }

  /* Populates the given popover with the settings */
  public override void add_settings( Grid grid ) {

    add_range_setting( grid, 0, _( "Column Width" ), 20, 150, 5, _col_width, (value) => {
      _col_width = value;
      update_button_label();
    });

    add_menubutton_setting( grid, 1, _( "Wrap Type" ), _wrap_type.label(), HardWrapType.LENGTH, (value) => {
      var type = (HardWrapType)value;
      return( type.label() );
    }, (value) => {
      _wrap_type = (HardWrapType)value;
    });

  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {

    var lines = original.split( "\n" );
    var str   = "";

    foreach( string line in lines ) {
      switch( _wrap_type ) {
        case HardWrapType.CHAR :  str += char_wrap( line );  break;
        case HardWrapType.WORD :  str += word_wrap( line );  break;
      }
    }

    return( str.chomp() );

  }

  private string char_wrap( string line ) {
    var ln  = line;
    var str = "";
    while( ln.char_count() > _col_width ) {
      str += ln.substring( 0, _col_width ) + "\n";
      ln   = ln.substring( _col_width );
    }
    return( str + ln + "\n" );
  }

  private string word_wrap( string line ) {
    var words  = Regex.split_simple( """\s""", line );
    var str    = "";
    var ln     = "";
    var ws_idx = 0;
    for( int i=0; i<words.length; i++ ) {
      var ws      = (i == 0) ? "" : line.get_char( ws_idx ).to_string();
      var ws_word = ws + words[i];
      var pos     = ln + ws_word;
      if( pos.char_count() < _col_width ) {
        ln = pos;
      } else {
        str += ln + "\n";
        ln   = words[i];
      }
      ws_idx += ws_word.length;
    }
    return( str + ln + "\n" );
  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "column-width", _col_width.to_string() );
    node->set_prop( "wrap-type", _wrap_type.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    var cw = node->get_prop( "column-width" );
    if( cw != null ) {
      _col_width = int.parse( cw );
    }
    var wt = node->get_prop( "wrap-type" );
    if( wt != null ) {
      _wrap_type = HardWrapType.parse( wt );
    }
    update_button_label();
  }

}
