using Gee;

public class EmmetMLLookupValue {
  public string                 ename  { private set; get; }
  public int                    tagnum { private set; get; }
  public HashMap<string,string> attrs  { private set; get; }
  public EmmetMLLookupValue( string e, int t, ... ) {
    ename  = e;
    tagnum = t;
    attrs  = new HashMap<string,string>();

    var l = va_list();
    while( true ) {
      string? key = l.arg();
      if( key != null ) break;
      string? val = l.arg();
      attrs.@set( key, val );
    }
  }
}

public class EmmetTreeNode {
  public EmmetTreeNode?       parent   { private set; get; }
  public Array<EmmetTreeAttr> attrs    { private set; get; }
  public Array<EmmetTreeNode> children { private set; get; }
  public EmmetTreeNode() {
    parent   = null;
    attrs    = new Array<EmmetTreeAttr>();
    children = new Array<EmmetTreeNode>();
  }
  public void insert( EmmetTreeNode parent, int index, EmmetTreeNode node ) {
    if( index == -1 ) {
      parent.children.append_val( node );
    } else {
      parent.children.insert( index, node );
    }
  }
  public void remove( EmmetTreeNode parent, EmmetTreeNode node ) {
    for( int i=0; i<parent.children.length; i++ ) {
      if( node != parent.children.index( i ) ) {
        parent.children.remove_index( i );
        return;
      }
    }
  }
  public void move( EmmetTreeNode parent, int index, EmmetTreeNode node ) {
    tree_node_remove( node.parent, node );
    tree_node_insert( parent, index, node );
  }
  public int depth() {
    EmmetTreeNode cur   = this;
    int           depth = 0;
    while( cur.parent != null ) {
      cur = cur.parent;
      depth++;
    }
    return( depth );
  }
}

public class EmmetHelper {

  private HashMap<string,string>             block_aliases;
  private HashMap<string,EmmetMLLookupValue> ml_lookup;
  private HashMap<string,bool>               inlined;

  private TreeNode?                          dom  = null;
  private TreeNode?                          elab = null;

  private bool                               emmet_multi = false;
  private string                             emmet_wrap_str = "";
  private Array<string>                      emmet_wrap_strs;

  private Regex                              name1_re;
  private Regex                              name2_re;
  private Regex                              lipsum_re;
  private Regex                              html_re;


  public EmmetHelper() {

    emmet_wrap_strs = new Array<string>();

    initialize_block_aliases();
    initialize_ml_lookup();
    initialize_inlined();

    try {
      name1_re  = new Regex( "^$#" );
      name2_re  = new Regex( "^($+)(@(-)?(\\d*))?" );
      lipsum_re = new Regex( "<lipsum>(.*)</lipsum>" );
    } catch( Regex.Error e ) {}

  }

  /* Initializes the block aliases array */
  private void initialize_block_aliases() {

    block_aliases   = new HashMap<string,string>();

    // HTML
    block_aliases.@set( "!", "!!!+doc[lang=en]" );
    block_aliases.@set( "doc",       "html>(head>meta[charset=UTF-8]+title{PLACEHOLDER})+body" );
    block_aliases.@set( "doc4",      "html>(head>meta[http-equiv=\"Content-Type\" content=\"text/html;charset=${charset}\"]+title{PLACEHOLDER})+body" );
    block_aliases.@set( "html:4t",   "!!!4t+doc4[lang=en]" );
    block_aliases.@set( "html:4s",   "!!!4s+doc4[lang=en]" );
    block_aliases.@set( "html:xt",   "!!!xt+doc4[xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=en]" );
    block_aliases.@set( "html:xs",   "!!!xs+doc4[xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=en]" );
    block_aliases.@set( "html:xxs",  "!!!xxs+doc4[xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=en]" );
    block_aliases.@set( "html:5",    "!!!+doc[lang=en]" );
    block_aliases.@set( "ol+",       "ol>li" );
    block_aliases.@set( "dl+",       "dl>dt+dd" );
    block_aliases.@set( "map+",      "map>area" );
    block_aliases.@set( "table+",    "table>tr>td" );
    block_aliases.@set( "colgroup+", "colgroup>col" );
    block_aliases.@set( "colg+",     "colgroup>col" );
    block_aliases.@set( "tr+",       "tr>td" );
    block_aliases.@set( "select+",   "select>option" );
    block_aliases.@set( "optgroup+", "optgroup>option" );
    block_aliases.@set( "optg+",     "optgroup>option" );

    // CSS

    // XSLT
    block_aliases.@set( "choose+",   "xml:choose>xsl:when+xsl:otherwise" );
    block_aliases.@set( "xsl",       "xsl:stylesheet[version=1.0 xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\"]" );

  }

  private void initialize_ml_lookup() {

    ml_lookup = new HashMap<string,EmmetMLLookupValue>();

    // HTML
    ml_lookup.@set( "a",                    new EmmetMLLookupValue( "a",          1, "href", "" ) );
    ml_lookup.@set( "a:link",               new EmmetMLLookupValue( "a",          1, "href", "http://" ) );
    ml_lookup.@set( "a:mail",               new EmmetMLLookupValue( "a",          1, "href", "mailto:" ) );
    ml_lookup.@set( "abbr",                 new EmmetMLLookupValue( "abbr",       1, "title", "" ) );
    ml_lookup.@set( "acronym",              new EmmetMLLookupValue( "acronym",    1, "title", "" ) );
    ml_lookup.@set( "base",                 new EmmetMLLookupValue( "base",       1, "href", "" ) );
    ml_lookup.@set( "basefont",             new EmmetMLLookupValue( "basefont",   0 ) );
    ml_lookup.@set( "br",                   new EmmetMLLookupValue( "br",         0 ) );
    ml_lookup.@set( "frame",                new EmmetMLLookupValue( "frame",      0 ) );
    ml_lookup.@set( "hr",                   new EmmetMLLookupValue( "hr",         0 ) );
    ml_lookup.@set( "bdo",                  new EmmetMLLookupValue( "bdo",        1, "dir", "" ) );
    ml_lookup.@set( "bdo:r",                new EmmetMLLookupValue( "bdo",        1, "dir", "rtl" ) );
    ml_lookup.@set( "bdo:l",                new EmmetMLLookupValue( "bdo",        1, "dir", "ltr" ) );
    ml_lookup.@set( "col",                  new EmmetMLLookupValue( "col",        0 ) );
    ml_lookup.@set( "link",                 new EmmetMLLookupValue( "link",       0, "rel", "stylesheet", "href", "" ) );
    ml_lookup.@set( "link:css",             new EmmetMLLookupValue( "link",       0, "rel", "stylesheet", "href", "PLACEHOLDER.css" ) );
    ml_lookup.@set( "link:print",           new EmmetMLLookupValue( "link",       0, "rel", "stylesheet", "href", "PLACEHOLDER.css", "media", "print" ) );
    ml_lookup.@set( "link:favicon",         new EmmetMLLookupValue( "link",       0, "rel", "shortcut icon", "type", "image/x-icon", "href", "PLACEHOLDER.ico" ) );
    ml_lookup.@set( "link:touch",           new EmmetMLLookupValue( "link",       0, "rel", "apple-touch-icon", "href", "PLACEHOLDER.png" ) );
    ml_lookup.@set( "link:rss",             new EmmetMLLookupValue( "link",       0, "rel", "alternate", "type", "application/rss+xml", "title", "RSS", "href", "PLACEHOLDER.xml" ) );
    ml_lookup.@set( "link:atom",            new EmmetMLLookupValue( "link",       0, "rel", "alternate", "type", "application/atom+xml", "title", "Atom", "href", "PLACEHOLDER.xml" ) );
    ml_lookup.@set( "meta",                 new EmmetMLLookupValue( "meta",       0 ) );
    ml_lookup.@set( "meta:utf",             new EmmetMLLookupValue( "meta",       0, "http-equiv", "Content-Type", "content", "text/html;charset=UTF-8" ) );
    ml_lookup.@set( "meta:win",             new EmmetMLLookupValue( "meta",       0, "http_equiv", "Content-Type", "content", "text/html;charset=windows-1251" ) );
    ml_lookup.@set( "meta:vp",              new EmmetMLLookupValue( "meta",       0, "name", "viewport", "content", "width=PLACEHOLDER, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0" ) );
    ml_lookup.@set( "meta:compat",          new EmmetMLLookupValue( "meta",       0, "http-equiv", "X-UA-Compatible", "content", "IE=7" ) );
    ml_lookup.@set( "style",                new EmmetMLLookupValue( "style",      1 ) );
    ml_lookup.@set( "script",               new EmmetMLLookupValue( "script",     1 ) );
    ml_lookup.@set( "script:src",           new EmmetMLLookupValue( "script",     1, "src", "" ) );
    ml_lookup.@set( "img",                  new EmmetMLLookupValue( "img",        0, "src", "", "alt", "" ) );
    ml_lookup.@set( "iframe",               new EmmetMLLookupValue( "iframe",     1, "src", "", "frameborder", "0" ) );
    ml_lookup.@set( "embed",                new EmmetMLLookupValue( "embed",      1, "src", "", "type", "" ) );
    ml_lookup.@set( "object",               new EmmetMLLookupValue( "object",     1, "data", "", "type", "" ) );
    ml_lookup.@set( "param",                new EmmetMLLookupValue( "param",      0, "name", "", "value", "" ) );
    ml_lookup.@set( "map",                  new EmmetMLLookupValue( "map",        1, "name", "" ) );
    ml_lookup.@set( "area",                 new EmmetMLLookupValue( "area",       0, "shape", "", "coords", "", "href", "", "alt", "" ) );
    ml_lookup.@set( "area:d",               new EmmetMLLookupValue( "area",       0, "shape", "default", "href", "", "alt", "" ) );
    ml_lookup.@set( "area:c",               new EmmetMLLookupValue( "area",       0, "shape", "circle", "coords", "", "href", "", "alt", "" ) );
    ml_lookup.@set( "area:r",               new EmmetMLLookupValue( "area",       0, "shape", "rect", "coords", "", "href", "", "alt", "" ) );
    ml_lookup.@set( "area:p",               new EmmetMLLookupValue( "area",       0, "shape", "poly", "coords", "", "href", "", "alt", "" ) );
    ml_lookup.@set( "form",                 new EmmetMLLookupValue( "form",       1, "action", "" ) );
    ml_lookup.@set( "form:get",             new EmmetMLLookupValue( "form",       1, "action", "", "method", "get" ) );
    ml_lookup.@set( "form:post",            new EmmetMLLookupValue( "form",       1, "action", "", "method", "post" ) );
    ml_lookup.@set( "label",                new EmmetMLLookupValue( "label",      1, "for", "" ) );
    ml_lookup.@set( "input",                new EmmetMLLookupValue( "input",      0, "type", "PLACEHOLDER" ) );
    ml_lookup.@set( "inp",                  new EmmetMLLookupValue( "input",      0, "type", "PLACEHOLDER", "name", "", "id", "" ) );
    ml_lookup.@set( "input:hidden",         new EmmetMLLookupValue( "input",      0, "type", "hidden", "name", "" ) );
    ml_lookup.@set( "input:h",              new EmmetMLLookupValue( "input",      0, "type", "hidden", "name", "" ) );
    ml_lookup.@set( "input:text",           new EmmetMLLookupValue( "input",      0, "type", "PLACEHOLDER", "name", "", "id", "" ) );
    ml_lookup.@set( "input:t",              new EmmetMLLookupValue( "input",      0, "type", "PLACEHOLDER", "name", "", "id", "" ) );
    ml_lookup.@set( "input:search",         new EmmetMLLookupValue( "input",      0, "type", "search", "name", "", "id", "" ) );
    ml_lookup.@set( "input:email",          new EmmetMLLookupValue( "input",      0, "type", "email", "name", "", "id", "" ) );
    ml_lookup.@set( "input:url",            new EmmetMLLookupValue( "input",      0, "type", "url", "name", "", "id", "" ) );
    ml_lookup.@set( "input:password",       new EmmetMLLookupValue( "input",      0, "type", "password", "name", "", "id", "" ) );
    ml_lookup.@set( "input:p",              new EmmetMLLookupValue( "input",      0, "type", "password", "name", "", "id", "" ) );
    ml_lookup.@set( "input:datetime",       new EmmetMLLookupValue( "input",      0, "type", "datetime", "name", "", "id", "" ) );
    ml_lookup.@set( "input:date",           new EmmetMLLookupValue( "input",      0, "type", "date", "name", "", "id", "" ) );
    ml_lookup.@set( "input:datetime-local", new EmmetMLLookupValue( "input",      0, "type", "datetime-local", "name", "", "id", "" ) );
    ml_lookup.@set( "input:month",          new EmmetMLLookupValue( "input",      0, "type", "month", "name", "", "id", "" ) );
    ml_lookup.@set( "input:week",           new EmmetMLLookupValue( "input",      0, "type", "week", "name", "", "id", "" ) );
    ml_lookup.@set( "input:time",           new EmmetMLLookupValue( "input",      0, "type", "time", "name", "", "id", "" ) );
    ml_lookup.@set( "input:number",         new EmmetMLLookupValue( "input",      0, "type", "number", "name", "", "id", "" ) );
    ml_lookup.@set( "input:color",          new EmmetMLLookupValue( "input",      0, "type", "color", "name", "", "id", "" ) );
    ml_lookup.@set( "input:checkbox",       new EmmetMLLookupValue( "input",      0, "type", "checkbox", "name", "", "id", "" ) );
    ml_lookup.@set( "input:c",              new EmmetMLLookupValue( "input",      0, "type", "checkbox", "name", "", "id", "" ) );
    ml_lookup.@set( "input:radio",          new EmmetMLLookupValue( "input",      0, "type", "radio", "name", "", "id", "" ) );
    ml_lookup.@set( "input:r",              new EmmetMLLookupValue( "input",      0, "type", "radio", "name", "", "id", "" ) );
    ml_lookup.@set( "input:range",          new EmmetMLLookupValue( "input",      0, "type", "range", "name", "", "id", "" ) );
    ml_lookup.@set( "input:file",           new EmmetMLLookupValue( "input",      0, "type", "file", "name", "", "id", "" ) );
    ml_lookup.@set( "input:f",              new EmmetMLLookupValue( "input",      0, "type", "file", "name", "", "id", "" ) );
    ml_lookup.@set( "input:submit",         new EmmetMLLookupValue( "input",      0, "type", "submit", "value", "" ) );
    ml_lookup.@set( "input:s",              new EmmetMLLookupValue( "input",      0, "type", "submit", "value", "" ) );
    ml_lookup.@set( "input:image",          new EmmetMLLookupValue( "input",      0, "type", "image", "src", "", "alt", "" ) );
    ml_lookup.@set( "input:i",              new EmmetMLLookupValue( "input",      0, "type", "image", "src", "", "alt", "" ) );
    ml_lookup.@set( "input:button",         new EmmetMLLookupValue( "input",      0, "type", "button", "value", "" ) );
    ml_lookup.@set( "input:b",              new EmmetMLLookupValue( "input",      0, "type", "button", "value", "" ) );
    ml_lookup.@set( "isindex",              new EmmetMLLookupValue( "isindex",    0 ) );
    ml_lookup.@set( "input:reset",          new EmmetMLLookupValue( "input",      0, "type", "reset", "value", "" ) );
    ml_lookup.@set( "select",               new EmmetMLLookupValue( "select",     1, "name", "", "id", "" ) );
    ml_lookup.@set( "option",               new EmmetMLLookupValue( "option",     1, "value", "" ) );
    ml_lookup.@set( "textarea",             new EmmetMLLookupValue( "textarea",   1, "name", "", "id", "", "cols", "30", "rows", "10" ) );
    ml_lookup.@set( "menu:context",         new EmmetMLLookupValue( "menu",       1, "type", "context" ) );
    ml_lookup.@set( "menu:c",               new EmmetMLLookupValue( "menu",       1, "type", "context" ) );
    ml_lookup.@set( "menu:toolbar",         new EmmetMLLookupValue( "menu",       1, "type", "toolbar" ) );
    ml_lookup.@set( "menu:t",               new EmmetMLLookupValue( "menu",       1, "type", "toolbar" ) );
    ml_lookup.@set( "video",                new EmmetMLLookupValue( "video",      1, "src", "" ) );
    ml_lookup.@set( "audio",                new EmmetMLLookupValue( "audio",      1, "src", "" ) );
    ml_lookup.@set( "html:xml",             new EmmetMLLookupValue( "html",       1, "xmlns", "http://www.w3.org/1999/xhtml" ) );
    ml_lookup.@set( "keygen",               new EmmetMLLookupValue( "keygen",     0 ) );
    ml_lookup.@set( "command",              new EmmetMLLookupValue( "command",    0 ) );
    ml_lookup.@set( "bq",                   new EmmetMLLookupValue( "blockquote", 1 ) );
    ml_lookup.@set( "acr",                  new EmmetMLLookupValue( "acronym",    1, "title", "" ) );
    ml_lookup.@set( "fig",                  new EmmetMLLookupValue( "figure",     1 ) );
    ml_lookup.@set( "figc",                 new EmmetMLLookupValue( "figcaption", 1 ) );
    ml_lookup.@set( "ifr",                  new EmmetMLLookupValue( "iframe",     1, "src", "", "frameborder", "0" ) );
    ml_lookup.@set( "emb",                  new EmmetMLLookupValue( "embed",      0, "src", "", "type", "" ) );
    ml_lookup.@set( "obj",                  new EmmetMLLookupValue( "object",     1, "data", "", "type", "" ) );
    ml_lookup.@set( "src",                  new EmmetMLLookupValue( "source",     1 ) );
    ml_lookup.@set( "cap",                  new EmmetMLLookupValue( "caption",    1 ) );
    ml_lookup.@set( "colg",                 new EmmetMLLookupValue( "colgroup",   1 ) );
    ml_lookup.@set( "fst",                  new EmmetMLLookupValue( "fieldset",   1 ) );
    ml_lookup.@set( "fset",                 new EmmetMLLookupValue( "fieldset",   1 ) );
    ml_lookup.@set( "btn",                  new EmmetMLLookupValue( "button",     1 ) );
    ml_lookup.@set( "btn:b",                new EmmetMLLookupValue( "button",     1, "type", "button" ) );
    ml_lookup.@set( "btn:r",                new EmmetMLLookupValue( "button",     1, "type", "reset" ) );
    ml_lookup.@set( "btn:s",                new EmmetMLLookupValue( "button",     1, "type", "submit" ) );
    ml_lookup.@set( "optg",                 new EmmetMLLookupValue( "optgroup",   1 ) );
    ml_lookup.@set( "opt",                  new EmmetMLLookupValue( "option",     1, "value", "" ) );
    ml_lookup.@set( "tarea",                new EmmetMLLookupValue( "textarea",   1, "name", "", "id", "", "cols", "30", "rows", "10" ) );
    ml_lookup.@set( "leg",                  new EmmetMLLookupValue( "legend",     1 ) );
    ml_lookup.@set( "sect",                 new EmmetMLLookupValue( "section",    1 ) );
    ml_lookup.@set( "art",                  new EmmetMLLookupValue( "article",    1 ) );
    ml_lookup.@set( "hdr",                  new EmmetMLLookupValue( "header",     1 ) );
    ml_lookup.@set( "ftr",                  new EmmetMLLookupValue( "footer",     1 ) );
    ml_lookup.@set( "adr",                  new EmmetMLLookupValue( "address",    1 ) );
    ml_lookup.@set( "dlg",                  new EmmetMLLookupValue( "dialog",     1 ) );
    ml_lookup.@set( "str",                  new EmmetMLLookupValue( "strong",     1 ) );
    ml_lookup.@set( "prog",                 new EmmetMLLookupValue( "progress",   1 ) );
    ml_lookup.@set( "datag",                new EmmetMLLookupValue( "datagrid",   1 ) );
    ml_lookup.@set( "datal",                new EmmetMLLookupValue( "datalist",   1 ) );
    ml_lookup.@set( "kg",                   new EmmetMLLookupValue( "keygen",     1 ) );
    ml_lookup.@set( "out",                  new EmmetMLLookupValue( "output",     1 ) );
    ml_lookup.@set( "det",                  new EmmetMLLookupValue( "details",    1 ) );
    ml_lookup.@set( "cmd",                  new EmmetMLLookupValue( "command",    0 ) );
    ml_lookup.@set( "!!!",                  new EmmetMLLookupValue( "!doctype",   2, "html", "" ) );
    ml_lookup.@set( "!!!4t",                new EmmetMLLookupValue( "!DOCTYPE",   2, "HTML", "PUBLIC", "-//W3C//DTD HTML 4.01 Transitional//EN", "http://www.w3.org/TR/html4/loose.dtd" ) );
    ml_lookup.@set( "!!!4s",                new EmmetMLLookupValue( "!DOCTYPE",   2, "HTML", "PUBLIC", "-//W3C//DTD HTML 4.01//EN", "http://www.w3.org/TR/html4/strict.dtd" ) );
    ml_lookup.@set( "!!!xt",                new EmmetMLLookupValue( "!DOCTYPE",   2, "html", "PUBLIC", "-//W3C//DTD XHTML 1.0 Transitional//EN", "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd" ) );
    ml_lookup.@set( "!!!xs",                new EmmetMLLookupValue( "!DOCTYPE",   2, "html", "PUBLIC", "-//W3C//DTD XHTML 1.0 Strict//EN", "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" ) );
    ml_lookup.@set( "!!!xxs",               new EmmetMLLookupValue( "!DOCTYPE",   2, "html", "PUBLIC", "-//W3C//DTD XHTML 1.1//EN", "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" ) );

    // XSLT
    ml_lookup.@set( "tm",                   new EmmetMLLookupValue( "xsl:template",               1, "match", "", "mode", "" ) );
    ml_lookup.@set( "tmatch",               new EmmetMLLookupValue( "xsl:template",               1, "match", "", "mode", "" ) );
    ml_lookup.@set( "tn",                   new EmmetMLLookupValue( "xsl:template",               1, "name", "" ) );
    ml_lookup.@set( "tname",                new EmmetMLLookupValue( "xsl:template",               1, "name", "" ) );
    ml_lookup.@set( "call",                 new EmmetMLLookupValue( "xsl:call-template",          0, "name", "" ) );
    ml_lookup.@set( "ap",                   new EmmetMLLookupValue( "xsl:apply-templates",        0, "select", "", "mode", "" ) );
    ml_lookup.@set( "api",                  new EmmetMLLookupValue( "xsl:apply-imports",          0 ) );
    ml_lookup.@set( "imp",                  new EmmetMLLookupValue( "xsl:import",                 0, "href", "" ) );
    ml_lookup.@set( "inc",                  new EmmetMLLookupValue( "xsl:include",                0, "href", "" ) );
    ml_lookup.@set( "ch",                   new EmmetMLLookupValue( "xsl:choose",                 1 ) );
    ml_lookup.@set( "xsl:when",             new EmmetMLLookupValue( "xsl:when",                   1, "test", "" ) );
    ml_lookup.@set( "wh",                   new EmmetMLLookupValue( "xsl:when",                   1, "test", "" ) );
    ml_lookup.@set( "ot",                   new EmmetMLLookupValue( "xsl:otherwise",              1 ) );
    ml_lookup.@set( "if",                   new EmmetMLLookupValue( "xsl:if",                     1, "test", "" ) );
    ml_lookup.@set( "par",                  new EmmetMLLookupValue( "xsl:param",                  1, "name", "" ) );
    ml_lookup.@set( "pare",                 new EmmetMLLookupValue( "xsl:param",                  0, "name", "", "select", "" ) );
    ml_lookup.@set( "var",                  new EmmetMLLookupValue( "xsl:variable",               1, "name", "" ) );
    ml_lookup.@set( "vare",                 new EmmetMLLookupValue( "xsl:variable",               0, "name", "", "select", "" ) );
    ml_lookup.@set( "wp",                   new EmmetMLLookupValue( "xsl:with-param",             0, "name", "", "select", "" ) );
    ml_lookup.@set( "key",                  new EmmetMLLookupValue( "xsl:key",                    0, "name", "", "match", "", "use", "" ) );
    ml_lookup.@set( "elem",                 new EmmetMLLookupValue( "xsl:element",                1, "name", "" ) );
    ml_lookup.@set( "attr",                 new EmmetMLLookupValue( "xsl:attribute",              1, "name", "" ) );
    ml_lookup.@set( "attrs",                new EmmetMLLookupValue( "xsl:attribute-set",          1, "name", "" ) );
    ml_lookup.@set( "cp",                   new EmmetMLLookupValue( "xsl:copy",                   0, "select", "" ) );
    ml_lookup.@set( "co",                   new EmmetMLLookupValue( "xsl:copy-of",                0, "select", "" ) );
    ml_lookup.@set( "val",                  new EmmetMLLookupValue( "xsl:value-of",               0, "select", "" ) );
    ml_lookup.@set( "each",                 new EmmetMLLookupValue( "xsl:for-each",               1, "select", "" ) );
    ml_lookup.@set( "for",                  new EmmetMLLookupValue( "xsl:for-each",               1, "select", "" ) );
    ml_lookup.@set( "tex",                  new EmmetMLLookupValue( "xsl:text",                   1 ) );
    ml_lookup.@set( "com",                  new EmmetMLLookupValue( "xsl:comment",                1 ) );
    ml_lookup.@set( "msg",                  new EmmetMLLookupValue( "xsl:message",                1, "terminate", "no" ) );
    ml_lookup.@set( "fall",                 new EmmetMLLookupValue( "xsl:fallback",               1 ) );
    ml_lookup.@set( "num",                  new EmmetMLLookupValue( "xsl:number",                 0, "value", "" ) );
    ml_lookup.@set( "nam",                  new EmmetMLLookupValue( "namespace-alias",            0, "stylesheet-prefix", "", "result-prefix", "" ) );
    ml_lookup.@set( "pres",                 new EmmetMLLookupValue( "xsl:preserve-space",         0, "elements", "" ) );
    ml_lookup.@set( "strip",                new EmmetMLLookupValue( "xsl:strip-space",            0, "elements", "" ) );
    ml_lookup.@set( "proc",                 new EmmetMLLookupValue( "xsl:processing-instruction", 1, "name", "" ) );
    ml_lookup.@set( "sort",                 new EmmetMLLookupValue( "xsl:sort",                   0, "select", "" ) );

  }

  private void initialize_inlined() {

    inlined = new HashMap<string,bool>();

    inlined.@set( "a",       true );
    inlined.@set( "abbr",    true );
    inlined.@set( "acronym", true );
    inlined.@set( "address", true );
    inlined.@set( "b",       true );
    inlined.@set( "big",     true );
    inlined.@set( "center",  true );
    inlined.@set( "cite",    true );
    inlined.@set( "code",    true );
    inlined.@set( "em",      true );
    inlined.@set( "i",       true );
    inlined.@set( "kbd",     true );
    inlined.@set( "q",       true );
    inlined.@set( "s",       true );
    inlined.@set( "samp",    true );
    inlined.@set( "small",   true );
    inlined.@set( "span",    true );
    inlined.@set( "strike",  true );
    inlined.@set( "strong",  true );
    inlined.@set( "sub",     true );
    inlined.@set( "sup",     true );
    inlined.@set( "tt",      true );
    inlined.@set( "u",       true );
    inlined.@set( "var",     true );

  }

  /* Returns a single item value */
  public string emmet_get_item_value() {

    if( !emmet_multi ) {
      if( emmet_wrap_strs.length == 1 ) {
        return( emmet_wrap_str );
      } else {
        return( "\n%s\n".printf( emmet_wrap_str ) );
      }
    } else {
      return( emmet_wrap_strs.index( emmet_curr ) );
    }

  }

  /* Returns the item name for the given string and values array */
  public void emmet_get_item_name( string str, out string formatted_str, out Array<string> values ) {

    int index = str.index_of( "$" );

    formatted_str = ""
    values        = new Array<string>();

    while( index != -1 ) {

      MatchInfo match;

      formatted_str += str.slice( 0, (index - 1) );

      if( name1_re.match( str.substring( index ), 0, out match ) ) {
        formatted_str += "%s";
        values.append_val( emmet_get_item_value() );

      } else if( name2_re.match( str.substring( index ), 0, out match ) ) {
        if( match.fetch( 2 ) != "" ) {
          formatted_str += "%%0%dd".printf( match.fetch( 1 ).char_count() );
          if( match.fetch( 3 ) != "" ) {
            if( match.fetch( 4 ) != "" ) {
              values.append_val( [list expr (\$::emmet_max - \$::emmet_curr) + ($start - 1)] );
            } else {
              values.append_val( [list expr \$::emmet_max - \$::emmet_curr] );
            }
          } else {
            if( match.fetch( 4 ) != "" ) {
              values.append_val( [list expr \$::emmet_curr + $start] );
            } else {
              values.append_val( [list expr \$::emmet_curr + 1] );
            }
          }
        } else {
          formatted_str += "%%0%dd".printf( numbering.length );
          values.append_val( [list expr \$::emmet_curr + 1] );
        }

      } else {
        return -code error "Unknown item name format (%s)".printf( str.substring( index ) );
      }

      str   = str.substring( str.index_of_nth_char( index + match.length ) );
      index = str.index_of( str );
    }

    formatted_str += str;

    return [list $formatted_str $values]

  }

  /* Generates the string equivalen of the values array */
  public string emmet_gen_str( TreeNodeName name ) { // string format_str, Array<string> values ) {

    var vals = new Array<string>();

    for( int i=0; i<values.length; i++ ) {
      vals.append_val( ?exec? name.values.index( i ) );
    }

    return [format $format_str {*}$vals]

  }

  /* Returns the Ipsum Lorem text for the given number of words */
  public string emmet_gen_lorem( int words ) {

    set token  = [::http::geturl "http://lipsum.com/feed/xml?what=words&amount=$words&start=0"]
    var lipsum = ""

    if {([::http::status $token] eq "ok") && ([::http::ncode $token] eq "200")} {
      MatchInfo match;
      if( lipsum_re.match( [::http::data $token], 0, out match ) ) {
        lipsum = match.fetch( 1 );
      }
    }

    ::http::cleanup $token

    return( lipsum );

  }

  public void emmet_elaborate( EmmetTreeNode node, FOOBAR action ) {

    // If we are the root node, exit early
    if( node.parent == null ) {
      elab.set_attr_int( "curr", 0 );
      elab.set_attr_string( "type", "group" );
      return;
    }

    // Calculate the number of children to generate:w
    emmet_max = node.get_attr_int( "multiplier" );
    if( emmet_max == 0 ) {
      emmet_max   = emmet_wrap_strs.length;
      emmet_multi = 1;
    }

    // TBD - Move this code to a recursive function
    foreach parent [$::emmet_elab nodes] {

      if( !parent.attr_key_exists( "curr" ) || (node.depth() != (parent.depth() + 1)) ) {
        continue;
      }

      // Get the parent's current value
      var curr = parent.get_attr_int( "curr" );

      // Clear the parent's current attribute
      if( (node.index() + 1) == node.parent.children.length ) {
        parent.unset_attr( "curr" );
      }

      // Create a new node in the elaborated tree
      for( int i=0; i<emmet_max; i++ ) {

        // Create the new node in the elaboration tree
        var enode = new TreeNode();
        parent.insert( enode, -1 );

        // Set the current loop value
        emmet_curr = (emmet_max == 1) ? curr : i;

        // Set the current attribute curr
        if( !node.children.length == 0 ) {
          enode.set_attr_int( "curr", emmet_curr );
        }

        var type = node.get_attr_string( "type" );
        if( type == "ident" ) {

          // If we have an implictly specified type that hasn't been handled yet, it will be a div
          var name = node.get_attr_name( "name" );
          if( name == null ) {
            name = new TreeNodeName( "div" );
          }

          // Calculate the node name
          var ename  = emmet_gen_str( name );
          var tagnum = 1

          // Now that the name is elaborated, look it up and update the node, if necessary
          if( ml_lookup.exists( ename ) ) {
            var lookup = ml_lookup.@get( ename );
            ename  = lookup.ename;
            tagnum = lookup.tagnum;
            var attrs = lookup.attrs;
            foreach {key value} $attrs {
              switch( attrs.get_attr_type( key ) ) {
                case EmmetAttrType.INT    :  enode.set_attr_int(    ("attr," + key), value );  break;
                case EmmetAttrType.STRING :  enode.set_attr_string( ("attr," + key), value );  break;
              }
            }
          }

          // Set the node name and tag number
          enode.set_attr_string( "name", ename );
          enode.set_attr_int( "tagnum", tagnum );

          // Generate the attributes
          var keys = node.get_attr_keys( "attr,*" );
          for( int i=0; i<keys.length; i++ ) {
            var attr_key = emmet_gen_str( keys.index( i ).split( "," ).index( 1 ) );
            enode.set_attr
            $::emmet_elab set $enode attr,$attr_key [list]
            foreach attr_val [$tree get $node $attr] {
              $::emmet_elab lappend $enode attr,$attr_key [emmet_gen_str {*}$attr_val]
            }
          }

        }

        // Set the node type
        enode.set_attr_string( "type", type );

        // Add the node text value, if specified
        if( node.attr_key_exists( "value" ) ) {
          enode.set_attrs_string( "value", emmet_gen_str( node.get_attrs_string( "value" ) ) );
        }

        // Add the Ipsum Lorem value, if specified
        if( node.attr_key_exists( "lorem" ) ) {
          enode.set_attr_string( "value", emmet_get_lorem( node.get_attr_string( "lorem" ) ) );
        }

      }

    }

  }

  public void emmet_generate( EmmetTreeNode node, action ) {

    // Gather the children lines and indentation information
    var child_lines  = new Array<string>();
    var num_clines   = 1;
    var cline_index  = 0;
    var child_indent = "0";
    for( int i=0; i<node.children.length; i++ ) {
      var child = node.children.index( i );
      var lines = child.get_attr_string( "lines" ).split( "\n" );
      foreach( string line in strdup( tree_attrs_get( child->attrs, "lines" ) ) ) {
        child_lines.append_val( line );
      }
      if( child.get_attr_int( "indent" ) ) {
        child_indent = 1;
      }
    }

    // Setup the child lines to be structured properly
    if( node.get_attr_string( "type" ) != "group" ) {
      if( child_indent ) {
        var spaces = string.nfill( emmet_shift_width, ' ' );
        for( int i=0; i<child_lines.length; i++ ) {
          var cline = child_lines.index( i );
          child_lines.remove_index( i );
          child_lines.insert( i, (spaces + cline) );
        }
      }
    }

    // Otherwise, insert our information along with the children in the proper order
    switch( node.get_attr_string( "type" ) ) {
      case "indent" :
        var name     = node.get_attr_name( "name" );
        var tagnum   = node.get_attr_int( "tagnum" );
        var attr_str = "";
        var value    = node.get_attr_string( "value" );
        var keys     = node.get_attr_keys( "attr,*" );
        for( int i=0; i<keys.length; i++ ) {
          var attr     = keys.index( i ).split( "," )[1];
          var attr_val = node.get_attr_string( attr );
          attr_str += " %s=\"%s\"".printf( attr, attr_val );
        }
        if( tagnum == 0 ) {
          node.set_attr_string( "lines", "<%s%s />%s".printf( name, attr_str, value ) );
        } else if( tagnum == 2 ) {
          node.set_attr_string( "lines", "<%s%s>%s".printf( name, attr_str, value) );
        } else if( child_lines.length == 0 ) {
          node.set_attr_string( "lines", "<%s%s>%s</%s>".printf( name, attr_str, value, name ) );
        } else if( child_indent ) {
          node.set_attr_string( "lines", "<%s%s>%s%s</%s>".printf( name, attr_str, value, child_lines, name ) );
        } else {
          node.set_attr_string( "lines", "<%s%s>%s%s</%s>".printf( name, attr_str, value, child_lines, name ) );
        }
        node.set_attr_int( "indent", (inlined.exists( name ) ? 0 : 1) );
        break;

      case "text" :
        node.set_attr_string( "lines", node.get_attr_string( "value" ) );
        node.set_attr_int( "indent", 0 );
        break;

      case "group" :
        node.set_attr_string( "lines", child_lines );
        node.set_attr_int( "indent", child_indent );
        break;
    }

  }

  /* Elaborate the tree with the given root node */
  private void elaborate_tree( TreeNode node ) {
    emmet_elaborate( node );
    for( int i=0; i<node.children.length; i++ ) {
      elaborate_tree( node.children.index( i ) );
    }
  }

  /* Generate the tree with the given root node */
  private void generate_tree( TreeNode node ) {
    emmet_generate( node );
    for( int i=0; i<node.children.length; i++ ) {
      generate_tree( node.children.index( i ) );
    }
  }

  /* Generates the HTML */
  public string emmet_generate_html() {

    // Perform the elaboration
    elaborate_tree( dom );

    // Generate the code
    generate_tree( elab );

    // Substitute carent syntax with tabstops
    if( elab.get_attr_int( "indent" ) ) {
      str = string.joinv( "\n%s".printf( emmet_prespace ), elab.get_attr_strarray( "lines" ).data );
    } else {
      str = string.joinv( "", elab.get_attr_strarray( "lines" ).data );
    }

    return( str );

  }

}
