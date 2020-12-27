%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "defs.h"
  #include "symtab.h"
  #include "codegen.h"

  int yyparse(void);
  int yylex(void);
  int yyerror(char *s);
  void warning(char *s);

  extern int yylineno;
  int out_lin = 0;
  char char_buffer[CHAR_BUFFER_LENGTH];
  int error_count = 0;
  int warning_count = 0;
  int var_num = 0;
  
  int fun_idx = -1;
  int fcall_idx = -1;
  int fun_args[100];
  int par_num = 0;
  int par_in_f = 0;
  int arg_num = 0;
  
  int tip = 0;
  
  int return_exist = 0;
  
  int lab_num = -1;
  int ternarni_lab_num = -1;
  int for_lab_num = -1;
  
  int jiro_lab_num = 0;
  int jiro_num = 0;
  int jiro_idx[100]; 
  
  FILE *output;
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
%token _COLON
%token <i> _AROP
%token <i> _RELOP
%token _COMMA
%token _QMARK
%token _INC
%token _FOR
%token _JIRO
%token _TRANGA
%token _ARROW
%token _FINISH
%token _TOERANA
%token <i> _MDOP

%type <i> num_exp mul_exp exp literal
%type <i> function_call argument argument_list rel_exp if_part
%type <i> tranga_lit
%type <i> ternarni_operator exp_var_const

%nonassoc ONLY_IF
%nonassoc _ELSE

%%

program
  : global_variable_list function_list
      {  
        if (lookup_symbol("main", FUN) == NO_INDEX)
          err("undefined reference to 'main'");
      }
  ;

global_variable_list
  : /* empty */
  | global_variable_list global_variable
  ;

global_variable
  : _TYPE _ID _SEMICOLON
      {
        if (lookup_symbol($2, GVAR) == NO_INDEX) {
           insert_symbol($2, GVAR, $1, NO_ATR, NO_ATR);
           code("\n%s:", $2);
           code("\n\t\tWORD\t1");
        }
        else 
           err("redefinition of global '%s'", $2);
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
        if (fun_idx == NO_INDEX)
          fun_idx = insert_symbol($2, FUN, $1, NO_ATR, par_num + 1);
        else 
          err("redefinition of function '%s'", $2);

        code("\n%s:", $2);
        code("\n\t\tPUSH\t%%14");
        code("\n\t\tMOV \t%%15,%%14");
      }
    _LPAREN parameter_list _RPAREN body
      {
        clear_symbols(fun_idx + 1);
        var_num = 0;
        par_in_f = 0;
        
        code("\n@%s_exit:", $2);
        code("\n\t\tMOV \t%%14,%%15");
        code("\n\t\tPOP \t%%14");
        code("\n\t\tRET");
      }
  ;

parameter_list
  : /* empty */
      { 
        set_atr1(fun_idx, 0);
        set_atr2(fun_idx, NO_ATR);
      }
  | parameters
  ;

parameters
  : parameter
  | parameters _COMMA parameter
  ;

parameter
  : _TYPE _ID
      {
        if ($1 == VOID) {
          err("invalid use of type 'void' in parameter declaration");
        }
        insert_symbol($2, PAR, $1, ++par_in_f, NO_ATR);
        ++par_num;
        set_atr1(fun_idx, par_num);
        fun_args[par_num] = $1;
      }
  ;

body
  : _LBRACKET variable_list
      {
        if (var_num) {
          code("\n\t\tSUBS\t%%15,$%d,%%15", 4*var_num);
        }
        code("\n@%s_body:", get_name(fun_idx));
      }
    statement_list _RBRACKET
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
        if (tip == VOID){
          err("invalid use of type 'void' in variable declaration");
        }
      }
  ;
  
vars
  : var_assig
  | vars _COMMA var_assig
  ;

var_assig
  : _ID
      {	
        if (lookup_symbol($1, VAR|PAR) == NO_INDEX)
          insert_symbol($1, VAR, tip, ++var_num, NO_ATR);
        else 
         err("redefinition of '%s'", $1);
      }
  | _ID _ASSIGN num_exp
      {
        int idx;
        if (lookup_symbol($1, VAR|PAR) == NO_INDEX) {
          idx = insert_symbol($1, VAR, tip, ++var_num, NO_ATR);
          if (tip != get_type($3)) {
            err("incompatible types in assignment");
          }
        } else {
          err("redefinition of '%s'", $1);
        }
        gen_mov($3, idx);
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
        int idx = lookup_symbol($1, VAR|PAR|GVAR);
        if (idx == NO_INDEX) {
          err("invalid lvalue '%s' in assignment", $1);
        }
        else {
          if (get_type(idx) != get_type($3)) {
            err("incompatible types in assignment");
          }
        }
        for (int i = 0; i < SYMBOL_TABLE_LENGTH; i++) {
          if (get_atr2(i) == 5 && get_kind(i) != LIT) {
            int t1 = get_type(i);    
            code("\n\t\t%s\t", ar_instructions[0 + (t1 - 1) * AROP_NUMBER]);
            gen_sym_name(i);
            code(",");
            code("$1");
            code(",");
            gen_sym_name(i);
            free_if_reg(i);
            set_atr2(i, NO_ATR);
          }
        }
        gen_mov($3, idx);
      }
  ;
  
increment_statement
  : _ID _INC _SEMICOLON
      {
        int idx;
        idx = lookup_symbol($1, FUN);
        if (idx != NO_INDEX) {
          err("'%s' function can not be incremented", $1);
        }
        else {
         idx = lookup_symbol($1, VAR|PAR|GVAR);
         if (idx == NO_INDEX) {
           err("'%s' undeclared", $1);
         }
        }
        int t1 = get_type(idx);    
        code("\n\t\t%s\t", ar_instructions[0 + (t1 - 1) * AROP_NUMBER]);
        gen_sym_name(idx);
        code(",");
        code("$1");
        code(",");
        gen_sym_name(idx);
        free_if_reg(idx);
      }
  ;

num_exp
  : mul_exp
  | num_exp _AROP mul_exp
      {
        if (get_type($1) != get_type($3)) {
          err("invalid operands: arithmetic operation");
        } else {
          int t1 = get_type($1);    
          code("\n\t\t%s\t", ar_instructions[$2 + (t1 - 1) * AROP_NUMBER]);
          gen_sym_name($1);
          code(",");
          gen_sym_name($3);
          code(",");
          free_if_reg($3);
          free_if_reg($1);
          $$ = take_reg();
          gen_sym_name($$);
          set_type($$, t1);
        }
      }
  ;

mul_exp
  : exp
  | mul_exp _MDOP exp
      {
        if (get_type($1) != get_type($3)) {
          err("invalid operands: arithmetic operation");
        } else {
          int t1 = get_type($1);    
          code("\n\t\t%s\t", ar_instructions[$2 + (t1 - 1) * AROP_NUMBER]);
          gen_sym_name($1);
          code(",");
          gen_sym_name($3);
          code(",");
          free_if_reg($3);
          free_if_reg($1);
          $$ = take_reg();
          gen_sym_name($$);
          set_type($$, t1);
        }
      }
  ;

exp
  : literal
  | _ID
      {
        $$ = lookup_symbol($1, VAR|PAR|GVAR);
        if ($$ == NO_INDEX) {
          err("'%s' undeclared", $1);
        }
      }
  | _ID _INC
      {
        int idx;
        idx = lookup_symbol($1, FUN);
        if (idx != NO_INDEX) {
          err("'%s' function can not be incremented", $1);
        }
        else {
         $$ = lookup_symbol($1, VAR|PAR|GVAR);
         if ($$ == NO_INDEX) {
           err("'%s' undeclared", $1);
         }
        }
        set_atr2($$, 5);
      }
  | function_call
      {
        $$ = take_reg();
        gen_mov(FUN_REG, $$);
      }
  | _LPAREN num_exp _RPAREN
      { $$ = $2; }
  | ternarni_operator
      { $$ = $1; }
  ;

ternarni_operator
  : _LPAREN rel_exp
      {
        $<i>$ = ++ternarni_lab_num  ;
        code("\n@ternarni%d:", ternarni_lab_num);
        code("\n\t\t%s\t@ternarni_false%d", opp_jumps[$2], $<i>$);
        code("\n@ternarni_true%d:", $<i>$);
      }
    _RPAREN _QMARK exp_var_const
      {
        $<i>$ = take_reg();
        gen_mov($6, $<i>$);
        code("\n\t\tJMP \t@ternarni_exit%d", $<i>3);
        code("\n@ternarni_false%d:", $<i>3);
      }
     _COLON exp_var_const
      { 
        gen_mov($9, $<i>7);
        if (get_type($6) != get_type($9)) {
          err("incompatible type in conditional exp");
        }
        code("\n@ternarni_exit%d:", $<i>3);
        $$ = $<i>7;
      }
  ;

exp_var_const
  : literal
      {
        $$ = $1;
      }
  | _ID
      {
        $$ = lookup_symbol($1, VAR|PAR|GVAR);
        if ($$ == NO_INDEX) {
          err("'%s' undeclared", $1);
        }
      }
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
        if (fcall_idx == NO_INDEX) {
          err("'%s' is not a function", $1);
        }
      }
    _LPAREN argument_list _RPAREN
      {
        if (get_atr1(fcall_idx) - get_atr2(fcall_idx) + 1 != $4) {
          if (get_atr1(fcall_idx) != 0) {
            err("wrong number of args to function '%s'",
              get_name(fcall_idx));
          }
        }
        code("\n\t\t\tCALL\t%s", get_name(fcall_idx));
        if ($4 > 0) {
          code("\n\t\t\tADDS\t%%15,$%d,%%15", $4 * 4);
        }
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
        if (fun_args[i] != get_type($1)) {
          err("incompatible type for argument in '%s'",
          get_name(fcall_idx));
        }
        ++arg_num;
        free_if_reg($1);
        code("\n\t\t\tPUSH\t");
        gen_sym_name($1);
      }
  ;

if_statement
  : if_part %prec ONLY_IF
      { code("\n@exit%d:", $1); }

  | if_part _ELSE statement
      { code("\n@exit%d:", $1); }
  ;

if_part
  : _IF _LPAREN
      {
        $<i>$ = ++lab_num;
        code("\n@if%d:", lab_num);
      }
    rel_exp
      {
        code("\n\t\t%s\t@false%d", opp_jumps[$4], $<i>3); 
        code("\n@true%d:", $<i>3);
      }
    _RPAREN statement
      {
        code("\n\t\tJMP \t@exit%d", $<i>3);
        code("\n@false%d:", $<i>3);
        $$ = $<i>3;
      }
  ;

rel_exp
  : num_exp _RELOP num_exp
      {
        if (get_type($1) != get_type($3)) {
          err("invalid operands: relational operator");
        }
        $$ = $2 + ((get_type($1) - 1) * RELOP_NUMBER);
        gen_cmp($1, $3);
      }
  ;

for_statement
  : _FOR _LPAREN 
      {
        $<i>$ = ++for_lab_num;
      }
   _TYPE _ID _ASSIGN literal
      {
        if ($4 != get_type($7)) {
          err("incompatible types in assignment");
        }
        $<i>$ = insert_symbol($5, VAR, $4, NO_ATR, NO_ATR);
        gen_mov($7, $<i>$);
        code("\n@for%d:", $<i>3);
      }
   _SEMICOLON rel_exp _SEMICOLON literal
      {
        if ($4 != get_type($12)) {
          err("incompatible types in assignment");
        }
        if (atoi(get_name($12)) == 0) {
          err("invalid literal, the step must be nonzero value");
        }
        code("\n\t\t%s\t@for_exit%d", opp_jumps[$10], $<i>3); 
        code("\n@for_true%d:", $<i>3);
      }
   _RPAREN statement
      {
        int t1 = get_type($<i>8);    
        code("\n\t\t%s\t", ar_instructions[0 + (t1 - 1) * AROP_NUMBER]);
        gen_sym_name($<i>8);
        code(",");
        gen_sym_name($12);
        code(",");
        gen_sym_name($<i>8);
        free_if_reg($<i>8);
        code("\n\t\tJMP \t@for%d", $<i>3);
        code("\n@for_exit%d:", $<i>3);
        clear_symbols($<i>8 - 1);
      }
  ;
  
jiro_statement
  : _JIRO _LSBRAC 
      {
        $<i>$ = ++jiro_lab_num;
        ++jiro_num;
        code("\n@jiro%d:", jiro_lab_num);
        code("\n\t\tJMP \t@jiro_compare%d", jiro_lab_num);
      }
    _ID
      {
        int idx = lookup_symbol($4, VAR|PAR|GVAR);
        if (idx == NO_INDEX) {
          err("'%s' undeclared", $4);
        }
        jiro_idx[jiro_num] = idx;
        set_atr2(idx, $<i>3);
        $<i>$ = get_last_element();
      }
    _RSBRAC _LBRACKET tranga_list 
      {
        code("\n@tranga_exit%d:", $<i>3);
        code("\n\t\tJMP \t@jiro_exit%d", $<i>3); 
      }
    toerana _RBRACKET
      {
        int idx = lookup_symbol($4, VAR|PAR|GVAR);
        //if (get_type(idx) != get_type($8)) {
        //  err("incompatible types in <jiro_expression>");
        //}
        code("\n@jiro_compare%d:", $<i>3);
        for (int i = 0; i < SYMBOL_TABLE_LENGTH; i++) {
          if (get_atr2(i) == $<i>3 && get_kind(i) == LIT) {
            gen_cmp(idx, i);
            code("\n\t\tJEQ \t@tranga%d_%s", $<i>3, get_name(i));
          }
        }
        code("\n\t\tJMP \t@toerana%d", $<i>3);
        code("\n@jiro_exit%d:", $<i>3);
        
        set_atr2(idx, NO_ATR);
        jiro_num--;
        clear_symbols($<i>5 + 1);
      }
  ;
  
tranga_list
  : tranga
  | tranga_list tranga
  ;
  
tranga
  : _TRANGA tranga_lit 
      {
        code("\n@tranga%d_%s:", get_atr2(jiro_idx[jiro_num]), get_name($2));
      }
    _ARROW statement finish
  ;
  
tranga_lit
  : _INT_NUMBER
      {
        int idx = lookup_symbol($1, LIT);
        if (get_type(jiro_idx[jiro_num]) != INT) {
          err("incompatible types of jiro const %s", $1);
        }
        if (idx == NO_INDEX) {
          $$ = insert_symbol($1, LIT, INT, NO_ATR, get_atr2(jiro_idx[jiro_num]));
        }
        else if (get_atr2(idx) != get_atr2(jiro_idx[jiro_num])) {
          $$ = insert_symbol($1, LIT, INT, NO_ATR, get_atr2(jiro_idx[jiro_num]));
        }
        else {
          err("invalid literal, constant %s is not unique value", $1);
        }
      }
  | _UINT_NUMBER
      {
        int idx = lookup_symbol($1, LIT);
        if (get_type(jiro_idx[jiro_num]) != UINT) {
          err("incompatible types of jiro const %s", $1);
        }
        if (idx == NO_INDEX) {
          $$ = insert_symbol($1, LIT, UINT, NO_ATR, get_atr2(jiro_idx[jiro_num]));
        }
        else if (get_atr2(idx) != get_atr2(jiro_idx[jiro_num])) {
          $$ = insert_symbol($1, LIT, UINT, NO_ATR, get_atr2(jiro_idx[jiro_num]));
        }
        else {
          err("invalid literal, constant %s is not unique value", $1);
        }
      }
  ;
  
finish
  : /* empty */
  | _FINISH _SEMICOLON
      {
        code("\n\t\tJMP \t@tranga_exit%d", get_atr2(jiro_idx[jiro_num]));
      }
  ;
  
toerana
  : /* empty */
  | _TOERANA _ARROW 
      {
        code("\n@toerana%d:", get_atr2(jiro_idx[jiro_num]));
      }
  statement
      {
        code("\n\t\tJMP \t@jiro_exit%d", get_atr2(jiro_idx[jiro_num]));
      }
  ;

return_statement
  : _RETURN _SEMICOLON
      {
        if (get_type(fun_idx) != VOID) {
          warning("return_statement with no value, in function returning value");
        }
        return_exist = 1;
        code("\n\t\tJMP \t@%s_exit", get_name(fun_idx));
      }
  | _RETURN num_exp _SEMICOLON
      {
        if (get_type(fun_idx) == VOID) {
          err("return_statement with a value, in void function");
        }
        else if (get_type(fun_idx) != get_type($2)) {
          err("incompatible types in return");
        }
        return_exist = 1;
        gen_mov($2, FUN_REG);
        code("\n\t\tJMP \t@%s_exit", get_name(fun_idx));        
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
  output = fopen("output.asm", "w+");

  synerr = yyparse();

  clear_symtab();
  fclose(output);
  
  if (warning_count)
    printf("\n%d warning(s).\n", warning_count);

  if (error_count) {
    remove("output.asm");
    printf("\n%d error(s).\n", error_count);
  }

  if (synerr)
    return -1;  //syntax error
  else if (error_count)
    return error_count & 127; //semantic errors
  else if (warning_count)
    return (warning_count & 127) + 127; //warnings
  else
    return 0; //OK
}

