%{
    #include <stdio.h>
    #include <string.h>
    #include "cgen.h"
    #include "myanalyzer.tab.h"

    int line_num = 1;
%}


IDENTIFIER  [a-zA-Z][0-9a-zA-Z_]*
DIGIT       [0-9]
NUMBER      {DIGIT}+
REAL        {NUMBER}(\.{NUMBER})?([eE][+-]?{NUMBER})?
STRING      \"[^\n]*\"


%%

@defmacro[ \t]+{IDENTIFIER}[ \t]+({REAL}|{NUMBER}|{STRING}) {
    // Copy the matched text to a buffer
    char *macro_def = strdup(yytext);

    // Skip the "@defmacro " part (10 characters)
    char *macro_name = macro_def + 10;

    // Find the end of the macro name by detecting the space at the end
    char *space_pos = strchr(macro_name, ' ');
    if (space_pos) {
        *space_pos = '\0';  // Terminate the macro name string
        // Get the value part after the macro name
        char *macro_value = space_pos + 1;
        printf("#define %s %s\n", macro_name, macro_value);
    }

    // Clean up duplicated string
    free(macro_def);
}

"void"          { return KW_VOID;}
"integer"       { return KW_INTEGER; }
"scalar"        { return KW_REAL; }
"str"           { return KW_STR; }
"bool"          { return KW_BOOL; }
"True"          { return KW_TRUE; }
"False"         { return KW_FALSE; }
"const"         { return KW_CONST; }
"if"            { return KW_IF; }
"else"          { return KW_ELSE; }
"endif"         { return KW_ENDIF; }
"for"           { return KW_FOR; }
"in"            { return KW_IN; }
"endfor"        { return KW_ENDFOR; }
"while"         { return KW_WHILE; }
"endwhile"      { return KW_ENDWHILE; }
"break"         { return KW_BREAK; }
"continue"      { return KW_CONTINUE; }
"def"           { return KW_DEF; }
"enddef"        { return KW_ENDDEF; }
"comp"          { return KW_COMP; }
"endcomp"       { return KW_ENDCOMP; }
"main"          { return KW_MAIN; }
"return"        { return KW_RETURN; }
"of"            { return KW_OF; }

"+"             { return OP_PLUS; }
"-"             { return OP_MINUS; }
"*"             { return OP_MUL; }
"/"             { return OP_DIV; }
"%"             { return OP_MOD; }
"**"            { return OP_POW; }
"=="            { return OP_EQ; }
"!="            { return OP_NEQ; }
"<"             { return OP_LESS; }
"<="            { return OP_LESSEQ; }
">"             { return OP_GREATER; }
">="            { return OP_GREATEREQ; }
"and"           { return OP_AND; }
"or"            { return OP_OR; }
"not"           { return OP_NOT;}

"="             { return OP_ASSIGN; }
"+="            { return OP_ASSIGN_INCR; }
"-="            { return OP_ASSIGN_DEC; }
"*="            { return OP_ASSIGN_MUL; }
"/="            { return OP_ASSIGN_DIV; }
"%="            { return OP_ASSIGN_MOD; }
":="            { return OP_ASSIGN_ARR; }

";"             { return SEMICOLON; }
"("             { return L_PARENTHESIS; }
")"             { return R_PARENTHESIS; }
","             { return COMMA; }
"["             { return L_BRACKET; }
"]"             { return R_BRACKET; }
":"             { return COLON; }
"."             { return DOT; }


"readStr"       { return FN_RSTR; }
"readInteger"   { return FN_RINT; }
"readScalar"    { return FN_RSCAL; }
"writeStr"      { return FN_WSTR; }
"writeInteger"  { return FN_WINT; }
"writeScalar"   { return FN_WSCAL; }
"write"         { return FN_WRT; }


{IDENTIFIER}         { yylval.str = strdup(yytext); return TK_IDENTIFIER; }
{NUMBER}             { yylval.str = strdup(yytext); return TK_INTEGER;  }
{REAL}               { yylval.str = strdup(yytext); return TK_REAL; }
{STRING}             { yylval.str = strdup(yytext); return TK_STRING; }


[ \r\t]+             /* Column, /r or /t */
"--"[^\n]*           /* Line Comment */

\n                   { ++line_num; }

<<EOF>>              return EOF;
.                    { printf("Unrecognized Token '%s' in line %d\n", yytext, line_num); exit(1);}
%%