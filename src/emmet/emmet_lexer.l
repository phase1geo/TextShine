%{
  /*
  */

  /*
   Name:    emmet_lexer.fcl
   Author:  Trevor Williams  (phase1geo@gmail.com)
   Date:    2/17/2016
   Brief:   Lexer for emmet syntax.
  */

  #include "emmet_parser.tab"

array set emmet_block_aliases {

  # HTML
  !         {!!!+doc[lang=en]}
  doc       {html>(head>meta[charset=UTF-8]+title{{|Document}})+body}
  doc4      {html>(head>meta[http-equiv="Content-Type" content="text/html;charset=${charset}"]+title{{|Document}})+body}
  html:4t   {!!!4t+doc4[lang=en]}
  html:4s   {!!!4s+doc4[lang=en]}
  html:xt   {!!!xt+doc4[xmlns="http://www.w3.org/1999/xhtml" xml:lang=en]}
  html:xs   {!!!xs+doc4[xmlns="http://www.w3.org/1999/xhtml" xml:lang=en]}
  html:xxs  {!!!xxs+doc4[xmlns="http://www.w3.org/1999/xhtml" xml:lang=en]}
  html:5    {!!!+doc[lang=en]}
  ol+       {ol>li}
  dl+       {dl>dt+dd}
  map+      {map>area}
  table+    {table>tr>td}
  colgroup+ {colgroup>col}
  colg+     {colgroup>col}
  tr+       {tr>td}
  select+   {select>option}
  optgroup+ {optgroup>option}
  optg+     {optgroup>option}

  # CSS

  # XSLT
  choose+   {xml:choose>xsl:when+xsl:otherwise}
  xsl       {xsl:stylesheet[version=1.0 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"]}
}

char* emmet_get_item_value() {

  if( !emmet_multi ) {
    if {[llength $::emmet_wrap_strs] == 1} {
      return $::emmet_wrap_str
    } else {
      return "\n$::emmet_wrap_str\n"
    }
  } else {
    return [lindex $::emmet_wrap_str $::emmet_curr]
  }

}

proc emmet_get_item_name {str} {

  set formatted_str ""
  set values        [list]

  while {[set index [string first \$ $str]] != -1} {
    append formatted_str [string range $str 0 [expr $index - 1]]
    if {[regexp {^\$#} [string range $str $index end] match rest]} {
      append formatted_str "%s"
      lappend values [list emmet_get_item_value]
    } elseif {[regexp {^(\$+)(@(-)?(\d*))?} [string range $str $index end] match numbering dummy reverse start]} {
      if {$dummy ne ""} {
        append formatted_str "%0[string length $numbering]d"
        if {$reverse ne ""} {
          if {$start ne ""} {
            lappend values [list expr (\$::emmet_max - \$::emmet_curr) + ($start - 1)]
          } else {
            lappend values [list expr \$::emmet_max - \$::emmet_curr]
          }
        } else {
          if {$start ne ""} {
            lappend values [list expr \$::emmet_curr + $start]
          } else {
            lappend values [list expr \$::emmet_curr + 1]
          }
        }
      } else {
        append formatted_str "%0[string length $numbering]d"
        lappend values [list expr \$::emmet_curr + 1]
      }
    } else {
      return -code error "Unknown item name format ([string range $str $index end])"
    }
    set str [string range $str [expr $index + [string length $match]] end]
  }

  append formatted_str $str

  return [list $formatted_str $values]

}

char* emmet_get_matching( char* str, char start_char, char end_char ) {

  int  strlen = strlen( str );
  int  count  = 1;
  bool skip   = false;

  for( int i=1; i<strlen; i=i+1 ) {
    if( skip ) {
      skip = false;
    } else {
      char c = str[i];
      if( c == '\' ) {
        skip = true;
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
  yylval.text    = strpcy( emmet_get_item_name( yytext ) );
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

. {
  yylval.text = strdup( yytext );
  yylloc.first_column = yylloc.last_column;
  yylloc.last_column += strlen( yytext );
  return yytext;
}

%%
