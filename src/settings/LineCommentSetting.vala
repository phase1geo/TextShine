/*
* Copyright (c) 2026 (https://github.com/phase1geo/TextShine)
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

public enum LineCommentType {
  NONE,
  SLASH2,
  HASH,
  DASH2,
  SEMIC,
  PERCENT,
  APOS,
  TICK_DASH2,
  CUSTOM,
  NUM;

  public string to_string() {
    switch( this ) {
      case NONE       :  return( "none" );
      case SLASH2     :  return( "slash2" );
      case HASH       :  return( "hash" );
      case DASH2      :  return( "dash2" );
      case SEMIC      :  return( "semic" );
      case PERCENT    :  return( "percent" );
      case APOS       :  return( "apos" );
      case TICK_DASH2 :  return( "tick-dash2" );
      case CUSTOM     :  return( "custom" );
      default         :  assert_not_reached();
    }
  }

  public static LineCommentType parse( string str ) {
    switch( str ) {
      case "none"       :  return( NONE );
      case "slash2"     :  return( SLASH2 );
      case "hash"       :  return( HASH );
      case "dash2"      :  return( DASH2 );
      case "semic"      :  return( SEMIC );
      case "percent"    :  return( PERCENT );
      case "apos"       :  return( APOS );
      case "tick-dash2" :  return( TICK_DASH2 );
      case "custom"     :  return( CUSTOM );
      default           :  return( NONE );
    }
  }

  public string label() {
    var comment = _( "Comment" );
    switch( this ) {
      case SLASH2     :  return( "<b>//</b> <i>%s</i>".printf( comment ) );
      case HASH       :  return( "<b>#</b> <i>%s</i>".printf( comment ) );
      case DASH2      :  return( "<b>--</b> <i>%s</i>".printf( comment ) );
      case SEMIC      :  return( "<b>;</b> <i>%s</i>".printf( comment ) );
      case PERCENT    :  return( "<b>%</b> <i>%s</i>".printf( comment ) );
      case APOS       :  return( "<b>'=</b> <i>%s</i>".printf( comment ) );
      case TICK_DASH2 :  return( "<b>`--</b> <i>%s</i>".printf( comment ) );
      case CUSTOM     :  return( _( "Custom" ) );
      default         :  return( _( "None" ) );
    }
  }

  public string start_string( string custom ) {
    switch( this ) {
      case NONE       :  return( "" );
      case SLASH2     :  return( "//" );
      case HASH       :  return( "#*" );
      case DASH2      :  return( "--" );
      case SEMIC      :  return( ";" );
      case PERCENT    :  return( "%" );
      case APOS       :  return( "'" );
      case TICK_DASH2 :  return( "`--" );
      case CUSTOM     :  return( custom );
      default         :  assert_not_reached();
    }
  }

}

public class LineCommentSetting : GlobalSetting {

  private Array<LineCommentType> _types;
  private Array<string>          _custom_start;

  //-------------------------------------------------------------
  // Constructor
  public LineCommentSetting() {

    base( "line", _( "Global Line Comment Settings" ) );

    _types        = new Array<LineCommentType>();
    _custom_start = new Array<string>();

    var none = LineCommentType.NONE;
    _types.append_val( none );
    _types.append_val( none );
    _types.append_val( none );

    _custom_start.append_val( "" );
    _custom_start.append_val( "" );
    _custom_start.append_val( "" );

  }

  //-------------------------------------------------------------
  // Constructor from XML
  public LineCommentSetting.from_xml( Xml.Node* node ) {

    base( "line", _( "Global Line Comment Settings" ) );

    _types        = new Array<LineCommentType>();
    _custom_start = new Array<string>();

    load( node );

  }

  //-------------------------------------------------------------
  // Creates a copy of this setting and returns it to the calling
  // function.
  public override GlobalSetting copy() {
    var copy = new LineCommentSetting();
    for( int i=0; i<_types.length; i++ ) {
      copy._types.insert_val( i, _types.index( i ) );
      copy._types.remove_index( i + 1 );
      copy._custom_start.insert_val( i, _custom_start.index( i ) );
      copy._custom_start.remove_index( i + 1 );
    }
    return( copy );
  }

  //-------------------------------------------------------------
  // Returns the number of block comment types we hold.
  public int size() {
    return( (int)_types.length );
  }

  //-------------------------------------------------------------
  // Returns the starting block comment string for the given index.
  // If this index is invalid, returns the empty string.
  public string start_string( int index ) {
    return( _types.index( index ).start_string( _custom_start.index( index ) ) );
  }

  //-------------------------------------------------------------
  // Adds the settings to the given grid
  public override void add_settings( Grid grid ) {

    for( int i=0; i<_types.length; i++ ) {

      var line_type = (LineCommentType)_types.index( i );
      var index     = i;

      var custom_focus = new EventControllerFocus();
      var custom_start = new Entry() {
        halign = Align.START,
        width_chars = 10
      };
      custom_start.add_controller( custom_focus );
      var custom_comment = new Label( "<i>%s</i>".printf( _( "Comment" ) ) ) {
        use_markup = true
      };
      var custom_box = new Box( Orientation.HORIZONTAL, 5 ) {
        visible = (line_type == LineCommentType.CUSTOM)
      };
      custom_box.append( custom_start );
      custom_box.append( custom_comment );

      custom_focus.leave.connect(() => {
        _custom_start.insert_val( i, custom_start.text.strip() );
        _custom_start.remove_index( i + 1 );
      });

      add_markup_menubutton_setting( grid, (i * 2), _( "Syntax" ), line_type, LineCommentType.NUM, (value) => {
        var ltype = (LineCommentType)value;
        return( ltype.label() );
      }, (value) => {
        var ltype = (LineCommentType)value;
        _types.insert_val( index, ltype );
        _types.remove_index( index + 1 );
        custom_box.visible = (_types.index( index ) == LineCommentType.CUSTOM);
      });

      grid.attach( custom_box, 0, ((i * 2) + 1) );

    }

  }

  //-------------------------------------------------------------
  // Called to save the contents of this setting to XML format.
  public override Xml.Node* save() {
    var node = base.save();
    for( int i=0; i<_types.length; i++ ) {
      Xml.Node* lnode = new Xml.Node( null, "comment" );
      var ltype = (LineCommentType)_types.index( i );
      lnode->set_prop( "type", ltype.to_string() );
      if( ltype == LineCommentType.CUSTOM ) {
        lnode->set_prop( "start", _custom_start.index( i ) );
      }
      node->add_child( lnode );
    }
    return( node );
  }

  //-------------------------------------------------------------
  // Called to load the contents of this setting from XML
  public override void load( Xml.Node* node ) {
    base.load( node );
    var index = 0;
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "comment") ) {
        var t = it->get_prop( "type" );
        if( t != null ) {
          var ltype = LineCommentType.parse( t );
          _types.append_val( ltype );
          _custom_start.append_val( "" );
          if( ltype == LineCommentType.CUSTOM ) {
            var s = it->get_prop( "start" );
            if( s != null ) {
              _custom_start.insert_val( index, s );
              _custom_start.remove_index( index + 1 );
            }
          }
          index++;
        }
      }
    }
  }

}
