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

public class ConvertMarkdownHTML : TextFunction {

  private Regex _re;

  /* Constructor */
  public ConvertMarkdownHTML( bool custom = false ) {
    base( "convert-markdown-html", custom, FunctionDirection.LEFT_TO_RIGHT );
    try {
      _re = new Regex( """(\t| {2,})""" );
    } catch( RegexError e ) {}
  }

  protected override string get_label0() {
    return( _( "Convert Markdown to HTML" ) );
  }

  protected override string get_label1() {
    return( _( "Convert HTML to Markdown" ) );
  }

  public override TextFunction copy( bool custom ) {
    var fn = new ConvertMarkdownHTML( custom );
    fn.direction = direction;
    return( fn );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    if( direction == FunctionDirection.LEFT_TO_RIGHT ) {
      return( markdown_to_html( original ) );
    } else {
      return( html_to_markdown( original ) );
    }
  }

  /* Converts the given string into HTML from Markdown */
  private string markdown_to_html( string text ) {
    var html = "";
    var flags = 0x47607004;
    var mkd   = new Markdown.Document.gfm_format( text.data, flags );
    mkd.compile( flags );
    mkd.get_document( out html );
    return( html );
  }

  /* Converts the given string into Markdown from HTML */
  private string html_to_markdown( string original ) {
    var html = "<div>" + original + "</div>";
    var doc = Xml.Parser.parse_memory( html, html.length );
    if( doc == null ) {
      return( original );
    }
    var root = doc->get_root_element();
    var text = parse_children( root, false );
    delete doc;
    return( text );
  }

  private string parse_node( Xml.Node* node, bool verbatim ) {
    var str = "";
    switch( node->type ) {
      case Xml.ElementType.ELEMENT_NODE :
        str = parse_element( node, verbatim );
        break;
      case Xml.ElementType.CDATA_SECTION_NODE :
        str = node->get_content();
        break;
      case Xml.ElementType.TEXT_NODE :
        var text     = node->get_content();
        var stripped = text.strip();
        if( verbatim || (text == " ") ) {
          str = text;
        } else if( stripped == "" ) {
          str = stripped;
        } else {
          try {
            text = _re.replace( text, text.length, 0, "" );
            if( text != "\n" ) {
              str += text.replace( "\n", " " );
            }
          } catch( RegexError e ) {}
        }
        break;
    }
    return( str );
  }

  private string parse_children( Xml.Node* node, bool verbatim ) {
    var str = "";
    for( Xml.Node* it=node->children; it!=null; it=it->next ) {
      str += parse_node( it, verbatim );
    }
    return( verbatim ? str : str.strip() );
  }

  /* Parses the given element for tag information */
  private string parse_element( Xml.Node* node, bool verbatim ) {
    var name = node->name.down();
    switch( name ) {
      case "a"          :
        var url = node->get_prop( "href" );
        if( url.get_char( 0 ) != '#' ) {
          var str = parse_children( node, verbatim );
          if( str == url ) {
            return( "<" + url + ">" );
          } else {
            return( "[" + str + "](" + url + ")" );
          }
        }
        break;
      case "img"        :
        var src = node->get_prop( "src" );
        var alt = node->get_prop( "alt" ) ?? "";
        return( "![" + alt + "](" + src + ")" );
      case "h1"         :  return( "# " + parse_children( node, false ) + "\n\n" );
      case "h2"         :  return( "## " + parse_children( node, false ) + "\n\n" );
      case "h3"         :  return( "### " + parse_children( node, false ) + "\n\n" );
      case "h4"         :  return( "#### " + parse_children( node, false ) + "\n\n" );
      case "h5"         :  return( "##### " + parse_children( node, false ) + "\n\n" );
      case "h6"         :  return( "###### " + parse_children( node, false ) + "\n\n" );
      case "strong"     :
      case "b"          :  return( "**" + parse_children( node, verbatim ) + "**" );
      case "em"         :
      case "i"          :  return( "*" + parse_children( node, verbatim ) + "*" );
      case "u"          :  return( "__" + parse_children( node, verbatim ) + "__" );
      case "s"          :
      case "del"        :  return( "~~" + parse_children( node, verbatim ) + "~~" );
      case "tt"         :
      case "code"       :  return( (verbatim ? "" : "`") + parse_children( node, verbatim ) + (verbatim ? "" : "`") );
      case "sub"        :  return( "<sub>" + parse_children( node, verbatim ) + "</sub>" );
      case "sup"        :  return( "<sup>" + parse_children( node, verbatim ) + "</sup>" );
      case "pre"        :  return( "\n```\n" + parse_children( node, true ) + "\n```\n" );
      case "li"         :  return( "- " + parse_children( node, verbatim ) + "\n" );
      case "blockquote" :  return( "> " + parse_children( node, verbatim ) + "\n" );
      case "br"         :  return( "\n" );
      case "hr"         :  return( "---\n" );
      case "div"        :
      case "p"          :  return( parse_children( node, verbatim ) + "\n\n" );
      case "th"         :
      case "td"         :
        var colspan = node->get_prop( "colspan" );
        var str     = parse_children( node, false );
        return( ((str == "") ? " " : str) + ((colspan != null) ? string.nfill( int.parse( colspan ), '|' ) : "|") );
      case "tr"         :  return( "|" + parse_children( node, verbatim ) + "\n" );
      case "table"      :  return( make_table( parse_children( node, verbatim ) ) + "\n\n" );
      case "ul"         :
      case "ol"         :
      case "span"       :  return( parse_children( node, verbatim ) );
      case "thead"      :
      case "tbody"      :  return( parse_children( node, verbatim ) + "\n" );
    }
    return( make_html( node, verbatim ) );
  }

  private string make_html( Xml.Node* node, bool verbatim ) {
    var name  = node->name.down();
    var stag  = "<" + name;
    var etag  = "</" + name + ">";
    var props = "";
    for( Xml.Attr* it=node->properties; it!=null; it=it->next ) {
      props += " " + it->name + "=\"" + node->get_prop( it->name ) + "\"";
    }
    stag += props + ">";
    return( stag + parse_children( node, verbatim ) + etag );
  }

  private string make_table( string text ) {

    var lines = new Array<string>();
    foreach( string line in text.split( "\n" ) ) {
      lines.append_val( line );
    }

    var cells = lines.index( 0 ).split( "|" );
    var row   = "|";
    for( int i=1; i<((int)cells.length - 1); i++ ) {
      row += "-|";
    }

    lines.insert_val( 1, row );

    var beautifier = new MarkdownTableBeauty();

    return( beautifier.transform_text( string.joinv( "\n", lines.data ), 0 ) );

  }

}
