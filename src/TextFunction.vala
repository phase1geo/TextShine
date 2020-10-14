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

public delegate void SettingRangeChangedFunc( int value );
public delegate void SettingStringChangedFunc( string value );
public delegate void SettingBoolChangedFunc( bool value );

public class TextFunction {

  private string _name;

  public string name {
    get {
      return( _name );
    }
  }
  public string label {
    owned get {
      switch( direction ) {
        case FunctionDirection.BOTTOM_UP     :
        case FunctionDirection.RIGHT_TO_LEFT :  return( get_label1() );
        default                              :  return( get_label0() );
      }
    }
  }
  public FunctionDirection direction { get; set; default = FunctionDirection.NONE; }

  public signal void update_button_label();
  public signal void settings_changed();

  /* Constructor */
  public TextFunction( string name, FunctionDirection dir = FunctionDirection.NONE ) {
    _name     = name;
    direction = dir;
  }

  protected virtual string get_label0() {
    assert( false );
    return( "" );
  }

  protected virtual string get_label1() {
    assert( false );
    return( "" );
  }

  /* Creates a copy of this function */
  public virtual TextFunction copy() {
    assert( false );
    return( new TextFunction( _name, direction ) );
  }

  /* Executes this text function using the editor */
  protected void run( Editor editor, UndoItem undo_item ) {
    var ranges = new Array<Editor.Position>();
    editor.get_ranges( ranges );
    for( int i=((int)ranges.length - 1); i>=0; i-- ) {
      var start = ranges.index( i ).start;
      var end   = ranges.index( i ).end;
      editor.replace_text( start, end, transform_text( editor.get_text( start, end ), editor.get_cursor_pos( start, end ) ), undo_item );
    }
  }

  /*
   This is the main function which will be called from the UI to perform the
   transformation action.  By default, we will run the transformation one time,
   but the text function can override this if it is providing a UI element
   that the user needs to add input to prior to the transformation.
  */
  public virtual void launch( Editor editor ) {
    var undo_item = new UndoItem( label );
    run( editor, undo_item );
    editor.undo_buffer.add_item( undo_item );
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

  /* Returns true if settings are available */
  public virtual bool settings_available() {
    return( false );
  }

  /* Populates the given popover with the text function settings widgets */
  public virtual void add_settings( Grid grid ) {
    // By default, we will do nothing
  }

  /* Called whenever a number setting with a range needs to be added */
  protected void add_range_setting( Grid grid, int row, string label, int min_value, int max_value, int step, int init_value, SettingRangeChangedFunc callback ) {

    var lbl = new Label( label );
    lbl.halign = Align.START;

    var sb = new SpinButton.with_range( min_value, max_value, step );
    sb.halign = Align.END;
    sb.value  = init_value;
    sb.value_changed.connect(() => {
      callback( (int)sb.value );
      settings_changed();
    });

    grid.attach( lbl, 0, row );
    grid.attach( sb,  1, row );

  }

  /* Called whenever a string setting widget needs to be added */
  protected void add_string_setting( Grid grid, int row, string label, string init_value, SettingStringChangedFunc callback ) {

    var lbl = new Label( label );
    lbl.halign = Align.START;

    var entry = new Entry();
    entry.text = init_value;
    entry.activate.connect(() => {
      init_value = entry.text;
    });
    entry.focus_out_event.connect((e) => {
      callback( entry.text );
      settings_changed();
      return( false );
    });

    grid.attach( lbl, 0, row );
    grid.attach( entry, 1, row );

  }

  /* Called whenever a boolean setting widget needs to be added */
  protected void add_bool_setting( Grid grid, int row, string label, bool init_value, SettingBoolChangedFunc callback ) {

    var lbl = new Label( label );
    lbl.halign = Align.START;

    var sw  = new Switch();
    sw.halign = Align.END;
    sw.active = init_value;
    sw.state_set.connect(() => {
      callback( sw.active );
      settings_changed();
      return( false );
    });

    grid.attach( lbl, 0, row );
    grid.attach( sw,  1, row );

  }

  /* Called to save this text function in XML format */
  public virtual Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "function" );
    node->set_prop( "name", _name );
    node->set_prop( "direction", direction.to_string() );
    return( node );
  }

  /* Loads the contents of this text function */
  public virtual void load( Xml.Node* node, TextFunctions functions ) {
    var d = node->get_prop( "direction" );
    if( d != null ) {
      direction = FunctionDirection.parse( d );
    }
  }

}

