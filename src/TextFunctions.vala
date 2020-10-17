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

  private Array<TextFunction> _functions;
  private Array<string>       _categories;
  private Array<int>          _map;
  private string              _favorites_file;
  private string              _custom_file;

  /* Constructor */
  public TextFunctions( MainWindow win ) {

    _favorites_file = GLib.Path.build_filename( TextShine.get_home_dir(), "favorites.xml" );
    _custom_file    = GLib.Path.build_filename( TextShine.get_home_dir(), "custom.xml" );

    _functions  = new Array<TextFunction>();
    _categories = new Array<string>();
    _map        = new Array<int>();

    /* Category - case */
    add_function( "case", new CaseCamel() );
    add_function( "case", new CaseLower() );
    add_function( "case", new CaseSentence() );
    add_function( "case", new CaseSnake() );
    add_function( "case", new CaseTitle() );
    add_function( "case", new CaseUpper() );

    /* Category - insert */
    add_function( "insert", new InsertLineStart( win ) );
    add_function( "insert", new InsertLineEnd( win ) );
    add_function( "insert", new InsertLineNumbers() );
    add_function( "insert", new InsertLoremIpsum() );
    add_function( "insert", new InsertFile( win ) );

    /* Category - remove */
    add_function( "remove", new RemoveBlankLines() );
    add_function( "remove", new RemoveDuplicateLines() );
    add_function( "remove", new RemoveLeadingWhitespace() );
    add_function( "remove", new RemoveTrailingWhitespace() );
    add_function( "remove", new RemoveLineNumbers() );
    add_function( "remove", new RemoveSelected() );

    /* Category - replace */
    add_function( "replace", new ReplaceTabsSpaces() );
    add_function( "replace", new ReplacePeriodsEllipsis() );
    add_function( "replace", new ReplaceReturnSpace() );
    add_function( "replace", new ReplaceSelected( win ) );

    /* Category - sort */
    add_function( "sort", new SortLines() );
    add_function( "sort", new SortReverseChars() );
    add_function( "sort", new SortMoveLines() );

    /* Category - indent */
    add_function( "indent", new Indent() );
    add_function( "indent", new Unindent() );
    add_function( "indent", new IndentXML() );

    /* Category - search-replace */
    add_function( "search-replace", new Find( win ) );
    add_function( "search-replace", new RegExpr( win ) );
    add_function( "search-replace", new InvertSelected() );
    add_function( "search-replace", new ClearSelected() );

    /* Load the custom functions */
    load_functions();
    load_custom();
    load_favorites();

  }

  /*
   Populate the functions and categories lists and creates a mapping between the
   two.
  */
  public void add_function( string category, TextFunction function ) {

    var ct_index = category_index( category );

    if( ct_index == -1 ) {
      ct_index = (int)_categories.length;
      _categories.append_val( category );
    }

    _functions.append_val( function );
    _map.append_val( ct_index );

    function.settings_changed.connect( save_functions );

  }

  /* Removes the given function index */
  public void remove_function( TextFunction function ) {

    for( int i=0; i<_functions.length; i++ ) {
      if( _functions.index( i ) == function ) {
        _functions.index( i ).settings_changed.disconnect( save_functions );
        _functions.remove_index( i );
        _map.remove_index( i );
        break;
      }
    }

  }

  /* Returns the index of the given category in the array */
  private int category_index( string category ) {

    for( int i=0; i<_categories.length; i++ ) {
      if( _categories.index( i ) == category ) {
        return( i );
      }
    }

    return( -1 );

  }

  /* Returns the list of text functions associated with the given category */
  public Array<TextFunction> get_category_functions( string category ) {

    var index     = category_index( category );
    var functions = new Array<TextFunction>();

    if( index != -1 ) {
      for( int i=0; i<_map.length; i++ ) {
        if( _map.index( i ) == index ) {
          functions.append_val( _functions.index( i ) );
        }
      }
    }

    return( functions );

  }

  /*
   Returns the text function associated with the given, if found; otherwise,
   returns null.
  */
  public TextFunction? get_function_by_name( string name ) {

    for( int i=0; i<_functions.length; i++ ) {
      if( _functions.index( i ).name == name ) {
        return( _functions.index( i ) );
      }
    }

    return( null );

  }

  /* Add the given function to the favorite list */
  public void favorite_function( TextFunction function ) {

    add_function( "favorites", function );

    /* Save the favorites changes */
    save_favorites();

  }

  /* Removes the given function from the favorite list */
  public int unfavorite_function( TextFunction function ) {

    var favorites = get_category_functions( "favorites" );
    var index     = -1;

    for( int i=0; i<favorites.length; i++ ) {
      if( favorites.index( i ) == function ) {
        index = i;
      }
    }

    /* Remove the function from our list */
    remove_function( function );

    /* Save the favorites changes */
    save_favorites();

    return( index );

  }

  /* Save the favorites to the XML file */
  private void save_favorites() {

    var functions = get_category_functions( "favorites" );

    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "favorites" );
    root->set_prop( "version", TextShine.version );

    for( int i=0; i<functions.length; i++ ) {
      root->add_child( functions.index( i ).save() );
    }

    doc->set_root_element( root );
    doc->save_format_file( _favorites_file, 1 );

    delete doc;

  }

  /* Load the favorites to the XML file */
  private void load_favorites() {

    Xml.Doc* doc = Xml.Parser.read_file( _favorites_file, null, Xml.ParserOption.HUGE );
    if( doc == null ) {
      return;
    }

    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( (it->type == Xml.Node.ELEMENT_NODE) && (it->name == "function") ) {
        var name = it->get_prop( "name" );
        for( int i=0; i<_functions.length; i++ ) {
          if( _functions.index( i ).name == name ) {
            var fn = _functions.index( i ).copy();
            fn.load( it, this );
            add_function( "favorites", fn );
            break;
          }
        }
      }
    }

    delete doc;

  }

  public void save_functions() {

    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "functions" );
    root->set_prop( "version", TextShine.version );

    for( int i=0; i<_functions.length; i++ ) {
      var function = _functions.index( i );
      var category = _categories.index( _map.index( i ) );
      if( (category != "favorites") && function.settings_available() ) {
        root->add_child( function.save() );
      }
    }

    doc->set_root_element( root );
    doc->save_format_file( _custom_file, 1 );

    delete doc;

  }

  public void load_functions() {

    Xml.Doc* doc = Xml.Parser.read_file( _custom_file, null, Xml.ParserOption.HUGE );
    if( doc == null ) {
      return;
    }

    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( (it->type == Xml.Node.ELEMENT_NODE) && (it->name == "function") ) {
        var name     = it->get_prop( "name" );
        var function = get_function_by_name( name );
        if( function != null ) {
          function.load( it, this );
        }
      }
    }

  }

  /* Saves the custom functions to their own file */
  public void save_custom() {

    var functions = get_category_functions( "custom" );

    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "customs" );
    root->set_prop( "version", TextShine.version );

    for( int i=0; i<functions.length; i++ ) {
      root->add_child( functions.index( i ).save() );
    }

    doc->set_root_element( root );
    doc->save_format_file( _custom_file, 1 );

    delete doc;

  }

  /* Load the custom functions from the XML file */
  private void load_custom() {

    Xml.Doc* doc = Xml.Parser.read_file( _custom_file, null, Xml.ParserOption.HUGE );
    if( doc == null ) {
      return;
    }

    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( (it->type == Xml.Node.ELEMENT_NODE) && (it->name == "custom") ) {
        var custom = new CustomFunction();
        custom.load( it, this );
        add_function( "custom", custom );
      }
    }

  }

}

