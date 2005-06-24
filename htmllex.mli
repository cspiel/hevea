(***********************************************************************)
(*                                                                     *)
(*                          HEVEA                                      *)
(*                                                                     *)
(*  Luc Maranget, projet Moscova, INRIA Rocquencourt                   *)
(*                                                                     *)
(*  Copyright 2001 Institut National de Recherche en Informatique et   *)
(*  Automatique.  Distributed only by permission.                      *)
(*                                                                     *)
(*  $Id: htmllex.mli,v 1.5 2005-06-24 08:32:21 maranget Exp $          *)
(***********************************************************************)
exception Error of string

val ptop : unit -> unit
val to_string : Lexeme.token -> string
val cost : Lexeme.style -> int * int
val reset : unit -> unit
val next_token : Lexing.lexbuf -> Lexeme.token
val styles : Lexing.lexbuf -> Css.id list
