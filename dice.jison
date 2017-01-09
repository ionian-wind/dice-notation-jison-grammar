/* description: Parses end executes mathematical es. */

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

"*"                                             return '*';
"/"                                             return '/';
"-"                                             return '-';
"+"                                             return '+';

"("                                             return '(';
")"                                             return ')';

"["                                             return '[';
"]"                                             return ']';

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
    : expression EOF                            { return ($1).exec() }
    ;

smart_roll
    : exploding_dice_roll                       { $$ = $1 }
    | dice_roll                                 { $$ = $1 }
    ;

drop_keep
    : smart_roll DL INTEGER                     { $$ = $1.drop(yy.Result.LOWEST, $3) }
    | smart_roll DL                             { $$ = $1.drop(yy.Result.LOWEST) }

    | smart_roll DH INTEGER                     { $$ = $1.drop(yy.Result.HIGHEST, $3) }
    | smart_roll DH                             { $$ = $1.drop(yy.Result.HIGHEST) }

    | smart_roll KL INTEGER                     { $$ = $1.keep(yy.Result.LOWEST, $3) }
    | smart_roll KL                             { $$ = $1.keep(yy.Result.LOWEST) }

    | smart_roll KH INTEGER                     { $$ = $1.keep(yy.Result.HIGHEST, $3) }
    | smart_roll KH                             { $$ = $1.keep(yy.Result.HIGHEST) }
    ;

exploding_dice_roll
    : dice_roll EXPLODE                         { $$ = $1.explode() }
    | dice_roll COMPOUND                        { $$ = $1.compound() }
    | dice_roll PENETRATE                       { $$ = $1.penetrate() }
    ;

dice
    : DICE group_or_int                         { $$ = new yy.Dice($2) }
    | DICE FATE                                 { $$ = new yy.Dice(Dice.FATE_DICE) }
    | DICE '%'                                  { $$ = new yy.Dice(100) }
    ;

dice_roll
    : group_or_int dice                         { $$ = $2.roll($1) }
    | dice                                      { $$ = $1.roll(new yy.Result(1, Result.STATIC)) }
    ;

concat_entry
    : group_or_int                              { $$ = $1 }
    | drop_keep                                 { $$ = $1 }
    | smart_roll                                { $$ = $1 }
    ;

concated_inner
    : concat_entry                              { $$ = [$1] }
    | concated_inner COMMA concat_entry         { $$ = $1.push($3); $$ = $1 }
    ;

concated_expr
    : '[' concated_inner ']'                    { $$ = (new yy.Result($2)).flatten() }
    ;

concated_drop_keep
    : concated_expr DL INTEGER                  { $$ = $1.drop(yy.Result.LOWEST, $3) }
    | concated_expr DL                          { $$ = $1.drop(yy.Result.LOWEST) }

    | concated_expr DH INTEGER                  { $$ = $1.drop(yy.Result.HIGHEST, $3) }
    | concated_expr DH                          { $$ = $1.drop(yy.Result.HIGHEST) }

    | concated_expr KL INTEGER                  { $$ = $1.keep(yy.Result.LOWEST, $3) }
    | concated_expr KL                          { $$ = $1.keep(yy.Result.LOWEST) }

    | concated_expr KH INTEGER                  { $$ = $1.keep(yy.Result.HIGHEST, $3) }
    | concated_expr KH                          { $$ = $1.keep(yy.Result.HIGHEST) }
    ;

group_or_int
    : INTEGER                                   { $$ = new yy.Result(yytext, Result.STATIC) }
    | '(' expression ')'                        { $$ = $2 }
    ;

expression
    : expression '+' expression                 { $$ = $1.exec() + $3.exec() }
    | expression '-' expression                 { $$ = $1.exec() - $3.exec() }
    | expression '*' expression                 { $$ = $1.exec() * $3.exec() }
    | expression '/' expression                 { $$ = $1.exec() / $3.exec() }
    | group_or_int                              { $$ = $1 }
    | concat_entry                              { $$ = $1 }
    ;
