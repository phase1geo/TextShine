%{
  /*
  */

  /*
   Name:    emmet_lexer.fcl
   Author:  Trevor Williams  (phase1geo@gmail.com)
   Date:    2/17/2016
   Brief:   Lexer for emmet syntax.
  */

  #include "emmet_parser.tab.h"

  char* emmet_get_matching( char* str, char start_char, char end_char ) {

    int strlen = strlen( str );
    int count  = 1;
    int skip   = 0;

    for( int i=1; i<strlen; i=i+1 ) {
      if( skip ) {
        skip = 0;
      } else {
        char c = str[i];
        if( c == '\\' ) {
          skip = 1;
        } else if( c == end_char ) {
          if( (count = (count - 1)) == 0 ) {
            unput( str + i + 1 );
            return( strndup( (str + 1), i ) );
          }
        } else if( c == start_char ) {
          count = count + 1;
        }
      }
    }

  }

%}

%option stack

%%

[ \n\t\b\f]+ {
  yylloc.first_column  = yylloc.last_column;
  yylloc.last_column += strlen( yytext );
}

[a-zA-Z$!][a-zA-Z0-9:!@$-]*\+? {
  if {[info exists ::emmet_block_aliases($yytext)]} {
    unput( emmet_block_aliases($yytext) );
  } else if( strncmp( yytext, "lorem", 5 ) == 0 ) {
    unput( yytext + 5 );
    yylloc.first_column = yylloc.last_column;
    yylloc.last_column += 5;
    return LOREM;
  } else if( strncmp( yytext, "lipsum", 6 ) == 0 ) {
    unput( yytext + 6 );
    yylloc.first_column = yylloc.last_column;
    yylloc.last_column += 6;
    return LOREM;
  } else {
    if( yytext[strlen(yytext) - 1] == '+' ) {
      unput( "+" );
      yytext = strndup( yytext, (strlen( yytext ) - 1) );
    }
    yylval.text          = strdup( emmet_get_item_name( yytext ) );
    yylloc.first_column  = yylloc.last_column;
    yylloc.last_column  += strlen( yytext );
    return IDENTIFIER;
  }
}

[1-9][0-9]*(\.[0-9]+)? {
  yylval.text    = strdup( yytext );
  yylloc.first_column  = yylloc.last_column;
  yylloc.last_column += strlen( yytext );
  return NUMBER;
}

\> {
  yylval.text   = strdup( yytext );
  yylloc.first_column = yylloc.last_column;
  yylloc.last_column = yylloc.last_column + 1;
  return CHILD;
}

\+ {
  yylval.text   = strdup( yytext );
  yylloc.first_column = yylloc.last_column;
  yylloc.last_column++;
  return SIBLING;
}

\^+ {
  yylval.text          = strdup( yytext );
  yylloc.first_column  = yylloc.last_column;
  yylloc.last_column  += strlen( yytext );
  return CLIMB;
}

\( {
  yylval.text   = [llength [$::emmet_dom children root]]
  yylloc.first_column = yylloc.last_column;
  yylloc.last_column++;
  return OPEN_GROUP;
}

\) {
  yylval.text   = strdup( yytext );
  yylloc.first_column = yylloc.last_column;
  yylloc.last_column++;
  return CLOSE_GROUP;
}

\* {
  yylval.text   = strdup( yytext );
  yylloc.first_column = yylloc.last_column;
  yylloc.last_column++;
  return MULTIPLY;
}

\[ {
  yylval.text = strdup( yytext );
  yylloc.first_column = yylloc.last_column;
  yylloc.last_column++;
  return OPEN_ATTR;
}

\] {
  yylval.text   = strdup( yytext );
  yylloc.first_column = yylloc.last_column;
  yylloc.last_column++;
  return CLOSE_ATTR;
}

\{.+\} {
  yylval.text  = strdup( emmet_get_item_name( emmet_get_matching( yytext, '{', '}' ) ) );
  yylloc.first_column $::yylloc.last_column
  yylloc.last_column += strlen( yylval.text ) length $yytext]
  return TEXT;
}

'.*' {
  yylval.text    = strdup( emmet_get_item_name( emmet_get_matching( yytext, '\'', '\'' ) ) );
  yylloc.first_column  = yylloc.last_column;
  yylloc.last_column += strlen( yytext );
  return VALUE;
}

\".*\" {
  yylval.text    = strdup( emmet_get_item_name( emmet_get_matching( yytext, '"', '"' ) ) );
  yylloc.first_column  = yylloc.last_column;
  yylloc.last_column += strlen( yytext );
  return VALUE;
}

\$# {
  yylval.text    = strdup( emmet_get_item_name( yytext ) );
  yylloc.first_column  = yylloc.last_column;
  yylloc.last_column += strlen( yytext );
  return VALUE;
}

= {
  yylval.text   = strdup( yytext );
  yylloc.first_column = yylloc.last_column;
  yylloc.last_column = yylloc.last_column + 1;
  return ASSIGN;
}

# {
  yylval.text   = strdup( yytext );
  yylloc.first_column = yylloc.last_column;
  yylloc.last_column = yylloc.last_column + 1;
  return ID;
}

\. {
  yylval.text   = strdup( yytext );
  yylloc.first_column = yylloc.last_column;
  yylloc.last_column = yylloc.last_column + 1;
  return CLASS;
}

%%
