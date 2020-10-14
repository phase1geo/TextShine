/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
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

using GLib;
using Gtk;

public class UndoItem : GLib.Object {

  private class UndoElement {
    public UndoElement() {}
    public virtual void undo( Editor editor ) {}
    public virtual void redo( Editor editor ) {}
    public virtual bool mergeable( bool insert, int start, int end ) { return( false ); }
  }

  private class UndoReplaceElement : UndoElement {
    private int    _start;
    private string _old_text;
    private string _new_text;
    public UndoReplaceElement( int start, string old_text, string new_text ) {
      _start    = start;
      _old_text = old_text;
      _new_text = new_text;
    }
    private void replace( Editor editor, string curr, string prev ) {
      TextIter start, end;
      editor.buffer.get_iter_at_offset( out start, _start );
      if( curr.length > 0 ) {
        editor.buffer.get_iter_at_offset( out end, (_start + curr.char_count()) );
        editor.buffer.delete( ref start, ref end );
      }
      editor.buffer.insert( ref start, prev, prev.length );
    }
    public override void undo( Editor editor ) {
      replace( editor, _new_text, _old_text );
    }
    public override void redo( Editor editor ) {
      replace( editor, _old_text, _new_text );
    }
  }

  private class UndoSelectElement : UndoElement {
    private bool _add;
    private int  _start;
    private int  _end;
    public UndoSelectElement( bool add, int start, int end ) {
      _add   = add;
      _start = start;
      _end   = end;
    }
    public override void undo( Editor editor ) {
      TextIter start, end;
      editor.buffer.get_iter_at_offset( out start, _start );
      editor.buffer.get_iter_at_offset( out end,   _end );
      if( _add ) {
        editor.buffer.remove_tag_by_name( "selected", start, end );
      } else {
        editor.buffer.apply_tag_by_name( "selected", start, end );
      }
    }
    public override void redo( Editor editor ) {
      TextIter start, end;
      editor.buffer.get_iter_at_offset( out start, _start );
      editor.buffer.get_iter_at_offset( out end,   _end );
      if( _add ) {
        editor.buffer.apply_tag_by_name( "selected", start, end );
      } else {
        editor.buffer.remove_tag_by_name( "selected", start, end );
      }
    }
  }

  private class UndoEditElement : UndoElement {
    private bool   _insert;
    private int    _start;
    private string _text;
    public UndoEditElement( bool insert, int start, string text ) {
      _insert = insert;
      _start  = start;
      _text   = text;
    }
    private void do_insert( Editor editor ) {
      TextIter start;
      editor.buffer.get_iter_at_offset( out start, _start );
      editor.buffer.insert( ref start, _text, _text.length );
    }
    private void do_delete( Editor editor ) {
      TextIter start, end;
      editor.buffer.get_iter_at_offset( out start, _start );
      editor.buffer.get_iter_at_offset( out end,   (_start + _text.char_count()) );
      editor.buffer.delete_range( start, end );
    }
    public override void undo( Editor editor ) {
      if( _insert ) {
        do_delete( editor );
      } else {
        do_insert( editor );
      }
    }
    public override void redo( Editor editor ) {
      if( _insert ) {
        do_insert( editor );
      } else {
        do_delete( editor );
      }
    }
    public override bool mergeable( bool insert, int start, int end ) {
      if( _insert ) {
        return( insert && ((_start + _text.char_count()) == start) );
      } else {
        return( (!insert && (end == _start)) || (insert && (start == _start)) );
      }
    }
  }

  private Array<UndoElement> _elements;

  public string name { set; get; default = ""; }
  public int    id   { set; get; default = -1; }

  /* Default constructor */
  public UndoItem( string name ) {
    this.name = name;
    _elements = new Array<UndoElement>();
  }

  public void add_replacement( int start, string old_text, string new_text ) {
    var element = new UndoReplaceElement( start, old_text, new_text );
    _elements.append_val( element );
  }

  public void add_select( bool add, int start, int end ) {
    var element = new UndoSelectElement( add, start, end );
    _elements.append_val( element );
  }

  public void add_edit( bool insert, int start, string text ) {
    var element = new UndoEditElement( insert, start, text );
    _elements.append_val( element );
  }

  /* Causes the stored item to be put into the before state */
  public void undo( Editor editor ) {
    for( int i=((int)_elements.length - 1); i>=0; i-- ) {
      _elements.index( i ).undo( editor );
    }
  }

  /* Causes the stored item to be put into the after state */
  public void redo( Editor editor ) {
    for( int i=0; i<_elements.length; i++ ) {
      _elements.index( i ).redo( editor );
    }
  }

  /*
   Returns a hnalde to the last undo element if it is mergeable; otherwise,
   returns null.
  */
  public bool mergeable( bool insert, int start, int end ) {
    if( _elements.length == 0 ) return( false );
    return( _elements.index( _elements.length - 1 ).mergeable( insert, start, end ) );
  }

  public string to_string() {
    return( "%s [%d]".printf( name, id ) );
  }

}
