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

public class QuotesDoubleSingle : TextFunction {

  /* Constructor */
  public QuotesDoubleSingle( bool custom = false ) {
    base( "quotes-double-single", custom, FunctionDirection.LEFT_TO_RIGHT );
  }

  protected override string get_label0() {
    return( _( "Double to Single Quotes" ) );
  }

  protected override string get_label1() {
    return( _( "Single to Double Quotes" ) );
  }
  public override TextFunction copy( bool custom ) {
    var fn = new QuotesDoubleSingle( custom );
    fn.direction = direction;
    return( fn );
  }

  private string replace_single_with_double( string original, string single, string double ) {
    var sbytes = single.length;
    var str    = original;
    var index  = str.index_of_char( single.get_char( 0 ) );
    while( index != -1 ) {
      if( !is_apostrophe( str, index ) ) {
        var prefix = str.slice( 0, index );
        var suffix = str.slice( (index + sbytes), str.length );
        str = prefix + double + suffix;
      }
      index = str.index_of_char( single.get_char( 0 ), (index + 1) );
    }
    return( str );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {

    var str = original;

    if( direction == FunctionDirection.LEFT_TO_RIGHT ) {

      str = str.replace( right_curved_dquote, right_curved_squote );
      str = str.replace( right_angled_dquote, right_angled_squote );
      str = str.replace( right_german_dquote, right_german_squote );
      str = str.replace( left_curved_dquote,  left_curved_squote );
      str = str.replace( left_angled_dquote,  left_angled_squote );
      str = str.replace( left_german_dquote,  left_german_squote );
      str = str.replace( "\"", "'" );

    } else {

      str = replace_single_with_double( str, right_curved_squote, right_curved_dquote );
      str = str.replace( right_angled_squote, right_angled_dquote );
      str = str.replace( right_german_squote, right_german_dquote );
      str = str.replace( left_curved_squote,  left_curved_dquote );
      str = str.replace( left_angled_squote,  left_angled_dquote );
      str = str.replace( left_german_squote,  left_german_dquote );
      str = replace_single_with_double( str, "'", "\"" );

    }

    return( str );

  }

}
