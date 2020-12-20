%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "defs.h"
  #include "symtab.h"

  int yyparse(void);
  int yylex(void);
  int yyerror(char *s);
  void warning(char *s);

  extern int yylineno;
  char char_buffer[CHAR_BUFFER_LENGTH];
  int error_count = 0;
  int warning_count = 0;
  int var_num = 0;
  
  int fun_idx = -1;
  int fcall_idx = -1;
  int fun_args[100];
  int par_num = 0;
  int arg_num = 0;
  
  int tip = 0;
  
  int return_exist = 0;
  
  int jiro_num = 0;
%}

%union {
  int i;
  char *s;
}

%token <i> _TYPE
%token _IF
%token _ELSE
%token _RETURN
%token <s> _ID
%token <s> _INT_NUMBER
%token <s> _UINT_NUMBER
%token _LPAREN
%token _RPAREN
%token _LBRACKET
%token _RBRACKET
%token _LSBRAC
%token _RSBRAC
%token _ASSIGN
%token _SEMICOLON
%token <i> _AROP
%token <i> _RELOP
%token _COMMA
%token _INC
%token _FOR
%token _JIRO
%token _TRANGA
%token _ARROW
%token _FINISH
%token _TOERANA
%token <i> _MDOP

%type <i> num_exp exp literal function_call rel_exp argument_list
			 tranga_lit tranga tranga_list

%nonassoc ONLY_IF
%nonassoc _ELSE

%left _AROP
%left _MDOP

%%

program
  : function_list
  		{  
        if(lookup_symbol("main", FUN) == NO_INDEX)
          err("undefined reference to 'main'");
      }
  ;

function_list
  : function
  | function_list function
  ;

function
  : _TYPE _ID
      {
        fun_idx = lookup_symbol($2, FUN);
        if(fun_idx == NO_INDEX) {
          fun_idx = insert_symbol($2, FUN, $1, NO_ATR, par_num + 1);
        }
        else 
          err("redefinition of function '%s'", $2);
      }
    _LPAREN parameter_list _RPAREN body
      {
        clear_symbols(fun_idx + 1);
        var_num = 0;
      }
  ;

parameter_list
  : /* empty */
      { set_atr1(fun_idx, 0); set_atr2(fun_idx, NO_ATR); }
  | parameters
  ;

parameters
  : parameter
  | parameters _COMMA parameter
  ;

parameter
  : _TYPE _ID
      {
      	if ($1 == VOID)
  	  			err("invalid use of type 'void' in parameter declaration");
			insert_symbol($2, PAR, $1, ++par_num, NO_ATR);
			set_atr1(fun_idx, par_num);
			fun_args[par_num] = $1;
      }
  ;

body
  : _LBRACKET variable_list statement_list _RBRACKET
  		{
  			if (return_exist == 0 && get_type(fun_idx) != VOID) {
  				warning("no return_statement in function");
  			}
  			return_exist = 0;
  		}
  ;

variable_list
  : /* empty */
  | variable_list variable
  ;

variable
  : _TYPE { tip = $1; } vars _SEMICOLON
      {
     		if (tip == VOID)
  	  			err("invalid use of type 'void' in variable declaration");
      }
  ;
  
vars
  : var_assig
  | vars _COMMA var_assig
  ;
  
var_assig
  : _ID
      {	
        if(lookup_symbol($1, VAR|PAR) == NO_INDEX)
           insert_symbol($1, VAR, tip, ++var_num, NO_ATR);
        else 
           err("redefinition of '%s'", $1);
      }
  | _ID _ASSIGN num_exp
   	{
        if(lookup_symbol($1, VAR|PAR) == NO_INDEX) {
           insert_symbol($1, VAR, tip, ++var_num, NO_ATR);
			  if(tip != get_type($3))
		         err("incompatible types in assignment");
		  }
        else 
           err("redefinition of '%s'", $1);
      }
  ;

statement_list
  : /* empty */
  | statement_list statement
  ;

statement
  : compound_statement
  | assignment_statement
  | increment_statement
  | if_statement
  | for_statement
  | jiro_statement
  | fun_call_statement
  | return_statement
  ;

compound_statement
  : _LBRACKET statement_list _RBRACKET
  ;

assignment_statement
  : _ID _ASSIGN num_exp _SEMICOLON
      {
        int idx = lookup_symbol($1, VAR|PAR);
        if(idx == NO_INDEX)
          err("invalid lvalue '%s' in assignment", $1);
        else
          if(get_type(idx) != get_type($3))
            err("incompatible types in assignment");
      }
  ;
  
increment_statement
  : _ID _INC _SEMICOLON
      {
        int idx;
        idx = lookup_symbol($1, FUN);
        if (idx != NO_INDEX)
        	 err("'%s' function can not be incremented", $1);
        else {
		     idx = lookup_symbol($1, VAR|PAR);
		     if(idx == NO_INDEX)
		       err("'%s' undeclared", $1);
		  }
      }
  ;

num_exp
  : exp
  | num_exp op exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: arithmetic operation");
      }
  ;
  
op
  : _AROP
  | _MDOP
  ;

exp
  : literal
  | _ID
      {
        $$ = lookup_symbol($1, VAR|PAR);
        if($$ == NO_INDEX)
          err("'%s' undeclared", $1);
      }
  | _ID _INC
  	  {
  	  	  int idx;
        idx = lookup_symbol($1, FUN);
        if (idx != NO_INDEX)
        	 err("'%s' function can not be incremented", $1);
        else {
		     $$ = lookup_symbol($1, VAR|PAR);
		     if($$ == NO_INDEX)
		     	err("'%s' undeclared", $1);
		  }
      }
  | function_call
  | _LPAREN num_exp _RPAREN
      { $$ = $2; }
  ;

literal
  : _INT_NUMBER
      { $$ = insert_literal($1, INT); }

  | _UINT_NUMBER
      { $$ = insert_literal($1, UINT); }
  ;

function_call
  : _ID 
      {
        fcall_idx = lookup_symbol($1, FUN);
        if(fcall_idx == NO_INDEX)
          err("'%s' is not a function", $1);
      }
    _LPAREN argument_list _RPAREN
      {
        if(get_atr1(fcall_idx) - get_atr2(fcall_idx) + 1 != $4)
		     if (get_atr1(fcall_idx) != 0)
		       err("wrong number of args to function '%s'", 
		           get_name(fcall_idx));
        set_type(FUN_REG, get_type(fcall_idx));
        $$ = FUN_REG;
        arg_num = 0;
      }
  ;
  
fun_call_statement
  : function_call _SEMICOLON
  ;

argument_list
	: /* empty */
		{ $$ = 0; }
	| arguments
		{ $$ = arg_num; }
	;

arguments
	: argument
	| arguments _COMMA argument
	;

argument
  : num_exp
    {
    	int i = get_atr2(fcall_idx) + arg_num;
    	if (fun_args[i] != get_type($1))
		 	err("incompatible type for argument in '%s'",
		      get_name(fcall_idx));
      ++arg_num;
    }
  ;

if_statement
  : if_part %prec ONLY_IF
  | if_part _ELSE statement
  ;

if_part
  : _IF _LPAREN rel_exp _RPAREN statement
  ;

rel_exp
  : num_exp _RELOP num_exp
      {
      	if(get_type($1) != get_type($3))
      		err("invalid operands: relational operator");
      }
  ;
  
for_statement
  : _FOR _LPAREN _TYPE _ID _ASSIGN literal
  		{
  		  if($3 != get_type($6))
  		  		err("incompatible types in assignment");
  		  $<i>$ = insert_symbol($4, VAR, $3, NO_ATR, NO_ATR);
      }
   _SEMICOLON rel_exp _SEMICOLON literal 
   	{
   		if($3 != get_type($11))
  		  		err("incompatible types in assignment");
  		  	if (atoi(get_name($11)) == 0)
   			err("invalid literal, the step must be nonzero value");
   	}
   _RPAREN statement
   	{
   		clear_symbols($<i>7 - 1);
   	}
  ;
  
jiro_statement
  : _JIRO _LSBRAC _ID
  		{ 
  			int idx = lookup_symbol($3, VAR|PAR);
  			if (idx == NO_INDEX)
  				err("'%s' undeclared", $3);
  			$<i>$ = get_last_element();
  			jiro_num++;
  		}
    _RSBRAC _LBRACKET tranga_list toerana _RBRACKET
  		{
  			int idx = lookup_symbol($3, VAR|PAR);
  			if (get_type(idx) != $7) {
  				err("incompatible types in <jiro_expression>");
  			}
  			jiro_num--;
  			clear_symbols($<i>4 + 1);
  		}
  ;
  
tranga_list
  : tranga
  		{
  			$$ = $1;
  		}
  | tranga_list tranga
  		{
  			$$ = $1;
  			if ($1 != $2) {
  				err("incompatible type in <constant_expression>");
  			}
  		}
  ;
  
tranga
  : _TRANGA tranga_lit _ARROW statement finish
  		{
  			$$ = $2;
  		}
  ;
  
tranga_lit
  : _INT_NUMBER
  		{
  			int idx = lookup_symbol($1, LIT);
  			if(idx == NO_INDEX)
  				insert_symbol($1, LIT, INT, NO_ATR, jiro_num);
         else if (get_atr2(idx) != jiro_num)
         	insert_symbol($1, LIT, INT, NO_ATR, jiro_num);
         else 
           err("invalid literal, constant %s is not unique value", $1);
         $$ = INT;
  		}
  | _UINT_NUMBER
  		{
  			int idx = lookup_symbol($1, LIT);
  			if(idx == NO_INDEX)
  				insert_symbol($1, LIT, UINT, NO_ATR, jiro_num);
         else if (get_atr2(idx) != jiro_num)
         	insert_symbol($1, LIT, UINT, NO_ATR, jiro_num);
         else 
         	err("invalid literal, constant %s is not unique value", $1);
         $$ = UINT;
  		}
  ;
  
finish
  : /* empty */
  | _FINISH _SEMICOLON
  ;
  
toerana
  : /* empty */
  | _TOERANA _ARROW statement
  ;

return_statement
  : _RETURN _SEMICOLON
		{
			if(get_type(fun_idx) != VOID)
      		warning("return_statement with no value, in function returning value");
      	return_exist = 1;
		}
  | _RETURN num_exp _SEMICOLON
      {
      	if(get_type(fun_idx) == VOID)
      		err("return_statement with a value, in void function");
      	else if(get_type(fun_idx) != get_type($2))
         	err("incompatible types in return");
         return_exist = 1;
      }
  ;

%%

int yyerror(char *s) {
  fprintf(stderr, "\nline %d: ERROR: %s", yylineno, s);
  error_count++;
  return 0;
}

void warning(char *s) {
  fprintf(stderr, "\nline %d: WARNING: %s", yylineno, s);
  warning_count++;
}

int main() {
  int synerr;
  init_symtab();

  synerr = yyparse();

  clear_symtab();
  
  if(warning_count)
    printf("\n%d warning(s).\n", warning_count);

  if(error_count)
    printf("\n%d error(s).\n", error_count);

  if(synerr)
    return -1; //syntax error
  else
    return error_count; //semantic errors
}

