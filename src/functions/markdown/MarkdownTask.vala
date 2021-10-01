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

public class MarkdownTask : TextFunction {

  public enum TaskAction {
    ADD,
    REMOVE,
    MARK_COMPLETE,
    MARK_INCOMPLETE,
    REMOVE_COMPLETED,
    LENGTH;

    public string label() {
      switch( this ) {
        case ADD              :  return( "Add" );
        case REMOVE           :  return( "Remove" );
        case MARK_COMPLETE    :  return( "Mark Complete" );
        case MARK_INCOMPLETE  :  return( "Mark Incomplete" );
        case REMOVE_COMPLETED :  return( "Remove Completed" );
        default               :  assert_not_reached();
      }
    }

    public string to_string() {
      switch( this ) {
        case ADD              :  return( "add" );
        case REMOVE           :  return( "remove" );
        case MARK_COMPLETE    :  return( "mark-complete" );
        case MARK_INCOMPLETE  :  return( "mark-incomplete" );
        case REMOVE_COMPLETED :  return( "remove-completed" );
        default               :  assert_not_reached();
      }
    }

    public static TaskAction parse( string val ) {
      switch( val ) {
        case "add"              :  return( ADD );
        case "remove"           :  return( REMOVE );
        case "mark-complete"    :  return( MARK_COMPLETE );
        case "mark-incomplete"  :  return( MARK_INCOMPLETE );
        case "remove-completed" :  return( REMOVE_COMPLETED );
        default                 :  assert_not_reached();
      }
    }
  }

  TaskAction _action = TaskAction.ADD;
  Regex      _complete_re;
  Regex      _incomplete_re;
  Regex      _any_re;

  /* Constructor */
  public MarkdownTask( bool custom = false ) {
    base( "markdown-task", custom, FunctionDirection.LEFT_TO_RIGHT );
    try {
      _any_re        = new Regex( """^\s*\[[ xX]\] (.*)$""" );
      _complete_re   = new Regex( """^(\s*)\[[xX]\] (.*)$""" );
      _incomplete_re = new Regex( """^(\s*)\[ \] (.*)$""" );
    } catch( RegexError e ) {}
  }

  protected override string get_label0() {
    return( _( "Tasks - %s" ).printf( _action.label() ) );
  }

  public override TextFunction copy( bool custom ) {
    var tmp = new MarkdownTask( custom );
    tmp._action = _action;
    return( tmp );
  }

  public override bool matches( TextFunction function ) {
    if( base.matches( function ) ) {
      var func = (MarkdownTask)function;
      return( _action == func._action );
    }
    return( false );
  }

  /* Specify that we have settings to display */
  public override bool settings_available() {
    return( true );
  }

  /* Populates the given popover with the settings */
  public override void add_settings( Grid grid ) {

    add_menubutton_setting( grid, 1, _( "Action" ), _action.label(), TaskAction.LENGTH, (value) => {
      var type = (TaskAction)value;
      return( type.label() );
    }, (value) => {
      _action = (TaskAction)value;
      update_button_label();
    });

  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "action", _action.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    var a = node->get_prop( "action" );
    if( a != null ) {
      _action = TaskAction.parse( a );
    }
    update_button_label();
  }

  private string add( string original ) {
    var str   = "";
    var first = true;
    MatchInfo match;
    foreach( string line in original.split( "\n" ) ) {
      if( first ) {
        first = false;
      } else {
        str += "\n";
      }
      if( (line.strip() != "") && !_any_re.match( line, 0, out match ) ) {
        str += "[ ] " + line;
      } else {
        str += line;
      }
    }
    return( str );
  }

  private string remove( string original ) {
    var str   = "";
    var first = true;
    MatchInfo match;
    foreach( string line in original.split( "\n" ) ) {
      if( first ) {
        first = false;
      } else {
        str += "\n";
      }
      if( _any_re.match( line, 0, out match ) ) {
        str += match.fetch( 1 );
      } else {
        str += line;
      }
    }
    return( str );
  }

  private string mark_complete( string original ) {
    var str   = "";
    var first = true;
    MatchInfo match;
    foreach( string line in original.split( "\n" ) ) {
      if( first ) {
        first = false;
      } else {
        str += "\n";
      }
      if( _incomplete_re.match( line, 0, out match ) ) {
        str += match.fetch( 1 ) + "[x] " + match.fetch( 2 );
      } else {
        str += line;
      }
    }
    return( str );
  }

  private string mark_incomplete( string original ) {
    var str   = "";
    var first = true;
    MatchInfo match;
    foreach( string line in original.split( "\n" ) ) {
      if( first ) {
        first = false;
      } else {
        str += "\n";
      }
      if( _complete_re.match( line, 0, out match ) ) {
        str += match.fetch( 1 ) + "[ ] " + match.fetch( 2 );
      } else {
        str += line;
      }
    }
    return( str );
  }

  private string remove_completed( string original ) {
    var str = "";
    MatchInfo match;
    foreach( string line in original.split( "\n" ) ) {
      if( !_complete_re.match( line, 0, out match ) ) {
        str += line + "\n";
      }
    }
    return( str );
  }

  public override string transform_text( string original, int cursor_pos ) {
    switch( _action ) {
      case TaskAction.ADD              :  return( add( original ) );
      case TaskAction.REMOVE           :  return( remove( original ) );
      case TaskAction.MARK_COMPLETE    :  return( mark_complete( original ) );
      case TaskAction.MARK_INCOMPLETE  :  return( mark_incomplete( original ) );
      case TaskAction.REMOVE_COMPLETED :  return( remove_completed( original ) );
      default                          :  assert_not_reached();
    }
  }

}


