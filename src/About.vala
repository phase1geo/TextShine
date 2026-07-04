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
using Gdk;

public class About {

  private AboutDialog _about;

  //-------------------------------------------------------------
  // Constructor
  public About( MainWindow win ) {

    var image = new Image.from_resource( "/io/github/phase1geo/textshine/textshine-logo.svg" );

    _about = new AboutDialog() {
      authors            = { "Trevor Williams" },
      program_name       = "TextShine",
      comments           = _( "Text conversion application" ),
      copyright          = _( "Copyright" ) + " © 2020-2026 Trevor Williams",
      version            = win.application.version,
      license_type       = License.GPL_3_0,
      website            = "https://appcenter.elementary.io/com.github.phase1geo.textshine/",
      website_label      = _( "TextShine in AppCenter" ),
      system_information = get_system_info(),
      logo               = image.get_paintable()
    };

   	_about.set_destroy_with_parent( true );
	  _about.set_transient_for( win);
	  _about.set_modal( true );

  }

  //-------------------------------------------------------------
  // Returns the system information about how this application was
  // built.
  private string get_system_info() {
    var runtime = Utils.get_flatpak_runtime();
    if( runtime != "" ) {
      return( _( "Flatpak Runtime: %s".printf( runtime ) ) );
    }
    return( "" );
  }

  //-------------------------------------------------------------
  // Displays the About window
  public void show() {
    _about.present();
  }

  // TODO - Need to add attribution for batch processing icon:
  // <a href="https://www.flaticon.com/free-icons/process-management" title="process management icons">Process management icons created by VectorPortal - Flaticon</a>

}


