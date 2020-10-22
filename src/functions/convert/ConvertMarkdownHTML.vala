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
  public ConvertMarkdownHTML() {
    base( "convert-markdown-html", FunctionDirection.LEFT_TO_RIGHT );
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

  public override TextFunction copy() {
    var fn = new ConvertMarkdownHTML();
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
    var text = parse_xml_node( root );
    delete doc;
    return( text );
  }

  private string parse_xml_node( Xml.Node* node ) {
    var str = "";
    for( Xml.Node* it=node->children; it!=null; it=it->next ) {
      str += parse_xml_node( it );
    }
    switch( node->type ) {
      case Xml.ElementType.ELEMENT_NODE       :
        str = parse_element( node, str );
        break;
      case Xml.ElementType.CDATA_SECTION_NODE :
      case Xml.ElementType.TEXT_NODE          :
        var text = node->get_content();
        try {
          text = _re.replace( text, text.length, 0, "" );
          if( text != "\n" ) {
            str += text.replace( "\n", " " );
          }
        } catch( RegexError e ) {}
        break;
    }
    return( str );
  }

  /* Parses the given element for tag information */
  private string parse_element( Xml.Node* node, string text ) {
    var name = node->name.down();
    var str  = text.strip();
    switch( name ) {
      case "a"          :
        var url = node->get_prop( "href" );
        if( url.get_char( 0 ) != '#' ) {
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
      case "h1"         :  return( "# " + str + "\n\n" );
      case "h2"         :  return( "## " + str + "\n\n" );
      case "h3"         :  return( "### " + str + "\n\n" );
      case "h4"         :  return( "#### " + str + "\n\n" );
      case "h5"         :  return( "##### " + str + "\n\n" );
      case "h6"         :  return( "###### " + str + "\n\n" );
      case "strong"     :
      case "b"          :  return( "**" + str + "**" );
      case "em"         :
      case "i"          :  return( "*" + str + "*" );
      case "u"          :  return( "__" + str + "__" );
      case "s"          :
      case "del"        :  return( "~~" + str + "~~" );
      case "tt"         :
      case "code"       :  return( "`" + str + "`" );
      case "sub"        :  return( "<sub>" + str + "</sub>" );
      case "sup"        :  return( "<sup>" + str + "</sup>" );
      case "verbatim"   :  return( "\n```\n" + str + "\n```\n" );
      case "li"         :  return( "- " + str + "\n" );
      case "blockquote" :  return( "> " + str + "\n" );
      case "p"          :  return( str.chug() + "\n\n" );
      case "th"         :
      case "td"         :
        var colspan = node->get_prop( "colspan" );
        return( ((str == "") ? " " : str) + ((colspan != null) ? string.nfill( int.parse( colspan ), '|' ) : "|") );
      case "tr"         :  return( "|" + str + "\n" );
      case "table"      :  return( make_table( str ) + "\n\n" );
    }
    return( text );
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
