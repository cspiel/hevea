open Symb
;;

type env =
  Style of string
| Font of int
| Color of string

let pretty_env = function
  Style s -> "Style: "^s
| Font i  -> "Font size: "^string_of_int i
| Color s  -> "Font color: "^s
;;

type action =
    Print of string
  | Open of (string * string)
  | Close of string
  | ItemDisplay
  | Print_arg of int
  | Print_fun of ((string -> string) * int)
  | Save_arg of int
  | Print_saved
  | Subst of string
  | Print_count of ((int -> string)  * int)
  | Env of env
  | Test of bool ref
  | SetTest of (bool ref * bool)
  | IfCond of bool ref * action list * action list
  | Br
;;

type pat = string list * string list
;;

let pretty_pat (_,args) =
  List.iter (fun s -> prerr_string s ; prerr_char ',') args
;;


let cmdtable =
  (Hashtbl.create 19 : (string, (pat * action list)) Hashtbl.t)
;;

let verbose = ref 0
;;

let display = ref false
and in_math = ref false
and alltt = ref false
;;

let pretty_macro n acs =
   pretty_pat n ;
   match acs with
     [Subst s] -> Printf.fprintf stderr "{%s}\n" s
   | _         -> Printf.fprintf stderr "...\n"
;;

let def_macro_pat name pat action =
  if !verbose > 1 then begin
   Printf.fprintf stderr "def_macro %s = " name;
   pretty_macro pat action
  end ;
  try
    Hashtbl.find cmdtable name ;
    Location.print_pos () ;
    prerr_string "Ignoring redefinition of: "; prerr_endline name ;
  with
    Not_found ->
      Hashtbl.add cmdtable name (pat,action)
;;

let redef_macro_pat name pat action =
  if !verbose > 1 then begin
   Printf.fprintf stderr "redef_macro %s = " name;
   pretty_macro pat action
  end ;
  try
    Hashtbl.find cmdtable name ;
    Hashtbl.add cmdtable name (pat,action)
  with
    Not_found -> begin
      Location.print_pos () ;
      prerr_string "Redefining non existing: "; prerr_endline name ;
      Hashtbl.add cmdtable name (pat,action)
  end
;;

let make_pat opts n =
  let n_opts = List.length opts in
  let rec do_rec r i =
    if i <=  n_opts  then r
    else do_rec (("#"^string_of_int i)::r) (i-1) in
  opts,do_rec [] n
;;

let def_macro name nargs body =
  def_macro_pat name (make_pat [] nargs) body
and redef_macro name nargs body =
  redef_macro_pat name (make_pat [] nargs) body
;;
     
let def_env name body1 body2 =
 def_macro ("\\"^name) 0 body1 ;
 def_macro ("\\end"^name) 0 body2
;;

let def_env_pat name pat b1 b2 =
  def_macro_pat ("\\"^name) pat b1 ;
  def_macro ("\\end"^name) 0 b2
;;

let find_macro name =
  try
    Hashtbl.find cmdtable name
  with Not_found -> begin
    Location.print_pos () ;
    prerr_string "Unknown macro: "; prerr_endline name ;
    ([],[]),[]
  end
;;

(* for conditionals *)

let extract_if name =
  let l = String.length name in
  if l <= 3 || String.sub name 0 3 <> "\\if" then
    raise (Failure ("Bad newif: "^name)) ;
  String.sub name 3 (l-3)
;;

let newif name = 
  let name = extract_if name in
  let cell = ref false in
  def_macro ("\\if"^name) 0 [Test cell] ;
  def_macro ("\\"^name^"true") 0 [SetTest (cell,true)] ;
  def_macro ("\\"^name^"false") 0 [SetTest (cell,false)] ;
;;

let true_true = ref true and false_false = ref false in
def_macro "\\iftrue" 0 [Test true_true] ;
def_macro "\\iffalse" 0 [Test false_false]
;;


let reg = ref "";;

(* General LaTeX macros *)

def_env "rm" [Env (Style "RM")] [];
def_env "tt" [Env (Style "TT")] [];
def_env "bf" [Env (Style  "B")] [];
def_env "em" [Env (Style "EM")] [];
def_env "it" [Env (Style "I")] [];
def_env "tiny" [Env (Font 1)][];
def_env "footnotesize" [Env (Font 2)][];
def_env "scriptsize" [Env (Font 2)][];
def_env "small" [Env (Font 3)] [];
def_env "normalsize" [Env (Font 3)][];
def_env "large" [Env (Font 4)] [];
def_env "Large" [Env (Font 5)] [];
def_env "huge" [Env (Font 6)] [];
def_env "Huge" [Env (Font 7)] [];
def_env "sl" [] [];
def_env "program" [] [];

def_env "purple" [Env (Color "purple")] [];
def_env "silver" [Env (Color "silver")] [];
def_env "gray" [Env (Color "gray")] [];
def_env "white" [Env (Color "white")] [];
def_env "maroon" [Env (Color "maroon")] [];
def_env "red" [Env (Color "red")] [];
def_env "fuchsia" [Env (Color "fuchsia")] [];
def_env "green" [Env (Color "green")] [];
def_env "lime" [Env (Color "lime")] [];
def_env "olive" [Env (Color "olive")] [];
def_env "yellow" [Env (Color "yellow")] [];
def_env "navy" [Env (Color "navy")] [];
def_env "blue" [Env (Color "blue")] [];
def_env "teal" [Env (Color "teal")] [];
def_env "aqua" [Env (Color "aqua")] [];

def_macro "\\title"  1 [Save_arg 0];
def_macro "\\maketitle" 0 [];

def_macro "\\document" 0
  [Print "<HTML>\n" ; Print "<HEAD><TITLE>\n" ;
   Print_saved; Print "</TITLE></HEAD>" ;
   Print "<BODY>\n" ; Print "<H1 ALIGN=center>" ;
   Print_saved ; Print "</H1>\n"];

def_macro "\\enddocument" 0 [Print "</BODY>\n</HTML>\n"];

def_macro "\\alltt" 0 [];
def_macro "\\endalltt" 0 [];

let no_dot = function
  "." -> ""
| s   -> s in
def_env "titlepage" [] [] ;
def_macro "\\cr" 0 [Subst "\\\\"] ;
def_macro "\\bgroup" 0 [Subst "{"] ;
def_macro "\\egroup" 0 [Subst "}"] ;
def_macro "\\smallskip" 0 [];
def_macro "\\medskip" 0 [];
def_macro "\\bigskip" 0 [Print "<BR>\n"];
def_macro "\\date" 1 [];
def_macro "\\author" 1 [];
def_macro "\\documentclass" 1 [];
def_macro "\\usepackage" 1 [];
def_macro "\\markboth" 2 [];
def_macro "\\dots" 0 [Print "..."];
def_macro "\\ldots" 0 [Print "..."];
def_macro "\\cdots" 0 [Print "..."];
def_macro "\\underline" 1
  [Subst "{" ; Env (Style "U") ; Print_arg 0 ; Subst "}"];
def_macro "\\ " 0 [Print " "];
def_macro "\\{" 0
  [IfCond (in_math,
     [Open ("","") ; Env (Style "RM") ; Print "{" ; Close ""],
     [Print "{"])];
def_macro "\\}" 0
  [IfCond (in_math,
     [Open ("","") ; Env (Style "RM") ; Print "}" ; Close ""],
     [Print "}"])] ;
def_macro "\\%" 0 [Print "%"];
def_macro "\\$" 0 [Print "$"];
def_macro "\\#" 0 [Print "#"];
def_macro "\\/" 0 [];
def_macro "\\newpage" 0 [];
def_macro "\\pagestyle" 1 [];
def_macro "\\thispagestyle" 1 [];
def_macro "\\ref" 1
  [Print "<A href=\"#"; Print_arg 0; Print "\">" ;
   Print_fun (Aux.rget,0) ; Print "</A>"];
def_macro "\\camlref" 1
  [Print "<A href=\"caml:"; Print_arg 0; Print "\">X</A>"];
def_macro "\\pageref" 1 [Print "<A href=\"#"; Print_arg 0; Print "\">X</A>"];

def_macro "\\@bibref" 1  [Print_fun (Aux.bget,0)] ;

def_macro "\\&" 0 [Print "&amp;"];
def_macro "\\_" 0 [Print "_"];
def_macro "\\\n" 0 [Print " "];
def_macro "\\backslash" 0 [Print "\\"];
def_macro "\\neg" 0 [Print "\172"];
let check_in = function
  "\\in" -> "\\notin"
| "="    -> "\\neq"
| "\\subset" -> "\\notsubset"
| s      -> "\\neg"^s in
def_macro "\\not" 1 [Print_fun (check_in,0)];
def_macro "\\raise" 2 [Print_arg 1];
def_macro "\\hbox" 0 [];
def_macro "\\mbox" 0 [];
def_macro "\\vbox" 0 [];
def_macro "\\parbox" 2 [Print_arg 1];
def_macro "\\copyright" 0 [Print "\169"];
def_macro "\\emptyset" 0 [Print "\216"];
def_macro "\\noindent" 0 [];
def_macro "\\kern" 1 [];
def_macro "\\vspace" 1 [];
def_macro "\\vspace*" 1 [];
def_macro "\\vfill" 0 [Print "<BR><BR>"];
let spaces = function
  ".5ex" -> ""
| _      -> "~" in
def_macro "\\hspace" 1 [Print_fun (spaces,0)];
def_macro "\\parskip" 1 [];
def_macro "\\oddsidemargin" 1 [];
def_macro "\\evensidemargin" 1 [];
def_macro "\\textwidth" 1 [];
def_macro "\\textheight" 1 [];
def_macro "\\parindent" 1 [];
def_macro "\\topmargin" 1 [];
def_macro "\\headsep" 1 [];
def_macro "\\topsep" 1 [];
def_macro "\\partopsep" 1 [];
def_macro "\\baselineskip" 1 [];
def_macro "\\-" 0 [];
(* oddities *)
def_macro "\\TeX" 0 [Print "TeX"] ;
def_macro "\\LaTeX" 0 [Print "L<sup>a</sup>T<sub>e</sub>X"] ;
def_macro "\\addcontentsline" 3 [];
def_macro "\\stackrel" 2
  [IfCond (display,
    [Subst "\\begin{array}{c}\\scriptsize #1\\\\ #2\\\\ ~ \\end{array}"],
    [Subst "{#2}^{#1}"])];
(* Maths *)
def_macro "\\vdots" 0
  [IfCond (display,
     [ItemDisplay ; Subst "\\cdot" ; Br ;
     Subst "\\cdot" ; Br ; Subst "\\cdot" ;ItemDisplay],
     [Print ":"])];;
def_macro "\\[" 0 [Subst "$$"];
def_macro "\\]" 0 [Subst "$$"];
def_macro "\\alpha" 0 [Print (get alpha)];
def_macro "\\beta" 0 [Print (get beta)];
def_macro "\\gamma" 0 [Print (get gamma)];
def_macro "\\delta" 0 [Print (get delta)];
def_macro "\\epsilon" 0 [Print (get epsilon)];
def_macro "\\varepsilon" 0 [Print (get varepsilon)];
def_macro "\\zeta" 0 [Print (get zeta)];
def_macro "\\eta" 0 [Print (get eta)];
def_macro "\\theta" 0 [Print (get theta)];
def_macro "\\vartheta" 0 [Print (get vartheta)];
def_macro "\\iota" 0 [Print (get iota)];
def_macro "\\kappa" 0 [Print (get kappa)];
def_macro "\\lambda" 0 [Print (get lambda)];
def_macro "\\mu" 0 [Print (get mu)];
def_macro "\\nu" 0 [Print (get nu)];
def_macro "\\xi" 0 [Print (get xi)];
def_macro "\\pi" 0 [Print (get pi)];
def_macro "\\varpi" 0 [Print (get varpi)];
def_macro "\\rho" 0 [Print (get rho)];
def_macro "\\varrho" 0 [Print (get varrho)];
def_macro "\\sigma" 0 [Print (get sigma)];
def_macro "\\varsigma" 0 [Print (get varsigma)];
def_macro "\\tau" 0 [Print (get tau)];
def_macro "\\upsilon" 0 [Print (get upsilon)];
def_macro "\\phi" 0 [Print (get phi)];
def_macro "\\varphi" 0 [Print (get varphi)];
def_macro "\\chi" 0 [Print (get chi)];
def_macro "\\psi" 0 [Print (get psi)];
def_macro "\\omega" 0 [Print (get omega)];

def_macro "\\Gamma" 0 [Print (get upgamma)];
def_macro "\\Delta" 0 [Print (get updelta)];
def_macro "\\Theta" 0 [Print (get uptheta)];
def_macro "\\Lambda" 0 [Print (get uplambda)];
def_macro "\\Xi" 0 [Print (get upxi)];
def_macro "\\Pi" 0 [Print (get uppi)];
def_macro "\\Sigma" 0 [Print (get upsigma)];
def_macro "\\Upsilon" 0 [Print (get upupsilon)];
def_macro "\\Phi" 0 [Print (get upphi)];
def_macro "\\Psi" 0 [Print (get uppsi)];
def_macro "\\Omega" 0 [Print (get upomega)];
();;

def_macro "\\pm" 0 [Print (get pm)];;
def_macro "\\mp" 0 [Print (get mp)];;
def_macro "\\times" 0 [Print (get times)];;
def_macro "\\div" 0 [Print (get div)];;
def_macro "\\ast" 0 [Print (get ast)];;
def_macro "\\star" 0 [Print (get star)];;
def_macro "\\circ" 0 [Print (get circ)];;
def_macro "\\bullet" 0 [Print (get bullet)];;
def_macro "\\cdot" 0 [Print (get cdot)];;
def_macro "\\cap" 0 [Print (get cap)];;
def_macro "\\cup" 0 [Print (get cup)];;
def_macro "\\sqcap" 0 [Print (get sqcap)];;
def_macro "\\sqcup" 0 [Print (get sqcup)];;
def_macro "\\vee" 0 [Print (get vee)];;
def_macro "\\wedge" 0 [Print (get wedge)];;
def_macro "\\setminus" 0 [Print (get setminus)];;
def_macro "\\wr" 0 [Print (get wr)];;
def_macro "\\diamond" 0 [Print (get diamond)];;
def_macro "\\bigtriangleup" 0 [Print (get bigtriangleup)];;
def_macro "\\bigtriangledown" 0 [Print (get bigtriangledown)];;
def_macro "\\triangleleft" 0 [Print (get triangleleft)];;
def_macro "\\triangleright" 0 [Print (get triangleright)];;
def_macro "\\lhd" 0 [Print (get triangleleft)];;
def_macro "\\rhd" 0 [Print (get triangleright)];;
def_macro "\\leq" 0 [Print (get leq)];;
def_macro "\\subset" 0 [Print (get subset)];;
def_macro "\\notsubset" 0 [Print (get notsubset)];;
def_macro "\\subseteq" 0 [Print (get subseteq)];;
def_macro "\\sqsubset" 0
  [IfCond (display,
    [Print (get display_sqsubset)],
    [Print "sqsubset"])];;
def_macro "\\in" 0 [Print (get elem)];;

def_macro "\\geq" 0 [Print (get geq)];;
def_macro "\\supset" 0 [Print (get supset)];;
def_macro "\\supseteq" 0 [Print (get supseteq)];;
def_macro "\\sqsupset" 0
  [IfCond (display,
     [ItemDisplay ; Print (get display_sqsupset) ; ItemDisplay],
     [Print "sqsupset"])];;
def_macro "\\equiv" 0 [Print (get equiv)];;
def_macro "\\ni" 0 [Print (get ni)];;


def_macro "\\sim" 0 [Print "~"];;
def_macro "\\simeq" 0
  [IfCond (display,
     [ItemDisplay ; Print "~<BR>-" ; ItemDisplay],
     [Print "simeq"])];;
def_macro "\\approx" 0 [Print (get approx)];;
def_macro "\\cong" 0 [Print (get cong)];;
def_macro "\\neq" 0 [Print (get neq)];;
def_macro "\\doteq" 0
  [IfCond (display,
     [ItemDisplay ; Print ".<BR>=" ; ItemDisplay],
     [Print "doteq"])];;
def_macro "\\propto" 0 [Print (get propto)];;
def_macro "\\models" 0 [Print "|="];;
def_macro "\\perp" 0 [Print (get perp)];;

def_macro "\\leftarrow" 0 [Print (get leftarrow)];;
def_macro "\\Leftarrow" 0 [Print (get upleftarrow)];;
def_macro "\\rightarrow" 0 [Print (get rightarrow)];;
def_macro "\\Rightarrow" 0 [Print (get uprightarrow)];;
def_macro "\\leftrightarrow" 0 [Print (get leftrightarrow)];;
def_macro "\\Leftrightarrow" 0 [Print (get upleftrightarrow)];;
def_macro "\\longrightarrow" 0 [Print (get longrightarrow)];;

def_macro "\\infty" 0 [Print (get infty)];;
def_macro "\\forall" 0 [Print (get forall)];;
def_macro "\\exists" 0 [Print (get exists)];;

def_macro "\\lfloor" 0 [Print (get lfloor)];;
def_macro "\\rfloor" 0 [Print (get rfloor)];;
def_macro "\\lceil" 0 [Print (get lceil)];;
def_macro "\\rceil" 0 [Print (get rceil)];;
def_macro "\\langle" 0 [Print (get langle)];;
def_macro "\\rangle" 0 [Print (get rangle)];;

def_macro "\\notin" 0 [Print (get notin)];;

def_macro "\\uparrow" 0 [Print (get uparrow)];;
def_macro "\\Uparrow" 0 [Print (get upuparrow)];;
def_macro "\\downarrow" 0 [Print (get downarrow)];;
def_macro "\\Downarrow" 0 [Print (get updownarrow)];;

def_macro "\\oplus" 0 [Print (get oplus)];;
def_macro "\\otimes" 0 [Print (get otimes)];;
def_macro "\\ominus" 0 [Print (get ominus)];;


def_macro "\\sum" 0 [IfCond (display,[Env (Font 7)],[]) ; Print (get upsigma)];
def_macro "\\int" 0
  [IfCond (display,
    [Print (get display_int)],
    [Print (get int)])];
def_macro "\\mathchardef" 2 [];
def_macro "\\cite" 1 [];
def_macro "\\Nat" 0 [Print "N"];
def_macro "\\;" 0 [Subst "~"] ;
def_macro "\\bar" 1
  [Open ("TABLE","") ; 
   Open ("TR","") ; Open ("TD","HEIGHT=2") ;
   Print "<HR NOSHADE>" ;
   Close "TD" ; Close "TR" ;
   Open ("TR","") ; Open ("TD","ALIGN=center") ;
   Print_arg 0 ;
   Close "TD" ; Close "TR" ; Close "TABLE"] ;
();;

let alpha_of_int i = String.make 1 (Char.chr (i-1+Char.code 'a'))
and upalpha_of_int i = String.make 1 (Char.chr (i-1+Char.code 'A'))
;;

let rec roman_of_int = function
  0 -> ""
| 1 -> "i"
| 2 -> "ii"
| 3 -> "iii"
| 4 -> "iv"
| 9 -> "ix"
| i ->
   if i < 9 then "v"^roman_of_int (i-5)
   else
     let d = i / 10 and u = i mod 10 in
     String.make d 'x'^roman_of_int u
;;

let uproman_of_int i = String.uppercase (roman_of_int i)
;;

      

let aigu = function
  "e" -> "�"
| "E" -> "�"
| s   -> s
and grave = function
  "a"  -> "�"
| "A"  -> "�"
| "e"  -> "�"
| "E" -> "�"
| "u" -> "�"
| "U" -> "�"
| s -> s
and circonflexe = function
  "a"  -> "�"
| "A"  -> "�"
| "e"  -> "�"
| "E" -> "�"
| "i" -> "�"
| "\\i" -> "�"
| "I" -> "�"
| "\\I" -> "�"
| "u" -> "�"
| "U" -> "�"
| s -> s
and trema = function
  "e"  -> "�"
| "E" -> "�"
| "i" -> "�"
| "\\i" -> "�"
| "I" -> "�"
| "\\I" -> "�"
| "u" -> "�"
| "U" -> "�"
| s -> s
and cedille = function
  "c" -> "�"
| "C" -> "�"
| s   -> s
and tilde = function
  "n" -> "�"
| "N" -> "�"
| s   -> s
;;


(* Accents *)
def_macro "\\'" 1 [Print_fun (aigu,0)];
def_macro "\\`" 1 [Print_fun (grave,0)];
def_macro "\\^" 1 [Print_fun (circonflexe,0)];
def_macro "\\\"" 1 [Print_fun (trema,0)];
def_macro "\c" 1  [Print_fun (cedille,0)];
def_macro "\\~" 1 [Print_fun (tilde,0)];

(* Counters *)
def_macro "\\arabic" 1 [Print_count (string_of_int,0)] ;
def_macro "\\alph" 1 [Print_count (alpha_of_int,0)] ;
def_macro "\\Alph" 1 [Print_count (upalpha_of_int,0)] ;
def_macro "\\roman" 1 [Print_count (roman_of_int,0)];
def_macro "\\Roman" 1 [Print_count (uproman_of_int,0)];
def_macro "\\uppercase" 1 [Print_fun (String.uppercase,0)];
();;

(* Macros  specific to me *)
def_macro "\\url" 2
  [Print "<A HREF=\"" ; Print_arg 0 ; Print "\">" ;
  Print_arg 1 ; Print "</A>"] ;
def_macro "\\localurl" 1  [] ;
def_macro "\\programindent" 1 [];
def_macro "\\rule" 2 [Print "<HR>\n"] ;
();;

(* Macros specific to the Caml manual *)

(*
def_env "options" [Print "<p><dl>"] [Print "</dl>"];
def_macro "\\var" 1 [Print "<i>"; Print_arg 0; Print "</i>"];
def_macro "\\nth" 2 [Print "<i>"; Print_arg 0;
                   Print "</i><sub>"; Print_arg 0; Print "</sub>"];
def_macro "\\nmth" 1 [Print "<i>"; Print_arg 0; 
                    Print "</i><sub>"; Print_arg 0;
                    Print "</sub><sup>"; Print_arg 0;
                    Print "</sup>"];
def_env "unix" [Print "<dl><dt><b>Unix:</b><dd>"] [Print "</dl>"];
def_macro "\\endmac" [Print "</dl>"];
def_macro "windows" [Print "<dl><dt><b>Windows:</b><dd>"];
def_macro "\\endwindows" [Print "</dl>"];
def_macro "requirements" [Print "<dl><dt><b>Requirements:</b><dd>"];
def_macro "\\endrequirements" [Print "</dl>"];
def_macro "troubleshooting" [Print "<dl><dt><b>Troubleshooting:</b><dd>"];
def_macro "\\endtroubleshooting" [Print "</dl>"];
def_macro "installation" [Print "<dl><dt><b>Installation:</b><dd>"];
def_macro "\\endinstallation" [Print "</dl>"];
def_macro "\\index" [Skip_arg];
def_macro "\\ikwd" [Skip_arg];
def_macro "\\th" [Print "-th"];
def_macro "library" [];
def_macro "\\endlibrary" [];
def_macro "comment" [Print "<dl><dd>"];
def_macro "\\endcomment" [Print "</dl>"];
def_macro "tableau"
  [Skip_arg;
   Print "<table border>\n<tr><th>";
   Print_arg 0;
   Print "</th><th>";
   Print_arg 0;
   Print "</th></tr>"];
def_macro "\\entree"
  [Print "<tr><td>"; Print_arg 0;
   Print "</td><td>"; Print_arg 0; Print "</td></tr>"];
def_macro "\\endtableau" [Print "</table>"];
def_macro "gcrule" [Print "<dl><dt><b>Rule:</b><dd>"];
def_macro "\\endgcrule" [Print "</dl>"];
def_macro "tableauoperateurs"
  [Print "<table border>\n<tr><th>Operator</th><th>Associated ident</th><th>Behavior in the default environment</th></tr>"];
def_macro "\\endtableauoperateurs" [Print "</table>\n"];
def_macro "\\entreeoperateur"
  [Print "<tr><td>"; Print_arg 0; Print "</td><td>"; Print_arg 0;
   Print "</td><td>"; Print_arg 0; Print "</td></tr>"];
def_macro "\\fromoneto"
  [Print "<i>"; Print_arg 0; Print "</i> = 1, ..., <i>";
   Print_arg 0; Print "</i>"];
def_macro "\\caml_example" 0 [Print "<pre>"];
def_macro "\\endcaml_example"0 [Print "</pre>"];
def_macro "\\rminalltt" 1 [Print_arg 0];
()
;;
*)



let invisible = function
  "\\pagebreak" -> true
| "\\nopagebreak" -> true
| "\linebreak" -> true
| "\\nolinebreak" -> true
| "\\label" -> true
| "\\index" -> true
| "\\vspace" -> true
| "\\glossary" -> true
| "\\marginpar" -> true
| "\\figure" -> true
| "\\table" -> true
| _         -> false
;;

let limit = function
  "\\underbrace"
| "\\sum"
| "\\prod"
| "\\coprod"
| "\\bigcap"
| "\\bigcup"
| "\\bigsqcap"
| "\\bigsqcup"
| "\\bigodot"
| "\\bigdotplus"
| "\\biguplus"
| "\\det" | "\\gcd" | "\\inf" | "\\liminf" |
   "\\limsup" | "\\max" | "\\min" | "\\Pr" | "\\sup" -> true
| _ -> false
;;

let int = function
  "\\int"
| "\\oint" -> true
| _ -> false
;;

let big = function
  "\\sum"
| "\\prod"
| "\\coprod"
| "\\int"
| "\\oint"
| "\\bigcap"
| "\\bigcup"
| "\\bigsqcap"
| "\\bigsqcup"
| "\\bigodot"
| "\\bigdotplus"
| "\\biguplus" -> true
| _ -> false
