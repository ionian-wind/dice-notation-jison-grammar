/* description: Parses end executes mathematical expressions. */

/* lexical grammar */
%lex

%%
\s+                                             /* skip whitespace */
[0-9]+                                          return 'INTEGER';

"dl"                                            return 'DL';
"dh"                                            return 'DH';
"kl"                                            return 'KL';
"kh"                                            return 'KH';

"F"                                             return 'FATE';
[dD]                                            return 'DICE';

"!!"                                            return 'COMPOUND';
"!p"                                            return 'PENETRATE';
"!"                                             return 'EXPLODE';

">"                                             return 'HIGHER_EQ';
"<"                                             return 'LOWER_EQ';

"f"                                             return 'COUNT_FAILURES';

"*"                                             return '*';
"/"                                             return '/';
"-"                                             return '-';
"+"                                             return '+';

"("                                             return '(';
")"                                             return ')';

"{"                                             return '{';
"}"                                             return '}';

","                                             return 'COMMA';

<<EOF>>                                         return 'EOF';

/lex

/* operator associations and precedence */

%left COMMA
%left '+' '-'
%left '*' '/'
%right DL DH KL KH
%right COMPOUND PENETRATE EXPLODE
%right DICE

%start expressions

%% /* language grammar */

expressions
    : e EOF                                       { console.log($1); return $1; }
    ;

drop_keep
    : exploding_dice_roll DL INTEGER            { $$ = $1 + '.drop("lowest", ' + $3 + ')' }
    | exploding_dice_roll DH INTEGER            { $$ = $1 + '.drop("highest", ' + $3 + ')' }
    | exploding_dice_roll KL INTEGER            { $$ = $1 + '.keep("lowest", ' + $3 + ')' }
    | exploding_dice_roll KH INTEGER            { $$ = $1 + '.keep("highest", ' + $3 + ')' }
    | dice_roll DL INTEGER                      { $$ = $1 + '.drop("lowest", ' + $3 + ')' }
    | dice_roll DH INTEGER                      { $$ = $1 + '.drop("highest", ' + $3 + ')' }
    | dice_roll KL INTEGER                      { $$ = $1 + '.keep("lowest", ' + $3 + ')' }
    | dice_roll KH INTEGER                      { $$ = $1 + '.keep("highest", ' + $3 + ')' }
    | exploding_dice_roll DL                    { $$ = $1 + '.drop("lowest")' }
    | exploding_dice_roll DH                    { $$ = $1 + '.drop("highest")' }
    | exploding_dice_roll KL                    { $$ = $1 + '.keep("lowest")' }
    | exploding_dice_roll KH                    { $$ = $1 + '.keep("highest")' }
    | dice_roll DL                              { $$ = $1 + '.drop("lowest")' }
    | dice_roll DH                              { $$ = $1 + '.drop("highest")' }
    | dice_roll KL                              { $$ = $1 + '.keep("lowest")' }
    | dice_roll KH                              { $$ = $1 + '.keep("highest")' }
    ;

exploding_dice_roll
    : dice_roll EXPLODE                         { $$ = $1 + '.explode()' }
    | dice_roll COMPOUND                        { $$ = $1 + '.compound()' }
    | dice_roll PENETRATE                       { $$ = $1 + '.penetrate()' }
    ;

dice_roll
    : group_or_int DICE group_or_int            { $$ = 'yy.dice(' + $3 + ').roll(' + $1 + ')' }
    | DICE group_or_int                         { $$ = 'yy.dice(' + $2 + ').roll(1)' }
    | DICE FATE                                 { $$ = 'yy.dice(FATE).roll(1)' }
    | group_or_int DICE FATE                    { $$ = 'yy.dice(FATE).roll(' + $1 + ')' }
    ;

concated_expr
    : '{' concated_inner '}'                    { $$ = 'yy.concat(' + $2 + ')' }
    ;

concated_inner
    : group_or_int                              { $$ = $1; }
    | concated_inner COMMA group_or_int         { $$ = $1 + ',' + $3 }
    | drop_keep                                 { $$ = $1; }
    | concated_inner COMMA drop_keep            { $$ = $1 + ',' + $3 }
    | exploding_dice_roll                       { $$ = $1; }
    | concated_inner COMMA exploding_dice_roll  { $$ = $1 + ',' + $3 }
    | dice_roll                                 { $$ = $1; }
    | concated_inner COMMA dice_roll            { $$ = $1 + ',' + $3 }
    ;

concated_drop_keep
    : concated_expr DL INTEGER                  { $$ = $1 + '.drop("lowest", ' + $3 + ')' }
    | concated_expr DH INTEGER                  { $$ = $1 + '.drop("highest", ' + $3 + ')' }
    | concated_expr KL INTEGER                  { $$ = $1 + '.keep("lowest", ' + $3 + ')' }
    | concated_expr KH INTEGER                  { $$ = $1 + '.keep("highest", ' + $3 + ')' }
    | concated_expr DL                          { $$ = $1 + '.drop("lowest")' }
    | concated_expr DH                          { $$ = $1 + '.drop("highest")' }
    | concated_expr KL                          { $$ = $1 + '.keep("lowest")' }
    | concated_expr KH                          { $$ = $1 + '.keep("highest")' }
    ;

group_or_int
    : INTEGER                                   { $$ = 'yy.number(' + yytext + ')' }
    | grouped_expr                              { $$ = $1; }
    ;

grouped_expr
    : '(' e ')'                                 { $$ = 'yy.group(' + $2 + ')' }
    ;

e
    : e '+' e                                   { $$ = $1 + '.add(' + $3 + ')' }
    | e '-' e                                   { $$ = $1 + '.sub(' + $3 + ')' }
    | e '*' e                                   { $$ = $1 + '.mul(' + $3 + ')' }
    | e '/' e                                   { $$ = $1 + '.div(' + $3 + ')' }
    | dice_roll                                 { $$ = $1 }
    | exploding_dice_roll                       { $$ = $1 }
    | drop_keep                                 { $$ = $1 }
    | group_or_int                              { $$ = $1 }
    | concated_expr                             { $$ = $1 }
    | concated_drop_keep                        { $$ = $1 }
    ;
