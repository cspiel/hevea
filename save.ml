
open Lexing

let brace_nesting = ref 0
and arg_buff = Out.create_buff ()
and delim_buff = Out.create_buff ()
;;


exception BadParse of string
;;
exception EofDelim of int
;;
exception NoDelim
;;
exception NoOpt
;;

let lex_tables = {
  Lexing.lex_base = 
   "\000\000\001\000\003\000\004\000\255\255\000\000\006\000\027\000\
    \087\000\198\000\017\001\019\000\052\000\002\000\252\255\062\000\
    \040\001\101\000\254\255\253\255\251\255\026\000\255\255\254\255\
    \248\255\001\000\162\000\005\000\186\000\077\001\097\001\110\001\
    \145\001\001\000\254\255\247\255\203\001\250\255\249\255\049\002\
    \139\002\220\002\045\003\103\003\184\003\120\001\044\002\054\002\
    \005\004\011\000\012\000\012\000\008\000\015\004\025\004\033\000\
    \002\000\255\255\254\255\004\000";
  Lexing.lex_backtrk = 
   "\002\000\255\255\009\000\255\255\255\255\255\255\000\000\004\000\
    \002\000\001\000\255\255\255\255\000\000\255\255\255\255\001\000\
    \002\000\000\000\255\255\255\255\255\255\004\000\255\255\255\255\
    \255\255\000\000\007\000\007\000\007\000\007\000\002\000\007\000\
    \007\000\007\000\255\255\255\255\255\255\255\255\255\255\006\000\
    \006\000\006\000\006\000\255\255\004\000\255\255\255\255\255\255\
    \002\000\255\255\255\255\255\255\255\255\002\000\002\000\255\255\
    \000\000\255\255\255\255\001\000";
  Lexing.lex_default = 
   "\255\255\019\000\024\000\020\000\000\000\004\000\017\000\255\255\
    \255\255\255\255\255\255\255\255\255\255\014\000\000\000\255\255\
    \255\255\017\000\000\000\000\000\000\000\255\255\000\000\000\000\
    \000\000\255\255\255\255\055\000\255\255\255\255\255\255\255\255\
    \038\000\255\255\000\000\000\000\037\000\000\000\000\000\255\255\
    \255\255\255\255\255\255\020\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\055\000\
    \255\255\000\000\000\000\255\255";
  Lexing.lex_trans = 
   "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\056\000\056\000\025\000\000\000\014\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \059\000\056\000\056\000\025\000\059\000\026\000\000\000\000\000\
    \027\000\000\000\000\000\014\000\000\000\000\000\000\000\000\000\
    \028\000\029\000\018\000\030\000\030\000\030\000\030\000\030\000\
    \030\000\030\000\030\000\030\000\030\000\010\000\000\000\000\000\
    \031\000\000\000\011\000\015\000\015\000\015\000\015\000\015\000\
    \015\000\015\000\015\000\012\000\012\000\012\000\012\000\012\000\
    \012\000\012\000\012\000\012\000\012\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\004\000\057\000\036\000\058\000\032\000\
    \021\000\004\000\000\000\033\000\012\000\012\000\012\000\012\000\
    \012\000\012\000\012\000\012\000\012\000\012\000\015\000\015\000\
    \015\000\015\000\015\000\015\000\015\000\015\000\019\000\004\000\
    \019\000\019\000\019\000\013\000\019\000\000\000\034\000\022\000\
    \255\255\023\000\000\000\019\000\019\000\009\000\000\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\255\255\000\000\000\000\000\000\019\000\000\000\019\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\000\000\000\000\000\000\000\000\009\000\000\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\054\000\054\000\054\000\054\000\054\000\054\000\
    \054\000\054\000\054\000\054\000\045\000\000\000\000\000\000\000\
    \000\000\000\000\255\255\054\000\054\000\054\000\054\000\054\000\
    \047\000\000\000\048\000\048\000\048\000\048\000\048\000\048\000\
    \048\000\048\000\048\000\048\000\009\000\000\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \018\000\255\255\255\255\035\000\014\000\255\255\255\255\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\255\255\000\000\000\000\000\000\009\000\000\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\016\000\016\000\016\000\016\000\016\000\016\000\016\000\
    \016\000\016\000\016\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\016\000\016\000\016\000\016\000\016\000\016\000\
    \016\000\016\000\016\000\016\000\016\000\016\000\016\000\016\000\
    \016\000\016\000\000\000\000\000\000\000\255\255\000\000\000\000\
    \000\000\016\000\016\000\016\000\016\000\016\000\016\000\045\000\
    \000\000\000\000\016\000\016\000\016\000\016\000\016\000\016\000\
    \000\000\000\000\000\000\000\000\000\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\000\000\
    \000\000\016\000\016\000\016\000\016\000\016\000\016\000\047\000\
    \045\000\048\000\048\000\048\000\048\000\048\000\048\000\048\000\
    \048\000\048\000\048\000\046\000\047\000\000\000\048\000\048\000\
    \048\000\048\000\048\000\048\000\048\000\048\000\048\000\048\000\
    \054\000\054\000\054\000\054\000\054\000\054\000\054\000\054\000\
    \054\000\054\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\054\000\054\000\054\000\054\000\054\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\049\000\000\000\050\000\000\000\
    \000\000\000\000\051\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\052\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\039\000\040\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\000\000\000\000\
    \000\000\000\000\000\000\000\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\045\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \045\000\000\000\047\000\038\000\048\000\048\000\048\000\048\000\
    \048\000\048\000\048\000\048\000\048\000\048\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \000\000\000\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\000\000\000\000\000\000\000\000\
    \000\000\255\255\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\038\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\255\255\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\041\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\038\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\042\000\039\000\039\000\038\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \000\000\043\000\000\000\000\000\000\000\000\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \044\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \044\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\020\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\047\000\000\000\048\000\048\000\048\000\
    \048\000\048\000\048\000\048\000\048\000\048\000\048\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\054\000\054\000\054\000\054\000\054\000\054\000\054\000\
    \054\000\054\000\054\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\054\000\054\000\054\000\054\000\054\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\255\255\
    \049\000\000\000\050\000\000\000\000\000\000\000\051\000\000\000\
    \000\000\000\000\049\000\000\000\050\000\052\000\000\000\000\000\
    \051\000\000\000\000\000\000\000\049\000\000\000\050\000\052\000\
    \000\000\000\000\051\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\052\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000";
  Lexing.lex_check = 
   "\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\025\000\056\000\002\000\255\255\027\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \000\000\025\000\056\000\002\000\059\000\002\000\255\255\255\255\
    \002\000\255\255\255\255\055\000\255\255\255\255\255\255\255\255\
    \002\000\002\000\006\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\007\000\255\255\255\255\
    \002\000\255\255\007\000\011\000\011\000\011\000\011\000\011\000\
    \011\000\011\000\011\000\007\000\007\000\007\000\007\000\007\000\
    \007\000\007\000\007\000\007\000\007\000\255\255\255\255\255\255\
    \255\255\255\255\255\255\000\000\001\000\033\000\001\000\002\000\
    \003\000\008\000\255\255\002\000\012\000\012\000\012\000\012\000\
    \012\000\012\000\012\000\012\000\012\000\012\000\015\000\015\000\
    \015\000\015\000\015\000\015\000\015\000\015\000\021\000\008\000\
    \049\000\050\000\051\000\007\000\052\000\255\255\002\000\003\000\
    \002\000\003\000\255\255\006\000\050\000\008\000\255\255\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\017\000\255\255\255\255\255\255\021\000\255\255\021\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\255\255\255\255\255\255\255\255\008\000\255\255\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\026\000\026\000\026\000\026\000\026\000\026\000\
    \026\000\026\000\026\000\026\000\028\000\255\255\255\255\255\255\
    \255\255\255\255\017\000\026\000\026\000\026\000\026\000\026\000\
    \028\000\255\255\028\000\028\000\028\000\028\000\028\000\028\000\
    \028\000\028\000\028\000\028\000\009\000\255\255\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \005\000\001\000\013\000\002\000\003\000\027\000\006\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\055\000\255\255\255\255\255\255\009\000\255\255\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\009\000\009\000\009\000\009\000\009\000\009\000\009\000\
    \009\000\010\000\010\000\010\000\010\000\010\000\010\000\010\000\
    \010\000\010\000\010\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\010\000\010\000\010\000\010\000\010\000\010\000\
    \016\000\016\000\016\000\016\000\016\000\016\000\016\000\016\000\
    \016\000\016\000\255\255\255\255\255\255\017\000\255\255\255\255\
    \255\255\016\000\016\000\016\000\016\000\016\000\016\000\029\000\
    \255\255\255\255\010\000\010\000\010\000\010\000\010\000\010\000\
    \255\255\255\255\255\255\255\255\255\255\029\000\029\000\029\000\
    \029\000\029\000\029\000\029\000\029\000\029\000\029\000\255\255\
    \255\255\016\000\016\000\016\000\016\000\016\000\016\000\030\000\
    \031\000\030\000\030\000\030\000\030\000\030\000\030\000\030\000\
    \030\000\030\000\030\000\031\000\031\000\255\255\031\000\031\000\
    \031\000\031\000\031\000\031\000\031\000\031\000\031\000\031\000\
    \045\000\045\000\045\000\045\000\045\000\045\000\045\000\045\000\
    \045\000\045\000\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\045\000\045\000\045\000\045\000\045\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\030\000\255\255\030\000\255\255\
    \255\255\255\255\030\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\030\000\032\000\032\000\032\000\032\000\032\000\032\000\
    \032\000\032\000\032\000\032\000\032\000\032\000\032\000\032\000\
    \032\000\032\000\032\000\032\000\032\000\032\000\032\000\032\000\
    \032\000\032\000\032\000\032\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\032\000\032\000\032\000\032\000\032\000\032\000\
    \032\000\032\000\032\000\032\000\032\000\032\000\032\000\032\000\
    \032\000\032\000\032\000\032\000\032\000\032\000\032\000\032\000\
    \032\000\032\000\032\000\032\000\036\000\036\000\036\000\036\000\
    \036\000\036\000\036\000\036\000\036\000\036\000\036\000\036\000\
    \036\000\036\000\036\000\036\000\036\000\036\000\036\000\036\000\
    \036\000\036\000\036\000\036\000\036\000\036\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\036\000\036\000\036\000\036\000\
    \036\000\036\000\036\000\036\000\036\000\036\000\036\000\036\000\
    \036\000\036\000\036\000\036\000\036\000\036\000\036\000\036\000\
    \036\000\036\000\036\000\036\000\036\000\036\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\046\000\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \047\000\255\255\046\000\039\000\046\000\046\000\046\000\046\000\
    \046\000\046\000\046\000\046\000\046\000\046\000\047\000\047\000\
    \047\000\047\000\047\000\047\000\047\000\047\000\047\000\047\000\
    \255\255\255\255\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\255\255\255\255\255\255\255\255\
    \255\255\032\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\039\000\039\000\039\000\039\000\
    \039\000\039\000\039\000\039\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\040\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\036\000\040\000\040\000\040\000\040\000\
    \040\000\040\000\040\000\040\000\040\000\040\000\040\000\040\000\
    \040\000\040\000\040\000\040\000\040\000\040\000\040\000\040\000\
    \040\000\040\000\040\000\040\000\040\000\040\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\040\000\040\000\040\000\040\000\
    \040\000\040\000\040\000\040\000\040\000\040\000\040\000\040\000\
    \040\000\040\000\040\000\040\000\040\000\040\000\040\000\040\000\
    \040\000\040\000\040\000\040\000\040\000\040\000\041\000\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\041\000\041\000\041\000\
    \041\000\041\000\041\000\041\000\041\000\041\000\041\000\041\000\
    \041\000\041\000\041\000\041\000\041\000\041\000\041\000\041\000\
    \041\000\041\000\041\000\041\000\041\000\041\000\041\000\255\255\
    \255\255\255\255\255\255\255\255\255\255\041\000\041\000\041\000\
    \041\000\041\000\041\000\041\000\041\000\041\000\041\000\041\000\
    \041\000\041\000\041\000\041\000\041\000\041\000\041\000\041\000\
    \041\000\041\000\041\000\041\000\041\000\041\000\041\000\042\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\042\000\042\000\
    \042\000\042\000\042\000\042\000\042\000\042\000\042\000\042\000\
    \042\000\042\000\042\000\042\000\042\000\042\000\042\000\042\000\
    \042\000\042\000\042\000\042\000\042\000\042\000\042\000\042\000\
    \255\255\042\000\255\255\255\255\255\255\255\255\042\000\042\000\
    \042\000\042\000\042\000\042\000\042\000\042\000\042\000\042\000\
    \042\000\042\000\042\000\042\000\042\000\042\000\042\000\042\000\
    \042\000\042\000\042\000\042\000\042\000\042\000\042\000\042\000\
    \043\000\043\000\043\000\043\000\043\000\043\000\043\000\043\000\
    \043\000\043\000\043\000\043\000\043\000\043\000\043\000\043\000\
    \043\000\043\000\043\000\043\000\043\000\043\000\043\000\043\000\
    \043\000\043\000\255\255\255\255\255\255\255\255\255\255\255\255\
    \043\000\043\000\043\000\043\000\043\000\043\000\043\000\043\000\
    \043\000\043\000\043\000\043\000\043\000\043\000\043\000\043\000\
    \043\000\043\000\043\000\043\000\043\000\043\000\043\000\043\000\
    \043\000\043\000\044\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\044\000\044\000\044\000\044\000\044\000\
    \044\000\044\000\044\000\048\000\255\255\048\000\048\000\048\000\
    \048\000\048\000\048\000\048\000\048\000\048\000\048\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\054\000\054\000\054\000\054\000\054\000\054\000\054\000\
    \054\000\054\000\054\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\054\000\054\000\054\000\054\000\054\000\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\043\000\
    \048\000\255\255\048\000\255\255\255\255\255\255\048\000\255\255\
    \255\255\255\255\053\000\255\255\053\000\048\000\255\255\255\255\
    \053\000\255\255\255\255\255\255\054\000\255\255\054\000\053\000\
    \255\255\255\255\054\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\054\000\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255"
}

let rec opt lexbuf = opt_rec lexbuf 0
and opt_rec lexbuf state =
  match Lexing.engine lex_tables state lexbuf with
    0 -> (incr brace_nesting ; opt2 lexbuf)
  | 1 -> (opt lexbuf)
  | 2 -> (raise NoOpt)
  | n -> lexbuf.Lexing.refill_buff lexbuf; opt_rec lexbuf n

and opt2 lexbuf = opt2_rec lexbuf 1
and opt2_rec lexbuf state =
  match Lexing.engine lex_tables state lexbuf with
    0 -> (  incr brace_nesting;
                   if !brace_nesting > 1 then begin
                     Out.put arg_buff "[" ; opt2 lexbuf
                   end else opt2 lexbuf)
  | 1 -> ( decr brace_nesting;
                 if !brace_nesting > 0 then begin
                    Out.put arg_buff "]" ; opt2 lexbuf
                 end else Out.to_string arg_buff)
  | 2 -> (let s = lexeme_char lexbuf 0 in
      Out.put_char arg_buff s ; opt2 lexbuf )
  | n -> lexbuf.Lexing.refill_buff lexbuf; opt2_rec lexbuf n

and arg lexbuf = arg_rec lexbuf 2
and arg_rec lexbuf state =
  match Lexing.engine lex_tables state lexbuf with
    0 -> (arg lexbuf)
  | 1 -> (incr brace_nesting;
      arg2 lexbuf)
  | 2 -> (lexeme lexbuf)
  | 3 -> (arg lexbuf)
  | 4 -> (lexeme lexbuf)
  | 5 -> (lexeme lexbuf)
  | 6 -> (lexeme lexbuf)
  | 7 -> (String.make 1 (lexeme_char lexbuf 0))
  | 8 -> (raise (BadParse "EOF"))
  | 9 -> (raise (BadParse "Empty Arg"))
  | n -> lexbuf.Lexing.refill_buff lexbuf; arg_rec lexbuf n

and arg2 lexbuf = arg2_rec lexbuf 3
and arg2_rec lexbuf state =
  match Lexing.engine lex_tables state lexbuf with
    0 -> (  incr brace_nesting;
                   if !brace_nesting > 1 then begin
                     Out.put arg_buff "{" ; arg2 lexbuf
                   end else arg2 lexbuf)
  | 1 -> ( decr brace_nesting;
                 if !brace_nesting > 0 then begin
                    Out.put arg_buff "}" ; arg2 lexbuf
                 end else Out.to_string arg_buff)
  | 2 -> (let s = lexeme lexbuf in
      Out.put arg_buff s ; arg2 lexbuf )
  | 3 -> (raise (BadParse "EOF"))
  | 4 -> (let s = lexeme_char lexbuf 0 in
      Out.put_char arg_buff s ; arg2 lexbuf )
  | n -> lexbuf.Lexing.refill_buff lexbuf; arg2_rec lexbuf n

and eat_delim lexbuf = eat_delim_rec lexbuf 4
and eat_delim_rec lexbuf state =
  match Lexing.engine lex_tables state lexbuf with
    0 -> (fun delim ->
    begin try
      do_eat_delim lexbuf delim 0
    with (NoDelim | EofDelim _) ->
      raise (BadParse ("delim : "^delim))
    end ;
    let _ = Out.to_string delim_buff in
    ())
  | n -> lexbuf.Lexing.refill_buff lexbuf; eat_delim_rec lexbuf n

and do_eat_delim lexbuf = do_eat_delim_rec lexbuf 5
and do_eat_delim_rec lexbuf state =
  match Lexing.engine lex_tables state lexbuf with
    0 -> (fun delim i ->
     let lxm = lexeme_char lexbuf 0 in
     let c = String.get delim i in
     Out.put_char delim_buff lxm ;
     if c = lxm then
       if i+1 >= String.length delim then
         ()
       else
         do_eat_delim lexbuf delim (i+1)
     else
         raise NoDelim
   )
  | 1 -> (fun delim i -> raise (EofDelim i))
  | n -> lexbuf.Lexing.refill_buff lexbuf; do_eat_delim_rec lexbuf n

and arg_delim lexbuf = arg_delim_rec lexbuf 4
and arg_delim_rec lexbuf state =
  match Lexing.engine lex_tables state lexbuf with
    0 -> (fun delim ->  failwith "Hum")
  | n -> lexbuf.Lexing.refill_buff lexbuf; arg_delim_rec lexbuf n

and cite_args lexbuf = cite_args_rec lexbuf 6
and cite_args_rec lexbuf state =
  match Lexing.engine lex_tables state lexbuf with
    0 -> (let lxm = lexeme lexbuf in lxm::cite_args lexbuf)
  | 1 -> (cite_args lexbuf)
  | 2 -> ([])
  | n -> lexbuf.Lexing.refill_buff lexbuf; cite_args_rec lexbuf n

and num_arg lexbuf = num_arg_rec lexbuf 7
and num_arg_rec lexbuf state =
  match Lexing.engine lex_tables state lexbuf with
    0 -> (let lxm = lexeme lexbuf in
    int_of_string lxm)
  | 1 -> (let lxm = lexeme  lexbuf in
    int_of_string ("0o"^String.sub lxm 1 (String.length lxm-1)))
  | 2 -> (let lxm = lexeme  lexbuf in
    int_of_string ("0x"^String.sub lxm 1 (String.length lxm-1)))
  | 3 -> (let c = lexeme_char lexbuf 1 in
    Char.code c)
  | 4 -> (failwith "num_arg")
  | n -> lexbuf.Lexing.refill_buff lexbuf; num_arg_rec lexbuf n

and input_arg lexbuf = input_arg_rec lexbuf 8
and input_arg_rec lexbuf state =
  match Lexing.engine lex_tables state lexbuf with
    0 -> (input_arg lexbuf)
  | 1 -> (lexeme lexbuf)
  | 2 -> (arg lexbuf)
  | n -> lexbuf.Lexing.refill_buff lexbuf; input_arg_rec lexbuf n

