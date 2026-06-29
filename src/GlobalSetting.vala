/*
* Copyright (c) 2025-2026 (https://github.com/phase1geo/Minder)
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

public class GlobalSetting {

  private string _name;
  private string _label;
  private bool   _enabled = false;

  public string name {
    get {
      return( _name );
    }
  }

  public string label {
    get {
      return( _label );
    }
  }

  public bool enabled {
    get {
      return( _enabled );
    }
    set {
      _enabled = value;
    }
  }

  //-------------------------------------------------------------
  // Constructor
  public GlobalSetting( string name, string label ) {
    _name  = name;
    _label = label;
  }

  //-------------------------------------------------------------
  // Creates a copy of this global setting and returns it to the
  // calling function.
  public virtual GlobalSetting copy() {
    var copy = new GlobalSetting( _name, _label );
    copy._enabled = _enabled;
    return( copy );
  }

  //-------------------------------------------------------------
  // Populates the given popover with the text function settings
  // widgets
  public virtual void add_settings( Grid grid ) {
    // By default, we will do nothing
  }

  //-------------------------------------------------------------
  // Called whenever a number setting with a range needs to be added
  protected void add_range_setting( Grid grid, int row, string label, int min_value, int max_value, int step, int init_value, SettingRangeChangedFunc callback ) {

    var lbl = new Label( label + ": " ) {
      halign = Align.START
    };

    var sb = new SpinButton.with_range( min_value, max_value, step ) {
      halign = Align.END,
      value  = init_value
    };
    sb.value_changed.connect(() => {
      callback( (int)sb.value );
    });

    grid.attach( lbl, 0, row );
    grid.attach( sb,  1, row );

  }

  //-------------------------------------------------------------
  // Called whenever a string setting widget needs to be added
  protected Entry add_string_setting( Grid grid, int row, string label, string init_value, SettingStringChangedFunc callback ) {

    var lbl = new Label( label + ": " ) {
      halign = Align.START
    };

    var focus_controller = new EventControllerFocus();
    var key_controller   = new EventControllerKey();
    var entry = new Entry() {
      text = init_value
    };
    entry.add_controller( focus_controller );
    entry.add_controller( key_controller );
    entry.activate.connect(() => {
      init_value = entry.text;
    });
    key_controller.key_released.connect((keyval, keymod, state) => {
      Idle.add(() => {
        callback( entry.text );
        return( false );
      });
    });
    focus_controller.leave.connect(() => {
      callback( entry.text );
    });

    grid.attach( lbl, 0, row );
    grid.attach( entry, 1, row );

    return( entry );

  }

  //-------------------------------------------------------------
  // Called whenever a boolean setting widget needs to be added
  protected void add_bool_setting( Grid grid, int row, string label, bool init_value, SettingBoolChangedFunc callback ) {

    var lbl = new Label( label + ": " ) {
      halign = Align.START
    };

    var sw  = new Switch() {
      halign = Align.END,
      active = init_value
    };
    sw.notify["active"].connect(() => {
      callback( sw.active );
    });

    grid.attach( lbl, 0, row );
    grid.attach( sw,  1, row );

  }

  //-------------------------------------------------------------
  // Called whenever a menubutton setting widget needs to be added
  protected void add_menubutton_setting( Grid grid, int row, string label, int init_value, int value_len, SettingMenuButtonLabelFunc label_func, SettingMenuButtonChangedFunc changed_func ) {

    var lbl = new Label( label + ": " ) {
      halign = Align.START
    };

    string[] values = {};
    for( int i=0; i<value_len; i++ ) {
      values += label_func( i );
    }

    var dd = new DropDown.from_strings( values ) {
      selected = init_value
    };
    dd.notify["selected"].connect(() => {
      changed_func( (int)dd.get_selected() );
    });

    grid.attach( lbl, 0, row );
    grid.attach( dd,  1, row );

  }

  //-------------------------------------------------------------
  // Called to save this global setting in XML format
  public virtual Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "%s-setting".printf( _name ) );
    node->set_prop( "enabled", _enabled.to_string() );
    return( node );
  }

  //-------------------------------------------------------------
  // Called to load this global setting from XML format
  public virtual void load( Xml.Node* node ) {
    var e = node->get_prop( "enabled" );
    if( e != null ) {
      _enabled = bool.parse( e );
    }
  }

}
