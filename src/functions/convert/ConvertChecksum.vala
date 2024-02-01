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

public class ConvertChecksum : TextFunction {

  public enum EncodeType {
    MD5,
    SHA1,
    SHA256,
    SHA384,
    SHA512,
    LENGTH;

    public string label() {
      switch( this ) {
        case MD5    :  return( "MD5" );
        case SHA1   :  return( "SHA-1" );
        case SHA256 :  return( "SHA-256" );
        case SHA384 :  return( "SHA-384" );
        case SHA512 :  return( "SHA-512" );
        default     :  assert_not_reached();
      }
    }

    public string to_string() {
      switch( this ) {
        case MD5    :  return( "md5" );
        case SHA1   :  return( "sha1" );
        case SHA256 :  return( "sha256" );
        case SHA384 :  return( "sha384" );
        case SHA512 :  return( "sha512" );
        default     :  assert_not_reached();
      }
    }

    public static EncodeType parse( string val ) {
      switch( val ) {
        case "md5"    :  return( MD5 );
        case "sha1"   :  return( SHA1 );
        case "sha256" :  return( SHA256 );
        case "sha384" :  return( SHA384 );
        case "sha512" :  return( SHA512 );
        default       :  assert_not_reached();
      }
    }

    public ChecksumType type() {
      switch( this ) {
        case MD5    :  return( ChecksumType.MD5 );
        case SHA1   :  return( ChecksumType.SHA1 );
        case SHA256 :  return( ChecksumType.SHA256 );
        case SHA384 :  return( ChecksumType.SHA384 );
        case SHA512 :  return( ChecksumType.SHA512 );
        default     :  assert_not_reached();
      }
    }
  }

  private EncodeType _type = EncodeType.MD5;

  /* Constructor */
  public ConvertChecksum( bool custom = false ) {
    base( "convert-checksum", custom );
  }

  protected override string get_label0() {
    return( _( "Encode as %s checksum" ).printf( _type.label() ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new ConvertChecksum( custom ) );
  }

  public override bool matches( TextFunction function ) {
    if( base.matches( function ) ) {
      var fn = (ConvertChecksum)function;
      return( _type == fn._type );
    }
    return( false );
  }

  public override bool settings_available() {
    return( true );
  }

  /* Populates the given popover with the settings */
  public override void add_settings( Grid grid ) {

    add_menubutton_setting( grid, 1, _( "Checksum Type" ), _type.label(), EncodeType.LENGTH, (value) => {
      var type = (EncodeType)value;
      return( type.label() );
    }, (value) => {
      _type = (EncodeType)value;
      update_button_label();
    });

  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    return( Checksum.compute_for_string( _type.type(), original ) );
  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "type", _type.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    var t = node->get_prop( "type" );
    if( t != null ) {
      _type = EncodeType.parse( t );
    }
    update_button_label();
  }

}
