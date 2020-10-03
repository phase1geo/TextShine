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

public enum FunctionDirection {
  NONE = 0,       // Not applicable
  TOP_DOWN,       // Sorts top-down
  BOTTOM_UP,      // Sorts button-up
  LEFT_TO_RIGHT,  // Converts left side to the right side
  RIGHT_TO_LEFT;  // Converts right side to the left side

  public string to_string() {
    switch( this ) {
      case NONE          :  return( "none" );
      case TOP_DOWN      :  return( "top-down" );
      case BOTTOM_UP     :  return( "bottom-up" );
      case LEFT_TO_RIGHT :  return( "left-to-right" );
      case RIGHT_TO_LEFT :  return( "right-to-left" );
      default            :  assert_not_reached();
    }
  }

  public static FunctionDirection parse( string val ) {
    switch( val ) {
      case "none"          :  return( NONE );
      case "top-down"      :  return( TOP_DOWN );
      case "bottom-up"     :  return( BOTTOM_UP );
      case "left-to-right" :  return( LEFT_TO_RIGHT );
      case "right-to-left" :  return( RIGHT_TO_LEFT );
      default              :  assert_not_reached();
    }
  }

  public bool is_vertical() {
    return( (this == TOP_DOWN) || (this == BOTTOM_UP) );
  }

  public bool is_horizontal() {
    return( (this == LEFT_TO_RIGHT) || (this == RIGHT_TO_LEFT) );
  }
}

public class TextFunction {

  private string _name;
  private string _label0;
  private string _label1;

  public string name {
    get {
      return( _name );
    }
  }
  public string label {
    get {
      switch( direction ) {
        case FunctionDirection.BOTTOM_UP     :
        case FunctionDirection.RIGHT_TO_LEFT :  return( _label1 );
        default                              :  return( _label0 );
      }
    }
  }
  public string label0 {
    get {
      return( _label0 );
    }
  }
  public string label1 {
    get {
      return( _label1 );
    }
  }
  public FunctionDirection direction { get; set; default = FunctionDirection.NONE; }

  /* Constructor */
  public TextFunction( string name, string label0, string label1 = "", FunctionDirection dir = FunctionDirection.NONE ) {
    _name     = name;
    _label0   = label0;
    _label1   = label1;
    direction = dir;
  }

  /* Executes this text function using the editor */
  protected void run( Editor editor ) {
    var ranges = new Array<Editor.Position>();
    editor.get_ranges( ranges );
    for( int i=((int)ranges.length - 1); i>=0; i-- ) {
      var start = ranges.index( i ).start;
      var end   = ranges.index( i ).end;
      editor.replace_text( start, end, transform_text( editor.get_text( start, end ), editor.get_cursor_pos( start, end ) ) );
    }
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
  protected virtual string transform_text( string original, int cursor_pos ) {
    return( original );
  }

  /* Returns the text change from this function */
  public virtual TextChange get_change() {
    return( new TextChange( this ) );
  }

  /*
   Helper function which returns the new string that replaces the given range
   from the original text with the new replacement text.
  */
  protected string replace_text( string original, int start_pos, int end_pos, string replacement ) {
    return( original.splice( 0, start_pos ) + replacement + original.splice( end_pos, original.length ) );
  }

}

