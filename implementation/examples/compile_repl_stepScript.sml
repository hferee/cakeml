open preamble repl_computeLib ml_repl_stepTheory
val _ = new_theory"compile_repl_step"

val _ = Hol_datatype`stop_list = stop_NIL | stop_CONS of 'a => stop_list`

val _ = computeLib.stoppers := let
  val stop_CONS = inst[alpha|->``:bc_inst list``]``stop_CONS``
  val stoppers = [stop_CONS ,``Dlet``,``Dletrec``,``Dtype``]
  in SOME (fn tm => mem tm stoppers) end

val compile_decs_def = Define`
  compile_decs cs [] acc = acc ∧
  compile_decs cs (d::ds) acc =
  let (css,csf,code) = compile_top cs (Tdec d) in
  compile_decs css ds (stop_CONS code acc)`

val _ = computeLib.add_funs[ml_repl_step_decls]

val compile_dec1_def = Define`
  compile_dec1 (a,cs) d =
    let (css,csf,code) = compile_top cs (Tdec d)
    in
      (stop_CONS code a, css)
`

val compile_decs_FOLDL = store_thm(
  "compile_decs_FOLDL",
  ``∀cs acc.
      compile_decs (cs:compiler_state) ds acc =
      FST (FOLDL compile_dec1 (acc,cs) ds)``,
  Induct_on `ds` >> rw[compile_decs_def, compile_dec1_def]);

fun rbinop_size acc t =
    if is_const t orelse is_var t then acc else rbinop_size (acc + 1) (rand t)
fun lbinop_size acc t =
    if is_const t orelse is_var t then acc else lbinop_size (acc + 1) (lhand t)

fun term_lsplit_after n t = let
  fun recurse acc n t =
    if n <= 0 then (List.rev acc, t)
    else
      let val (fx,y) = dest_comb t
          val (f,x) = dest_comb fx
      in
        recurse (x::acc) (n - 1) y
      end handle HOL_ERR _ => (List.rev acc, t)
in
  recurse [] n t
end

val (app_nil, app_cons) = CONJ_PAIR listTheory.APPEND
fun APP_CONV t = (* don't eta-convert *)
    ((REWR_CONV app_cons THENC RAND_CONV APP_CONV) ORELSEC
     REWR_CONV app_nil) t

fun onechunk n t = let
  val (pfx, sfx) = term_lsplit_after n t
in
  if null pfx orelse listSyntax.is_nil sfx then raise UNCHANGED
  else let
    val pfx_t = listSyntax.mk_list(pfx, type_of (hd pfx))
  in
    APP_CONV (listSyntax.mk_append(pfx_t, sfx)) |> SYM
  end
end

fun chunkify_CONV n t =
    TRY_CONV (onechunk n THENC RAND_CONV (chunkify_CONV n)) t

fun foldl_append_CONV t = let
  fun core t = (PolyML.fullGC(); EVAL t)
in
  REWR_CONV rich_listTheory.FOLDL_APPEND THENC
  RATOR_CONV (RAND_CONV core)
end t

fun iterate n t = let
  fun recurse m th =
      if m < 1 then th
      else
        let
          val _ = print (Int.toString (n - m) ^ ": ")
          val th' = time foldl_append_CONV (rhs (concl th))
        in
          recurse (m - 1) (TRANS th th')
        end
in
  recurse n (REFL t)
end

fun fmkeys fm_t = let
  val kv = rand fm_t
in
  lhand kv :: fmkeys (lhand fm_t)
end handle HOL_ERR _ => []

val FLOOKUP_t = prim_mk_const { Thy = "finite_map", Name = "FLOOKUP"}
val lookup_fmty = #1 (dom_rng (type_of FLOOKUP_t))
fun mk_flookup_eqn fm k =
    EVAL (mk_comb(mk_icomb(FLOOKUP_t, fm), k))

val mk_def = let
  val iref = ref 0
in
  fn t => let
    val i = !iref
    val _ = iref := !iref + 1;
    val nm = "internal" ^ Int.toString (!iref)
  in
    new_definition(nm ^ "_def", mk_eq(mk_var(nm, type_of t), t))
  end
end

fun extract_fmap sz t = let
  fun test t = finite_mapSyntax.is_fupdate t andalso lbinop_size 0 t > sz
  val fm = find_term test t
  val lookup_t = inst (match_type lookup_fmty (type_of fm)) FLOOKUP_t
  val def = mk_def fm
  val def' = SYM def
  val fl_def' = AP_TERM lookup_t def
  val c_t = lhs (concl def)
  val keys = fmkeys fm
  fun fulleqn k = let
    val th0 = AP_THM fl_def' k
  in
    CONV_RULE (RAND_CONV EVAL) th0
  end
  val eqns = map fulleqn keys
in
  (ONCE_DEPTH_CONV (REWR_CONV def') t, eqns)
end


(*
val _ = Globals.max_print_depth := 20

fun mk_initial_split n =
  ``FOLDL compile_dec1 (stop_NIL, init_compiler_state) ml_repl_step_decls``
     |> (RAND_CONV (EVAL THENC chunkify_CONV n) THENC
         RATOR_CONV (RAND_CONV EVAL))

val initial_split20 = mk_initial_split 20
val initial_split10 = time mk_initial_split 10

val thm120 = CONV_RULE (RAND_CONV (iterate 6)) initial_split20

val (fmreplace, eqns) = extract_fmap 50 (rhs (concl thm120))



val thm150 = CONV_RULE (RAND_CONV (iterate 15)) initial_split10

val thm140 = CONV_RULE (RAND_CONV (iterate 1)) thm120
val thm160 = CONV_RULE (RAND_CONV (iterate 1)) thm140

val _ = PolyML.fullGC();
val res = time EVAL
  ``compile_decs init_compiler_state (TAKE 100 ml_repl_step_decls) stop_NIL``
*)

(*
EVAL ``TAKE 20 (DROP 100 ml_repl_step_decls)``
val _ = time EVAL ``compile_decs init_compiler_state ml_repl_step_decls stop_NIL``
*)

(*
val Dlet_o = time EVAL ``EL 11 ml_repl_step_decls`` |> concl |> rhs
val many_o10 = EVAL ``GENLIST (K ^Dlet_o) 10`` |> concl |> rhs
val many_o20 = EVAL ``GENLIST (K ^Dlet_o) 20`` |> concl |> rhs
val many_o40 = EVAL ``GENLIST (K ^Dlet_o) 40`` |> concl |> rhs
val many_o80 = EVAL ``GENLIST (K ^Dlet_o) 80`` |> concl |> rhs
val many_o160 = EVAL ``GENLIST (K ^Dlet_o) 160`` |> concl |> rhs

val _ = PolyML.fullGC();
val _ = time EVAL ``compile_decs init_compiler_state ^many_o10 stop_NIL``
val _ = PolyML.fullGC();
val _ = time EVAL ``compile_decs init_compiler_state ^many_o20 stop_NIL``
val _ = PolyML.fullGC();
val _ = time EVAL ``compile_decs init_compiler_state ^many_o40 stop_NIL``
val _ = PolyML.fullGC();
val _ = time EVAL ``compile_decs init_compiler_state ^many_o80 stop_NIL``
val _ = PolyML.fullGC();
val _ = time EVAL ``compile_decs init_compiler_state ^many_o160 stop_NIL``

val _ = computeLib.stoppers := NONE
val num_compset = reduceLib.num_compset()
*)

val _ = export_theory()
