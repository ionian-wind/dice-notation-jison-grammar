/* lexical grammar */
%lex

%%
\s+                                             /* skip whitespace */
[0-9]+                                          return 'INTEGER';
\:([a-z0-9_]+)\:                                return 'MACRO';

"raise"                                         return 'CRAISE';
"dice"                                          return 'CDICE';
"round"                                         return 'CROUND';
"near"                                          return 'ROUNDNEAR';
"down"                                          return 'ROUNDDOWN';

"D"                                             return 'DROP';
"K"                                             return 'KEEP';
"DL"                                            return 'DROP_L';
"KL"                                            return 'KEEP_L';
"DH"                                            return 'DROP_H';
"KH"                                            return 'KEEP_H';

[d]                                             return 'SIMPLE_DICE';
[F]                                             return 'FATE_DICE';

[c]                                             return 'COUNT';
[f]                                             return 'FAILURE';

"!!"                                            return 'COMPOUND';
"!p"                                            return 'PENETRATE';
"!"                                             return 'EXPLODE';
[r]                                             return 'REROLL';

"*"                                             return '*';
"/"                                             return '/';
"-"                                             return '-';
"+"                                             return '+';

"("                                             return '(';
")"                                             return ')';

"["                                             return '[';
"]"                                             return ']';

"{"                                             return '{';
"}"                                             return '}';

">"                                             return 'GT';
">="                                            return 'GTE';
"<"                                             return 'LT';
"<="                                            return 'LTE';
"="                                             return 'EQ';

","                                             return 'COMMA';
"%"                                             return '%';


<<EOF>>                                         return 'EOF';

/lex

/* operator associations and precedence */

%left '+' '-'
%left '*' '/'
%right SIMPLE_DICE FATE_DICE WILD_DICE
%left REROLL DROP KEEP DROP_L KEEP_L DROP_H KEEP_H
%left COMPOUND PENETRATE EXPLODE
%left COUNT
%left COMMA

%start result

%% /* language grammar */

release_macro
    : MACRO                                     { $$ = 'yy.deserialize(yy.MACRO.get(\'' + $1 + '\'))' }
    ;

check_content
    : INTEGER                                   { $$ = [$1] }
    | check_content COMMA INTEGER               { $$ = $1.push($3); $$ = $1 }
    ;

check
    : INTEGER GT INTEGER                        { $$ = 'new yy.Check(yy.C.GT, ' + $3 + ', ' + $1 + ')' }
    | GT INTEGER                                { $$ = 'new yy.Check(yy.C.GT, ' + $2 + ', null)' }

    | INTEGER GTE INTEGER                       { $$ = 'new yy.Check(yy.C.GTE, ' + $3 + ', ' + $1 + ')' }
    | GTE INTEGER                               { $$ = 'new yy.Check(yy.C.GTE, ' + $2 + ', null)' }

    | INTEGER LT INTEGER                        { $$ = 'new yy.Check(yy.C.LT, ' + $3 + ', ' + $1 + ')' }
    | LT INTEGER                                { $$ = 'new yy.Check(yy.C.LT, ' + $2 + ', null)' }

    | INTEGER LTE INTEGER                       { $$ = 'new yy.Check(yy.C.LTE, ' + $3 + ', ' + $1 + ')' }
    | LTE INTEGER                               { $$ = 'new yy.Check(yy.C.LTE, ' + $2 + ', null)' }

    | INTEGER EQ INTEGER                        { $$ = 'new yy.Check(yy.C.EQ, ' + $3 + ', ' + $1 + ')' }
    | EQ INTEGER                                { $$ = 'new yy.Check(yy.C.EQ, ' + $2 + ', null)' }

    | INTEGER EQ '[' check_content ']'          { $$ = 'new yy.Check(yy.C.EQ, [' + $4.join(',') + '], ' + $1 + ')' }
    | EQ '[' check_content ']'                  { $$ = 'new yy.Check(yy.C.EQ, [' + $3.join(',') + '], null)' }
    ;

dice
    : SIMPLE_DICE group_or_int                  { $$ = '(new yy.Dice(new yy.Number(1), ' + $2 + '))' }
    | SIMPLE_DICE '%'                           { $$ = '(new yy.Dice(new yy.Number(1), new yy.Number(100)))' }
    | SIMPLE_DICE                               { $$ = '(new yy.Dice(new yy.Number(1), new yy.Number(yy.CFG.get(\'dice\'))))' }
    | FATE_DICE INTEGER                         { $$ = '(new yy.Dice(' + $2 + '.neg(), ' + $2 + '))' }
    | FATE_DICE                                 { $$ = '(new yy.Dice((new yy.Number(1)).neg(), new yy.Number(1)))' }
    ;

dice_roll
    : dice                                      { $$ = $1 + '.roll(1)' }
    | group_or_int dice                         { $$ = $2 + '.roll(' + $1 + ')' }
    ;

dice_reroll
    : dice_roll                                 { $$ = $1 }
    | dice_roll REROLL check                    { $$ = $1 + '.reroll(' + $3 + ')' }
    ;

roll
    : dice_reroll COMPOUND check                { $$ = $1 + '.compound(' + $2 + ')' }
    | dice_reroll COMPOUND                      { $$ = $1 + '.compound(null)' }
    | dice_reroll PENETRATE check               { $$ = $1 + '.penetrate(' + $2 + ')' }
    | dice_reroll PENETRATE                     { $$ = $1 + '.penetrate(null)' }
    | dice_reroll EXPLODE check                 { $$ = $1 + '.explode(' + $2 + ')' }
    | dice_reroll EXPLODE                       { $$ = $1 + '.explode(null)' }
    | dice_reroll                               { $$ = $1 }
    ;

drop_keep
    : roll DROP INTEGER                         { $$ = $1 + '.drop(new yy.Check(yy.C.LOWEST, null, ' + $3 + '))' }
    | roll DROP check                           { $$ = $1 + '.drop(' + $3 + ')' }
    | roll DROP                                 { $$ = $1 + '.drop(new yy.Check(yy.C.LOWEST, null, null))' }
    | roll DROP_L                               { $$ = $1 + '.drop(new yy.Check(yy.C.LOWEST, null, null))' }
    | roll DROP_L INTEGER                       { $$ = $1 + '.drop(new yy.Check(yy.C.LOWEST, null, ' + $3 + '))' }
    | roll DROP_H                               { $$ = $1 + '.drop(new yy.Check(yy.C.HIGHEST, null, null))' }
    | roll DROP_H INTEGER                       { $$ = $1 + '.drop(new yy.Check(yy.C.HIGHEST, null, ' + $3 + '))' }
    | roll KEEP INTEGER                         { $$ = $1 + '.keep(new yy.Check(yy.C.LOWEST, null, ' + $3 + '))' }
    | roll KEEP check                           { $$ = $1 + '.keep(' + $3 + ')' }
    | roll KEEP_L                               { $$ = $1 + '.keep(new yy.Check(yy.C.LOWEST, null, null))' }
    | roll KEEP_L INTEGER                       { $$ = $1 + '.keep(new yy.Check(yy.C.LOWEST, null, ' + $3 + '))' }
    | roll KEEP_H                               { $$ = $1 + '.keep(new yy.Check(yy.C.HIGHEST, null, null))' }
    | roll KEEP                                 { $$ = $1 + '.keep(new yy.Check(yy.C.HIGHEST, null, null))' }
    | roll KEEP_H INTEGER                       { $$ = $1 + '.keep(new yy.Check(yy.C.HIGHEST, null, ' + $3 + '))' }
    ;

concat_entry
    : group_or_int                              { $$ = $1 }
    | roll                                      { $$ = $1 }
    | drop_keep                                 { $$ = $1 }
    | repeatable                                { $$ = $1 }
    ;

concated_inner
    : concat_entry                              { $$ = '.add(' + $1 + ')' }
    | concated_inner COMMA concat_entry         { $$ = $1 + '.add(' + $3 + ')' }
    ;

concated_expr
    : '[' concated_inner ']'                    { $$ = '(new yy.Pool())' + $2 }
    ;

concated_drop_keep
    : concated_expr DL INTEGER                  { $$ = $1 + '.drop(yy.C.LOWEST,' + $3 + ')' }
    | concated_expr DL                          { $$ = $1 + '.drop(yy.C.LOWEST)' }

    | concated_expr DH INTEGER                  { $$ = $1 + '.drop(yy.C.HIGHEST,' + $3 + ')' }
    | concated_expr DH                          { $$ = $1 + '.drop(yy.C.HIGHEST)' }

    | concated_expr KL INTEGER                  { $$ = $1 + '.keep(yy.C.LOWEST,' + $3 + ')' }
    | concated_expr KL                          { $$ = $1 + '.keep(yy.C.LOWEST)' }

    | concated_expr KH INTEGER                  { $$ = $1 + '.keep(yy.C.HIGHEST,' + $3 + ')' }
    | concated_expr KH                          { $$ = $1 + '.keep(yy.C.HIGHEST)' }
    ;

group_or_int
    : INTEGER                                   { $$ = '(new yy.Number(' + yytext + '))' }
    | '(' expression ')'                        { $$ = '(' + $2 + ')' }
    ;

repeatable
    : '{' expression '}' INTEGER                { $$ = $2 + '.repeat(' + $4 + ')' }
    ;

expression
    : expression '+' expression                 { $$ = $1 + '.sum(' + $3 + ')' }
    | expression '-' expression                 { $$ = $1 + '.sub(' + $3 + ')' }
    | expression '*' expression                 { $$ = $1 + '.mul(' + $3 + ')' }
    | expression '/' expression                 { $$ = $1 + '.div(' + $3 + ', yy.CFG.get(\'round\'))' }
    | concat_entry                              { $$ = $1 }
/*  | '-' expression %prec UMINUS               { $$ = $2 + '.neg()' } */
    ;

expressions
    : concated_expr                             { $$ = $1 }
    | concated_drop_keep                        { $$ = $1 }
    | expression                                { $$ = $1 }
    ;

macro_define
    : macro_define COMMA macro_entry            { $$ = $1 + ' && ' + $3 }
    | macro_entry                               { $$ = $1 }
    ;

macross
    : '{' macro_define '}'                      { $$ = $2 }
    ;

cfg_entry
    : CROUND EQ ROUNDNEAR                       { $$ = 'yy.CFG.set(\'round\', \'near\')' }
    | CROUND EQ ROUNDDOWN                       { $$ = 'yy.CFG.set(\'round\', \'down\')' }
    | CRAISE EQ INTEGER                         { $$ = 'yy.CFG.set(\'raise\', ' + $2 + ')' }
    | CDICE EQ INTEGER                          { $$ = 'yy.CFG.set(\'dice\', ' + $2 + ')' }
    | MACRO EQ expressions                      { $$ = 'yy.MACRO.set(\'' + $1 + '\', ' + $3 + '.serialize())' }
    ;

cfg_inner
    : cfg_inner COMMA cfg_entry                 { $$ = $1 + ' && ' + $3 }
    | cfg_entry                                 { $$ = $1 }
    ;

configuration
    : '{' cfg_inner '}'                         { $$ = $2 }
    ;

count_success_fail
    : COUNT check                               { $$ = '.count(' + $2 + ', null)' }
    | COUNT FAILURE check                       { $$ = '.count(null, ' + $3 + ')' }
    | COUNT check FAILURE check                 { $$ = '.count(' + $2 + ', ' + $4 + ')' }
    ;

notation
    : expressions                               { $$ = $1 + '.exec()' }
    | expressions count_success_fail            { $$ = $1 + $2 }
    ;

result
    : configuration notation EOF                { return console.log($1, ';', $2) }
    | notation configuration EOF                { return console.log($2, ';', $1) }
    | notation EOF                              { return console.log($1) }
    ;
