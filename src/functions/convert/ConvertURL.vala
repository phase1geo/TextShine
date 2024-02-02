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

public class ConvertURL : TextFunction {

  public enum CharacterSet {
    UTF8,
    WIN,
    NUM;

    public string to_string() {
      switch( this ) {
        case UTF8 :  return( "utf8" );
        case WIN  :  return( "win" );
        default   :  assert_not_reached();
      }
    }

    public string label() {
      switch( this ) {
        case UTF8 :  return( _( "UTF-8" ) );
        case WIN  :  return( _( "Windows-1252" ) );
        default   :  assert_not_reached();
      }
    }

    public static CharacterSet parse( string val ) {
      switch( val ) {
        case "utf8" :  return( UTF8 );
        case "win"  :  return( WIN );
        default     :  assert_not_reached();
      }
    }

    public bool use_utf8() {
      return( this == UTF8 );
    }
  }

  public enum EntryType {
    ANY,
    NO_ALT,
    ALT,
    SKIP
  }

  public class URLEntry {
    public string    ch    { get; private set; }
    public string    win   { get; private set; }
    public string    utf8  { get; private set; }
    public EntryType etype { get; private set; }
    public URLEntry( string ch, string win, string utf8, EntryType etype ) {
      this.ch    = ch;
      this.win   = win;
      this.utf8  = utf8;
      this.etype = etype;
    }
    public string encode( string str, bool use_utf8, bool use_alt ) {
      if( (etype == EntryType.ANY) || (etype ==(use_alt ? EntryType.ALT : EntryType.NO_ALT)) ) {
        return( str.replace( ch, (use_utf8 ? utf8 : win) ) );
      }
      return( str );
    }
    public string decode( string str, bool use_utf8 ) {
      return( str.replace( (use_utf8 ? utf8 : win), ch ) );
    }
  }

  public class URLEntries {
    public Array<URLEntry> _entries;
    public URLEntries() {
      _entries = new Array<URLEntry>();
    }
    public void add( string ch, string win, string utf8, EntryType type = EntryType.ANY ) {
      var entry = new URLEntry( ch, win, utf8, type );
      _entries.append_val( entry );
    }
    public string encode( string str, bool use_utf8, bool use_alt ) {
      var estr = str;
      for( int i=0; i<_entries.length; i++ ) {
        estr = _entries.index( i ).encode( estr, use_utf8, use_alt );
      }
      return( estr );
    }
    public string decode( string str, bool use_utf8 ) {
      var dstr = str;
      for( int i=(int)(_entries.length - 1); i>=0; i-- ) {
        dstr = _entries.index( i ).decode( dstr, use_utf8 );
      }
      return( dstr );
    }
    public string get_test_string() {
      var str = "";
      for( int i=0; i<_entries.length; i++ ) {
        var entry = _entries.index( i );
        if( (entry.etype == EntryType.ANY) || (entry.etype == EntryType.SKIP) ) {
          str += entry.ch + " ";
        }
      }
      return( str.chomp() );
    }
  }

  private static URLEntries _entries  = null;
  private CharacterSet      _type     = CharacterSet.UTF8;
  private bool              _use_plus = true;

  /* Constructor */
  public ConvertURL( bool custom = false ) {
    base( "convert-url-encode", custom, FunctionDirection.LEFT_TO_RIGHT );
    populate_table();
  }

  private void populate_table() {
    if( _entries != null ) return;
    _entries = new URLEntries();
    _entries.add( "%",  "%25", "%25" );
    _entries.add( "+",  "%2B", "%2B" );
    _entries.add( " ",  "%20", "%20", EntryType.NO_ALT );
    _entries.add( " ",  "+",   "+",   EntryType.ALT );
    _entries.add( "!",  "%21", "%21", EntryType.SKIP );
    _entries.add( "\"", "%22", "%22" );
    _entries.add( "#",  "%23", "%23" );
    _entries.add( "$",  "%24", "%24" );
    _entries.add( "&",  "%26", "%26" );
    _entries.add( "'",  "%27", "%27", EntryType.SKIP );
    _entries.add( "(",  "%28", "%28", EntryType.SKIP );
    _entries.add( ")",  "%29", "%29", EntryType.SKIP );
    _entries.add( "*",  "%2A", "%2A", EntryType.SKIP );
    _entries.add( ",",  "%2C", "%2C" );
    _entries.add( "-",  "%2D", "%2D", EntryType.SKIP );
    _entries.add( ".",  "%2E", "%2E", EntryType.SKIP );
    _entries.add( "/",  "%2F", "%2F" );
    _entries.add( ":",  "%3A", "%3A" );
    _entries.add( ";",  "%3B", "%3B" );
    _entries.add( "<",  "%3C", "%3C" );
    _entries.add( "=",  "%3D", "%3D" );
    _entries.add( ">",  "%3E", "%3E" );
    _entries.add( "?",  "%3F", "%3F" );
    _entries.add( "@",  "%40", "%40" );
    _entries.add( "[",  "%5B", "%5B" );
    _entries.add( "\\", "%5C", "%5C" );
    _entries.add( "]",  "%5D", "%5D" );
    _entries.add( "^",  "%5E", "%5E" );
    _entries.add( "_",  "%5F", "%5F", EntryType.SKIP );
    _entries.add( "`",  "%60", "%60" );
    _entries.add( "{",  "%7B", "%7B" );
    _entries.add( "|",  "%7C", "%7C" );
    _entries.add( "}",  "%7D", "%7D" );
    _entries.add( "~",  "%7E", "%7E", EntryType.SKIP );
    _entries.add( "€",  "%80", "%E2%82%AC" );
    // _entries.add( "�",  "%81", "%81" );
    _entries.add( "‚",  "%82", "%E2%80%9A" );
    _entries.add( "ƒ",  "%83", "%C6%92" );
    _entries.add( "„",  "%84", "%E2%80%9E" );
    _entries.add( "…",  "%85", "%E2%80%A6" );
    _entries.add( "†",  "%86", "%E2%80%A0" );
    _entries.add( "‡",  "%87", "%E2%80%A1" );
    _entries.add( "ˆ",  "%88", "%CB%86" );
    _entries.add( "‰",  "%89", "%E2%80%B0" );
    _entries.add( "Š",  "%8A", "%C5%A0" );
    _entries.add( "‹",  "%8B", "%E2%80%B9" );
    _entries.add( "Œ",  "%8C", "%C5%92" );
    // _entries.add( "�",  "%8D", "%C5%8D" );
    _entries.add( "Ž",  "%8E", "%C5%BD" );
    // _entries.add( "�",  "%8F", "%8F" );
    // _entries.add( "�",  "%90", "%C2%90" );
    _entries.add( "‘",  "%91", "%E2%80%98" );
    _entries.add( "’",  "%92", "%E2%80%99" );
    _entries.add( "“",  "%93", "%E2%80%9C" );
    _entries.add( "”",  "%94", "%E2%80%9D" );
    _entries.add( "•",  "%95", "%E2%80%A2" );
    _entries.add( "–",  "%96", "%E2%80%93" );
    _entries.add( "—",  "%97", "%E2%80%94" );
    _entries.add( "˜",  "%98", "%CB%9C" );
    _entries.add( "™",  "%99", "%E2%84%A2" );
    _entries.add( "š",  "%9A", "%C5%A1" );
    _entries.add( "›",  "%9B", "%E2%80%BA" );
    _entries.add( "œ",  "%9C", "%C5%93" );
    // _entries.add( "�",  "%9D", "%9D" );
    _entries.add( "ž",  "%9E", "%C5%BE" );
    _entries.add( "Ÿ",  "%9F", "%C5%B8" );
    _entries.add( "¡",  "%A1", "%C2%A1" );
    _entries.add( "¢",  "%A2", "%C2%A2" );
    _entries.add( "£",  "%A3", "%C2%A3" );
    _entries.add( "¤",  "%A4", "%C2%A4" );
    _entries.add( "¥",  "%A5", "%C2%A5" );
    _entries.add( "¦",  "%A6", "%C2%A6" );
    _entries.add( "§",  "%A7", "%C2%A7" );
    _entries.add( "¨",  "%A8", "%C2%A8" );
    _entries.add( "©",  "%A9", "%C2%A9" );
    _entries.add( "ª",  "%AA", "%C2%AA" );
    _entries.add( "«",  "%AB", "%C2%AB" );
    _entries.add( "¬",  "%AC", "%C2%AC" );
    _entries.add( "®",  "%AE", "%C2%AE" );
    _entries.add( "¯",  "%AF", "%C2%AF" );
    _entries.add( "°",  "%B0", "%C2%B0" );
    _entries.add( "±",  "%B1", "%C2%B1" );
    _entries.add( "²",  "%B2", "%C2%B2" );
    _entries.add( "³",  "%B3", "%C2%B3" );
    _entries.add( "´",  "%B4", "%C2%B4" );
    _entries.add( "µ",  "%B5", "%C2%B5" );
    _entries.add( "¶",  "%B6", "%C2%B6" );
    _entries.add( "·",  "%B7", "%C2%B7" );
    _entries.add( "¸",  "%B8", "%C2%B8" );
    _entries.add( "¹",  "%B9", "%C2%B9" );
    _entries.add( "º",  "%BA", "%C2%BA" );
    _entries.add( "»",  "%BB", "%C2%BB" );
    _entries.add( "¼",  "%BC", "%C2%BC" );
    _entries.add( "½",  "%BD", "%C2%BD" );
    _entries.add( "¾",  "%BE", "%C2%BE" );
    _entries.add( "¿",  "%BF", "%C2%BF" );
    _entries.add( "À",  "%C0", "%C3%80" );
    _entries.add( "Á",  "%C1", "%C3%81" );
    _entries.add( "Â",  "%C2", "%C3%82" );
    _entries.add( "Ã",  "%C3", "%C3%83" );
    _entries.add( "Ä",  "%C4", "%C3%84" );
    _entries.add( "Å",  "%C5", "%C3%85" );
    _entries.add( "Æ",  "%C6", "%C3%86" );
    _entries.add( "Ç",  "%C7", "%C3%87" );
    _entries.add( "È",  "%C8", "%C3%88" );
    _entries.add( "É",  "%C9", "%C3%89" );
    _entries.add( "Ê",  "%CA", "%C3%8A" );
    _entries.add( "Ë",  "%CB", "%C3%8B" );
    _entries.add( "Ì",  "%CC", "%C3%8C" );
    _entries.add( "Í",  "%CD", "%C3%8D" );
    _entries.add( "Î",  "%CE", "%C3%8E" );
    _entries.add( "Ï",  "%CF", "%C3%8F" );
    _entries.add( "Ð",  "%D0", "%C3%90" );
    _entries.add( "Ñ",  "%D1", "%C3%91" );
    _entries.add( "Ò",  "%D2", "%C3%92" );
    _entries.add( "Ó",  "%D3", "%C3%93" );
    _entries.add( "Ô",  "%D4", "%C3%94" );
    _entries.add( "Õ",  "%D5", "%C3%95" );
    _entries.add( "Ö",  "%D6", "%C3%96" );
    _entries.add( "×",  "%D7", "%C3%97" );
    _entries.add( "Ø",  "%D8", "%C3%98" );
    _entries.add( "Ù",  "%D9", "%C3%99" );
    _entries.add( "Ú",  "%DA", "%C3%9A" );
    _entries.add( "Û",  "%DB", "%C3%9B" );
    _entries.add( "Ü",  "%DC", "%C3%9C" );
    _entries.add( "Ý",  "%DD", "%C3%9D" );
    _entries.add( "Þ",  "%DE", "%C3%9E" );
    _entries.add( "ß",  "%DF", "%C3%9F" );
    _entries.add( "à",  "%E0", "%C3%A0" );
    _entries.add( "á",  "%E1", "%C3%A1" );
    _entries.add( "â",  "%E2", "%C3%A2" );
    _entries.add( "ã",  "%E3", "%C3%A3" );
    _entries.add( "ä",  "%E4", "%C3%A4" );
    _entries.add( "å",  "%E5", "%C3%A5" );
    _entries.add( "æ",  "%E6", "%C3%A6" );
    _entries.add( "ç",  "%E7", "%C3%A7" );
    _entries.add( "è",  "%E8", "%C3%A8" );
    _entries.add( "é",  "%E9", "%C3%A9" );
    _entries.add( "ê",  "%EA", "%C3%AA" );
    _entries.add( "ë",  "%EB", "%C3%AB" );
    _entries.add( "ì",  "%EC", "%C3%AC" );
    _entries.add( "í",  "%ED", "%C3%AD" );
    _entries.add( "î",  "%EE", "%C3%AE" );
    _entries.add( "ï",  "%EF", "%C3%AF" );
    _entries.add( "ð",  "%F0", "%C3%B0" );
    _entries.add( "ñ",  "%F1", "%C3%B1" );
    _entries.add( "ò",  "%F2", "%C3%B2" );
    _entries.add( "ó",  "%F3", "%C3%B3" );
    _entries.add( "ô",  "%F4", "%C3%B4" );
    _entries.add( "õ",  "%F5", "%C3%B5" );
    _entries.add( "ö",  "%F6", "%C3%B6" );
    _entries.add( "÷",  "%F7", "%C3%B7" );
    _entries.add( "ø",  "%F8", "%C3%B8" );
    _entries.add( "ù",  "%F9", "%C3%B9" );
    _entries.add( "ú",  "%FA", "%C3%BA" );
    _entries.add( "û",  "%FB", "%C3%BB" );
    _entries.add( "ü",  "%FC", "%C3%BC" );
    _entries.add( "ý",  "%FD", "%C3%BD" );
    _entries.add( "þ",  "%FE", "%C3%BE" );
    _entries.add( "ÿ",  "%FF", "%C3%BF" );
    // stdout.printf( "test str: (%s)\n", _entries.get_test_string() );
  }

  protected override string get_label0() {
    return( _( "Encode URL" ) );
  }

  protected override string get_label1() {
    return( _( "Decode URL" ) );
  }

  public override TextFunction copy( bool custom ) {
    var tf = new ConvertURL( custom );
    tf._type     = _type;
    tf._use_plus = _use_plus;
    tf.direction = direction;
    return( tf );
  }

  public override bool matches( TextFunction function ) {
    if( base.matches( function ) ) {
      var fn = (ConvertURL)function;
      return( (_type == fn._type) && (_use_plus == fn._use_plus) );
    }
    return( false );
  }

  public override bool settings_available() {
    return( true );
  }

  public override void add_settings( Grid grid ) {

    add_menubutton_setting( grid, 1, _( "Character Set" ), _type, CharacterSet.UTF8, (value) => {
      var type = (CharacterSet)value;
      return( type.label() );
    }, (value) => {
      _type = (CharacterSet)value;
      update_button_label();
    });

    add_bool_setting( grid, 2, _( "Replace space with '+'" ), _use_plus, (value) => {
      _use_plus = value;
      update_button_label();
    });

  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    if( direction == FunctionDirection.LEFT_TO_RIGHT ) {
      return( _entries.encode( original, _type.use_utf8(), _use_plus ) );
    } else {
      return( _entries.decode( original, _type.use_utf8() ) );
    }
  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "type", _type.to_string() );
    node->set_prop( "use-plus", _use_plus.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    var t = node->get_prop( "type" );
    if( t != null ) {
      _type = CharacterSet.parse( t );
    }
    var p = node->get_prop( "use-plus" );
    if( p != null ) {
      _use_plus = bool.parse( p );
    }
    update_button_label();
  }

}
