/*
* Copyright (c) 2023 (https://github.com/phase1geo/Journaler)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
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
using Enchant;

/* My implementation of gtkspell that is compatible with Gtk4 and gtksourceview-5 */
public class SpellChecker {

  private Broker       broker = null;
  private unowned Dict dict;

  private TextView?    view = null;
  private GestureClick right_click;
  private TextTag?     tag_highlight = null;
  private TextMark?    mark_insert_start = null;
  private TextMark?    mark_insert_end = null;
  private TextMark?    mark_click = null;
  private bool         deferred_check = false;

  private const GLib.ActionEntry action_entries[] = {
    { "action_replace_word",      action_replace_word, "s" },
    { "action_add_to_dictionary", action_add_to_dictionary },
    { "action_ignore_all",        action_ignore_all },
    { "action_none",              null }
  };

  public signal void populate_extra_menu();

  /* Default constructor */
  public SpellChecker() {
    broker = new Broker();
    right_click = new GestureClick() {
      button = 3
    };
  }

  private bool text_iter_forward_word_end( ref TextIter iter ) {
    if( !iter.forward_word_end() ) {
      return( false );
    }
    if( (iter.get_char() != '\'') && (iter.get_char() != '’') ) {
      return( true );
    }
    TextIter iter2 = iter.copy();
    if( iter2.forward_char() && iter2.get_char().isalpha() ) {
      return( iter.forward_word_end() );
    }
    return( true );
  }

  private bool text_iter_backward_word_start( ref TextIter iter ) {
    if( !iter.backward_word_start() ) {
      return( false );
    }
    TextIter iter2 = iter.copy();
    if( iter2.get_char().isalpha() && iter2.backward_char() && ((iter2.get_char() == '\'') || (iter2.get_char() == '’')) ) {
      return( iter.backward_word_start() );
    }
    return( true );
  }

  private void check_word( TextIter start, TextIter end ) {
    var text = view.buffer.get_text( start, end, false );
    if( !text.get_char( 0 ).isdigit() && (dict.check( text ) != 0) ) {
      view.buffer.apply_tag( tag_highlight, start, end );
    }
  }

  /*
  private string iter_string( TextIter iter ) {
    return( "%d.%d".printf( iter.get_line(), iter.get_line_offset() ) );
  }
  */

  private void check_range( TextIter start, TextIter end, bool force_all ) {
    TextIter wstart, wend, cursor, precursor;
    bool inword, highlight;
    if( end.inside_word() ) {
      text_iter_forward_word_end( ref end );
    }
    if( !start.starts_word() ) {
      if( start.inside_word() || start.ends_word() ) {
        text_iter_backward_word_start( ref start );
      } else {
        if( text_iter_forward_word_end( ref start ) ) {
          text_iter_backward_word_start( ref start );
        }
      }
    }
    view.buffer.get_iter_at_mark( out cursor, view.buffer.get_insert() );
    precursor = cursor.copy();
    precursor.backward_char();
    highlight = cursor.has_tag( tag_highlight ) || precursor.has_tag( tag_highlight );
    view.buffer.remove_tag( tag_highlight, start, end );
    if( start.get_offset() == 0 ) {
      text_iter_forward_word_end( ref start );
      text_iter_backward_word_start( ref start );
    }

    wstart = start.copy();
    while( wstart.compare( end ) < 0 ) {
      wend = wstart.copy();
      text_iter_forward_word_end( ref wend );
      if( wstart.equal( wend ) ) {
        break;
      }
      inword = (wstart.compare( cursor ) < 0) && (cursor.compare( wend ) <= 0);
      if( inword && !force_all ) {
        if( highlight ) {
          check_word( wstart, wend );
        } else {
          deferred_check = true;
        }
      } else {
        check_word( wstart, wend );
        deferred_check = false;
      }
      text_iter_forward_word_end( ref wend );
      text_iter_backward_word_start( ref wend );
      if( wstart.equal( wend ) ) {
        break;
      }
      wstart = wend.copy();
    }
  }

  private void check_deferred_range( bool force_all ) {
    TextIter start, end;
    view.buffer.get_iter_at_mark( out start, mark_insert_start );
    view.buffer.get_iter_at_mark( out end,   mark_insert_end );
    check_range( start, end, force_all );
  }

  private void insert_text_before( ref TextIter iter, string text ) {
    view.buffer.move_mark( mark_insert_start, iter );
  }

  private void insert_text_after( ref TextIter iter, string text ) {
    TextIter start;
    view.buffer.get_iter_at_mark( out start, mark_insert_start );
    iter = start;
    iter.forward_chars( text.char_count() );
    check_range( start, iter, false );
    view.buffer.move_mark( mark_insert_end, iter );
  }

  private void delete_range_after( TextIter start, TextIter end ) {
    check_range( start, end, false );
  }

  private void mark_set( TextIter iter, TextMark mark ) {
    if( (mark == view.buffer.get_insert()) && deferred_check ) {
      check_deferred_range( false );
    }
  }

  private void get_word_extents_from_mark( out TextIter start, out TextIter end, TextMark mark ) {
    view.buffer.get_iter_at_mark( out start, mark );
    if( !start.starts_word() ) {
      text_iter_backward_word_start( ref start );
    }
    end = start.copy();
    if( end.inside_word() ) {
      text_iter_forward_word_end( ref end );
    }
  }

  // -----------------------------------------------------------------------

  private void add_to_dictionary() {

    TextIter start, end;
    get_word_extents_from_mark( out start, out end, mark_click );

    var word = view.buffer.get_text( start, end, false );
    dict.add( word );
    recheck_all();

  }

  private void ignore_all() {

    TextIter start, end;
    get_word_extents_from_mark( out start, out end, mark_click );

    var word = view.buffer.get_text( start, end, false );
    dict.add_to_session( word );
    recheck_all();

  }

  private void replace_word( string new_word ) {

    TextIter start, end;
    get_word_extents_from_mark( out start, out end, mark_click );

    string old_word = view.buffer.get_text( start, end, false );

    view.buffer.begin_user_action();
    view.buffer.delete( ref start, ref end );
    view.buffer.insert( ref start, new_word, new_word.length );
    view.buffer.end_user_action();

    dict.store_replacement( old_word, new_word );

  }

  private void add_suggestion_menus( string word ) {

    string[] suggestions = dict.suggest( word, word.length );

    var suggest_menu = new GLib.Menu();
    var more_menu    = new GLib.Menu();

    if( suggestions.length == 0 ) {
      suggest_menu.append( _( "No suggestions" ), "spell.action_none" );
    } else {
      var count = 0;
      foreach( var suggestion in suggestions ) {
        var suggest = suggestion.replace( "'", "\\'" );
        if( count++ < 5 ) {
          suggest_menu.append( suggestion, "spell.action_replace_word('%s')".printf( suggest ) );
        } else {
          more_menu.append( suggestion, "spell.action_replace_word('%s')".printf( suggest ) );
        }
      }
      if( more_menu.get_n_items() > 0 ) {
        suggest_menu.append_submenu( _( "More Suggestions" ), more_menu );
      }
    }

    var add_ign_menu = new GLib.Menu();
    add_ign_menu.append( _( "Add \"%s\" to Dictionary" ).printf( word ), "spell.action_add_to_dictionary" );
    add_ign_menu.append( _( "Ignore All" ), "spell.action_ignore_all" );

    var spell_menu   = new GLib.Menu();
    spell_menu.append_section( null, suggest_menu );
    spell_menu.append_section( null, add_ign_menu );

    var top_menu = (GLib.Menu)view.extra_menu;
    top_menu.append_section( _( "Spell Check" ), spell_menu );

  }

  private void populate_popup() {

    TextIter start, end;
    get_word_extents_from_mark( out start, out end, mark_click );

    view.extra_menu = null;
    populate_extra_menu();

    if( !start.has_tag( tag_highlight ) ) {
      return;
    }

    var word = view.buffer.get_text( start, end, false );
    add_suggestion_menus( word );

  }

  private void right_button_press_event( int n_press, double x, double y ) {
    TextIter iter;
    int buf_x, buf_y;
    if( deferred_check ) {
      check_deferred_range( true );
    }
    view.window_to_buffer_coords( TextWindowType.TEXT, (int)x, (int)y, out buf_x, out buf_y );
    view.get_iter_at_location( out iter, buf_x, buf_y );
    view.buffer.move_mark( mark_click, iter );
    populate_popup();
  }

  private void action_replace_word( SimpleAction action, Variant? variant ) {
    replace_word( variant.get_string() );
  }

  private void action_add_to_dictionary() {
    add_to_dictionary();
  }

  private void action_ignore_all() {
    ignore_all();
  }

  private void set_buffer( TextView? new_view ) {

    TextIter start, end;

    if( view != null ) {
      SignalHandler.disconnect_matched( view.buffer, SignalMatchType.DATA, 0, 0, null, null, this );
      view.buffer.get_bounds( out start, out end );
      view.buffer.remove_tag( tag_highlight, start, end );
      tag_highlight = null;

      view.buffer.delete_mark( mark_insert_start );
      view.buffer.delete_mark( mark_insert_end );
      view.buffer.delete_mark( mark_click );
      mark_insert_start = null;
      mark_insert_end   = null;
      mark_click        = null;
    }

    view = new_view;

    if( view != null ) {
      view.buffer.insert_text.connect( insert_text_before );
      view.buffer.insert_text.connect_after( insert_text_after );
      view.buffer.delete_range.connect_after( delete_range_after );
      view.buffer.mark_set.connect( mark_set );

      var actions = new SimpleActionGroup();
      actions.add_action_entries( action_entries, this );
      view.insert_action_group( "spell", actions );

      var action = (SimpleAction)actions.lookup_action( "action_none" );
      if( action != null ) {
        action.set_enabled( false );
      }

      var tagtable = view.buffer.get_tag_table();
      tag_highlight = tagtable.lookup( "misspelled-tag" );

      if( tag_highlight == null ) {
        tag_highlight = view.buffer.create_tag( "misspelled-tag", "underline", Pango.Underline.ERROR, null );
      }

      view.buffer.get_bounds( out start, out end );
      mark_insert_start = view.buffer.create_mark( "sc-insert-start", start, true );
      mark_insert_end   = view.buffer.create_mark( "sc-insert-end",   end,   true );
      mark_click        = view.buffer.create_mark( "sc-click",        start, true );
      deferred_check    = false;
      recheck_all();
    }

  }

  public bool attach( TextView new_view ) {
    assert( view == null );
    new_view.add_controller( right_click );
    new_view.destroy.connect( detach );
    right_click.pressed.connect( right_button_press_event );
    set_buffer( new_view );
    return( true );
  }

  public void detach() {
    if( view == null ) {
      return;
    }
    view.remove_controller( right_click );
    set_buffer( null );
    view = null;
    deferred_check = false;
  }

  public void recheck_all() {
    TextIter start, end;
    if( view != null ) {
      view.buffer.get_bounds( out start, out end );
      check_range( start, end, true );
    }
  }

  public void ignore_word( string word ) {
    dict.add_to_session( word, word.length );
    recheck_all();
  }

  public List<string> get_suggestions( string word ) {
    var list = new List<string>();
    string[] suggestions = dict.suggest( word, word.length );
    foreach( var suggestion in suggestions ) {
      list.append( suggestion );
    }
    return( list );
  }

  public void get_language_list( Gee.ArrayList<string> langs ) {
    broker.list_dicts((lang_tag, provider_name, provider_desc, provider_file) => {
      langs.add( lang_tag );
    });
  }

  private bool set_language_internal( string? lang ) {
    var language = lang;
    if( lang == null ) {
      language = "en";
    }
    dict = broker.request_dict( language );
    if( dict == null ) {
      return( false );
    }
    return( true );
  }

  public bool set_language( string? lang ) {
    if( set_language_internal( lang ) ) {
      recheck_all();
      return( true );
    }
    return( false );
  }

}
