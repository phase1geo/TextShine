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

public class RegExpr : TextFunction {

  private MainWindow  _win;
  private Regex       _re;
  private bool        _tags_exist     = false;
  private UndoItem    _undo_item;
  private string      _find_text      = "";
  private string      _replace_text   = "";
  private bool        _highlight_line = false;

  /* Constructor */
  public RegExpr( MainWindow win, bool custom = false ) {

    base( "regexpr", custom );

    _re  = null;
    _win = win;

  }

  public override string get_description() {
    return( _( "Performs a regular expression search and highlights all matched text." ) );
  }

  protected override string get_label0() {
    return( _( "Regular Expression" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new RegExpr( _win, custom ) );
  }

  public override bool matches( TextFunction function ) {
    if( base.matches( function ) ) {
      var func = (RegExpr)function;
      return(
        (_find_text == func._find_text) &&
        (_replace_text == func._replace_text) &&
        (_highlight_line == func._highlight_line)
      );
    }
    return( false );
  }

  /* Creates the search UI */
  private void create_widget( Editor editor, out Box box, out Entry entry ) {

    var pattern = new SearchEntry();
    pattern.placeholder_text = _( "Regular Expression" );
    pattern.populate_popup.connect((menu) => {
      populate_pattern_popup( menu, pattern );
    });

    var replace = new Entry();
    replace.placeholder_text = _( "Replace With" );
    replace.populate_popup.connect((menu) => {
      populate_replace_popup( menu, replace );
    });

    var highlight_line = new CheckButton.with_label( _( "Highlight Line" ) );

    if( custom ) {

      pattern.text = _find_text;
      pattern.changed.connect(() => {
        _find_text = pattern.text;
        custom_changed();
      });

      replace.text = _replace_text;
      replace.changed.connect(() => {
        _replace_text = replace.text;
        custom_changed();
      });

      highlight_line.active = _highlight_line;
      highlight_line.toggled.connect(() => {
        _highlight_line = highlight_line.get_active();
        custom_changed();
      });

    } else {

      pattern.search_changed.connect(() => {
        _find_text = pattern.text;
        _undo_item = new UndoItem( label );
        do_search( editor, _undo_item );
      });
      pattern.activate.connect(() => {
        end_search( editor );
      });

      replace.activate.connect(() => {
        _replace_text = replace.text;
        do_replace( editor, _undo_item );
      });

      highlight_line.toggled.connect(() => {
        _highlight_line = highlight_line.active;
        _undo_item = new UndoItem( label );
        do_search( editor, _undo_item );
      });

      handle_widget_escape( pattern, _win );
      handle_widget_escape( replace, _win );

      entry = pattern;

    }

    box = new Box( Orientation.VERTICAL, 5 );
    box.margin = 5;
    box.pack_start( pattern,        false, true,  0 );
    box.pack_start( replace,        false, true,  0 );
    box.pack_start( highlight_line, false, false, 0 );

  }

  public override Box? get_widget( Editor editor ) {
    Box   box;
    Entry entry;
    create_widget( editor, out box, out entry );
    return( box );
  }

  private void populate_pattern_popup( Gtk.Menu menu, Entry entry ) {
    menu.add( new SeparatorMenuItem() );
    add_character_patterns( menu, entry );
    add_iteration_patterns( menu, entry );
    add_location_patterns( menu, entry );
    add_advanced_patterns( menu, entry );
    menu.show_all();
  }

  private void populate_replace_popup( Gtk.Menu menu, Entry entry ) {
    if( _tags_exist ) {
      menu.add( new SeparatorMenuItem() );
      add_case_patterns( menu, entry );
      add_position_patterns( menu, entry );
      Utils.populate_insert_popup( menu, entry );
      menu.show_all();
    }
  }

  private void add_submenu( Gtk.Menu menu, string name, out Gtk.Menu submenu ) {
    submenu = new Gtk.Menu();
    var item = new Gtk.MenuItem.with_label( name );
    item.submenu = submenu;
    menu.add( item );
  }

  private void add_pattern( Gtk.Menu mnu, Entry entry, string lbl, string pattern ) {
    var label = (pattern.length < 5) ? (lbl + " - <b>" + pattern + "</b>") : lbl;
    var item = new Gtk.MenuItem.with_label( label );
    (item.get_child() as Label).use_markup = true;
    item.activate.connect(() => {
      entry.insert_at_cursor( pattern );
    });
    mnu.add( item );
  }

  private void add_character_patterns( Gtk.Menu menu, Entry entry ) {
    Gtk.Menu submenu;
    add_submenu( menu, _( "Character Patterns" ), out submenu );
    add_pattern( submenu, entry, _( "Digit" ),          """\d""" );
    add_pattern( submenu, entry, _( "Non-Digit" ),      """\D""" );
    add_pattern( submenu, entry, _( "New-line" ),       """\n""" );
    add_pattern( submenu, entry, _( "Non-New-line" ),   """\N""" );
    add_pattern( submenu, entry, _( "Tab" ),            """\t""" );
    add_pattern( submenu, entry, _( "Page Break" ),     """\f""" );
    add_pattern( submenu, entry, _( "Whitespace" ),     """\s""" );
    add_pattern( submenu, entry, _( "Non-Whitespace" ), """\S""" );
    add_pattern( submenu, entry, _( "Word" ),           """\w""" );
    add_pattern( submenu, entry, _( "Non-Word" ),       """\W""" );
    add_pattern( submenu, entry, _( "Any character" ),  "." );
  }

  private void add_location_patterns( Gtk.Menu menu, Entry entry ) {
    Gtk.Menu submenu;
    add_submenu( menu, _( "Location Patterns" ), out submenu );
    add_pattern( submenu, entry, _( "Word Boundary" ),     """\b""" );
    add_pattern( submenu, entry, _( "Non-Word Boundary" ), """\B""" );
    add_pattern( submenu, entry, _( "Start Of Line" ),     "^" );
    add_pattern( submenu, entry, _( "End Of Line" ),       "$" );
  }

  private void add_iteration_patterns( Gtk.Menu menu, Entry entry ) {
    Gtk.Menu submenu;
    add_submenu( menu, _( "Iteration Patterns" ), out submenu );
    add_pattern( submenu, entry, _( "0 or 1 Times" ),    "?" );
    add_pattern( submenu, entry, _( "0 or More Times" ), "*" );
    add_pattern( submenu, entry, _( "1 or More Times" ), "+" );
  }

  private void add_advanced_patterns( Gtk.Menu menu, Entry entry ) {
    Gtk.Menu submenu, tags;
    add_submenu( menu, _( "Advanced Patterns" ), out submenu );
    add_pattern( submenu, entry, _( "Word" ),         """\w+""" );
    add_pattern( submenu, entry, _( "Number" ),       """\d+""" );
    add_pattern( submenu, entry, _( "URL" ),          """(https?://(?:www\.|(?!www))[^\s\.]+\.\S{2,}|www\.\S+\.\S{2,})""" );
    add_pattern( submenu, entry, _( "E-mail" ),       """([a-z0-9_\.-]+)@([\da-z\.-]+)\.([a-z\.]{2,6})""" );
    add_pattern( submenu, entry, _( "Date" ),         """[0-3]?[0-9].[0-3]?[0-9].(?:[0-9]{2})?[0-9]{2}""" );
    add_pattern( submenu, entry, _( "Phone Number" ), """\d?(\s?|-?|\+?|\.?)((\(\d{1,4}\))|(\d{1,3})|\s?)(\s?|-?|\.?)((\(\d{1,3}\))|(\d{1,3})|\s?)(\s?|-?|\.?)((\(\d{1,3}\))|(\d{1,3})|\s?)(\s?|-?|\.?)\d{3}(-|\.|\s)\d{4}""" );
    add_submenu( submenu, _( "HTML/XML Tags" ), out tags );
    add_pattern( tags, entry, _( "Specific Start Tag" ), """<TAG(\s+\w+=("[^"]*"|'[^']*'))*\s*>""" );
    add_pattern( tags, entry, _( "Specific End Tag" ),   """</TAG\s*>""" );
    add_pattern( tags, entry, _( "Specific Tag" ),       """</?TAG(\s+\w+=("[^"]*"|'[^']*'))*\s*>""" );
    add_pattern( tags, entry, _( "Any Start Tag" ),      """<(\w+)(\s+\w+=("[^"]*"|'[^']*'))*\s*>""" );
    add_pattern( tags, entry, _( "Any End Tag" ),        """</(\w+)\s*>""" );
    add_pattern( tags, entry, _( "Any Tag" ),            """<("[^"]*"|'[^']*'|[^'">])*>""" );
  }

  private void add_replace( Gtk.Menu mnu, Entry entry, string lbl, string pattern ) {
    var label = (pattern.length < 5) ? (lbl + " - <b>" + pattern + "</b>") : lbl;
    var item = new Gtk.MenuItem.with_label( label );
    (item.get_child() as Label).use_markup = true;
    item.activate.connect(() => {
      entry.insert_at_cursor( pattern );
    });
    mnu.add( item );
  }

  private void add_case_patterns( Gtk.Menu menu, Entry entry ) {
    Gtk.Menu submenu;
    add_submenu( menu, _( "Case Patterns" ), out submenu );
    add_replace( submenu, entry, _( "Uppercase Next Character" ), """\u""" );
    add_replace( submenu, entry, _( "Lowercase Next Character" ), """\l""" );
    add_replace( submenu, entry, _( "Start Uppercase Change" ),   """\U""" );
    add_replace( submenu, entry, _( "Start Lowercase Change" ),   """\L""" );
    add_replace( submenu, entry, _( "End Case Change" ),          """\E""" );
  }

  private void add_position_patterns( Gtk.Menu menu, Entry entry ) {
    var captured = (_re.get_capture_count() > 9) ? 9 : _re.get_capture_count();
    if( captured == 0 ) return;
    Gtk.Menu submenu;
    add_submenu( menu, _( "Positional Patterns" ), out submenu );
    add_replace( submenu, entry, _( "Matched Pattern" ), """\0""" );
    for( int i=0; i<captured; i++ ) {
      add_replace( submenu, entry, _( "Subpattern %d" ).printf( i + 1 ), ( """\%d""" ).printf( i + 1 ) );
    }
  }

  /* Perform search and replacement */
  private void do_search( Editor editor, UndoItem? undo_item ) {

    /* Get the selected ranges and clear them */
    var ranges = new Array<Editor.Position>();
    editor.get_ranges( ranges, false );
    editor.remove_selected( _undo_item );

    /* Clear the tags */
    _tags_exist = false;

    /* If the pattern text is empty, just return now */
    if( _find_text == "" ) {
      return;
    }

    MatchInfo match;

    try {
      _re = new Regex( _find_text );
    } catch( RegexError e ) {
      return;
    }

    for( int i=0; i<ranges.length; i++ ) {

      var text        = editor.get_text( ranges.index( i ).start, ranges.index( i ).end );
      var start_index = ranges.index( i ).start.get_offset();

      while( _re.match( text, 0, out match ) ) {
        TextIter start_iter, end_iter;
        int start, end;
        match.fetch_pos( 0, out start, out end );
        if( start == end ) break;
        editor.buffer.get_iter_at_offset( out start_iter, start_index + start );
        editor.buffer.get_iter_at_offset( out end_iter,   start_index + end );
        if( _highlight_line ) {
          start_iter.set_line( start_iter.get_line() );
          end_iter.forward_line();
        }
        editor.add_selected( start_iter, end_iter, _undo_item );
        _tags_exist = true;
        text = text.splice( 0, end );
        start_index += end;
      }

    }

  }

  /* Finalizes the search operation (TBD) */
  private void end_search( Editor editor ) {

    /* Add the undo_item to the buffer */
    editor.undo_buffer.add_item( _undo_item );

    /* Close the error display */
    _win.close_error();

    /* Hide the widget */
    _win.remove_widget();

  }

  /* Replace all matches with the replacement text */
  private void do_replace( Editor editor, UndoItem undo_item ) {

    var ranges       = new Array<Editor.Position>();
    var replace_text = Utils.replace_date( _replace_text );

    editor.get_ranges( ranges );

    try {

      var re        = new Regex( _find_text );
      var int_value = 1;

      for( int i=((int)ranges.length - 1); i>=0; i-- ) {
        var range    = ranges.index( i );
        var text     = editor.get_text( range.start, range.end );
        var new_text = re.replace( text, text.length, 0, Utils.replace_index( replace_text, ref int_value ) );
        editor.replace_text( range.start, range.end, new_text, undo_item );
      }

    } catch( RegexError e ) {
      _win.show_error( e.message );
      return;
    }

    /* Hide the error message */
    _win.close_error();

    /* Hide the widget */
    _win.remove_widget();

  }

  public override void run( Editor editor, UndoItem undo_item ) {
    do_search( editor, undo_item );
    if( _replace_text != "" ) {
      do_replace( editor, undo_item );
    }
  }

  /* Called when the action button is clicked.  Displays the UI. */
  public override void launch( Editor editor ) {
    if( custom ) {
      do_search( editor, null );
      if( _replace_text != "" ) {
        do_replace( editor, null );
      }
    } else {
      Box   box;
      Entry entry;
      create_widget( editor, out box, out entry );
      _win.add_widget( box, entry );
    }
  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "pattern", _find_text );
    node->set_prop( "replace", _replace_text );
    node->set_prop( "highlight-line", _highlight_line.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    string? p = node->get_prop( "pattern" );
    if( p != null ) {
      _find_text = p;
    }
    string? r = node->get_prop( "replace" );
    if( r != null ) {
      _replace_text = r;
    }
    string? hl = node->get_prop( "highlight-line" );
    if( hl != null ) {
      _highlight_line = bool.parse( hl );
    }
  }

}
