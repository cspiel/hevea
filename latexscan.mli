(***********************************************************************)
(*                                                                     *)
(*                          HEVEA                                      *)
(*                                                                     *)
(*  Luc Maranget, projet PARA, INRIA Rocquencourt                      *)
(*                                                                     *)
(*  Copyright 1998 Institut National de Recherche en Informatique et   *)
(*  Automatique.  Distributed only by permission.                      *)
(*                                                                     *)
(***********************************************************************)

module type S =
  sig
    exception Error of string

    val no_prelude : unit -> unit

    val print_env_pos : unit -> unit
    val main : Lexing.lexbuf -> unit
end

module Make (Html : OutManager.S) : S

