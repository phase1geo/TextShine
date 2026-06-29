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

public class GlobalSettings {

  private Array<GlobalSetting> _settings;

  //-------------------------------------------------------------
  // Constructor
  public GlobalSettings() {

    _settings = new Array<GlobalSetting>();

    // Add the supported settings here
    var string_setting = new StringSetting();
    var block_setting  = new BlockCommentSetting();
    // var line_setting   = new LineCommentSetting();

    _settings.append_val( string_setting );
    _settings.append_val( block_setting );
    // _settings.append_val( line_setting );

  }

  //-------------------------------------------------------------
  // Creates the global settings from Xml format.
  public GlobalSettings.from_xml( Xml.Node* node ) {
    _settings = new Array<GlobalSetting>();
    load( node );
  }

  //-------------------------------------------------------------
  // Creates a global settings that is a copy of the other setting.
  public GlobalSettings.copy( GlobalSettings other ) {
    _settings = new Array<GlobalSetting>();
    for( int i=0; i<other.size(); i++ ) {
      _settings.append_val( other.get_setting( i ).copy() );
    }
  }

  //-------------------------------------------------------------
  // Returns the number of settings stored in this class.
  public int size() {
    return( (int)_settings.length );
  }

  //-------------------------------------------------------------
  // Returns the setting located at the given index.
  public GlobalSetting get_setting( int index ) {
    return( _settings.index( index ) );
  }

  //-------------------------------------------------------------
  // Searches the list of global settings for the one identified by
  // name.
  public GlobalSetting? find_setting( string name ) {
    for( int i=0; i<_settings.length; i++ ) {
      if( _settings.index( i ).name == name ) {
        return( _settings.index( i ) );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Builds the UI and returns it as a vertical box.
  public MenuButton build() {

    var box = new Box( Orientation.VERTICAL, 5 );

    for( int i=0; i<_settings.length; i++ ) {

      var setting = _settings.index( i );

      var enable = new CheckButton.with_label( _( "Enabled" ) );
      var grid   = new Grid();

      setting.add_settings( grid );

      var child_box = new Box( Orientation.VERTICAL, 5 );
      child_box.append( enable );
      child_box.append( grid );

      var expander = new Expander( setting.label ) {
        child = child_box
      };

      box.append( expander );

    }

    var popover = new Popover() {
      child = box
    };

    var mb = new MenuButton() {
      icon_name = "emblem-system-symbolic",
      tooltip_text = _( "Function Settings" ),
      popover = popover
    };

    return( mb );

  }

  //-------------------------------------------------------------
  // Saves the contents of the global settings to XML format.
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "settings" );
    for( int i=0; i<_settings.length; i++ ) {
      node->add_child( _settings.index( i ).save() );
    }
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the saved settings from XML format.
  public void load( Xml.Node* node ) {
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        GlobalSetting? setting = null;
        switch( it->name ) {
          case "string-setting" :  setting = new StringSetting.from_xml( it );  break;
          case "block-setting"  :  setting = new BlockCommentSetting.from_xml( it );  break;
          // case "line-setting"   :  setting = new LineCommentSetting.from_xml( it );  break;
          default               :  break;
        }
        if( setting != null ) {
          _settings.append_val( setting );
        }
      }
    }
  }

}
