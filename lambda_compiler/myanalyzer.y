%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "cgen.h"

    extern int yylex(void);
    extern int line_num;
%}    


%union{
    char* str;
}


/* keywords */
%token KW_VOID
%token KW_INTEGER
%token KW_REAL
%token KW_STR
%token KW_BOOL
%token KW_TRUE
%token KW_FALSE
%token KW_CONST
%token KW_IF
%token KW_ELSE
%token KW_ENDIF
%token KW_FOR
%token KW_IN
%token KW_ENDFOR
%token KW_WHILE
%token KW_ENDWHILE
%token KW_BREAK
%token KW_CONTINUE
%token KW_DEF
%token KW_ENDDEF
%token KW_COMP
%token KW_ENDCOMP
%token KW_MAIN
%token KW_RETURN
%token KW_OF



/* operators */
%left OP_PLUS
%left OP_MINUS
%left OP_MUL
%left OP_DIV
%left OP_MOD
%right OP_POW
%left OP_EQ
%left OP_NEQ
%left OP_LESS
%left OP_LESSEQ
%left OP_GREATER
%left OP_GREATEREQ
%left OP_AND
%left OP_OR
%right OP_NOT

%right OP_ASSIGN
%right OP_ASSIGN_INCR
%right OP_ASSIGN_DEC
%right OP_ASSIGN_MUL
%right OP_ASSIGN_DIV
%right OP_ASSIGN_MOD
%right OP_ASSIGN_ARR

/* io functions */
%token FN_RSTR
%token FN_RINT
%token FN_RSCAL
%token FN_WSTR
%token FN_WINT
%token FN_WSCAL
%token FN_WRT

/* delimiters */
%token SEMICOLON
%left L_PARENTHESIS
%left R_PARENTHESIS
%token COMMA
%left L_BRACKET
%left R_BRACKET
%token COLON
%token DOT



/* flex tokens */
%token <str> TK_IDENTIFIER
%token <str> TK_INTEGER
%token <str> TK_REAL
%token <str> TK_STRING

%start input

// body types
%type <str> start
%type <str> main
%type <str> const_declaration
%type <str> const_assign

%type <str> local_declarations
%type <str> var_const_decl

// function types
%type <str> fun_definition
%type <str> fun_parameters
%type <str> fun_parameter_member
%type <str> function_body
%type <str> data_type
%type <str> io_call
%type <str> io_call_content
%type <str> return_statement
%type <str> function_call
%type <str> function_call_arguments


// statements types
%type <str> statements
%type <str> statement
%type <str> assign_object


// variable types
%type <str> var_decl
%type <str> var_strings
%type <str> var_loop

// loops
%type <str> for_loop
%type <str> while_loop

// if blocks
%type <str> if_block


// expressions
%type <str> expression
%type <str> array_expression
%type <str> compact_array



// analyzer main part
%%

input:
    start {
        if(yyerror_count == 0){
            puts(c_prologue);
            printf("%s\n",$1);
        }
    }
;

// program starting here, start by parsing main decl
// we do left recursion
start:
        main { $$ = template("%s\n", $1); }
    |   const_declaration start { $$ = template("%s\n\n%s", $1, $2); }
    |   var_decl start { $$ = template("%s\n\n%s", $1, $2); }
    |   fun_definition start { $$ = template("%s\n\n%s", $1, $2); }
;

main:
        KW_DEF KW_MAIN L_PARENTHESIS R_PARENTHESIS COLON KW_ENDDEF SEMICOLON{ $$ = template("void main(){}"); }
    |   KW_DEF KW_MAIN L_PARENTHESIS R_PARENTHESIS COLON function_body KW_ENDDEF SEMICOLON  { $$ = template("void main(){\n%s\n}",$6); }
;


function_body:
        local_declarations statements   { $$ = template("\t%s\n%s", $1, $2); }
    |   statements local_declarations   { $$ = template("\t%s\n%s", $1, $2); }
    |   statements                      { $$ = template("%s\n", $1); }
;

var_const_decl:
        var_decl            { $$ = $1; }
    |   const_declaration   { $$ = $1; }


local_declarations:
        local_declarations var_const_decl       { $$ = template("%s\n%s", $1, $2); }
    |   var_const_decl                          { $$ = $1; }
;


// declaring constants
const_declaration: 
    KW_CONST const_assign COLON data_type SEMICOLON  { $$ = template("const %s %s;\n", $4, $2); }
;


const_assign:
        TK_IDENTIFIER OP_ASSIGN expression      { $$ = template("%s = %s", $1, $3); }
    |   TK_IDENTIFIER OP_ASSIGN TK_STRING       { $$ = template("%s = %s", $1, $3); }
;


// declaring variables


// main variable declaration loop
var_decl:   
        var_loop COLON data_type SEMICOLON   { $$ = template("%s %s;\n", $3, $1); }
;

//
//  a, b, c : integer;
//
//
// variable declaration recursion until no variables are left (many variables may be declarated in a single line e.g. a, b, c: int; )
var_loop:
        var_strings                         { $$ = $1; }
    |   var_loop COMMA var_strings          { $$ = template("%s, %s", $1, $3); }


var_strings:
        TK_IDENTIFIER                                               { $$ = template("%s", $1); }
    |   TK_IDENTIFIER L_BRACKET expression R_BRACKET                { $$ = template("%s[%s]", $1, $3); }
;


data_type:
        KW_INTEGER  { $$ = template("int"); }
    |   KW_STR      { $$ = template("str"); }
    |   KW_REAL     { $$ = template("double"); }
    |   KW_BOOL     { $$ = template("bool"); }
    |   KW_VOID     { $$ = template("void"); }
;

// function parsing

fun_definition:
    // function with return type
        KW_DEF TK_IDENTIFIER L_PARENTHESIS fun_parameters R_PARENTHESIS OP_MINUS OP_GREATER data_type COLON function_body KW_ENDDEF SEMICOLON
        { $$ = template("%s %s(%s) {\n%s\n}", $8, $2, $4, $10);}
    // function with void type to return
    |   KW_DEF TK_IDENTIFIER L_PARENTHESIS fun_parameters R_PARENTHESIS COLON function_body KW_ENDDEF SEMICOLON
        { $$ = template("void %s(%s) {\n%s\n}\n", $2, $4, $7);}
;


// left recursion to parse all function arguments
fun_parameters:
        fun_parameter_member COMMA fun_parameters   { $$ = template("%s, %s", $1, $3); }
    |   fun_parameter_member                        { $$ = $1; }
    |   %empty                                      { $$ = ""; }
;


// base case (smallest part) of function paremeters:
// 2 cases: a) simple variable, b) array
fun_parameter_member: 
        TK_IDENTIFIER COLON data_type                       { $$ = template("%s %s", $3, $1); }
    |   TK_IDENTIFIER L_BRACKET R_BRACKET COLON data_type   { $$ = template("%s %s[]", $5, $1); }
;


// statements and expressions


// statement right recursion
statements:
        statement
    |   statements statement    { $$ = template("%s\n\t%s", $1, $2); }
;

// statement part, every possible command or block
statement:
        assign_object SEMICOLON         { $$ = template("%s;", $1); }
    |   function_call SEMICOLON         { $$ = template("%s;", $1); }
    |   compact_array                   { $$ = $1; }
    |   for_loop                        { $$ = template("%s", $1); }
    |   while_loop                      { $$ = template("%s", $1); }
    |   KW_CONTINUE SEMICOLON           { $$ = template("continue;"); }
    |   KW_BREAK SEMICOLON              { $$ = template("break;"); }
    |   if_block                        { $$ = template("%s", $1); }
    |   return_statement                { $$ = template("%s", $1); }
    |   io_call                         { $$ = template("%s", $1); }
;

// assignment of variables (simple variables, array element) simple or incremental
assign_object:
      var_strings OP_ASSIGN expression              { $$ = template("%s = %s", $1, $3); }
    | var_strings OP_ASSIGN_INCR expression         { $$ = template("%s+=%s", $1, $3); }
    | var_strings OP_ASSIGN_DEC expression          { $$ = template("%s-=%s", $1, $3); }
    | var_strings OP_ASSIGN_MUL expression          { $$ = template("%s*=%s", $1, $3); }
    | var_strings OP_ASSIGN_DIV expression          { $$ = template("%s/=%s", $1, $3); }
    | var_strings OP_ASSIGN_MOD expression          { $$ = template("%s = %s %% %s", $1, $1, $3); }
;

// function call with argument parsing
function_call:
    TK_IDENTIFIER L_PARENTHESIS function_call_arguments R_PARENTHESIS    { $$ = template("%s(%s)", $1, $3); }
;

// function call argument right recursion in order to get all argument possibly seperated by commas
function_call_arguments:
        %empty                                      { $$ = template(""); }
    |   function_call_arguments COMMA expression    { $$ = template("%s, %s", $1, $3); }
    |   expression                                  { $$ = template("%s", $1); }
;


// for loop parsing
for_loop:
        KW_FOR TK_IDENTIFIER KW_IN L_BRACKET expression COLON expression R_BRACKET COLON statements KW_ENDFOR SEMICOLON
        { $$ = template("\n\tfor(int %s = %s; %s<%s; %s++){\n\t\t%s\n\t}", $2, $5, $2, $7, $2, $10); }
    |   KW_FOR TK_IDENTIFIER KW_IN L_BRACKET expression COLON expression COLON expression R_BRACKET COLON statements KW_ENDFOR SEMICOLON
        { $$ = template("\n\tfor(int %s = %s; %s<%s; %s = %s + %s){\n\t\t%s\n\t}", $2, $5, $2, $9, $2, $2, $7, $12); }

// while loop parsings
while_loop:
        KW_WHILE L_PARENTHESIS expression R_PARENTHESIS COLON statements KW_ENDWHILE SEMICOLON
        { $$ = template("\n\twhile(%s){\n\t\t%s\n\t}", $3, $6);}
;

// if block
if_block:
        KW_IF L_PARENTHESIS expression R_PARENTHESIS COLON statements KW_ENDIF SEMICOLON
        { $$ = template("\n\tif(%s){\n\t   %s\n\t}", $3, $6);}
    |   KW_IF L_PARENTHESIS expression R_PARENTHESIS COLON statements KW_ELSE COLON statements KW_ENDIF SEMICOLON
        { $$ = template("\n\tif(%s){\n\t   %s\n\t}\n\telse{\n\t%s\n\t}\n", $3, $6, $9); }
;

// plain return or return a variable or expression generally
return_statement:
        KW_RETURN SEMICOLON               { $$ = template("\n\treturn;\n"); }
    |   KW_RETURN expression SEMICOLON    { $$ = template("\n\treturn %s;\n",$2 ); }
;


// possible array expressions
array_expression:
        TK_IDENTIFIER L_BRACKET expression R_BRACKET    { $$ = template("%s[%s]", $1, $3); }
    |   TK_IDENTIFIER L_BRACKET R_BRACKET               { $$ = template("*%s", $1);}
;

// the most importan recursion, it detects complex expressions, 
// such as mathematical expression, plain variables, numbers etc.
expression:
        OP_MINUS expression                          { $$ = template("-%s", $2); }
    |   OP_PLUS expression                           { $$ = template("+%s", $2); }
    |   L_PARENTHESIS expression R_PARENTHESIS       { $$ = template("(%s)", $2); }
    |   expression OP_PLUS expression                { $$ = template("%s + %s", $1, $3); }
    |   expression OP_MINUS expression               { $$ = template("%s - %s", $1, $3); }
    |   expression OP_MUL expression                 { $$ = template("%s * %s", $1, $3); }
    |   expression OP_DIV expression                 { $$ = template("%s / %s", $1, $3); }
    |   expression OP_MOD expression                 { $$ = template("%s %% %s", $1, $3); }
    |   expression OP_POW expression                 { $$ = template("pow(%s,%s)", $1, $3); }
    |   expression OP_EQ  expression                 { $$ = template("%s == %s", $1, $3); }
    |   expression OP_NEQ expression                 { $$ = template("%s != %s", $1, $3); }
    |   expression OP_LESS expression                { $$ = template("%s < %s", $1, $3); }
    |   expression OP_LESSEQ expression              { $$ = template("%s <= %s", $1, $3); }
    |   expression OP_GREATER expression             { $$ = template("%s > %s", $1, $3); }
    |   expression OP_GREATEREQ expression           { $$ = template("%s >= %s", $1, $3); }
    |   expression OP_AND expression                 { $$ = template("%s && %s", $1, $3); }
    |   expression OP_OR  expression                 { $$ = template("%s || %s", $1, $3); }
    |   OP_NOT expression                            { $$ = template("!%s", $2); }
    |   array_expression            { $$ = $1; }
    |   TK_IDENTIFIER               { $$ = $1; }
    |   TK_INTEGER                  { $$ = $1; }
    |   TK_REAL                     { $$ = $1; }    
    |   KW_TRUE                     { $$ = "1"; }
    |   KW_FALSE                    { $$ = "0"; }
    |   io_call                     { $$ = $1; }
    |   function_call               { $$ = $1;}
;


// compact array statement parsing, the second case is not working

compact_array:
    TK_IDENTIFIER OP_ASSIGN_ARR L_BRACKET expression KW_FOR TK_IDENTIFIER COLON expression R_BRACKET COLON data_type SEMICOLON {
        $$ = template("%s* %s=(%s*)malloc(%s * sizeof(%s)); \n\tfor (int %s = 0 ; %s < %s ; %s++) {\n\t\t%s[%s]=%s;\n\t}\n", $11, $1, $11, $8, $11, $6, $6, $8, $6, $1, $6, $6);
    }
    | TK_IDENTIFIER OP_ASSIGN_ARR L_BRACKET expression KW_FOR TK_IDENTIFIER COLON data_type KW_IN TK_IDENTIFIER KW_OF TK_INTEGER R_BRACKET COLON data_type SEMICOLON{
        $$ = template("%s* %s=(%s*)malloc(%s * sizeof(%s)); \n\tfor (int i = 0 ; i < %s ; ++i) {\n\t\t%s[i]=%s[i];\n\t}\n", $15, $1, $15, $12, $15, $12, $1, $10);
    }
;


// input-output call from lambdalib.h
io_call:
        var_strings OP_ASSIGN FN_RSTR L_PARENTHESIS R_PARENTHESIS SEMICOLON     { $$ = template("%s = readStr();", $1); }
    |   var_strings OP_ASSIGN FN_RSCAL L_PARENTHESIS R_PARENTHESIS SEMICOLON    { $$ = template("%s = readScalar();", $1); }
    |   var_strings OP_ASSIGN FN_RINT L_PARENTHESIS R_PARENTHESIS SEMICOLON     { $$ = template("%s = readInteger();", $1); }
    |   FN_WSTR L_PARENTHESIS io_call_content R_PARENTHESIS SEMICOLON     { $$ = template("writeStr(%s);", $3); }
    |   FN_WSCAL L_PARENTHESIS io_call_content R_PARENTHESIS SEMICOLON    { $$ = template("writeScalar(%s);", $3); }
    |   FN_WINT L_PARENTHESIS io_call_content R_PARENTHESIS SEMICOLON     { $$ = template("writeInteger(%s);", $3); }
    |   FN_WRT L_PARENTHESIS io_call_content R_PARENTHESIS SEMICOLON      { $$ = template("write(%s);", $3); }
;


// argument of io print call s
io_call_content:
        TK_IDENTIFIER       { $$ = $1; }
    |   TK_STRING           { $$ = $1; }
    |   TK_INTEGER          { $$ = $1; }
    |   TK_REAL             { $$ = $1; }
    |   array_expression    { $$ = $1; }
;


%%
int main() {

    //check for errros, if exist print syntax error msg
    if ( yyparse() != 0 )
        fprintf(stderr,"Syntax Error(s). Please check your input \n");
}