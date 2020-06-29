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

public class TextFunctions {

  /* Constructor */
  public TextFunctions( Editor editor, Box box ) {

    box.set_size_request( 200, 600 );

    /* Create scrolled box */
    var cbox = new Box( Orientation.VERTICAL, 0 );
    var sw   = new ScrolledWindow( null, null );
    var vp   = new Viewport( null, null );
    vp.set_size_request( 200, 600 );
    vp.add( cbox );
    sw.add( vp );

    /* Add widgets to box */
    cbox.pack_start( create_case( editor ),           false, false, 5 );
    cbox.pack_start( create_search_replace( editor ), false, false, 5 );

    box.pack_start( sw, true, true, 10 );

  }

  /* Creates category returning expander and item box */
  private Expander create_category( string name, string label, out Box item_box ) {

    var setting = "category-" + name + "-expanded";

    /* Create expander */
    var exp = new Expander( "  " + Utils.make_title( label ) );
    exp.use_markup = true;
    exp.expanded   = TextShine.settings.get_boolean( setting );
    exp.activate.connect(() => {
      TextShine.settings.set_boolean( setting, !exp.expanded );
    });

    item_box = new Box( Orientation.VERTICAL, 10 );
    item_box.border_width = 10;

    exp.add( item_box );

    return( exp );

  }

  /* Adds a function button to the given category item box */
  private void add_function( Box box, Editor editor, TextFunction function ) {

    var button = new Button.with_label( function.label );
    button.xalign = (float)0;
    button.set_relief( ReliefStyle.NONE );
    button.clicked.connect(() => {
      function.launch( editor );
    });

    box.pack_start( button, false, false, 0 );

  }

  /* Adds the case changing functions */
  private Expander create_case( Editor editor ) {
    Box box;
    var exp = create_category( "case", _( "Change Case" ), out box );
    add_function( box, editor, new CaseCamel() );
    add_function( box, editor, new CaseLower() );
    add_function( box, editor, new CaseSentence() );
    add_function( box, editor, new CaseTitle() );
    add_function( box, editor, new CaseUpper() );
    return( exp );
  }

  /* Adds the search and replace functions */
  private Expander create_search_replace( Editor editor ) {
    Box box;
    var exp = create_category( "search-replace", _( "Search and Replace" ), out box );
    add_function( box, editor, new RegExpr() );
    return( exp );
  }

}

