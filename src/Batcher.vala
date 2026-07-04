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

public enum OutputDirectoryType {
  REPLACE,
  SAME_DIRECTORY,
  NEW_DIRECTORY,
  NUM;

  //-------------------------------------------------------------
  // Returns the string representation of this enumeration.
  public string to_string() {
    switch( this ) {
      case REPLACE        :  return( "replace" );
      case SAME_DIRECTORY :  return( "same-dir" );
      case NEW_DIRECTORY  :  return( "new_dir" );
      default             :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Returns the enumerated value based on the provided string.
  public static OutputDirectoryType parse( string val ) {
    switch( val ) {
      case "replace"  :  return( REPLACE );
      case "same-dir" :  return( SAME_DIRECTORY );
      case "new-dir"  :  return( NEW_DIRECTORY );
      default         :  return( REPLACE );
    }
  }

  //-------------------------------------------------------------
  // Outputs the label to display for this value.
  public string label() {
    switch( this ) {
      case REPLACE        :  return( _( "Replace original file" ) );
      case SAME_DIRECTORY :  return( _( "Create converted file in the same directory as original file" ) );
      case NEW_DIRECTORY  :  return( _( "Create converted file in specified output directory" ) );
      default             :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Outputs the filename to output the converted file contents to.
  public string output_filename( File file, string suffix, string new_dir ) {
    switch( this ) {
      case REPLACE        :  return( file.get_path() );
      case NEW_DIRECTORY  :  return( Path.build_filename( new_dir, file.get_basename() ) );
      case SAME_DIRECTORY :
        var parts = new Gee.ArrayList<string>.wrap( file.get_basename().split( "." ) );
        parts.insert( (parts.size - 1), suffix );
        return( Path.build_filename( file.get_parent().get_path(), string.joinv( ".", parts.to_array() ) ) );
      default             :  assert_not_reached();
    }

  }

}

public class Batcher {

  private MainWindow          _win;
  private CustomFunction      _function        = null;
  private bool                _use_folder      = false;
  private bool                _recursive       = false;
  private OutputDirectoryType _output_dir_type = OutputDirectoryType.REPLACE;
  private string              _same_dir_suffix = _( "converted" );
  private string              _new_output_dir  = "";

  //-------------------------------------------------------------
  // Constructor
  public Batcher( MainWindow win ) {

    _win = win;

  }

  //-------------------------------------------------------------
  // Creates the batch processing button that can be added to the
  // header bar of the application.
  public Button build_button() {

    var btn = new Button.from_icon_name( "batch-processing" ) {
      has_frame = false,
      sensitive = !_win.functions.category_empty( "custom" ),
      tooltip_text = _( "Batch Process Files/Folders" )
    };

    btn.clicked.connect(() => {
      var win = new Granite.Dialog() {
        modal = true,
        title = _( "Batch Processing" ),
        transient_for = _win
      };
      win.get_content_area().append( build_ui( win ) );
      win.present();
    });

    _win.functions.changed.connect(() => {
      btn.sensitive = !_win.functions.category_empty( "custom" );
    });

    return( btn );

  }

  //-------------------------------------------------------------
  // Builds the batch mode UI and returns it to the calling function
  // as a Gtk Box.
  public Box build_ui( Granite.Dialog batch_win ) {

    var functions = _win.functions.get_category_functions( "custom" );

    string[] func_names    = {};
    var      selected_func = 0;
    for( int i=0; i<functions.length; i++ ) {
      var function = (CustomFunction)functions.index( i );
      if( function.launchable( _win.editor ) ) {
        if( (_function != null) && (function.user_label == _function.user_label) ) {
          selected_func = i;
        }
        func_names += function.user_label;
      }
    }

    var function_lbl = new Label( _( "Conversion Action:" ) ) {
      halign = Align.START
    };

    var function_dd = new DropDown.from_strings( func_names ) {
      selected = selected_func
    };

    function_dd.notify["selected"].connect(() => {
      _function = (CustomFunction)functions.index( function_dd.selected );
    });

    var function_box = new Box( Orientation.HORIZONTAL, 5 );
    function_box.append( function_lbl );
    function_box.append( function_dd );

    var folder_cb = new CheckButton.with_label( _( "Load all files from selected folder" ) ) {
      halign = Align.START,
      active = _use_folder
    };

    var folder_recursive = new CheckButton.with_label( _( "Convert files found in all subdirectories" ) ) {
      halign = Align.START,
      active = _recursive,
      visible = _use_folder,
      margin_start = 20
    };

    folder_recursive.notify["active"].connect(() => {
      _recursive = folder_recursive.active;
    });

    folder_cb.notify["active"].connect(() => {
      folder_recursive.visible = folder_cb.active;
      _use_folder = folder_cb.active;
    });

    string[] outputs = {};
    for( int i=0; i<OutputDirectoryType.NUM; i++ ) {
      var od_type = (OutputDirectoryType)i;
      outputs += od_type.label();
    }

    var output_dd = new DropDown.from_strings( outputs );

    // Create the same directory UI
    var same_dir_lbl = new Label( _( "Filename suffix:" ) ) {
      halign = Align.START
    };

    var same_dir_entry = new Entry() {
      halign = Align.FILL,
      text = _same_dir_suffix
    };

    var same_dir_box = new Box( Orientation.HORIZONTAL, 5 ) {
      visible = (_output_dir_type == OutputDirectoryType.SAME_DIRECTORY)
    };
    same_dir_box.append( same_dir_lbl );
    same_dir_box.append( same_dir_entry );

    // Create the new directory UI
    var new_dir_lbl = new Label( _( "Output directory:" ) ) {
      halign = Align.START
    };

    var new_dir_entry = new Entry() {
      halign   = Align.START,
      text     = _new_output_dir,
      editable = false
    };

    var new_dir_btn = new Button.from_icon_name( "folder-open-symbolic" );
    new_dir_btn.clicked.connect(() => {
      var dialog = new FileDialog() {
        modal = true,
        title = _( "Select output directory" ),
        accept_label = _( "Select" )
      };
      dialog.select_folder.begin( _win, null, (obj, res) => {
        try {
          var folder = dialog.select_folder.end( res );
          _new_output_dir = folder.get_path();
          new_dir_entry.text = _new_output_dir;
        } catch( Error e ) {}
      });
    });

    var new_dir_box = new Box( Orientation.HORIZONTAL, 5 ) {
      visible = (_output_dir_type == OutputDirectoryType.NEW_DIRECTORY)
    };
    new_dir_box.append( new_dir_lbl );
    new_dir_box.append( new_dir_entry );
    new_dir_box.append( new_dir_btn );

    output_dd.notify["selected"].connect(() => {
      _output_dir_type     = (OutputDirectoryType)output_dd.selected;
      same_dir_box.visible = (_output_dir_type == OutputDirectoryType.SAME_DIRECTORY);
      new_dir_box.visible  = (_output_dir_type == OutputDirectoryType.NEW_DIRECTORY);
    });

    output_dd.selected = _output_dir_type;

    var run_btn = new Button.with_label( _( "Run" ) ) {
      halign = Align.END
    };

    run_btn.clicked.connect(() => {
      if( _use_folder ) {
        run_folder();
      } else {
        run_selected();
      }
      batch_win.destroy();
    });

    var cancel_btn = new Button.with_label( _( "Cancel" ) ) {
      halign = Align.END,
      hexpand = true
    };

    cancel_btn.clicked.connect(() => {
      batch_win.destroy();
    });

    var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
      valign = Align.END
    };
    bbox.append( cancel_btn );
    bbox.append( run_btn );

    var box = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    box.append( function_box );
    box.append( folder_cb );
    box.append( folder_recursive );
    box.append( output_dd );
    box.append( same_dir_box );
    box.append( new_dir_box );
    box.append( bbox );

    return( box );

  }

  //-------------------------------------------------------------
  // Converts the given file based on the batch settings.
  private void convert_file( File file ) {

    // Open the file and insert it into the text field
    if( _win.open_file( file.get_path(), false ) ) {

      // Perform transform
      _function.launch( _win.editor );

      // Get the output file name
      _win.set_current_file( _output_dir_type.output_filename( file, _same_dir_suffix, _new_output_dir ) );
      _win.save_current_file( false );

    }

  }

  //-------------------------------------------------------------
  // Opens each file within the selected folder and converts each found
  // file one at a time.
  private void convert_folder( File folder ) {

    var enumerator = folder.enumerate_children(
      FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
      FileQueryInfoFlags.NONE
    );

    try {
      FileInfo? info;
      while( (info = enumerator.next_file()) != null ) {
        var child = enumerator.get_child( info );
        if( (info.get_file_type() == FileType.DIRECTORY) && _recursive ) {
          convert_folder( child );
        } else if( info.get_file_type() == FileType.REGULAR ) {
          convert_file( child );
        }
      }
    } catch( Error e ) {}

  }

  //-------------------------------------------------------------
  // Runs the batcher on user-selected files.
  public void run_selected() {

    var dialog = new FileDialog() {
      modal = true,
      title = _( "Select one or more files to convert" ),
      accept_label = _( "Select" )
    };

    dialog.open_multiple.begin( _win, null, (obj, res) => {
      try {
        var files = dialog.open_multiple.end( res );
        Idle.add(() => {
          _win.remove_widget();
          for( int i=0; i<files.get_n_items(); i++ ) {
            var file = (File)files.get_item( i );
            convert_file( file );
          }
          _win.do_new();
          _win.notification( _( "Batch processing complete!" ), "" );
          return( false );
        });
      } catch( Error e ) {}
    });

  }

  //-------------------------------------------------------------
  // Runs the batcher on a user-selected directory.
  public void run_folder() {

    var dialog = new FileDialog() {
      modal = true,
      title = _( "Select directory to convert" ),
      accept_label = _( "Select" )
    };

    dialog.select_folder.begin( _win, null, (obj, res) => {
      try {
        var folder = dialog.select_folder.end( res );
        Idle.add(() => {
          _win.remove_widget();
          convert_folder( folder );
          _win.do_new();
          _win.notification( _( "Batch processing complete!" ), "" );
          return( false );
        });
      } catch( Error e ) {}
    });

  }

}
