(***********************************************************************)
(*                                                                     *)
(*                          HEVEA                                      *)
(*                                                                     *)
(*  Luc Maranget, projet Moscova, INRIA Rocquencourt                   *)
(*                                                                     *)
(*  Copyright 2001 Institut National de Recherche en Informatique et   *)
(*  Automatique.  Distributed only by permission.                      *)
(*                                                                     *)
(*  $Id: htmltext.mli,v 1.5 2001-05-28 17:28:56 maranget Exp $         *)
(***********************************************************************)
exception No

type tsize = Int of int | Big | Small
type nat =
    Style of Lexeme.tag
  | Size of tsize
  | Color of string
  | Face of string
  | Other

type t_style = { nat : nat; txt : string; ctxt : string; } 
type style = t_style list

val cost : style -> int * int
exception NoProp
val get_prop : nat -> (nat -> bool)
val is_font : nat -> bool
val font_props : (nat -> bool) list
val neutral_prop : (nat -> bool) -> bool
val same_style : t_style -> t_style -> bool

type env = t_style list
exception Split of t_style * env

val add_style : Lexeme.style -> env -> env


val blanksNeutral : t_style -> bool