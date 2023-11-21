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

public class ReplaceTabsSpaces : TextFunction {

  private int _spaces = 1;

  /* Constructor */
  public ReplaceTabsSpaces( bool custom = false ) {
    base( "replace-tabs-spaces", custom, FunctionDirection.LEFT_TO_RIGHT );
  }

  protected override string get_label0() {
    if( _spaces == 1 ) {
      return( _( "Tabs With 1 Space" ) );
    } else {
      return( _( "Tabs With %d Spaces" ).printf( _spaces ) );
    }
  }

  protected override string get_label1() {
    if( _spaces == 1 ) {
      return( _( "1 Space With Tabs" ) );
    } else {
      return( _( "%d Spaces With Tabs" ).printf( _spaces ) );
    }
  }

  public override TextFunction copy( bool custom ) {
    var fn = new ReplaceTabsSpaces( custom );
    fn.direction = direction;
    fn._spaces   = _spaces;
    return( fn );
  }

  public override bool matches( TextFunction function ) {
    return( base.matches( function ) && (_spaces == ((ReplaceTabsSpaces)function)._spaces) );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    var spaces = string.nfill( _spaces, ' ' );
    if( direction == FunctionDirection.LEFT_TO_RIGHT ) {
      return( original.replace( "\t", spaces ) );
    } else {
      return( original.replace( spaces, "\t" ) );
    }
  }

  /* Specify that we have settings to display */
  public override bool settings_available() {
    return( true );
  }

  /* Populates the given popover with the settings */
  public override void add_settings( Popover popover, Grid grid ) {

    add_range_setting( grid, 0, _( "Spaces" ), 1, 20, 1, _spaces, (value) => {
      _spaces = value;
      update_button_label();
    });

  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "spaces", _spaces.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    var s = node->get_prop( "spaces" );
    if( s != null ) {
      _spaces = int.parse( s );
    }
    update_button_label();
  }

}
