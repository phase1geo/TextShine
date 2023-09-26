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
using Gdk;
using Gee;

public class SidebarCustomSettings : SidebarBox {

  private CustomFunction? _custom;
  private Entry           _name;
  private TextView        _description;

  /* Constructor */
  public SidebarCustomSettings( MainWindow win, Editor editor ) {

    base( win, editor );

    var nlbl = new Label( Utils.make_title( _( "Name:" ) ) );
    nlbl.use_markup = true;

    _name = new Entry();

    var nbox = new Box( Orientation.HORIZONTAL, 0 );
    nbox.pack_start( nlbl,  false, false, 5 );
    nbox.pack_start( _name, true,  true,  5 );

    var dlbl = new Label( Utils.make_title( _( "Description:" ) ) );
    dlbl.halign     = Align.START;
    dlbl.use_markup = true;

    _description = new TextView();
    _description.wrap_mode = WrapMode.WORD;

    var dbox = new Box( Orientation.VERTICAL, 0 );
    dbox.margin_left = 5;
    dbox.margin_right = 5;
    dbox.pack_start( dlbl, false, true, 5 );
    dbox.pack_start( _description, true, true, 5 );

    var done = new Button.with_label( _( "Done" ) );
    done.get_style_context().add_class( "suggested-action" );
    done.clicked.connect(() => {
      _custom.set_name( _name.text );
      _custom.set_description( _description.buffer.text );
      switch_stack( SwitchStackReason.EDIT, _custom );
    });

    var bbox = new Box( Orientation.HORIZONTAL, 0 );
    bbox.pack_end( done, false, false, 5 );

    pack_start( nbox, false, true, 5 );
    pack_start( dbox, true,  true, 5 );
    pack_end(   bbox, false, true, 5 );

  }

  public override void displayed( SwitchStackReason reason, TextFunction? function ) {

    _custom = (CustomFunction)function;

    /* Update name and description fields with the function information */
    _name.text = _custom.name;
    _description.buffer.text = _custom.get_description();

  }

}

