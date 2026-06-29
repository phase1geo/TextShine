/*
* Copyright (c) 2026 (https://github.com/phase1geo/Minder)
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

public class StringSetting : GlobalSetting {

  private bool _single = false;
  private bool _double = true;
  private bool _triple = false;
  private bool _back   = false;
  private Array<string> _delims;

  //-------------------------------------------------------------
  // Constructor
  public StringSetting() {
    base( "string", _( "Global String Settings" ) );
    _delims = new Array<string>();
  }

  //-------------------------------------------------------------
  // Constructor from XML
  public StringSetting.from_xml( Xml.Node* node ) {
    base( "string", _( "Global String Settings" ) );
    _delims = new Array<string>();
    load( node );
  }

  //-------------------------------------------------------------
  // Returns a copy of this setting.
  public override GlobalSetting copy() {
    var copy = new StringSetting();
    copy.enabled = enabled;
    copy._single = _single;
    copy._double = _double;
    copy._triple = _triple;
    copy._back   = _back;
    copy.update_delims();
    return( copy );
  }

  //-------------------------------------------------------------
  // Adds the settings to the given grid
  public override void add_settings( Grid grid ) {
    add_bool_setting( grid, 0, _( "<b>'</b> <i>Single-quoted string</i> <b>'</b>" ), _single, (value) => {
      _single = value;
      update_delims();
    });
    add_bool_setting( grid, 1, _( "<b>\"</b> <i>Double-quoted string</i> <b>\"</b>" ), _double, (value) => {
      _double = value;
      update_delims();
    });
    add_bool_setting( grid, 2, _( "<b>\"\"\"</b> <i>Triple-double-quoted string</i> <b>\"\"\"</b>" ), _triple, (value) => {
      _triple = value;
    });
    add_bool_setting( grid, 3, _( "<b>`</b> <i>Backtick-quoted string</i> <b>`</b>" ), _back, (value) => {
      _back = value;
    });
  }

  //-------------------------------------------------------------
  // Calculates the delims used for string matching.
  private void update_delims() {
    _delims.remove_range( 0, _delims.length );
    if( _single ) {
      _delims.append_val( "'" );
    }
    if( _double ) {
      _delims.append_val( "\"" );
    }
    if( _triple ) {
      _delims.append_val( "\"\"\"" );
    }
    if( _back ) {
      _delims.append_val( "`" );
    }
  }

  //-------------------------------------------------------------
  // Returns the number of valid delimiters stored
  public int size() {
    return( (int)_delims.length );
  }

  //-------------------------------------------------------------
  // Returns the delimiter string associated with the given index.
  public string get_delim( int index ) {
    return( _delims.index( index ) );
  }

  //-------------------------------------------------------------
  // Called to save the contents of this setting to XML format.
  public override Xml.Node* save() {
    var node = base.save();
    node->set_prop( "single", _single.to_string() );
    node->set_prop( "double", _double.to_string() );
    node->set_prop( "triple", _triple.to_string() );
    node->set_prop( "back",   _back.to_string() );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the contents of this setting from XML format.
  public override void load( Xml.Node* node ) {
    base.load( node );
    var s = node->get_prop( "single" );
    if( s != null ) {
      _single = bool.parse( s );
    }
    var d = node->get_prop( "double" );
    if( d != null ) {
      _double = bool.parse( d );
    }
    var t = node->get_prop( "triple" );
    if( t != null ) {
      _triple = bool.parse( t );
    }
    var b = node->get_prop( "back" );
    if( b != null ) {
      _back = bool.parse( b );
    }
    update_delims();
  }

}
