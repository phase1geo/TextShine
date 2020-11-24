/*
* Copyright (c) 2020 (https://github.com/phase1geo/Minder)
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
using Gdk;
using Cairo;

public class Utils {

  /* Returns true if the specified version is older than this version */
  public static bool is_version_older( string other_version ) {
    var my_parts    = TextShine.version.split( "." );
    var other_parts = other_version.split( "." );
    for( int i=0; i<my_parts.length; i++ ) {
      if( int.parse( other_parts[i] ) < int.parse( my_parts[i] ) ) {
        return( true );
      }
    }
    return( false );
  }

  /*
   Helper function for converting an RGBA color value to a stringified color
   that can be used by a markup parser.
  */
  public static string color_from_rgba( RGBA rgba ) {
    return( "#%02x%02x%02x".printf( (int)(rgba.red * 255), (int)(rgba.green * 255), (int)(rgba.blue * 255) ) );
  }

  /* Sets the context source color to the given color value */
  public static void set_context_color( Context ctx, RGBA color ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
  }

  /*
   Sets the context source color to the given color value overriding the
   alpha value with the given value.
  */
  public static void set_context_color_with_alpha( Context ctx, RGBA color, double alpha ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, alpha );
  }

  /*
   Adds the given accelerator label to the given menu item.
  */
  public static void add_accel_label( Gtk.MenuItem item, uint key, Gdk.ModifierType mods ) {

    /* Convert the menu item to an accelerator label */
    AccelLabel? label = item.get_child() as AccelLabel;

    if( label == null ) return;

    /* Add the accelerator to the label */
    label.set_accel( key, mods );
    label.refetch();

  }

  /* Returns a string that is used to display a tooltip with displayed accelerator */
  public static string tooltip_with_accel( string tooltip, string accel ) {
    string[] accels = {accel};
    return( Granite.markup_accel_tooltip( accels, tooltip ) );
  }

  /* Returns a string that will be drawn as a title when markup is applied */
  public static string make_title( string str ) {
    return( "<b>" + str + "</b>" );
  }

  /* Searches for the beginning or ending word */
  public static int find_word( string str, int cursor, bool wordstart ) {
    try {
      MatchInfo match_info;
      var substr = wordstart ? str.substring( 0, cursor ) : str.substring( cursor );
      var re = new Regex( wordstart ? ".*(\\W\\w|[\\w\\s][^\\w\\s])" : "(\\w\\W|[^\\w\\s][\\w\\s])" );
      if( re.match( substr, 0, out match_info ) ) {
        int start_pos, end_pos;
        match_info.fetch_pos( 1, out start_pos, out end_pos );
        return( wordstart ? (start_pos + 1) : (cursor + start_pos + 1) );
      }
    } catch( RegexError e ) {}
    return( -1 );
  }

  /* Show the specified popover */
  public static void show_popover( Popover popover ) {
#if GTK322
    popover.popup();
#else
    popover.show();
#endif
  }

  /* Hide the specified popover */
  public static void hide_popover( Popover popover ) {
#if GTK322
    popover.popdown();
#else
    popover.hide();
#endif
  }

  /*
   Replaces all of the date and time placeholders with the current date/time
   values.
  */
  public static string replace_date( string value ) {
    var now = new DateTime.now_local();
    return( now.format( value.replace( "%1", "%%1" ) ) );
  }

  /* Replace the given string with the given value */
  public static string replace_index( string pattern, ref int value ) {
    var str = pattern.replace( "%1", value.to_string() );
    value++;
    return( str );
  }

  /*
   Adds a submenu to the given menu with the specified name, returning the
   created submenu.
  */
  public static void add_submenu( Gtk.Menu menu, string name, out Gtk.Menu submenu ) {
    submenu = new Gtk.Menu();
    var item = new Gtk.MenuItem.with_label( name );
    item.submenu = submenu;
    menu.add( item );
  }

  /*
   Adds a new menu item that inserts a given pattern at the current insertion
   point.
  */
  public static void add_literal_pattern( Gtk.Entry entry, Gtk.Menu mnu, string lbl, string pattern ) {
    var item = new Gtk.MenuItem.with_label( lbl );
    item.activate.connect(() => {
      entry.insert_at_cursor( pattern );
    });
    mnu.add( item );
  }

  /*
   Adds a new menu item that inserts a given pattern at the current insertion
   point.
  */
  public static void add_pattern( Gtk.Entry entry, Gtk.Menu mnu, string lbl, string pattern ) {
    var label = (pattern.length < 5) ? (lbl + " - <b>" + pattern + "</b>") : lbl;
    var item = new Gtk.MenuItem.with_label( label );
    (item.get_child() as Label).use_markup = true;
    item.activate.connect(() => {
      entry.insert_at_cursor( pattern );
    });
    mnu.add( item );
  }

  /* Adds items to the popup menu for a text insertion based widget */
  public static void populate_insert_popup( Gtk.Menu menu, Gtk.Entry entry ) {

    Gtk.Menu chars, date, time;

    menu.add( new SeparatorMenuItem() );
    add_submenu( menu, _( "Insert Characters" ), out chars );
    add_submenu( menu, _( "Insert Date" ), out date );
    add_submenu( menu, _( "Insert Time" ), out time );

    add_literal_pattern( entry, chars, _( "Insert New-line" ),   "\n" );
    add_literal_pattern( entry, chars, _( "Insert Tab" ),        "\t" );
    add_literal_pattern( entry, chars, _( "Insert Page Break" ), "\f" );
    add_pattern( entry, chars, _( "Insert Incrementing Decimal" ), "%1" );
    add_pattern( entry, chars, _( "Insert Percent Sign" ), "%%" );

    add_pattern( entry, date, _( "Standard Date" ), "%x" );
    date.add( new SeparatorMenuItem() );
    add_pattern( entry, date, _( "Day of Month (1-31)" ), "%e" );
    add_pattern( entry, date, _( "Day of Month (01-31)" ), "%d" );
    add_pattern( entry, date, _( "Month (01-12)" ), "%m" );
    add_pattern( entry, date, _( "Year (YYYY)" ), "%Y" );
    add_pattern( entry, date, _( "Year (YY)" ), "%y" );
    add_pattern( entry, date, _( "Day of Week" ), "%A" );
    add_pattern( entry, date, _( "Day of Week (Abbreviated)" ), "%a" );
    add_pattern( entry, date, _( "Name of Month" ), "%B" );
    add_pattern( entry, date, _( "Name of Month (Abbreviated)" ), "%b" );

    add_pattern( entry, time, _( "Standard Time" ), "%X" );
    time.add( new SeparatorMenuItem() );
    add_pattern( entry, time, _( "Seconds (00-59)" ), "%S" );
    add_pattern( entry, time, _( "Minutes (00-59)" ), "%M" );
    add_pattern( entry, time, _( "Hours (00-12)" ), "%H" );
    add_pattern( entry, time, _( "Hours (00-23)" ), "%I" );
    add_pattern( entry, time, _( "AM/PM" ), "%p" );
    add_pattern( entry, time, _( "Timezone" ), "%Z" );

    menu.show_all();

  }

}
