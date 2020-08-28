%{

  /*
   Name:    snip_parser.tac
   Author:  Trevor Williams  (phase1geo@gmail.com)
   Date:    8/10/2015
   Brief:   Parser for snippet syntax.
  */

  // #include "emmet_lexer.h"

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
    void* value;
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

  int tree_attrs_keyexists( tree_attrs* attrs, char* key ) {
    for( int i=0; i<attrs->num; i++ ) {
      if( strcmp( attrs->attrs[i]->key, key ) == 0 ) {
        return( 1 );
      }
    }
    return( 0 );
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

      // Set the node type
      tree_attrs_set( enode->attrs, "type", type );

      // Add the node text value, if specified
      if( tree_attrs_keyexists( node->attrs, "value" ) ) {
        tree_attrs_set( enode->attrs, "value", emmet_gen_str( tree_attrs_get( node->attrs, "value" ) ) );
      }

      // Add the Ipsum Lorem value, if specified
      if( tree_attrs_keyexists( node->attrs, "lorem" ) ) {
        tree_attrs_set( enode->attrs, "value" emmet_gen_lorem( tree_attrs_get( node->attrs, "lorem" ) ) );
      }

    }

  }

}

void emmet_generate(
  tree_node* node,
  action
) {

  // Gather the children lines and indentation information
  char** child_lines  = malloc( sizeof( char* ) );
  int    num_clines   = 1;
  int    cline_index  = 0;
  char   child_indent[2] = "0";
  for( int i=0; i<node->num_children; i++ ) {
    tree_node* child = node->children[i];
    char*      lines = strdup( tree_attrs_get( child->attrs, "lines" ) );
    char*      token = strtok( lines, "\n" );
    while( token != NULL ) {
      child_lines[cline_index++] = strdup( token );
      token = strtok( NULL, "\n" );
    }
    if( strcmp( tree_attrs_get( child->attrs, "indent" ), "1" ) == 0 ) {
      child_indent = "1";
    }
  }

  // Setup the child lines to be structured properly
  if( strcmp( tree_attrs_get( node->attrs, "type" ), "group" ) != 0 ) {
    if( strcmp( child_indent, "1" ) == 0 ) {
      char* spaces = malloc( sizeof( char ) * emmet_shift_width );
      for( int i=0; i<emmet_shift_width; i++ ) {
        spaces[i] = ' ';
      }
      for( int i=0; i<cline_index; i++ ) {
        // TBD
        sprintf( "%s%s", spaces, child_lines[i] );
      }
      foreach line $child_lines {
        lset child_lines $i "$spaces$line"
        incr i
      }
    } else {
      set child_lines [join $child_lines {}]
    }
  }

  # Otherwise, insert our information along with the children in the proper order
  char* node_type = tree_attrs_get( node->attrs, "type" );
  if( strcmp( node_type, "indent" ) == 0 ) {
    char* name     = tree_attrs_get( node->attrs, "name" );
    int   tagnum   = atoi( tree_attrs_get( node->attrs, "tagnum" ) );
    char* attr_str = NULL;
    char* value    = tree_attrs_get( node->attrs, "value" );
    foreach attr [$tree keys $node attr,*] {
      if {[set attr_val [concat {*}[$tree get $node $attr]]] eq ""} {
        set attr_val "{|}"
      }
      append attr_str " [lindex [split $attr ,] 1]=\"$attr_val\""
    }
    if( tagnum == 0 ) {
      $tree set $node lines [list "<$name$attr_str />$value"]
    } else if( tagnum == 2 ) {
      $tree set $node lines [list "<$name$attr_str>$value"]
    } else if( [llength $child_lines] == 0} {
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

  } else if( strcmp( node_type, "text" ) == 0 ) {
    tree_attrs_set( node->attrs, "lines", tree_attrs_get( node->attrs, "value" ) );
    tree_attrs_set( node->attrs, "indent", "0" );

  } else if( strcmp( node_type, "group" ) == 0 ) {
    tree_attrs_set( node->attrs, "lines",  child_lines2 );
    tree_attrs_set( node->attrs, "indent", child_indent );
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

%token <text>    IDENTIFIER NUMBER CHILD SIBLING CLIMB OPEN_GROUP CLOSE_GROUP MULTIPLY TEXT VALUE
%token OPEN_ATTR CLOSE_ATTR ASSIGN ID CLASS LOREM

%type <node>    expression
%type <node>    item
%type <integer> multiply_opt number_opt
%type <attr>    attr_item attr_items
%type <attr>    attrs attr attrs_opt

%%

main
  : expression {
      emmet_value = emmet_generate_html();
    }
  ;

expression
  : item {
      $$ = $1;
    }
  | expression CHILD item {
      tree_node_move( $1, -1, $3 );
      if( tree_attrs_keyexists( $3->attrs, "name" ) && (strcmp( tree_attrs_get( $3->attrs, "name" ), "" ) == 0 ) ) {
        char* name = tree_attrs_get( $1->attrs, "name" );
        if( strcmp( name, "em" ) == 0 ) {
          tree_attrs_set( $3->attrs, "name", "span" );
        } else if( (strcmp( name, "table" ) == 0) ||
                   (strcmp( name, "tbody" ) == 0) ||
                   (strcmp( name, "thead" ) == 0) ||
                   (strcmp( name, "tfoot" ) == 0) ) {
          tree_attrs_set( $3->attrs, "name", "tr" );
        } else if( strcmp( name, "tr" ) == 0 ) {
          tree_attrs_set( $3->attrs, "name", "td" );
        } else if( (strcmp( name, "ul" ) == 0) ||
                   (strcmp( name, "ol" ) == 0) ) {
          tree_attrs_set( $3->attrs, "name", "li" );
        } else if( (strcmp( name, "select" ) == 0) ||
                   (strcmp( name, "optgroup" ) == 0) ) {
          tree_attrs_set( $3->attrs, "name", "option" );
        } else {
          tree_attrs_set( $3->attrs, "name", "div" );
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

item
  : IDENTIFIER attrs_opt multiply_opt {
      tree_node* node = tree_node_create();
      tree_node_insert( emmet_dom, -1, node );
      tree_attrs_set( node->attrs, "type", "ident" );
      tree_attrs_set( node->attrs, "name", $1 );
      /*
      foreach {attr_name attr_val} $2 {
        $::emmet_dom lappend $node attr,$attr_name $attr_val
      }
      */
      tree_attrs_set( node->attrs, "multiplier", $3 );
      $$ = node;
    }
  | IDENTIFIER attrs_opt TEXT multiply_opt {
      tree_node* node = tree_node_create();
      tree_node_insert( emmet_dom, -1, node );
      tree_attrs_set( node->attrs, "type", "ident" );
      tree_attrs_set( node->attrs, "name", $1 );
      tree_attrs_set( node->attrs, "value", $3 );
      /*
      foreach {attr_name attr_val} $2 {
        $::emmet_dom lappend $node attr,$attr_name $attr_val
      }
      */
      tree_attrs_set( node->attrs, "multiplier", $4 );
      $$ = node;
    }
  | attrs multiply_opt {
      tree_node* node = tree_node_create();
      tree_node_insert( emmet_dom, -1, node );
      tree_attrs_set( node->attrs, "type", "ident" );
      tree_attrs_set( node->attrs, "name", "" );
      /*
      foreach {attr_name attr_val} $1 {
        $::emmet_dom lappend $node "attr,$attr_name" $attr_val
      }
      */
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
      /*
      foreach {attr_name attr_val} $3 {
        $::emmet_dom lappend $node "attr,$attr_name" $attr_val
      }
      */
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

multiply_opt
  : MULTIPLY NUMBER {
      $$ = $2;
    }
  | MULTIPLY {
      $$ = 0;
    }
  | {
      $$ = 1;
    }
  ;

attr_item
  : IDENTIFIER ASSIGN VALUE {
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

attr_items
  : attr_item {
      $$ = $1;
    }
  | attr_items attr_item {
      $$ = [concat $1 $2];
    }
  ;

attr
  : OPEN_ATTR attr_items CLOSE_ATTR {
      $$ = $2;
    }
  | ID IDENTIFIER {
      $$ = [list [list id {}] $2];
    }
  | CLASS IDENTIFIER {
      $$ = [list [list class {}] $2];
    }
  ;

attrs
  : attr {
      $$ = $1;
    }
  | attrs attr {
      $$ = [concat $2 $1];
    }
  ;

attrs_opt
  : attrs {
      $$ = $1;
    }
  | {
      $$ = [list];
    }
  ;

number_opt
  : NUMBER {
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
*/

char* parse_emmet( char* str, char* prespace, char* wrap_str ) {

  # Check to see if the trim filter was specified
  set str [emmet_condition_abbr $str $wrap_str]

  # Flush the parsing buffer
  EMMET__FLUSH_BUFFER

  # Insert the string to scan
  emmet__scan_string( $str );

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
  emmet_parse();

  /*
    # Destroy the trees
    tree_node_destroy( emmet_dom );
    tree_node_destroy( emmet_elab );

    return -code error $rc
  */

  /* Destroy the trees */
  tree_node_destroy( emmet_dom );
  tree_node_destroy( emmet_elab );

  return( emmet_value );

}
