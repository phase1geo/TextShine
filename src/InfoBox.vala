/*
* Copyright (c) 2020-2026 (https://github.com/phase1geo/TextShine)
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

public class InfoBox : Box {

  private Image _image;
  private Label _label;

  //-------------------------------------------------------------
  // Constructor
  public InfoBox() {

    Object( orientation: Orientation.HORIZONTAL, spacing: 5 );

    _image = new Image() {
      halign = Align.START
    };

    _label = new Label( "" ) {
      halign = Align.START,
      hexpand = true
    };

    var btn = new Button.from_icon_name( "window-close-symbolic" ) {
      has_frame = false,
      halign = Align.END
    };

    btn.clicked.connect(() => {
      visible = false;
    });

    add_css_class( "info-box" );

    append( _image );
    append( _label );
    append( btn );

  }

  private void show_box( string resource_icon, string message ) {
    _image.resource = "dialog-info-symbolic";
    _label.label    = message;
    visible         = true;
  }

  public void show_info( string message ) {
    show_box( "dialog-information-symbolic", message );
  }

  public void show_warning( string message ) {
    show_box( "dialog-warning-symblic", message );
  }

}
