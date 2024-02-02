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

public class MarkdownTaskRemoveCompleted : TextFunction {

  Regex _completed_re;
  Regex _incompleted_re;
  MarkdownTaskApplyType _apply = MarkdownTaskApplyType.LINE;

  /* Constructor */
  public MarkdownTaskRemoveCompleted( bool custom = false ) {
    base( "markdown-task-remove-completed", custom );
    try {
      _completed_re   = new Regex( """^(\s*)\[[xX]\] (.*)$""" );
      _incompleted_re = new Regex( """^(\s*)\[[ ]\] (.*)$""" );
    } catch( RegexError e ) {}
  }

  protected override string get_label0() {
    return( _( "Remove Completed Markdown Tasks" ) );
  }

  public override TextFunction copy( bool custom ) {
    var tf = new MarkdownTaskRemoveCompleted( custom );
    tf._apply = _apply;
    return( tf );
  }

  public override bool matches( TextFunction function ) {
    return( base.matches( function ) && (_apply == ((MarkdownTaskRemoveCompleted)function)._apply) );
  }

  public override bool settings_available() {
    return( true );
  }

  /* Populates the given popover with the settings */
  public override void add_settings( Grid grid ) {
    add_menubutton_setting( grid, 0, _( "Apply To" ), _apply, MarkdownTaskApplyType.LENGTH, (value) => {
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

  private string add_line( string line, ref bool first ) {
    if( first ) {
      first = false;
      return( line );
    }
    return( "\n" + line );
  }

  public override string transform_text( string original, int cursor_pos ) {
    var str = "";
    var first = true;
    var last_deleted = false;
    MatchInfo match;
    foreach( string line in original.split( "\n" ) ) {
      if( _incompleted_re.match( line, 0, out match ) ) {
        str += add_line( line, ref first );
        last_deleted = false;
      } else if( _completed_re.match( line, 0, out match ) ||
                 ((line.strip() == "") && last_deleted) ||
                 ((_apply == MarkdownTaskApplyType.PARAGRAPH) && last_deleted) ) {
        last_deleted = true;
      } else {
        str += add_line( line, ref first );
        last_deleted = false;
      }
    }
    return( str );
  }

}


