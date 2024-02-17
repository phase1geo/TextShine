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

public class Preferences : Dialog {

  private MainWindow _win;
  private FontButton _font;
  private MenuButton _spell_lang;

  private const GLib.ActionEntry action_entries[] = {
    { "action_spell_menu", action_spell_menu, "s" }
  };

  /* Default constructor */
  public Preferences( MainWindow win ) {

    Object(
      resizable: false,
      title: _( "Preferences" ),
      transient_for: win,
      modal: true
    );

    _win = win;

    var box = new Box( Orientation.VERTICAL, 10 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };

    /* Add the preference items */
    box.append( create_font_selection() );
    box.append( create_spell_checker() );
    box.append( create_spell_checker_language() );

    /* Set the content area of the dialog box */
    get_content_area().append( box );

    /* Add the menu actions */
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "prefs", actions );

  }

  /* Create font selection box */
  private Box create_font_selection() {

    var lbl = new Label( _( "Font:" ) ) {
      halign = Align.START,
      hexpand = true
    };

    _font = new FontButton() {
      halign = Align.END,
      hexpand = true
    };

    _font.set_filter_func( (family, face) => {
      var fd     = face.describe();
      var weight = fd.get_weight();
      var style  = fd.get_style();
      return( (weight == Pango.Weight.NORMAL) && (style == Pango.Style.NORMAL) );
    });

    _font.font_set.connect(() => {
      var name = _font.get_font_family().get_name();
      var size = _font.get_font_size() / Pango.SCALE;
      _win.editor.change_name_font( name, size );
      TextShine.settings.set_string( "default-font-family", name );
      TextShine.settings.set_int( "default-font-size", size );
    });

    /* Set the font button defaults */
    var fd = _font.get_font_desc();
    fd.set_family( TextShine.settings.get_string( "default-font-family" ) );
    fd.set_size( TextShine.settings.get_int( "default-font-size" ) * Pango.SCALE );
    _font.set_font_desc( fd );

    var box = new Box( Orientation.HORIZONTAL, 10 );
    box.append( lbl );
    box.append( _font );

    return( box );

  }

  private Box create_spell_checker() {

    var lbl = new Label( _( "Enable Spell Checker:" ) ) {
      halign = Align.START,
      hexpand = true
    };

    var sw = new Switch() {
      halign = Align.END,
      hexpand = true,
      active = TextShine.settings.get_boolean( "enable-spell-checking" )
    };

    sw.notify["active"].connect(() => {
      TextShine.settings.set_boolean( "enable-spell-checking", sw.active );
      _win.editor.set_spellchecker();
    });

    var box = new Box( Orientation.HORIZONTAL, 10 );
    box.append( lbl );
    box.append( sw );

    return( box );

  }

  /* Create the spell checker language menu */
  private GLib.Menu create_spell_lang_menu() {

    var menu  = new GLib.Menu();
    var langs = new Gee.ArrayList<string>();

    _win.editor.spell.get_language_list( langs );

    var sys_menu = new GLib.Menu();
    sys_menu.append( _( "Use System Language" ), "win.action_spell_menu('system')" );

    var other_menu = new GLib.Menu();
    langs.foreach((lang) => {
      other_menu.append( lang, "prefs.action_spell_menu('%s')".printf( lang ) );
      return( true );
    });

    menu.append_section( null, sys_menu );
    menu.append_section( null, other_menu );

    return( menu );

  }

  /* Handles changes to the spell checker language menu */
  private void action_spell_menu( SimpleAction action, Variant? variant ) {

    if( variant != null ) {
      var lang = variant.get_string();
      if( lang == "system" ) {
        lang = _( "Use System Language" );
      }
      _spell_lang.label = lang;
      TextShine.settings.set_string( "spell-language", lang );
    }

  }

  /* Creates the UI to adjust the spell checker language */
  private Box create_spell_checker_language() {

    var lbl = new Label( _( "Spell Checker Language:" ) ) {
      halign = Align.START,
      hexpand = true
    };

    var menu = create_spell_lang_menu();

    var lang = TextShine.settings.get_string( "spell-language" );
    if( lang == "system" ) {
      lang = _( "Use System Language" );
    }

    _spell_lang = new MenuButton() {
      label      = lang,
      menu_model = menu
    };

    var box = new Box( Orientation.HORIZONTAL, 10 );
    box.append( lbl );
    box.append( _spell_lang );

    return( box );

  }

}
