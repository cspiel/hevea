exception Error of string
;;

let libdir =
  try Sys.getenv "HTMLGENDIR" with Not_found -> LIBDIR
;;


let put_from_lib name put =
  try
    let size = 1024 in
    let buff = String.create size in
    let chan_in = open_in_bin (Filename.concat libdir name) in
    let rec do_rec () =
      let i = input chan_in buff 0 size in
      if i > 0 then begin
        put (String.sub buff 0 i) ;
        do_rec ()
      end in
    do_rec () ;
    close_in chan_in
  with Sys_error _ ->
    raise (Error ("Cannot find file"^name^" from the library"))
;;

let copy_from_lib name =
  try
  let size = 1024 in
  let buff = String.create size in
  let chan_in = open_in_bin (Filename.concat libdir name)
  and chan_out = open_out_bin name in
  let rec do_rec () =
    let i = input chan_in buff 0 size in
    if i > 0 then begin
      output chan_out buff 0 i ;
      do_rec ()
    end in
  do_rec () ;
  close_in chan_in ;
  close_out chan_out
  with Sys_error _ ->
    raise (Error ("Cannot copy file"^name^" from the library"))
;;