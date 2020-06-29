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

public class TextFunction {

  private string _name;
  private string _label;
  private string _category;

  public string label {
    get {
      return( _label );
    }
  }

  /* Constructor */
  public TextFunction( string name, string label, string category ) {
    _name     = name;
    _label    = label;
    _category = category;
  }

  /* Called to save this text function */
  public Xml.Node* save() {
    Xml.Node* n = new Xml.Node( null, "function" );
    n->set_prop( "name", _name );
    save_contents( n );
    return( n );
  }

  /* Loads the contents of this Xml node */
  public void load( Xml.Node* n ) {
    load_contents( n );
  }

  /* Executes this text function using the editor */
  protected void run( Editor editor ) {
    editor.replace_text( transform_text( editor.get_current_text() ) );
  }

  /*
   This is the main function which will be called from the UI to perform the
   transformation action.  By default, we will run the transformation one time,
   but the text function can override this if it is providing a UI element
   that the user needs to add input to prior to the transformation.
  */
  public virtual void launch( Editor editor ) {
    run( editor );
  }

  /* Transforms the given text */
  protected virtual string transform_text( string original ) {
    return( original );
  }

  /* Loads the contents of this node */
  protected virtual void save_contents( Xml.Node* n ) {}

  /* Saves the contents of this node */
  protected virtual void load_contents( Xml.Node* n ) {}

  /*
   Helper function which returns the new string that replaces the given range
   from the original text with the new replacement text.
  */
  protected string replace_text( string original, int start_pos, int end_pos, string replacement ) {
    stdout.printf( "first (%s), second (%s), third (%s)\n", original.splice( 0, start_pos ), replacement, original.splice( end_pos, original.length ) );
    return( original.splice( 0, start_pos ) + replacement + original.splice( end_pos, original.length ) );
  }

}

