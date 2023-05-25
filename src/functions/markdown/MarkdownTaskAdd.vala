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

public enum MarkdownTaskApplyType {
  LINE,
  PARAGRAPH,
  LENGTH;

  public string label() {
    switch( this ) {
      case LINE      :  return( _( "Line" ) );
      case PARAGRAPH :  return( _( "Paragraph" ) );
      default        :  assert_not_reached();
    }
  }

  public string to_string() {
    switch( this ) {
      case LINE      :  return( "line" );
      case PARAGRAPH :  return( "paragraph" );
      default        :  assert_not_reached();
    }
  }

  public static MarkdownTaskApplyType parse( string val ) {
    switch( val ) {
      case "line"      :  return( LINE );
      case "paragraph" :  return( PARAGRAPH );
      default          :  assert_not_reached();
    }
  }
}

public class MarkdownTaskAdd : TextFunction {


  private Regex                 _re;
  private MarkdownTaskApplyType _apply = MarkdownTaskApplyType.LINE;

  /* Constructor */
  public MarkdownTaskAdd( bool custom = false ) {
    base( "markdown-task-add", custom );
    try {
      _re = new Regex( """^\s*\[[ xX]\] (.*)$""" );
    } catch( RegexError e ) {}
  }

  public override string get_description() {
    return( _( "Converts each line of text into a Markdown task." ) );
  }

  protected override string get_label0() {
    return( _( "Add Markdown Tasks" ) );
  }

  public override TextFunction copy( bool custom ) {
    var tf = new MarkdownTaskAdd( custom );
    tf._apply = _apply;
    return( tf );
  }

  public override bool matches( TextFunction function ) {
    return( base.matches( function ) && (_apply == ((MarkdownTaskAdd)function)._apply) );
  }

  public override bool settings_available() {
    return( true );
  }

  /* Populates the given popover with the settings */
  public override void add_settings( Grid grid ) {
    add_menubutton_setting( grid, 0, _( "Apply To" ), _apply.label(), MarkdownTaskApplyType.LENGTH, (value) => {
      var apply = (MarkdownTaskApplyType)value;
      return( apply.label() );
    }, (value) => {
      _apply = (MarkdownTaskApplyType)value;
    });
  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "apply", _apply.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    var a = node->get_prop( "apply" );
    if( a != null ) {
      _apply = MarkdownTaskApplyType.parse( a );
    }
  }

  public override string transform_text( string original, int cursor_pos ) {
    var str   = "";
    var first = true;
    var add   = false;
    MatchInfo match;
    foreach( string line in original.split( "\n" ) ) {
      if( first ) {
        first = false;
      } else {
        str += "\n";
      }
      if( line.strip() == "" ) {
        add = false;
      } else if( !_re.match( line, 0, out match ) ) {
        if( !add ) {
          str += "[ ] ";
        } else if( add ) {
          str += "    ";
        }
        add = (_apply == MarkdownTaskApplyType.PARAGRAPH);
      }
      str += line;
    }
    return( str );
  }

}


