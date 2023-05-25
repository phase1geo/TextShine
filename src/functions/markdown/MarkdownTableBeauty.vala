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
using Gee;
using GLib.Math;

public class MarkdownTableBeauty : TextFunction {

  private class Matrix {

    public enum ColumnAlignment {
      NONE,
      CENTER,
      LEFT,
      RIGHT
    }

    private class Cell {
      public string data;
      public int    column;
      public int    colspan;
      public Cell( string data, int column ) {
        this.data    = data;
        this.column  = column;
        this.colspan = 1;
      }
      public int last_column() {
        return( column + (colspan - 1) );
      }
      public int column_width() {
        var width = data.char_count();
        return( (colspan == 1) ? width : (int)round( (width - ((colspan -1) * 2)) / colspan ) );
      }
      public void update_column_widths( ref int[] col_widths ) {
        var col_width = column_width();
        for( int i=column; i<=last_column(); i++ ) {
          col_widths[i] = (i == 0) ? (int)fmin( col_widths[i], col_width ) : (int)fmax( col_widths[i], col_width );
        }
      }
      public ColumnAlignment get_alignment( bool prev_none ) {
        var first = data.get_char( 0 );
        var last  = data.get_char( data.index_of_nth_char( data.char_count() - 1 ) );
        if( first == ':' ) {
          return( (last == ':') ? ColumnAlignment.CENTER : ColumnAlignment.LEFT );
        } else if( last == ':' ) {
          return( ColumnAlignment.RIGHT );
        } else if( first == '?' ) {
          return( prev_none ? ColumnAlignment.NONE : ColumnAlignment.LEFT );
        }
        return( ColumnAlignment.NONE );
      }
      private string spacing( ref int[] widths ) {
        var total = 0;
        for( int i=column; i<(column + colspan); i++ ) {
          total += widths[i];
        }
        if( colspan > 1 ) {
          total += ((colspan - 1) * 2);
        }
        return( string.nfill( (total - data.char_count()), ' ' ) );
      }
      public string adjust( ref int[] widths, Array<ColumnAlignment> aligns ) {
        var space = spacing( ref widths );
        var lines = string.nfill( (colspan - 1), '|' );
        if( column == 0 ) {
          return( string.nfill( widths[0], ' ' ) );
        } else {
          switch( aligns.index( column ) ) {
            case ColumnAlignment.LEFT   :
            case ColumnAlignment.NONE   :  return( " " + data + space + " " + lines );
            case ColumnAlignment.RIGHT  :  return( " " + space + data + " " + lines );
            case ColumnAlignment.CENTER :
              return( " " + space.slice( 0, (space.length / 2) ) + data + space.slice( (space.length / 2), space.length ) + " " + lines );
          }
        }
        return( "" );
      }
    }

    public class Row {
      private Array<Cell> _cells;
      public Row() {
        _cells = new Array<Cell>();
        _cells.append_val( new Cell( "", 0 ) );
      }
      public void add_cell( string data ) {
        if( data != "" ) {
          var cell = new Cell( data, (num_columns() + 1) );
          _cells.append_val( cell );
        } else {
          _cells.index( _cells.length - 1 ).colspan++;
        }
      }
      public int num_columns() {
        return( (_cells.length > 0) ? _cells.index( _cells.length - 1 ).last_column() : 0 );
      }
      public void pad_columns( string data, int max_column ) {
        for( int i=(num_columns() + 1); i<=max_column; i++ ) {
          _cells.append_val( new Cell( data, i ) );
        }
      }
      public void update_column_widths( ref int[] col_widths ) {
        for( int i=0; i<_cells.length; i++ ) {
          _cells.index( i ).update_column_widths( ref col_widths );
        }
      }
      public Array<ColumnAlignment> get_alignments() {
        var prev_none  = true;
        var alignments = new Array<ColumnAlignment>();
        for( int i=0; i<_cells.length; i++ ) {
          var alignment = _cells.index( i ).get_alignment( prev_none );
          alignments.append_val( alignment );
          prev_none &= (alignment == ColumnAlignment.NONE);
        }
        return( alignments );
      }
      public string adjust_data( ref int[] widths, Array<ColumnAlignment> aligns ) {
        var cells = new Array<string>();
        for( int i=0; i<_cells.length; i++ ) {
          cells.append_val( _cells.index( i ).adjust( ref widths, aligns ) );
        }
        return( string.joinv( "|", cells.data ) + "|" );
      }
    }

    private Array<Row> _rows;
    private int        _max_column;
    public Matrix( string text ) {
      _rows = new Array<Row>();
      foreach( string rowstr in text.split( "\n" ) ) {
        var row  = new Matrix.Row();
        var data = rowstr.split( "|" );
        foreach( string item in data[1:data.length-1] ) {
          var stripped = item.strip();
          row.add_cell( (item == "") ? "" : ((stripped == "") ? " " : stripped) );
        }
        add_row( row );
      }
    }
    private void add_row( Row row ) {
      var row_cols = row.num_columns();
      if( row_cols < _max_column ) {
        row.pad_columns( ((_rows.length == 1) ? "?" : " "), _max_column );
      } else if( row_cols > _max_column ) {
        _max_column = row_cols;
        for( int i=0; i<_rows.length; i++ ) {
          _rows.index( i ).pad_columns( ((i == 1) ? "?" : ""), _max_column );
        }
      }
      _rows.append_val( row );
    }
    private int[] get_column_widths() {
      var col_widths = new int[_max_column + 1];
      for( int i=0; i<=_max_column; i++ ) {
        col_widths[i] = (i == 0) ? 10000 : 0;
      }
      for( int i=0; i<_rows.length; i++ ) {
        if( i != 1 ) {
          _rows.index( i ).update_column_widths( ref col_widths );
        }
      }
      return( col_widths );
    }
    private Array<ColumnAlignment> get_alignments() {
      return( _rows.index( 1 ).get_alignments() );
    }
    private string create_align_row( ref int[] widths, Array<ColumnAlignment> aligns ) {
      var cols = new Array<string>();
      cols.append_val( string.nfill( widths[0], ' ' ) );
      for( int i=1; i<=_max_column; i++ ) {
        switch( aligns.index( i ) ) {
          case ColumnAlignment.LEFT   :  cols.append_val( ":" + string.nfill( (widths[i] + 1), '-' ) );  break;
          case ColumnAlignment.RIGHT  :  cols.append_val( string.nfill( (widths[i] + 1), '-' ) + ":" );  break;
          case ColumnAlignment.CENTER :  cols.append_val( ":" + string.nfill( widths[i], '-' ) + ":" );  break;
          case ColumnAlignment.NONE   :  cols.append_val( string.nfill( (widths[i] + 2), '-' ) );  break;
        }
      }
      return( string.joinv( "|", cols.data ) + "|" );
    }
    public string adjust_rows() {
      var lines  = new Array<string>();
      var widths = get_column_widths();
      var aligns = get_alignments();
      for( int i=0; i<_rows.length; i++ ) {
        if( i == 1 ) {
          lines.append_val( create_align_row( ref widths, aligns ) );
        } else {
          lines.append_val( _rows.index( i ).adjust_data( ref widths, aligns ) );
        }
      }
      return( string.joinv( "\n", lines.data ) );
    }

  }

  private Regex _table_re;

  /* Constructor */
  public MarkdownTableBeauty( bool custom = false ) {
    base( "markdown-table-beautifier", custom );
    try {
      _table_re = new Regex( """^[ \t]*\|""" );
    } catch( RegexError e ) {}
  }

  public override string get_description() {
    return( _( "Finds Markdown tables in the text and pads/aligns data in the table cells to improve readability." ) );
  }

  protected override string get_label0() {
    return( _( "Beautify Tables" ) );
  }

  public override TextFunction copy( bool custom ) {
    return( new MarkdownTableBeauty( custom ) );
  }

  public override string transform_text( string original, int cursor_pos ) {

    MatchInfo match;
    var text   = original;
    var sbytes = -1;
    var ebytes = -1;
    var bytes  = 0;
    var found  = false;
    var nbytes = "\n".length;
    var str    = "";

    foreach( string line in text.split( "\n" ) ) {
      if( _table_re.match( line, 0, out match ) ) {
        if( !found ) sbytes = bytes;
        ebytes = bytes + line.length;
        found = true;
      } else {
        if( found ) {
          str += beautify_table( text, sbytes, ebytes ) + "\n";
          found = false;
        }
        str += line + "\n";
      }
      bytes += (line.length + nbytes);
    }

    if( found ) {
      str += beautify_table( text, sbytes, ebytes );
    }

    return( str );

  }

  private string beautify_table( string text, int start, int end ) {
    var matrix = new Matrix( text.slice( start, end ) );
    return( matrix.adjust_rows() );
  }

}


