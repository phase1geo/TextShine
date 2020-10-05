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

  private SpinButton _sb;
  private int        _spaces = 1;

  /* Constructor */
  public ReplaceTabsSpaces() {
    base( "replace-tabs-spaces", FunctionDirection.LEFT_TO_RIGHT );
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

  public override TextFunction copy() {
    var fn = new ReplaceTabsSpaces();
    fn._spaces = _spaces;
    return( fn );
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
  public override void add_settings( Box box, int padding ) {

    var sbox = new Box( Orientation.HORIZONTAL, 5 );
    var lbl  = new Label( _( "Spaces" ) );

    _sb = new SpinButton.with_range( 1, 20, 1 );
    _sb.value_changed.connect( value_changed );

    sbox.pack_start( lbl, false, true,  5 );
    sbox.pack_end(   _sb, false, false, 5 );

    box.pack_start( sbox, true, true, padding );

  }

  private void value_changed() {
    _spaces = (int)_sb.value;
    update_button_label();
  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "spaces", _spaces.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    var s = node->get_prop( "spaces" );
    if( s != null ) {
      _spaces = int.parse( s );
    }
    update_button_label();
  }

}
