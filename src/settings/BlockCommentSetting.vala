/*
* Copyright (c) 2026 (https://github.com/phase1geo/Minder)
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

public enum BlockCommentType {
  NONE,
  SLASH_STAR,
  PAREN_STAR,
  CURLY,
  CURLY_DASH,
  TICK_HASH,
  HASH_EQUAL,
  EQUAL_BEGIN,
  DASH2_SQUARE,
  PAREN_STAR_BANG,
  SLASH_STAR2,
  CUSTOM,
  NUM;

  public string to_string() {
    switch( this ) {
      case NONE            :  return( "none" );
      case SLASH_STAR      :  return( "slash-star" );
      case PAREN_STAR      :  return( "paren-star" );
      case CURLY           :  return( "curly" );
      case CURLY_DASH      :  return( "curly-dash" );
      case TICK_HASH       :  return( "tick-hash" );
      case HASH_EQUAL      :  return( "hash-equal" );
      case EQUAL_BEGIN     :  return( "equal-begin" );
      case DASH2_SQUARE    :  return( "dash2-square" );
      case PAREN_STAR_BANG :  return( "paren-star-bang" );
      case SLASH_STAR2     :  return( "slash-star2" );
      case CUSTOM          :  return( "custom" );
      default              :  assert_not_reached();
    }
  }

  public static BlockCommentType parse( string str ) {
    switch( str ) {
      case "none"            :  return( NONE );
      case "slash-star"      :  return( SLASH_STAR );
      case "paren-star"      :  return( PAREN_STAR );
      case "curly"           :  return( CURLY );
      case "curly-dash"      :  return( CURLY_DASH );
      case "tick-hash"       :  return( TICK_HASH );
      case "hash-equal"      :  return( HASH_EQUAL );
      case "equal-begin"     :  return( EQUAL_BEGIN );
      case "dash2-square"    :  return( DASH2_SQUARE );
      case "paren-star-bang" :  return( PAREN_STAR_BANG );
      case "slash-star2"     :  return( SLASH_STAR2 );
      case "custom"          :  return( CUSTOM );
      default                :  return( NONE );
    }
  }

  public string label() {
    var comment = _( "Comment" );
    switch( this ) {
      case SLASH_STAR      :  return( "<b>/*</b> <i>%s</i> <b>*/</b>".printf( comment ) );
      case PAREN_STAR      :  return( "<b>(*</b> <i>%s</i> <b>*)</b>".printf( comment ) );
      case CURLY           :  return( "<b>{</b> <i>%s</i> <b>}</b>".printf( comment ) );
      case CURLY_DASH      :  return( "<b>{-</b> <i>%s</i> <b>-}</b>".printf( comment ) );
      case TICK_HASH       :  return( "<b>`#</b> <i>%s</i> <b>`</b>".printf( comment ) );
      case HASH_EQUAL      :  return( "<b>#=</b> <i>%s</i> <b>=#</b>".printf( comment ) );
      case EQUAL_BEGIN     :  return( "<b>=begin</b> <i>%s</i> <b>=end</b>".printf( comment ) );
      case DASH2_SQUARE    :  return( "<b>--[[</b> <i>%s</i> <b>]]</b>".printf( comment ) );
      case PAREN_STAR_BANG :  return( "<b>(*!</b> <i>%s</i> <b>*)</b>".printf( comment ) );
      case SLASH_STAR2     :  return( "<b>/**</b> <i>%s</i> <b>*/</b>".printf( comment ) );
      case CUSTOM          :  return( _( "Custom" ) );
      default              :  return( _( "None" ) );
    }
  }

  public string start_string( string custom ) {
    switch( this ) {
      case NONE            :  return( "" );
      case SLASH_STAR      :  return( "/*" );
      case PAREN_STAR      :  return( "(*" );
      case CURLY           :  return( "{" );
      case CURLY_DASH      :  return( "{-" );
      case TICK_HASH       :  return( "`#" );
      case HASH_EQUAL      :  return( "#=" );
      case EQUAL_BEGIN     :  return( "=begin" );
      case DASH2_SQUARE    :  return( "--[[" );
      case PAREN_STAR_BANG :  return( "(*!" );
      case SLASH_STAR2     :  return( "/**" );
      case CUSTOM          :  return( custom );
      default              :  assert_not_reached();
    }
  }

  public string end_string( string custom ) {
    switch( this ) {
      case NONE            :  return( "" );
      case SLASH_STAR      :  return( "*/" );
      case PAREN_STAR      :  return( "*)" );
      case CURLY           :  return( "}" );
      case CURLY_DASH      :  return( "-}" );
      case TICK_HASH       :  return( "`" );
      case HASH_EQUAL      :  return( "=#" );
      case EQUAL_BEGIN     :  return( "=end" );
      case DASH2_SQUARE    :  return( "]]" );
      case PAREN_STAR_BANG :  return( "*)" );
      case SLASH_STAR2     :  return( "*/" );
      case CUSTOM          :  return( custom );
      default              :  assert_not_reached();
    }
  }


}

public class BlockCommentSetting : GlobalSetting {

  private Array<BlockCommentType> _types;
  private Array<string>           _custom_start;
  private Array<string>           _custom_end;

  //-------------------------------------------------------------
  // Constructor
  public BlockCommentSetting() {

    base( "block", _( "Global Block Comment Settings" ) );

    _types        = new Array<BlockCommentType>();
    _custom_start = new Array<string>();
    _custom_end   = new Array<string>();

    var none = BlockCommentType.NONE;
    _types.append_val( none );
    _types.append_val( none );
    _types.append_val( none );

    _custom_start.append_val( "" );
    _custom_start.append_val( "" );
    _custom_start.append_val( "" );

    _custom_end.append_val( "" );
    _custom_end.append_val( "" );
    _custom_end.append_val( "" );

  }

  //-------------------------------------------------------------
  // Constructor from XML
  public BlockCommentSetting.from_xml( Xml.Node* node ) {

    base( "block", _( "Global Block Comment Settings" ) );

    _types        = new Array<BlockCommentType>();
    _custom_start = new Array<string>();
    _custom_end   = new Array<string>();

    load( node );

  }

  //-------------------------------------------------------------
  // Creates a copy of this setting and returns it to the calling
  // function.
  public override GlobalSetting copy() {
    var copy = new BlockCommentSetting();
    for( int i=0; i<_types.length; i++ ) {
      copy._types.insert_val( i, _types.index( i ) );
      copy._types.remove_index( i + 1 );
      copy._custom_start.insert_val( i, _custom_start.index( i ) );
      copy._custom_start.remove_index( i + 1 );
      copy._custom_end.insert_val( i, _custom_end.index( i ) );
      copy._custom_end.remove_index( i + 1 );
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
  // Returns the ending block comment string for the given index.
  // If this index is invalid, returns the empty string.
  public string end_string( int index ) {
    return( _types.index( index ).end_string( _custom_end.index( index ) ) );
  }

  //-------------------------------------------------------------
  // Adds the settings to the given grid
  public override void add_settings( Grid grid ) {

    for( int i=0; i<_types.length; i++ ) {

      var block_type = (BlockCommentType)_types.index( i );

      var custom_focus = new EventControllerFocus();
      var custom_start = new Entry() {
        halign = Align.START,
        width_chars = 10
      };
      custom_start.add_controller( custom_focus );
      var custom_comment = new Label( "<i>%s</i>".printf( _( "Comment" ) ) );
      var custom_end = new Entry() {
        halign = Align.START,
        width_chars = 10
      };
      custom_end.add_controller( custom_focus );
      var custom_box = new Box( Orientation.HORIZONTAL, 5 ) {
        visible = (block_type == BlockCommentType.CUSTOM)
      };
      custom_box.append( custom_start );
      custom_box.append( custom_comment );
      custom_box.append( custom_end );

      custom_focus.leave.connect(() => {
        _custom_start.insert_val( i, custom_start.text.strip() );
        _custom_start.remove_index( i + 1 );
        _custom_end.insert_val( i, custom_end.text.strip() );
        _custom_end.remove_index( i + 1 );
      });

      add_menubutton_setting( grid, (i * 2), block_type.label(), block_type, BlockCommentType.NUM, (value) => {
        var btype = (BlockCommentType)value;
        return( btype.label() );
      }, (value) => {
        var btype = (BlockCommentType)value;
        _types.insert_val( i, btype );
        _types.remove_index( i + 1 );
        custom_box.visible = (_types.index( i ) == BlockCommentType.CUSTOM);
      });

      grid.attach( custom_box, 0, ((i * 2) + 1) );

    }

  }

  //-------------------------------------------------------------
  // Called to save the contents of this setting to XML format.
  public override Xml.Node* save() {
    var node = base.save();
    for( int i=0; i<_types.length; i++ ) {
      var btype = (BlockCommentType)_types.index( i );
      Xml.Node* bnode = new Xml.Node( null, "comment" );
      bnode->set_prop( "type", btype.to_string() );
      if( btype == BlockCommentType.CUSTOM ) {
        bnode->set_prop( "start", _custom_start.index( i ) );
        bnode->set_prop( "end",   _custom_end.index( i ) );
      }
      node->add_child( bnode );
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
          var btype = BlockCommentType.parse( t );
          _types.append_val( btype );
          _custom_start.append_val( "" );
          _custom_end.append_val( "" );
          if( btype == BlockCommentType.CUSTOM ) {
            var s = it->get_prop( "start" );
            if( s != null ) {
              _custom_start.insert_val( index, s );
              _custom_start.remove_index( index + 1 );
            }
            var e = it->get_prop( "end" );
            if( e != null ) {
              _custom_end.insert_val( index, e );
              _custom_end.remove_index( index + 1 );
            }
          }
          index++;
        }
      }
    }
  }

}
