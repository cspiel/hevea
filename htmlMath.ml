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

let header = "$Id: htmlMath.ml,v 1.25 2004-07-14 02:46:19 thakur Exp $" 


open Misc
open Parse_opts
open Element
open HtmlCommon
open Stack



let delay_stack = Stack.create "delay_stack"
;;
(* delaying output .... *)

let delay f =
  if !verbose > 2 then prerr_flags "=> delay" ;
  push stacks.s_vsize flags.vsize ;
  flags.vsize <- 0;
  push delay_stack f ;
  open_block DELAY "" ;
  if !verbose > 2 then prerr_flags "<= delay"
;;

let flush x =
  if !verbose > 2 then
    prerr_flags ("=> flush arg is ``"^string_of_int x^"''");
  try_close_block DELAY ;
  let ps,_,pout = pop_out out_stack in
  if ps <> DELAY then
    raise (Misc.Fatal ("html: Flush attempt on: "^string_of_block ps)) ;
  let mods = as_envs !cur_out.active !cur_out.pending in
  do_close_mods () ;
  let old_out = !cur_out in
  cur_out := pout ;
  let f = pop delay_stack in
  f x ;
  Out.copy old_out.out !cur_out.out ;
  flags.empty <- false ; flags.blank <- false ;
  free old_out ;
  !cur_out.pending <- mods ;
  flags.vsize <- max (pop stacks.s_vsize) flags.vsize ;
  if !verbose > 2 then
    prerr_flags "<= flush"
;;

(* put functions *)

let put  = HtmlCommon.put
and put_char = HtmlCommon.put_char
;;

let put_in_math s =
  if flags.in_pre && !pedantic then
    put s
  else begin
    put "<I>";
    put s;
    put "</I>";
    flags.empty <- false; flags.blank <- false;
  end
;;

(*----------*)
(* DISPLAYS *)
(*----------*)

let open_center () =  open_block DIV "ALIGN=center"
and close_center () = close_block DIV
;;





let begin_item_display f is_freeze =
  if !verbose > 2 then begin
    Printf.fprintf stderr "begin_item_display: ncols=%d empty=%s" flags.ncols (sbool flags.empty) ;
    prerr_newline ()
  end ;
  open_block TD "NOWRAP";
  open_block INTERN "" ;
  if is_freeze then(* push out_stack (Freeze f) ;*)freeze f;


and end_item_display () =
  let f,is_freeze = pop_freeze () in
  let _ = close_flow_loc INTERN in
  if close_flow_loc TD then
    flags.ncols <- flags.ncols + 1;
  if !verbose > 2 then begin
    Printf.fprintf stderr "end_item_display: ncols=%d stck: " flags.ncols;
    pretty_stack out_stack
  end;
  flags.vsize,f,is_freeze
;;

let open_display_varg varg =
  if !verbose > 2 then begin
    Printf.fprintf stderr "open_display: "
  end ;
  try_open_display () ;
  open_block DISPLAY varg ;
  open_block TD "NOWRAP" ;
  open_block INTERN "" ;
  if !verbose > 2 then begin
    pretty_cur !cur_out ;
    prerr_endline ""
  end     
;;

(************************************************************************
*									*
*    To open display with vertical and horizontal alignment arguments   *
*                                                                       *
************************************************************************)

let open_display_varg_harg varg harg = 
  if !verbose > 2 then begin
    Printf.fprintf stderr "open_display: "
  end ;
  try_open_display () ;
  open_block DISPLAY (varg^harg);
  open_block TD "NOWRAP" ;
  open_block INTERN "" ;
  if !verbose > 2 then begin
    pretty_cur !cur_out ;
    prerr_endline ""
  end
;;

let open_display () = open_display_varg "VALIGN=middle"

let close_display () =
  if !verbose > 2 then begin
    prerr_flags "=> close_display"
  end ;
  if not (flush_freeze ()) then begin
    close_flow INTERN ;
    let n = flags.ncols in
    if !verbose > 2 then
      Printf.fprintf stderr "=> close_display, ncols=%d\n" n ;
    if (n = 0 && not flags.blank) then begin
      if !verbose > 2 then begin
        prerr_string "No Display n=0" ;
        (Out.debug stderr !cur_out.out);
        prerr_endline "" 
      end;
      let active = !cur_out.active and pending = !cur_out.pending in
      do_close_mods () ;
      let ps,_,pout = pop_out out_stack in
      if ps <> TD then
        failclose "close_display" ps TD ;
      do_close_mods () ;
      try_close_block TD ;
      let ps,_,ppout = pop_out out_stack in
      if ps <> DISPLAY then
        failclose "close_display" ps DISPLAY;
      try_close_block DISPLAY ;
      let old_out = !cur_out in
      cur_out := ppout ;
      do_close_mods () ;
      Out.copy old_out.out !cur_out.out ;
      flags.empty <- false ; flags.blank <- false ;
      free old_out ; free pout ;     
      !cur_out.pending <- as_envs active pending
    end else if (n=1 && flags.blank) then begin
      if !verbose > 2 then begin
        prerr_string "No display n=1";
        (Out.debug stderr !cur_out.out);
        prerr_endline "" ;
      end;
      close_flow FORGET ;
      let active = !cur_out.active and pending = !cur_out.pending in
      let ps,_,pout = pop_out out_stack in
      if ps <> DISPLAY then
        failclose "close_display" ps DISPLAY ;
      try_close_block DISPLAY ;
      let old_out = !cur_out in
      cur_out := pout ;
      do_close_mods () ;
      Out.copy_no_tag old_out.out !cur_out.out ;
      flags.empty <- false ; flags.blank <- false ;
      free old_out ;
      !cur_out.pending <- as_envs active pending
    end else begin
      if !verbose > 2 then begin
        prerr_string ("One Display n="^string_of_int n) ;
        (Out.debug stderr !cur_out.out);
        prerr_endline ""
      end;
      flags.empty <- flags.blank ;
      close_flow TD ;
      close_flow DISPLAY
    end ;
    try_close_display ()
  end ;
  if !verbose > 2 then
    prerr_flags ("<= close_display")
;;

  
let do_item_display force =
  if !verbose > 2 then begin
    prerr_endline ("Item Display ncols="^string_of_int flags.ncols^" table_inside="^sbool flags.table_inside)
  end ;
  let f,is_freeze = pop_freeze () in
  if (force && not flags.empty) || flags.table_inside then begin
    push stacks.s_saved_inside
      (pop stacks.s_saved_inside || flags.table_inside) ;
    flags.table_inside <- false ;
    let active  = !cur_out.active
    and pending = !cur_out.pending in
    flags.ncols <- flags.ncols + 1 ;
    let save = get_block TD "NOWRAP" in
    if !verbose > 2 then begin
      Out.debug stderr !cur_out.out ;
      prerr_endline "To be copied"
    end;
    if close_flow_loc TD then flags.ncols <- flags.ncols + 1; 
    if !verbose > 2 then begin
      Out.debug stderr !cur_out.out ;
      prerr_endline "Was copied"
    end;
    Out.copy save.out !cur_out.out ;
    flags.empty <- false ; flags.blank <- false ;
    free save ;
    !cur_out.pending <- as_envs active pending ;
    !cur_out.active <- [] ;
    if !verbose > 2 then begin
      Out.debug stderr !cur_out.out ;
      prerr_endline ("Some Item")
    end;
    open_block TD "NOWRAP" ;
    open_block INTERN ""
  end else begin
    if !verbose > 2 then begin
      Out.debug stderr !cur_out.out ;
      prerr_endline "No Item" ;
      prerr_endline ("flags: empty="^sbool flags.empty^" blank="^sbool flags.blank)
    end;
    close_flow INTERN ;
    if !verbose > 2 then begin
      Out.debug stderr !cur_out.out ;
      prerr_endline "No Item" ;
      prerr_endline ("flags: empty="^sbool flags.empty^" blank="^sbool flags.blank)
    end;
    open_block INTERN ""
  end ;
  if is_freeze then push out_stack (Freeze f) ;
  if !verbose > 2 then begin
    prerr_string ("out item_display -> ncols="^string_of_int flags.ncols) ;
    pretty_stack out_stack
  end ;
;;

let item_display () = do_item_display false
and force_item_display () = do_item_display true
;;


let erase_display () =
  erase_block INTERN ;
  erase_block TD ;
  erase_block DISPLAY ;
  try_close_display ()
;;


let open_maths display =
  if display then open_center ();
  push stacks.s_in_math flags.in_math;
  flags.in_math <- true;
  if display then open_display ()
  else open_group "";
;;

let close_maths display =
  if display then close_display ()
  else close_group ();
  flags.in_math <- pop stacks.s_in_math ;

  if display then close_center ()
;;



(* vertical display *)

let open_vdisplay display =  
  if !verbose > 1 then
    prerr_endline "open_vdisplay";
  if not display then
    raise (Misc.Fatal ("VDISPLAY in non-display mode"));
  open_block TABLE (display_arg !verbose)

and close_vdisplay () =
  if !verbose > 1 then
    prerr_endline "close_vdisplay";
  close_block TABLE

and open_vdisplay_row s =
  if !verbose > 1 then
    prerr_endline "open_vdisplay_row";
  open_block TR "" ;
  open_block TD s ;
  open_display ()

and close_vdisplay_row () =
  if !verbose > 1 then
    prerr_endline "close_vdisplay_row";
  close_display () ;
  force_block TD "&nbsp;" ;
  close_block TR
;;



(* Sup/Sub stuff *)

let get_script_font () =
  let n = get_fontsize () in
  if n >= 3 then Some (n-1) else None
;;

let open_script_font () =
  if not !pedantic then
    match get_script_font () with
    | Some m -> open_mod (Font m)
    | _ -> ()
;;


let put_sup_sub display scanner (arg : string Lexstate.arg) =
  if display then open_display () else open_block INTERN "" ;
  open_script_font () ;
  scanner arg ;
  if display then close_display () else close_block INTERN ;
;;

let reput_sup_sub tag = function
  | "" -> ()
  | s  ->
      open_block INTERN "" ;
      clearstyle () ;
      if not  (flags.in_pre && !pedantic) then begin
        put_char '<' ;
        put tag ;
        put_char '>'
      end ;
      put s ;
      if not  (flags.in_pre && !pedantic) then begin
        put "</" ;
        put tag ;
        put_char '>'
      end ;
      close_block INTERN


let standard_sup_sub scanner what sup sub display =
  let sup,fsup =
    hidden_to_string (fun () -> put_sup_sub display scanner sup)
  in
  let sub,fsub =
    hidden_to_string (fun () -> put_sup_sub display scanner sub) in

  if display && (fsub.table_inside || fsup.table_inside) then begin
    force_item_display () ;
    open_vdisplay display ;
    if sup <> "" then begin
      open_vdisplay_row "NOWRAP" ;
      clearstyle () ;
      put sup ;
      close_vdisplay_row ()
    end ;           
    open_vdisplay_row "" ;
    what ();
    close_vdisplay_row () ;
    if sub <> "" then begin
      open_vdisplay_row "NOWRAP" ;
      clearstyle () ;
      put sub ;
      close_vdisplay_row ()
    end ;
    close_vdisplay () ;
    force_item_display ()
  end else begin
    what ();
    reput_sup_sub "SUB" sub ;
    reput_sup_sub "SUP" sup
  end
;;


let limit_sup_sub scanner what sup sub display =
  let sup = to_string (fun () -> put_sup_sub display scanner sup)
  and sub = to_string (fun () -> put_sup_sub display scanner sub) in
  if sup = "" && sub = "" then
    what ()
  else begin
    force_item_display () ;
    open_vdisplay display ;
    open_vdisplay_row "ALIGN=center" ;
    put sup ;
    close_vdisplay_row () ;
    open_vdisplay_row "ALIGN=left" ;
    what () ;
    close_vdisplay_row () ;
    open_vdisplay_row "ALIGN=center" ;
    put sub ;
    close_vdisplay_row () ;
    close_vdisplay () ;
    force_item_display ()
  end
;;

let int_sup_sub something vsize scanner what sup sub display =
  let sup = to_string (fun () -> put_sup_sub display scanner sup)
  and sub = to_string (fun () -> put_sup_sub display scanner sub) in
  if something then begin
    force_item_display () ;
    what () ;
    force_item_display ()
  end ;
  if sup <> "" || sub <> "" then begin
    open_vdisplay display ;
    open_vdisplay_row "ALIGN=left NOWRAP" ;
    put sup ;
    close_vdisplay_row () ;
    open_vdisplay_row "ALIGN=left" ;
    for i = 2 to vsize do
      skip_line ()
    done ;
    close_vdisplay_row () ;
    open_vdisplay_row "ALIGN=left NOWRAP" ;
    put sub ;
    close_vdisplay_row () ;
    close_vdisplay () ;
    force_item_display ()
  end
;;


let insert_vdisplay open_fun =
  if !verbose > 2 then begin
    prerr_flags "=> insert_vdisplay" ;
  end ;
  try
    let mods = to_pending !cur_out.pending !cur_out.active in
    let bs,bargs,bout = pop_out out_stack in
    if bs <> INTERN then
      failclose "insert_vdisplay" bs INTERN ;
    let ps,pargs,pout = pop_out out_stack in
    if ps <> TD then
      failclose "insert_vdisplay" ps TD ;
    let pps,ppargs,ppout = pop_out out_stack  in
    if pps <> DISPLAY then
      failclose "insert_vdisplay" pps DISPLAY ;
    let new_out = create_status_from_scratch false [] in
    push_out out_stack (pps,ppargs,new_out) ;
    push_out out_stack (ps,pargs,pout) ;
    push_out out_stack (bs,bargs,bout) ;    
    close_display () ;
    cur_out := ppout ;
    open_fun () ;
    do_put (Out.to_string new_out.out) ;
    flags.empty <- false ; flags.blank <- false ;
    free new_out ;    
    if !verbose > 2 then begin
      prerr_string "insert_vdisplay -> " ;
      pretty_mods stderr mods ;
      prerr_newline ()
    end ;
    if !verbose > 2 then
      prerr_flags "<= insert_vdisplay" ;
    mods
  with PopFreeze ->
    raise (UserError "\\over should be properly parenthesized")
;;



let over display lexbuf =
  if display then begin
    let mods = insert_vdisplay
        (fun () ->
          open_vdisplay display ;
          open_vdisplay_row "NOWRAP ALIGN=center") in
    close_vdisplay_row () ;
(*
    open_vdisplay_row "" ;
    close_mods () ;
    horizontal_line  "NOSHADE" Length.Default (Length.Pixel 2);
*)
    open_vdisplay_row "BGCOLOR=black" ;
    close_mods () ;
    line_in_table 3 ;
    close_vdisplay_row () ;
    open_vdisplay_row "NOWRAP ALIGN=center" ;
    close_mods () ;
    open_mods mods ;
    freeze
      (fun () ->
        close_vdisplay_row () ;
        close_vdisplay ();)
  end else begin
    put "/"
  end
;;

(********************************************************
 *  For use by                                          *
 *      \cfrac to align arguments to the left or right  *
 *      \xleftarrow and \xrightarrow to print the arrow *
 *          instead of the fraction bar                 *
 ********************************************************)

let over_align align1 align2 display lexbuf =
  if align1 then begin
    let mods = insert_vdisplay
      (fun () ->
        open_vdisplay display ;
        open_vdisplay_row ("NOWRAP ALIGN=center") ;
        skip_column ()) in
    skip_column () ;
    close_vdisplay_row () ;
    open_vdisplay_row "" ;
    close_mods () ;
    arrow_in_three_cols align2 ;
    close_vdisplay_row () ;
    open_vdisplay_row ("NOWRAP ALIGN=center") ;
    skip_column () ;
    close_mods () ;
    open_mods mods ;
    freeze
      (fun () ->
        skip_column () ;
        close_vdisplay_row () ;
        close_vdisplay ();)
  end
  else begin
    let alignment = if align2 then "ALIGN=right" else "ALIGN=left" in
    if display then begin
      let mods = insert_vdisplay
        (fun () ->
          open_vdisplay display ;
          open_vdisplay_row ("NOWRAP "^alignment)) in
      close_vdisplay_row () ;
      open_vdisplay_row "BGCOLOR=black" ;
      close_mods () ;
      line_in_table 3 ;
      close_vdisplay_row () ;
      open_vdisplay_row ("NOWRAP "^alignment) ;
      close_mods () ;
      open_mods mods ;
      freeze
        (fun () ->
          close_vdisplay_row () ;
          close_vdisplay ();)
    end 
    else begin
      put "/"
    end
  end
;;

let box_around_display lexbuf = 
  let mods = insert_vdisplay
      (fun () ->
        open_vdisplay true ;
        open_vdisplay_row ("NOWRAP ALIGN=center")) in
  close_vdisplay_row () ;
  close_vdisplay () 
;;
    

(* Gestion of left and right delimiters *)

let put_delim delim i =
  if !verbose > 1 then
    prerr_endline
     ("put_delim: ``"^delim^"'' ("^string_of_int i^")") ;
  if delim <> "." then begin
    begin_item_display (fun () -> ()) false ;
    Symb.put_delim skip_line put delim i ;
    let _ = end_item_display () in ()
  end
;;

let left delim k =
  let _,f,is_freeze = end_item_display () in
  delay
    (fun vsize ->
      put_delim delim vsize ;
      begin_item_display (fun () -> ()) false ;
      k vsize ;
      let _ = end_item_display () in
      ()) ;
  begin_item_display f is_freeze
;;

let right delim =
  let vsize,f,is_freeze = end_item_display () in
  put_delim delim vsize;
  flush vsize ;
  begin_item_display f is_freeze ;
  vsize
;;


