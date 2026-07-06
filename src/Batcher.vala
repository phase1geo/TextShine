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

public enum InputType {
  FILES,
  FOLDER,
  NUM;

  //-------------------------------------------------------------
  // Returns the string version of this enum.
  public string to_string() {
    switch( this ) {
      case FILES  :  return( "files" );
      case FOLDER :  return( "folder" );
      default     :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Parses the given string and returns the enumerated value.
  public static InputType parse( string val ) {
    switch( val ) {
      case "files"  :  return( FILES );
      case "folder" :  return( FOLDER );
      default       :  return( FILES );
    }
  }

  //-------------------------------------------------------------
  // Displays the label to show within the UI for this option.
  public string label() {
    switch( this ) {
      case FILES  :  return( _( "Select files" ) );
      case FOLDER :  return( _( "Select folder" ) );
      default     :  assert_not_reached();
    }
  }
}

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
      case NEW_DIRECTORY  :  return( "new-dir" );
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
  // Creates a unique filename based on the given path.
  private string uniquify_path( string path ) {
    if( !FileUtils.test( path, FileTest.EXISTS ) ) {
      return( path );
    }
    var index    = 1;
    var new_path = "";
    do {
      var parts       = path.split( "." );
      var parts_index = (parts.length == 1) ? 0 : (parts.length - 2);
      parts[parts_index] = "%s (%d)".printf( parts[parts_index], index++ );
      new_path = string.joinv( ".", parts );
    } while( FileUtils.test( new_path, FileTest.EXISTS ) );
    return( new_path );
  }

  //-------------------------------------------------------------
  // Outputs the filename to output the converted file contents to.
  public string output_filename( File file, string suffix, string new_dir ) {
    switch( this ) {
      case REPLACE        :
        return( file.get_path() );
      case NEW_DIRECTORY  :
        var path = Path.build_filename( new_dir, file.get_basename() );
        return( uniquify_path( path ) );
      case SAME_DIRECTORY :
        var parts = new Gee.ArrayList<string>.wrap( file.get_basename().split( "." ) );
        parts.insert( (parts.size - 1), suffix );
        var path = Path.build_filename( file.get_parent().get_path(), string.joinv( ".", parts.to_array() ) );
        return( uniquify_path( path ) );
      default :
        assert_not_reached();
    }

  }

}

public class Batcher {

  private const int frame_top_margin = 15;

  private MainWindow          _win;
  private CustomFunction      _function        = null;
  private InputType           _input_type      = InputType.FILES; 
  private bool                _recursive       = false;
  private OutputDirectoryType _output_dir_type = OutputDirectoryType.REPLACE;
  private string              _same_dir_suffix = _( "converted" );
  private string              _new_output_dir  = "";

  private signal void update_run_state();

  //-------------------------------------------------------------
  // Constructor
  public Batcher( MainWindow win ) {
    _win = win;
  }

  //-------------------------------------------------------------
  // Creates the batch processing button that can be added to the
  // header bar of the application.
  public Button build_button() {

    var btn = new Button.from_icon_name( _win.get_header_icon_name( "text-x-generic" ) ) {
      has_frame = false,
      sensitive = !_win.functions.category_empty( "custom" ),
      tooltip_markup = Utils.tooltip_with_accel( _( "Batch Process Files/Folder" ), "<control>y" )
    };

    btn.clicked.connect(() => {
      var win = build_window();
      win.present();
    });

    _win.functions.changed.connect(() => {
      btn.sensitive = !_win.functions.category_empty( "custom" );
    });

    return( btn );

  }

  //-------------------------------------------------------------
  // Displays the batching UI.
  public void show() {
    if( !_win.functions.category_empty( "custom" ) ) {
      var win = build_window();
      win.present();
    }
  }

  //-------------------------------------------------------------
  // Creates the batch window.
  private Granite.Dialog build_window() {

    // Load the previously stored values
    load();

    var win = new Granite.Dialog() {
      modal = true,
      title = _( "Batch Processing" ),
      transient_for = _win
    };

    win.get_content_area().append( build_ui( win ) );

    var cancel = (Button)win.add_button( _( "Cancel" ), Gtk.ResponseType.CLOSE );
    cancel.clicked.connect(() => {
      win.destroy();
    });

    var run = (Button)win.add_button( _( "Run" ), Gtk.ResponseType.ACCEPT );
    run.clicked.connect(() => {
      if( _input_type == InputType.FOLDER ) {
        run_folder( win );
      } else {
        run_selected( win );
      }
    });

    update_run_state.connect(() => {
      switch( _output_dir_type ) {
        case OutputDirectoryType.SAME_DIRECTORY :  run.sensitive = (_same_dir_suffix != "");  break;
        case OutputDirectoryType.NEW_DIRECTORY  :  run.sensitive = (_new_output_dir  != "");  break;
        default                                 :  run.sensitive = true;  break;
      }
    });

    win.set_size_request( 500, 400 );

    // Make sure that the Run button is evaluated
    update_run_state();

    return( win );

  }

  //-------------------------------------------------------------
  // Builds the function frame and returns it to the calling function.
  private Frame build_function_frame() {

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

    // Conversion action selection
    var dd = new DropDown.from_strings( func_names ) {
      halign        = Align.FILL,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = frame_top_margin,
      margin_bottom = 5,
      selected      = selected_func
    };

    Idle.add(() => {
      dd.grab_focus();
      return( false );
    });

    dd.notify["selected"].connect(() => {
      _function = (CustomFunction)functions.index( dd.selected );
    });

    var frame_label = new Label( Utils.make_title( _( "Conversion Action" ) ) ) {
      use_markup = true
    };

    var frame = new Frame( null ) {
      label_widget = frame_label,
      child = dd
    };

    return( frame );

  }

  //-------------------------------------------------------------
  // Builds the input frame for the batch UI.
  private Frame build_input_frame() {

    string[] values = {};
    for( int i=0; i<InputType.NUM; i++ ) {
      var val = (InputType)i;
      values += val.label();
    }

    var dd = new DropDown.from_strings( values ) {
      selected = _input_type
    };

    var folder_recursive = new CheckButton.with_label( _( "Recursively convert subdirectories" ) ) {
      halign = Align.START,
      active = _recursive,
      visible = (_input_type == InputType.FOLDER)
    };

    folder_recursive.notify["active"].connect(() => {
      _recursive = folder_recursive.active;
    });

    dd.notify["selected"].connect(() => {
      _input_type = (InputType)dd.selected;
      folder_recursive.visible = (_input_type == InputType.FOLDER);
    });

    var box = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = frame_top_margin,
      margin_bottom = 5
    };
    box.append( dd );
    box.append( folder_recursive );

    var frame_label = new Label( Utils.make_title( _( "Input Options" ) ) ) {
      use_markup = true
    };

    var frame = new Frame( null ) {
      label_widget = frame_label,
      child = box
    };

    return( frame );

  }

  //-------------------------------------------------------------
  // Updates the same directory example text with the appropriate
  // information based on the value of same_dir_suffix.
  private void update_same_dir_label( Label lbl ) {
    if( _same_dir_suffix == "" ) {
      lbl.label = _( "A suffix string is needed to proceed!" );
    } else {
      lbl.label = "(" + _( "example" ) + ": <i>" + _( "filename" ) + ".%s.txt</i>)".printf( _same_dir_suffix );
    }
  }

  //-------------------------------------------------------------
  // Creates the output frame and returns it to the calling function.
  private Frame build_output_frame() {

    string[] outputs = {};
    for( int i=0; i<OutputDirectoryType.NUM; i++ ) {
      var od_type = (OutputDirectoryType)i;
      outputs += od_type.label();
    }

    var dd = new DropDown.from_strings( outputs );

    // Create the same directory UI
    var same_dir_lbl = new Label( _( "Filename suffix:" ) ) {
      halign = Align.START
    };

    var same_dir_entry = new Entry() {
      halign = Align.FILL,
      hexpand = true,
    };

    var same_dir_sample = new Label( "" ) {
      use_markup = true,
      halign = Align.START
    };

    update_same_dir_label( same_dir_sample );

    same_dir_entry.changed.connect(() => {
      _same_dir_suffix = same_dir_entry.text;
      update_same_dir_label( same_dir_sample );
      update_run_state();
    });

    var same_dir_box = new Grid() {
      halign = Align.FILL,
      row_spacing = 5,
      column_spacing = 5,
      visible = (_output_dir_type == OutputDirectoryType.SAME_DIRECTORY)
    };
    same_dir_box.attach( same_dir_lbl,    0, 0 );
    same_dir_box.attach( same_dir_entry,  1, 0 );
    same_dir_box.attach( same_dir_sample, 1, 1 );

    // Create the new directory UI
    var new_dir_lbl = new Label( _( "Output directory:" ) ) {
      halign = Align.START
    };

    var new_dir_entry = new Entry() {
      halign   = Align.FILL,
      placeholder_text = _( "Select output directory" ),
      hexpand  = true,
      text     = _new_output_dir,
      editable = false
    };

    var new_dir_btn = new Button.from_icon_name( "folder-open-symbolic" ) {
      tooltip_text = _( "Change output directory" )
    };

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
          update_run_state();
        } catch( Error e ) {}
      });
    });

    var new_dir_box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign  = Align.FILL,
      visible = (_output_dir_type == OutputDirectoryType.NEW_DIRECTORY)
    };
    new_dir_box.append( new_dir_lbl );
    new_dir_box.append( new_dir_entry );
    new_dir_box.append( new_dir_btn );

    dd.notify["selected"].connect(() => {
      _output_dir_type     = (OutputDirectoryType)dd.selected;
      same_dir_box.visible = (_output_dir_type == OutputDirectoryType.SAME_DIRECTORY);
      new_dir_box.visible  = (_output_dir_type == OutputDirectoryType.NEW_DIRECTORY);
      update_run_state();
    });

    dd.selected = _output_dir_type;

    var box = new Box( Orientation.VERTICAL, 5 ) {
      halign        = Align.FILL,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = frame_top_margin,
      margin_bottom = 5,
    };
    box.append( dd );
    box.append( same_dir_box );
    box.append( new_dir_box );

    var frame_label = new Label( Utils.make_title( _( "Output Options" ) ) ) {
      use_markup = true
    };

    var frame = new Frame( null ) {
      label_widget = frame_label,
      child = box
    };

    return( frame );

  }

  //-------------------------------------------------------------
  // Builds the batch mode UI and returns it to the calling function
  // as a Gtk Box.
  private Box build_ui( Granite.Dialog batch_win ) {

    var title = new Label( Utils.make_title( _( "Batch Processor" ) ) ) {
      use_markup = true,
      halign = Align.CENTER
    };

    var box = new Box( Orientation.VERTICAL, frame_top_margin );
    box.append( title );
    box.append( build_function_frame() );
    box.append( build_input_frame() );
    box.append( build_output_frame() );

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

    try {

      var enumerator = folder.enumerate_children(
        FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
        FileQueryInfoFlags.NONE
      );

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
  public void run_selected( Granite.Dialog batch_win ) {

    var dialog = new FileDialog() {
      modal = true,
      title = _( "Select one or more files to convert" ),
      accept_label = _( "Select" )
    };

    dialog.open_multiple.begin( batch_win, null, (obj, res) => {
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
          save();
          batch_win.destroy();
          return( false );
        });
      } catch( Error e ) {}
    });

  }

  //-------------------------------------------------------------
  // Runs the batcher on a user-selected directory.
  public void run_folder( Granite.Dialog batch_win ) {

    var dialog = new FileDialog() {
      modal = true,
      title = _( "Select directory to convert" ),
      accept_label = _( "Select" )
    };

    dialog.select_folder.begin( batch_win, null, (obj, res) => {
      try {
        var folder = dialog.select_folder.end( res );
        Idle.add(() => {
          _win.remove_widget();
          convert_folder( folder );
          _win.do_new();
          _win.notification( _( "Batch processing complete!" ), "" );
          save();
          batch_win.destroy();
          return( false );
        });
      } catch( Error e ) {}
    });

  }

  //-------------------------------------------------------------
  // Returns the XML filepath for saving/loading the bathcher values.
  private string xml_file() {
    return( GLib.Path.build_filename( TextShine.get_home_dir(), "batcher.xml" ) );
  }

  //-------------------------------------------------------------
  // Saves the batcher settings in XML format.  This only needs to be
  // called when the batcher window is closed.
  private void save() {

    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "batcher" );
    root->set_prop( "version", _win.application.version );

    root->set_prop( "function",        _function.name );
    root->set_prop( "input-type",      _input_type.to_string() );
    root->set_prop( "recursive",       _recursive.to_string() );
    root->set_prop( "output-dir-type", _output_dir_type.to_string() );
    root->set_prop( "same-dir-suffix", _same_dir_suffix );
    root->set_prop( "new-output-dir",  _new_output_dir );

    doc->set_root_element( root );
    doc->save_format_file( xml_file(), 1 );

    delete doc;

  }

  //-------------------------------------------------------------
  // Loads the batcher settings in XML format.
  private void load() {

    var filename = xml_file();

    if( !FileUtils.test( filename, FileTest.EXISTS ) ) {
      return;
    }

    Xml.Doc* doc = Xml.Parser.read_file( filename, null, Xml.ParserOption.HUGE );
    if( doc == null ) {
      return;
    }

    var root = doc->get_root_element();

    var f = root->get_prop( "function" );
    if( f != null ) {
      var functions = _win.functions.get_category_functions( "custom" );
      for( int i=0; i<functions.length; i++ ) {
        if( functions.index( i ).name == f ) {
          _function = (CustomFunction)functions.index( i );
          break;
        }
      }
      if( (_function == null) && (functions.length > 0) ) {
        _function = (CustomFunction)functions.index( 0 );
      }
    }

    var it = root->get_prop( "input-type" );
    if( it != null ) {
      _input_type = InputType.parse( it );
    }

    var r = root->get_prop( "recursive" );
    if( r != null ) {
      _recursive = bool.parse( r );
    }

    var ot = root->get_prop( "output-dir-type" );
    if( ot != null ) {
      _output_dir_type = OutputDirectoryType.parse( ot );
    }

    var sds = root->get_prop( "same-dir-suffix" );
    if( sds != null ) {
      _same_dir_suffix = sds;
    }

    var nod = root->get_prop( "new-output-dir" );
    if( nod != null ) {
      _new_output_dir = FileUtils.test( nod, FileTest.EXISTS ) ? nod : "";
    }

    delete doc;

  }

}
