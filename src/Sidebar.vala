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
using Gee;

public class Functions {
  private TextFunction _func;
  private Button?      _favorite;
  private Revealer     _revealer1;
  private Revealer     _revealer2;
  private Expander?    _exp;
  public TextFunction func {
    get {
      return( _func );
    }
  }
  public delegate void UpdateButtonStateFunc( Button btn );
  public Functions( TextFunction func, Button? favorite, Revealer revealer1, Revealer? revealer2 = null, Expander? exp = null ) {
    _func      = func;
    _favorite  = favorite;
    _revealer1 = revealer1;
    _revealer2 = revealer2;
    _exp       = exp;
  }
  public void reveal( string value ) {
    var contains = _func.label.down().contains( value );
    _revealer1.reveal_child = contains;
    if( _revealer2 != null ) {
      _revealer2.reveal_child = contains;
    }
    if( (_exp != null) && contains ) {
      _exp.expanded = true;
    }
  }
  public bool unfavorite( TextFunction function, UpdateButtonStateFunc func ) {
    if( _func.matches( function ) && (_favorite != null) ) {
      func( _favorite );
      return( true );
    }
    return( false );
  }
}

public enum SwitchStackReason {
  NONE,           /* There is no reason for switching */
  NEW,            /* We are creating a new cuastom function */
  EDIT,           /* We are editing an existing function */
  EDIT_SETTINGS,  /* We are editing the custom settings */
  ADD,            /* We are adding a new custom function */
  DELETE          /* We are deleting a custom function */
}

public class Sidebar : Stack {

  public signal void action_applied( TextFunction function );

  /* Constructor */
  public Sidebar( MainWindow win, Editor editor ) {

    var functions       = new SidebarFunctions( win, editor );
    var custom          = new SidebarCustom( win, editor );
    var custom_settings = new SidebarCustomSettings( win, editor );

    functions.action_applied.connect((fn) => {
      action_applied( fn );
    });
    functions.switch_stack.connect((reason, fn) => {
      visible_child_name = "custom";
      custom.displayed( reason, fn );
    });

    custom.action_applied.connect((fn) => {
      action_applied( fn );
    });
    custom.switch_stack.connect((reason,fn) => {
      if( reason == SwitchStackReason.EDIT_SETTINGS ) {
        visible_child_name = "custom_settings";
        custom_settings.displayed( reason, fn );
      } else {
        visible_child_name = "functions";
        functions.displayed( reason, fn );
      }
    });

    custom_settings.action_applied.connect((fn) => {
      action_applied( fn );
    });
    custom_settings.switch_stack.connect((reason,fn) => {
      visible_child_name = "custom";
      custom.displayed( reason, fn );
    });

    add_named( functions,       "functions" );
    add_named( custom,          "custom" );
    add_named( custom_settings, "custom_settings" );

  }

}

