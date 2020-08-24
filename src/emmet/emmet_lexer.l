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
  emmet_begpos  = emmet_endpos;
  emmet_endpos += strlen( emmet_text );
}

[a-zA-Z$!][a-zA-Z0-9:!@$-]*\+? {
  if {[info exists ::emmet_block_aliases($emmet_text)]} {
    unput( emmet_block_aliases($emmet_text) );
  } else if( strncmp( emmet_text, "lorem", 5 ) == 0 ) {
    unput( emmet_text + 5 );
    emmet_begpos = emmet_endpos;
    emmet_endpos += 5;
    return LOREM;
  } else if( strncmp( emmet_text, "lipsum", 6 ) == 0 ) {
    unput( emmet_text + 6 );
    emmet_begpos = emmet_endpos;
    emmet_endpos += 6;
    return LOREM;
  } else {
    if( emmet_text[strlen(emmet_text) - 1] == '+' ) {
      unput( "+" );
      emmet_text = strndup( emmet_text, (strlen( emmet_text ) - 1) );
    }
    emmet_lval    = strdup( emmet_get_item_name( emmet_text ) );
    emmet_begpos  = emmet_endpos;
    emmet_endpos += strlen( emmet_text );
    return IDENTIFIER;
  }
}

[1-9][0-9]*(\.[0-9]+)? {
  emmet_lval    = strdup( emmet_text );
  emmet_begpos  = emmet_endpos;
  emmet_endpos += strlen( emmet_text );
  return NUMBER;
}

\> {
  emmet_lval   = strdup( emmet_text );
  emmet_begpos = emmet_endpos;
  emmet_endpos = emmet_endpos + 1;
  return CHILD;
}

\+ {
  emmet_lval   = strdup( emmet_text );
  emmet_begpos = emmet_endpos;
  emmet_endpos++;
  return SIBLING;
}

\^+ {
  emmet_lval    = strdup( emmet_text );
  emmet_begpos  = emmet_endpos;
  emmet_endpos += strlen( emmet_text );
  return CLIMB;
}

\( {
  emmet_lval   = [llength [$::emmet_dom children root]]
  emmet_begpos = emmet_endpos;
  emmet_endpos++;
  return OPEN_GROUP;
}

\) {
  emmet_lval   = strdup( emmet_text );
  emmet_begpos = emmet_endpos;
  emmet_endpos++;
  return CLOSE_GROUP;
}

\* {
  emmet_lval   = strdup( emmet_text );
  emmet_begpos = emmet_endpos;
  emmet_endpos++;
  return MULTIPLY;
}

\[ {
  emmet_lval = strdup( emmet_text );
  emmet_begpos = emmet_endpos;
  emmet_endpos++;
  return OPEN_ATTR;
}

\] {
  emmet_lval   = strdup( emmet_text );
  emmet_begpos = emmet_endpos;
  emmet_endpos++;
  return CLOSE_ATTR;
}

\{.+\} {
  emmet_lval  = strdup( emmet_get_item_name( emmet_get_matching( emmet_text, '{', '}' ) ) );
  set ::emmet_begpos $::emmet_endpos
  incr ::emmet_endpos [string length $emmet_text]
  return TEXT;
}

'.*' {
  emmet_lval    = strdup( emmet_get_item_name( emmet_get_matching( emmet_text, '\'', '\'' ) ) );
  emmet_begpos  = emmet_endpos;
  emmet_endpos += strlen( emmet_text );
  return VALUE;
}

\".*\" {
  emmet_lval    = strdup( emmet_get_item_name( emmet_get_matching( emmet_text, '"', '"' ) ) );
  emmet_begpos  = emmet_endpos;
  emmet_endpos += strlen( emmet_text );
  return VALUE;
}

\$# {
  emmet_lval    = strpcy( emmet_get_item_name( emmet_text ) );
  emmet_begpos  = emmet_endpos;
  emmet_endpos += strlen( emmet_text );
  return VALUE;
}

= {
  emmet_lval   = strdup( emmet_text );
  emmet_begpos = emmet_endpos;
  emmet_endpos = emmet_endpos + 1;
  return ASSIGN;
}

# {
  emmet_lval   = strdup( emmet_text );
  emmet_begpos = emmet_endpos;
  emmet_endpos = emmet_endpos + 1;
  return ID;
}

\. {
  emmet_lval   = strdup( emmet_text );
  emmet_begpos = emmet_endpos;
  emmet_endpos = emmet_endpos + 1;
  return CLASS;
}

. {
  emmet_lval = strdup( emmet_text );
  emmet_begpos = emmet_endpos;
  emment_endpos += strlen( emmet_text );
  return $emmet_text;
}

%%
