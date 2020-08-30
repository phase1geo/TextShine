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

char* parse_emmet( char* str, char* prespace, char* wrap_str ) {

  // Check to see if the trim filter was specified
  str = emmet_condition_abbr( str, wrap_str );

  // Flush the parsing buffer
  EMMET__FLUSH_BUFFER

  // Insert the string to scan
  emmet__scan_string( str );

  // Initialize some values
  yylloc.first_column = 0;
  yylloc.last_column  = 0;
  emmet_prespace      = strdup( prespace );

  // Condition the wrap strings
  emmet_helper_condition_wrap_strings( wrap_str );

  // Parse the string
  emmet_parse();

  return( emmet_value );

}
