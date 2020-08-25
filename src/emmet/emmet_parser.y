%{

  /*
   Name:    snip_parser.tac
   Author:  Trevor Williams  (phase1geo@gmail.com)
   Date:    8/10/2015
   Brief:   Parser for snippet syntax.
  */

  #include "emmet_lexer.h"

  char*  emmet_value;
  char*  emmet_errmsg;
  char*  emmet_errstr;
  int    emmet_shift_width = 2;
  int    emmet_item_id     = 0;
  int    emmet_max         = 1;
  int    emmet_multi       = 0;
  int    emmet_curr        = 0;
  int    emmet_start       = 1;
  char*  emmet_prespace;
  char*  emmet_wrap_str;
  char** emmet_wrap_strs;
  char** emmet_filters;

  struct tree_attr {
    char* key;
    char* value;
  };

  struct tree_attrs {
    tree_attr** attrs;
    int         size;
    int         num;
  };

  /* Creates a new tree attribute list and returns it to the calling function */
  tree_attrs* tree_attrs_create() {
    tree_attrs* attrs = malloc( sizeof( tree_attrs ) );
    attrs->attrs[i]
    return( attrs );
  }

  /* Destroys the given tree attribute list */
  void tree_attrs_destroy( tree_attrs* attrs ) {
    for( int i=0; i<attrs->num; i++ ) {
      free( attrs->attrs[i]->key );
      free( attrs->attrs[i]->value );
      free( attrs->attrs[i] );
    }
    free( attrs );
  }

  /* Sets the given attribute */
  void tree_attrs_set( tree_attrs* attrs, char* key, char* value ) {
    for( int i=0; i<attrs->num; i++ ) {
      if( strcmp( attrs->attrs[i]->key, key ) == 0 ) {
        free( attrs->attrs[i]->value );
        attrs->attrs[i]->value = strdup( value );
        return;
      }
    }
    if( (attrs->num + 1) > attrs->size ) {
      tree_attr** tmp = malloc( sizeof( tree_attr* ) * (attrs->size * 2) );
      for( int i=0; i<attrs->num; i++ ) {
        tmp[i] = attrs->attrs[i];
      }
      free( attrs->attrs );
      attrs->attrs  = tmp;
      attrs->size  *= 2;
      attrs->attrs[attrs->num] = malloc( sizeof( tree_attr ) );
      attrs->attrs[attrs->num]->key   = strdup( key );
      attrs->attrs[attrs->num]->value = strdup( value );
      attrs->num++;
    }
  }

  /*
   Returns the stored attribute value for the given key.  If the key could not
   be found, returns 0.
  */
  char* tree_attrs_get( tree_attrs* attrs, char* key ) {
    for( int i=0; i<attrs->num; i++ ) {
      if( strcmp( attrs->attrs[i]->key, key ) == 0 ) {
        return( attrs->attrs[i]->value );
      }
    }
    return( 0 );
  }

  struct tree_node {
    tree_node*  parent;
    tree_attrs* attrs;
    int         size;
    int         num_children;
    tree_node** children;
  };

  tree_node* emmet_dom  = 0;
  tree_node* emmet_elab = 0;

  /* Creates a new node */
  tree_node* tree_node_create() {
    tree_node* node = malloc( sizeof( tree_node ) );
    node->parent       = 0;
    node->attrs        = tree_attrs_create();
    node->size         = 1;
    node->num_children = 0;
    node->children     = malloc( sizeof( tree_node* ) );
    return( node );
  }

  /* Deallocates the given tree node */
  void tree_node_destroy( tree_node* node ) {
    if( node->num_children > 0 ) {
      for( int i=0; i<node->num_children; i++ ) {
        tree_node_destroy( node->children[i] );
      }
      free( node->children );
    }
    tree_attrs_destroy( node->attrs );
    free( node );
  }

  /* Inserts the given node into the parent at the given index */
  void tree_node_insert( tree_node* parent, int index, tree_node* node ) {
    tree_node** children = parent->children;
    if( (parent->num_children + 1) > parent->size ) {
      children = malloc( sizeof( tree_node* ) * (parent->size * 2) );
      parent->size *= 2;
    }
    if( index == -1 ) {
      children[parent->num_children++] = node;
    } else {
      for( int i=(parent->num_children - 1), j=parent->num_children; i>=0; i-- ) {
        children[j--] = (i == index) ? node : parent->children[i];
      }
    }
    parent->children = children;
    parent->num_children++;
  }

  /* Removes the given node from the parent */
  void tree_node_remove( tree_node* parent, tree_node* node ) {
    int num_children = parent->num_children;
    for( int i=0, j=0; i<num_children; i++ ) {
      if( node != parent->children[i] ) {
        parent->children[j++] = parent->children[i];
        parent->num_children--;
      }
    }
  }

  /* Moves a node */
  void tree_node_move( tree_node* parent, int index, tree_node* node ) {
    tree_node_remove( node->parent, node );
    tree_node_insert( parent, index, node );
  }

  /*
array set emmet_ml_lookup {

  # HTML
  a                    {a          1 {href ""}}
  a:link               {a          1 {href "http://"}}
  a:mail               {a          1 {href "mailto:"}}
  abbr                 {abbr       1 {title ""}}
  acronym              {acronym    1 {title ""}}
  base                 {base       1 {href ""}}
  basefont             {basefont   0 {}}
  br                   {br         0 {}}
  frame                {frame      0 {}}
  hr                   {hr         0 {}}
  bdo                  {bdo        1 {dir ""}}
  bdo:r                {bdo        1 {dir "rtl"}}
  bdo:l                {bdo        1 {dir "ltr"}}
  col                  {col        0 {}}
  link                 {link       0 {rel "stylesheet" href ""}}
  link:css             {link       0 {rel "stylesheet" href "{|style}.css"}}
  link:print           {link       0 {rel "stylesheet" href "{|print}.css" media "print"}}
  link:favicon         {link       0 {rel "shortcut icon" type "image/x-icon" href "{|favicon.ico}"}}
  link:touch           {link       0 {rel "apple-touch-icon" href "{|favicon.png}"}}
  link:rss             {link       0 {rel "alternate" type "application/rss+xml" title "RSS" href "{|rss.xml}"}}
  link:atom            {link       0 {rel "alternate" type "application/atom+xml" title "Atom" href "{|atom.xml}"}}
  meta                 {meta       0 {}}
  meta:utf             {meta       0 {http-equiv "Content-Type" content "text/html;charset=UTF-8"}}
  meta:win             {meta       0 {http_equiv "Content-Type" content "text/html;charset=windows-1251"}}
  meta:vp              {meta       0 {name "viewport" content "width={|device-width}, user-scalable={|no}, initial-scale={|1.0}, maximum-scale={|1.0}, minimum-scale={|1.0}"}}
  meta:compat          {meta       0 {http-equiv "X-UA-Compatible" content "{|IE=7}"}}
  style                {style      1 {}}
  script               {script     1 {}}
  script:src           {script     1 {src ""}}
  img                  {img        0 {src "" alt ""}}
  iframe               {iframe     1 {src "" frameborder "0"}}
  embed                {embed      1 {src "" type ""}}
  object               {object     1 {data "" type ""}}
  param                {param      0 {name "" value ""}}
  map                  {map        1 {name ""}}
  area                 {area       0 {shape "" coords "" href "" alt ""}}
  area:d               {area       0 {shape "default" href "" alt ""}}
  area:c               {area       0 {shape "circle" coords "" href "" alt ""}}
  area:r               {area       0 {shape "rect" coords "" href "" alt ""}}
  area:p               {area       0 {shape "poly" coords "" href "" alt ""}}
  form                 {form       1 {action ""}}
  form:get             {form       1 {action "" method "get"}}
  form:post            {form       1 {action "" method "post"}}
  label                {label      1 {for ""}}
  input                {input      0 {type "{|text}"}}
  inp                  {input      0 {type "{|text}" name "" id ""}}
  input:hidden         {input      0 {type "hidden" name ""}}
  input:h              {input      0 {type "hidden" name ""}}
  input:text           {input      0 {type "{|text}" name "" id ""}}
  input:t              {input      0 {type "{|text}" name "" id ""}}
  input:search         {input      0 {type "search" name "" id ""}}
  input:email          {input      0 {type "email" name "" id ""}}
  input:url            {input      0 {type "url" name "" id ""}}
  input:password       {input      0 {type "password" name "" id ""}}
  input:p              {input      0 {type "password" name "" id ""}}
  input:datetime       {input      0 {type "datetime" name "" id ""}}
  input:date           {input      0 {type "date" name "" id ""}}
  input:datetime-local {input      0 {type "datetime-local" name "" id ""}}
  input:month          {input      0 {type "month" name "" id ""}}
  input:week           {input      0 {type "week" name "" id ""}}
  input:time           {input      0 {type "time" name "" id ""}}
  input:number         {input      0 {type "number" name "" id ""}}
  input:color          {input      0 {type "color" name "" id ""}}
  input:checkbox       {input      0 {type "checkbox" name "" id ""}}
  input:c              {input      0 {type "checkbox" name "" id ""}}
  input:radio          {input      0 {type "radio" name "" id ""}}
  input:r              {input      0 {type "radio" name "" id ""}}
  input:range          {input      0 {type "range" name "" id ""}}
  input:file           {input      0 {type "file" name "" id ""}}
  input:f              {input      0 {type "file" name "" id ""}}
  input:submit         {input      0 {type "submit" value ""}}
  input:s              {input      0 {type "submit" value ""}}
  input:image          {input      0 {type "image" src "" alt ""}}
  input:i              {input      0 {type "image" src "" alt ""}}
  input:button         {input      0 {type "button" value ""}}
  input:b              {input      0 {type "button" value ""}}
  isindex              {isindex    0 {}}
  input:reset          {input      0 {type "reset" value ""}}
  select               {select     1 {name "" id ""}}
  option               {option     1 {value ""}}
  textarea             {textarea   1 {name "" id "" cols "{|30}" rows "{|10}"}}
  menu:context         {menu       1 {type "context"}}
  menu:c               {menu       1 {type "context"}}
  menu:toolbar         {menu       1 {type "toolbar"}}
  menu:t               {menu       1 {type "toolbar"}}
  video                {video      1 {src ""}}
  audio                {audio      1 {src ""}}
  html:xml             {html       1 {xmlns "http://www.w3.org/1999/xhtml"}}
  keygen               {keygen     0 {}}
  command              {command    0 {}}
  bq                   {blockquote 1 {}}
  acr                  {acronym    1 {title ""}}
  fig                  {figure     1 {}}
  figc                 {figcaption 1 {}}
  ifr                  {iframe     1 {src "" frameborder "0"}}
  emb                  {embed      0 {src "" type ""}}
  obj                  {object     1 {data "" type ""}}
  src                  {source     1 {}}
  cap                  {caption    1 {}}
  colg                 {colgroup   1 {}}
  fst                  {fieldset   1 {}}
  fset                 {fieldset   1 {}}
  btn                  {button     1 {}}
  btn:b                {button     1 {type "button"}}
  btn:r                {button     1 {type "reset"}}
  btn:s                {button     1 {type "submit"}}
  optg                 {optgroup   1 {}}
  opt                  {option     1 {value ""}}
  tarea                {textarea   1 {name "" id "" cols "{|30}" rows "{|10}"}}
  leg                  {legend     1 {}}
  sect                 {section    1 {}}
  art                  {article    1 {}}
  hdr                  {header     1 {}}
  ftr                  {footer     1 {}}
  adr                  {address    1 {}}
  dlg                  {dialog     1 {}}
  str                  {strong     1 {}}
  prog                 {progress   1 {}}
  datag                {datagrid   1 {}}
  datal                {datalist   1 {}}
  kg                   {keygen     1 {}}
  out                  {output     1 {}}
  det                  {details    1 {}}
  cmd                  {command    0 {}}
  !!!                  {!doctype   2 {html}}
  !!!4t                {!DOCTYPE   2 {HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"}}
  !!!4s                {!DOCTYPE   2 {HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd"}}
  !!!xt                {!DOCTYPE   2 {html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"}}
  !!!xs                {!DOCTYPE   2 {html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"}}
  !!!xxs               {!DOCTYPE   2 {html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"}}
  c                    {!--        2 {${child} --}}

  # XSLT
  tm                   {xsl:template               1 {match "" mode ""}}
  tmatch               {xsl:template               1 {match "" mode ""}}
  tn                   {xsl:template               1 {name ""}}
  tname                {xsl:template               1 {name ""}}
  call                 {xsl:call-template          0 {name ""}}
  ap                   {xsl:apply-templates        0 {select "" mode ""}}
  api                  {xsl:apply-imports          0 {}}
  imp                  {xsl:import                 0 {href ""}}
  inc                  {xsl:include                0 {href ""}}
  ch                   {xsl:choose                 1 {}}
  xsl:when             {xsl:when                   1 {test ""}}
  wh                   {xsl:when                   1 {test ""}}
  ot                   {xsl:otherwise              1 {}}
  if                   {xsl:if                     1 {test ""}}
  par                  {xsl:param                  1 {name ""}}
  pare                 {xsl:param                  0 {name "" select ""}}
  var                  {xsl:variable               1 {name ""}}
  vare                 {xsl:variable               0 {name "" select ""}}
  wp                   {xsl:with-param             0 {name "" select ""}}
  key                  {xsl:key                    0 {name "" match "" use ""}}
  elem                 {xsl:element                1 {name ""}}
  attr                 {xsl:attribute              1 {name ""}}
  attrs                {xsl:attribute-set          1 {name ""}}
  cp                   {xsl:copy                   0 {select ""}}
  co                   {xsl:copy-of                0 {select ""}}
  val                  {xsl:value-of               0 {select ""}}
  each                 {xsl:for-each               1 {select ""}}
  for                  {xsl:for-each               1 {select ""}}
  tex                  {xsl:text                   1 {}}
  com                  {xsl:comment                1 {}}
  msg                  {xsl:message                1 {terminate "no"}}
  fall                 {xsl:fallback               1 {}}
  num                  {xsl:number                 0 {value ""}}
  nam                  {namespace-alias            0 {stylesheet-prefix "" result-prefix ""}}
  pres                 {xsl:preserve-space         0 {elements ""}}
  strip                {xsl:strip-space            0 {elements ""}}
  proc                 {xsl:processing-instruction 1 {name ""}}
  sort                 {xsl:sort                   0 {select ""}}
}

array set emmet_inlined {
  a       1
  abbr    1
  acronym 1
  address 1
  b       1
  big     1
  center  1
  cite    1
  code    1
  em      1
  i       1
  kbd     1
  q       1
  s       1
  samp    1
  small   1
  span    1
  strike  1
  strong  1
  sub     1
  sup     1
  tt      1
  u       1
  var     1
}
  */

  /* TBD
proc emmet_gen_str {format_str values} {

  set vals [list]

  foreach value $values {
    lappend vals [eval {*}$value]
  }

  return [format $format_str {*}$vals]

}

proc emmet_gen_lorem {words} {

  set token  [::http::geturl "http://lipsum.com/feed/xml?what=words&amount=$words&start=0"]
  set lipsum ""

  if {([::http::status $token] eq "ok") && ([::http::ncode $token] eq "200")} {
    regexp {<lipsum>(.*)</lipsum>} [::http::data $token] -> lipsum
  }

  ::http::cleanup $token

  return $lipsum

}

proc emmet_elaborate {tree node action} {

  # If we are the root node, exit early
  if {$node eq "root"} {
    $::emmet_elab set root curr 0
    $::emmet_elab set root type "group"
    return
  }

  # Calculate the number of children to generate:w
  if {[set ::emmet_max [$tree get $node multiplier]] == 0} {
    set ::emmet_max   [llength $::emmet_wrap_strs]
    set ::emmet_multi 1
  }

  foreach parent [$::emmet_elab nodes] {

    if {![$::emmet_elab keyexists $parent curr] || ([$tree depth $node] != [expr [$::emmet_elab depth $parent] + 1])} {
      continue
    }

    # Get the parent's current value
    set curr [$::emmet_elab get $parent curr]

    # Clear the parent's current attribute
    if {[expr [$tree index $node] + 1] == [llength [$tree children [$tree parent $node]]]} {
      $::emmet_elab unset $parent curr
    }

    # Create a new node in the elaborated tree
    for {set i 0} {$i < $::emmet_max} {incr i} {

      # Create the new node in the elaboration tree
      set enode [$::emmet_elab insert $parent end]

      # Set the current loop value
      set ::emmet_curr [expr ($::emmet_max == 1) ? $curr : $i]

      # Set the current attribute curr
      if {![$tree isleaf $node]} {
        $::emmet_elab set $enode curr $::emmet_curr
      }

      if {[set type [$tree get $node type]] eq "ident"} {

        # If we have an implictly specified type that hasn't been handled yet, it will be a div
        if {[set name [$tree get $node name]] eq ""} {
          set name [list "div" {}]
        }

        # Calculate the node name
        set ename  [emmet_gen_str {*}$name]
        set tagnum 1

        # Now that the name is elaborated, look it up and update the node, if necessary
        if {[set alias [emmet::lookup_node_alias $ename]] ne ""} {
          lassign $alias ename tagnum attrs
          foreach {key value} $attrs {
            $::emmet_elab set $enode attr,$key $value
          }
        } elseif {[info exists ::emmet_ml_lookup($ename)]} {
          lassign $::emmet_ml_lookup($ename) ename tagnum attrs
          foreach {key value} $attrs {
            $::emmet_elab set $enode attr,$key $value
          }
        }

        # Set the node name and tag number
        $::emmet_elab set $enode name   $ename
        $::emmet_elab set $enode tagnum $tagnum

        # Generate the attributes
        foreach attr [$tree keys $node attr,*] {
          set attr_key [emmet_gen_str {*}[lindex [split $attr ,] 1]]
          $::emmet_elab set $enode attr,$attr_key [list]
          foreach attr_val [$tree get $node $attr] {
            $::emmet_elab lappend $enode attr,$attr_key [emmet_gen_str {*}$attr_val]
          }
        }

      }

      # Set the node type
      $::emmet_elab set $enode type $type

      # Add the node text value, if specified
      if {[$tree keyexists $node value]} {
        $::emmet_elab set $enode value [emmet_gen_str {*}[$tree get $node value]]
      }

      # Add the Ipsum Lorem value, if specified
      if {[$tree keyexists $node lorem]} {
        $::emmet_elab set $enode value [emmet_gen_lorem [$tree get $node lorem]]
      }

    }

  }

}

proc emmet_generate {tree node action} {

  # Gather the children lines and indentation information
  set child_lines  [list]
  set child_indent 0
  foreach child [$tree children $node] {
    lappend child_lines {*}[$tree get $child lines]
    if {[$tree get $child indent]} {
      set child_indent 1
    }
  }

  # Setup the child lines to be structured properly
  if {[$tree get $node type] ne "group"} {
    if {$child_indent} {
      set spaces [string repeat { } $::emmet_shift_width]
      set i      0
      foreach line $child_lines {
        lset child_lines $i "$spaces$line"
        incr i
      }
    } else {
      set child_lines [join $child_lines {}]
    }
  }

  # Otherwise, insert our information along with the children in the proper order
  switch [$tree get $node type] {
    ident {
      set name     [$tree get $node name]
      set tagnum   [$tree get $node tagnum]
      set attr_str ""
      set value    ""
      if {[$tree keyexists $node value]} {
        set value [$tree get $node value]
      }
      foreach attr [$tree keys $node attr,*] {
        if {[set attr_val [concat {*}[$tree get $node $attr]]] eq ""} {
          set attr_val "{|}"
        }
        append attr_str " [lindex [split $attr ,] 1]=\"$attr_val\""
      }
      if {$tagnum == 0} {
        $tree set $node lines [list "<$name$attr_str />$value"]
      } elseif {$tagnum == 2} {
        $tree set $node lines [list "<$name$attr_str>$value"]
      } elseif {[llength $child_lines] == 0} {
        if {$value eq ""} {
          set value "{|}"
        }
        $tree set $node lines [list "<$name$attr_str>$value</$name>"]
      } else {
        if {$child_indent} {
          $tree set $node lines [list "<$name$attr_str>$value" {*}$child_lines "</$name>"]
        } else {
          $tree set $node lines [list "<$name$attr_str>$value$child_lines</$name>"]
        }
      }
      $tree set $node indent [expr [info exists ::emmet_inlined($name)] ? 0 : 1]
    }
    text {
      $tree set $node lines  [list [$tree get $node value]]
      $tree set $node indent 0
    }
    group {
      $tree set $node lines  $child_lines
      $tree set $node indent $child_indent
    }
  }

}

char* emmet_generate_html() {

  # Perform the elaboration
  $::emmet_dom walkproc root -order pre -type dfs emmet_elaborate

  # Generate the code
  $::emmet_elab walkproc root -order post -type dfs emmet_generate

  # Substitute carent syntax with tabstops
  if {[$::emmet_elab get root indent]} {
    set str [join [$::emmet_elab get root lines] "\n$::emmet_prespace"]
  } else {
    set str [join [$::emmet_elab get root lines] {}]
  }
  set index 1
  while {[regexp {(.*?)\{\|(.*?)\}(.*)$} $str -> before value after]} {
    if {$value eq ""} {
      set str "$before\$$index$after"
    } else {
      set str "$before\${$index:$value}$after"
    }
    incr index
  }

  return $str

}
  */

%}

%union {
  int        integer;
  char*      text;
  tree_node* node;
};

%token <text>    IDENTIFIER NUMBER CHILD SIBLING CLIMB OPEN_GROUP CLOSE_GROUP MULTIPLY
%token <node>    expression
%token <node>    item
%token <integer> multiply_opt number_opt
%token <attr>    attr_item attr_items
%token <attr>    attrs attr attrs_opt
%token OPEN_ATTR CLOSE_ATTR ASSIGN ID CLASS VALUE TEXT LOREM
%token SIBLING

%%

main: expression {
        emmet_value = emmet_generate_html();
      }
    ;

expression: item {
              $$ = $1;
            }
          | expression CHILD item {
              tree_node_move( $1, -1, $3 );
              if {[$::emmet_dom keyexists $3 name] && ([$::emmet_dom get $3 name] eq "")} {
                switch [lindex [$::emmet_dom get $1 name] 0] {
                  em       { $::emmet_dom set $3 name [list "span" {}] }
                  table -
                  tbody -
                  thead -
                  tfoot    { $::emmet_dom set $3 name [list "tr" {}] }
                  tr       { $::emmet_dom set $3 name [list "td" {}] }
                  ul -
                  ol       { $::emmet_dom set $3 name [list "li" {}] }
                  select -
                  optgroup { $::emmet_dom set $3 name [list "option" {}] }
                  default  { $::emmet_dom set $3 name [list "div" {}] }
                }
              }
              $$ = $3;
            }
          | expression SIBLING item {
              node_tree_move( $1->parent, -1, $3 );
              $$ = $3;
            }
          | expression CLIMB item {
              tree_node* parent = $1->parent;
              for( int i=1; i<strlen( $2 ); i++ ) {
                parent = parent->parent;
              }
              node_tree_move( parent, -1, $3 );
              $$ = $3;
            }
          ;

item: IDENTIFIER attrs_opt multiply_opt {
        tree_node* node = tree_node_create();
        tree_node_insert( emmet_dom, -1, node );
        tree_attrs_set( node->attrs, "type", "ident" );
        tree_attrs_set( node->attrs, "name", $1 );
        foreach {attr_name attr_val} $2 {
          $::emmet_dom lappend $node attr,$attr_name $attr_val
        }
        tree_attrs_set( node->attrs, "multiplier", $3 );
        $$ = node;
      }
    | IDENTIFIER attrs_opt TEXT multiply_opt {
        tree_node* node = tree_node_create();
        tree_node_insert( emmet_dom, -1, node );
        tree_attrs_set( node->attrs, "type", "ident" );
        tree_attrs_set( node->attrs, "name", $1 );
        tree_attrs_set( node->attrs, "value", $3 );
        foreach {attr_name attr_val} $2 {
          $::emmet_dom lappend $node attr,$attr_name $attr_val
        }
        tree_attrs_set( node->attrs, "multiplier", $4 );
        $$ = node;
      }
    | attrs multiply_opt {
        tree_node* node = tree_node_create();
        tree_node_insert( emmet_dom, -1, node );
        tree_attrs_set( node->attrs, "type", "ident" );
        tree_attrs_set( node->attrs, "name", "" );
        foreach {attr_name attr_val} $1 {
          $::emmet_dom lappend $node "attr,$attr_name" $attr_val
        }
        tree_attrs_set( node->attrs, "multiplier", $2 );
        $$ = node;
      }
    | TEXT multiply_opt {
        tree_node* node = tree_node_create();
        tree_node_insert( emmet_dom, -1, node );
        tree_attrs_set( node->attrs, "type", "text" );
        tree_attrs_set( node->attrs, "value", $1 );
        tree_attrs_set( node->attrs, "multiplier", $2 );
        $$ = node;
      }
    | LOREM number_opt attrs_opt multiply_opt {
        tree_node* node = tree_node_create();
        tree_node_insert( emmet_dom, -1, node );
        tree_attrs_set( node, "type", "ident" );
        tree_attrs_set( node, "name", "" );
        tree_attrs_set( node, "lorem", $2 );
        foreach {attr_name attr_val} $3 {
          $::emmet_dom lappend $node "attr,$attr_name" $attr_val
        }
        tree_attrs_set( node->attrs, "multiplier", $4 );
        $$ = node;
      }
    | OPEN_GROUP expression CLOSE_GROUP multiply_opt {
        tree_node* node = tree_node_create();
        tree_node_insert( emmet_dom, -1, node );
        tree_attrs_set( node, "type", "group" );
        tree_attrs_set( node->attrs, "multiplier", $4 );
        for( int i=$1; i<(emmet_dom->num_children - 1); i++ ) {
          tree_node_move( node, -1, emmet_dom->children[i] );
        }
        $$ = node;
      }
    ;

multiply_opt: MULTIPLY NUMBER {
                $$ = $2;
              }
            | MULTIPLY {
                $$ = 0;
              }
            | {
                $$ = 1;
              }
            ;

attr_item: IDENTIFIER ASSIGN VALUE {
             $$ = [list $1 $3];
           }
         | IDENTIFIER ASSIGN NUMBER {
             $$ = [list $1 [list $3 {}]];
           }
         | IDENTIFIER ASSIGN IDENTIFIER {
             $$ = [list $1 $3];
           }
         | IDENTIFIER {
             $$ = [list $1 [list {} {}]];
           }
         ;

attr_items: attr_item {
              $$ = $1;
            }
          | attr_items attr_item {
              $$ = [concat $1 $2];
            }
          ;

attr: OPEN_ATTR attr_items CLOSE_ATTR {
        $$ = $2;
      }
    | ID IDENTIFIER {
        $$ = [list [list id {}] $2];
      }
    | CLASS IDENTIFIER {
        $$ = [list [list class {}] $2];
      }
    ;

attrs: attr {
         $$ = $1;
       }
     | attrs attr {
         $$ = [concat $2 $1];
       }
     ;

attrs_opt: attrs {
             $$ = $1;
           }
         | {
             $$ = [list];
           }
         ;

number_opt: NUMBER {
              $$ = atoi( $1 );
            }
          | {
              $$ = 30;
            }
          ;

%%

  /*
void emmet_error( char* s ) {

  emmet_errstr = "[string repeat { } $::emmet_begpos]^"
  emmet_errmsg = strdup( s );

}

# Handles abbreviation filtering
proc emmet_condition_abbr {str wrap_str} {

  set filters [list]

  while {[regexp {^(.*)\|(haml|html|e|c|xsl|s|t)$} $str -> str filter]} {
    lappend filters $filter
  }

  # Make sure that we maintain the filter order that the user presented
  set ::emmet_filters [lreverse $filters]

  # If we have a wrap string and the abbreviation lacks the $# indicator, add it
  if {$wrap_str ne ""} {
    if {[string first \$# $str] == -1} {
      append str ">{\$#}"
    }
  }

  return $str

}

char* parse_emmet( char* str, char* prespace, char* wrap_str ) {

  # Check to see if the trim filter was specified
  set str [emmet_condition_abbr $str $wrap_str]

  # Flush the parsing buffer
  EMMET__FLUSH_BUFFER

  # Insert the string to scan
  emmet__scan_string $str

  # Initialize some values
  yylloc.first_column = 0;
  yylloc.last_column  = 0;
  emmet_prespace      = strdup( prespace );

  # Condition the wrap strings
  set ::emmet_wrap_str  [string trim $wrap_str]
  set ::emmet_wrap_strs [list]
  foreach line [split [string trim $wrap_str] \n] {
    lappend ::emmet_wrap_strs [string trim $line]
  }

  # Create the trees
  emmet_dom  = tree_node_create();
  emmet_elab = tree_node_create();

  # Parse the string
  if {[catch { emmet_parse } rc] || ($rc != 0)} {

    # Destroy the trees
    tree_node_destroy( emmet_dom );
    tree_node_destroy( emmet_elab );

    return -code error $rc

  }

  # Destroy the trees
  tree_node_destroy( emmet_dom );
  tree_node_destroy( emmet_elab );

  return( emmet_value );

}
  */
