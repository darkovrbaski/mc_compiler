%option noyywrap yylineno
%{
   #include <string.h>
   #include "micko.tab.h"
   #include "defs.h"
   extern YYSTYPE yylval;
%}

%%

[ \t\n]+             { /* skip white spaces, tabs and new lines */ }

"int"                { yylval.i = INT;  return _TYPE; }
"unsigned"           { yylval.i = UINT; return _TYPE; }
"void"               { yylval.i = VOID; return _TYPE; }
"if"                 { return _IF; }
"else"               { return _ELSE; }
"return"             { return _RETURN; }
"for"                { return _FOR; }
"jiro"               { return _JIRO; }
"tranga"             { return _TRANGA; }
"->"                 { return _ARROW; }
"finish"             { return _FINISH; }
"toerana"            { return _TOERANA; }

"("                  { return _LPAREN; }
")"                  { return _RPAREN; }
"{"                  { return _LBRACKET; }
"}"                  { return _RBRACKET; }
"["                  { return _LSBRAC; }
"]"                  { return _RSBRAC; }
";"                  { return _SEMICOLON; }
":"                  { return _COLON; }
"="                  { return _ASSIGN; }
","                  { return _COMMA; }
"?"                  { return _QMARK; }

"+"                  { yylval.i = ADD; return _AROP; }
"-"                  { yylval.i = SUB; return _AROP; }
"*"                  { yylval.i = MUL; return _MDOP; }
"/"                  { yylval.i = DIV; return _MDOP; }
"++"                 { return _INC;}

"<"                  { yylval.i = LT; return _RELOP; }
">"                  { yylval.i = GT; return _RELOP; }
"<="                 { yylval.i = LE; return _RELOP; }
">="                 { yylval.i = GE; return _RELOP; }
"=="                 { yylval.i = EQ; return _RELOP; }
"!="                 { yylval.i = NE; return _RELOP; }

[a-zA-Z][a-zA-Z0-9]* { yylval.s = strdup(yytext); 
                       return _ID; }
[+-]?[0-9]{1,10}     { yylval.s = strdup(yytext); 
                       return _INT_NUMBER;}
[0-9]{1,10}[uU]      { yylval.s = strdup(yytext); 
                       yylval.s[yyleng-1] = 0;
                       return _UINT_NUMBER;}

\/\/.*               { /* skip single line coments (//) */ }

"/*"([^*]|"\n"|(\*+([^*/]|"\n")))*"*"+"/" { /* skip multi line coments (//) */ }

.                    { printf("line %d: LEXICAL ERROR on char %c\n"
                        , yylineno, *yytext);}

%%
