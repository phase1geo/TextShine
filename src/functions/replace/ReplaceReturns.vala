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

public class ReplaceReturns : TextFunction {

  private int _returns = 2;

  /* Constructor */
  public ReplaceReturns( bool custom = false ) {
    base( "replace-returns", custom, FunctionDirection.LEFT_TO_RIGHT );
  }

  protected override string get_label0() {
    return( _( "Single Return With %d Returns" ).printf( _returns ) );
  }

  protected override string get_label1() {
    return( _( "%d Returns With Single Return" ).printf( _returns ) );
  }

  public override TextFunction copy( bool custom ) {
    var fn = new ReplaceReturns( custom );
    fn.direction = direction;
    fn._returns  = _returns;
    return( fn );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    var returns = string.nfill( _returns, '\n' );
    if( direction == FunctionDirection.LEFT_TO_RIGHT ) {
      return( original.replace( "\n", returns ) );
    } else {
      return( original.replace( returns, "\n" ) );
    }
  }

  /* Specify that we have settings to display */
  public override bool settings_available() {
    return( true );
  }

  /* Populates the given popover with the settings */
  public override void add_settings( Grid grid ) {

    add_range_setting( grid, 0, _( "Returns" ), 2, 20, 1, _returns, (value) => {
      _returns = value;
      update_button_label();
    });

  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "returns", _returns.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    var s = node->get_prop( "returns" );
    if( s != null ) {
      _returns = int.parse( s );
    }
    update_button_label();
  }

}
