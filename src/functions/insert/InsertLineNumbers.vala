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

public class InsertLineNumbers : TextFunction {

  private string _separator;
  private bool   _pad;
  private bool   _skip_blanks;

  /* Constructor */
  public InsertLineNumbers( bool custom = false ) {
    base( "insert-line-numbers", custom );
    _separator   = ".";
    _pad         = false;
    _skip_blanks = true;
  }

  protected override string get_label0() {
    return( _( "Insert Line Numbers" ) );
  }

  public override TextFunction copy( bool custom ) {
    var fn = new InsertLineNumbers( custom );
    fn._separator   = _separator;
    fn._pad         = _pad;
    fn._skip_blanks = _skip_blanks;
    return( fn );
  }

  public override bool matches( TextFunction function ) {
    if( base.matches( function ) ) {
      var func = (InsertLineNumbers)function;
      return(
        (_separator == func._separator) &&
        (_pad == func._pad) &&
        (_skip_blanks == func._skip_blanks)
      );
    }
    return( false );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    var lines     = original.split( "\n" );
    var num_lines = lines.length;
    var linenum   = 1;
    for( int i=0; i<num_lines; i++ ) {
      if( !_skip_blanks || (lines[i].strip() != "") ) {
        var num = linenum++.to_string();
        if( _pad ) {
          lines[i] = num + _separator + string.nfill( ((num_lines.to_string().char_count() - num.char_count()) + 1), ' ' ) + lines[i];
        } else {
          lines[i] = num + _separator + " " + lines[i];
        }
      }
    }
    return( string.joinv( "\n", lines ) );
  }

  /* Specify that we have settings to display */
  public override bool settings_available() {
    return( true );
  }

  /* Populates the given popover with the settings */
  public override void add_settings( Popover popover, Grid grid ) {

    add_string_setting( grid, 0, _( "Separator" ), _separator, (value) => {
      _separator = value;
    });

    add_bool_setting( grid, 1, _( "Add Padding" ), _pad, (value) => {
      _pad = value;
    });

    add_bool_setting( grid, 2, _( "Skip Blank Lines" ), _skip_blanks, (value) => {
      _skip_blanks = value;
    });

  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "separator", _separator );
    node->set_prop( "pad", _pad.to_string() );
    node->set_prop( "skip_blanks", _skip_blanks.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    var s = node->get_prop( "separator" );
    if( s != null ) {
      _separator = s;
    }
    var p = node->get_prop( "pad" );
    if( p != null ) {
      _pad = bool.parse( p );
    }
    var sb = node->get_prop( "skip_blanks" );
    if( sb != null ) {
      _skip_blanks = bool.parse( sb );
    }
    update_button_label();
  }

}

