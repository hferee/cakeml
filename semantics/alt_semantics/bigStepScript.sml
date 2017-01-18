(*Generated by Lem from bigStep.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasives_extraTheory libTheory namespaceTheory astTheory ffiTheory semanticPrimitivesTheory smallStepTheory;

val _ = numLib.prefer_num();



val _ = new_theory "bigStep"

(*open import Pervasives_extra*)
(*open import Lib*)
(*open import Namespace*)
(*open import Ast*)
(*open import SemanticPrimitives*)
(*open import Ffi*)

(* To get the definition of expression divergence to use in defining definition
 * divergence *)
(*open import SmallStep*)

(* ------------------------ Big step semantics -------------------------- *)

(* If the first argument is true, the big step semantics counts down how many
   functions applications have happened, and raises an exception when the counter
   runs out. *)

val _ = Hol_reln ` (! ck env l s.
T
==>
evaluate ck env s (Lit l) (s, Rval (Litv l)))

/\ (! ck env e s1 s2 v.
(evaluate ck s1 env e (s2, Rval v))
==>
evaluate ck s1 env (Raise e) (s2, Rerr (Rraise v)))

/\ (! ck env e s1 s2 err.
(evaluate ck s1 env e (s2, Rerr err))
==>
evaluate ck s1 env (Raise e) (s2, Rerr err))

/\ (! ck s1 s2 env e v pes.
(evaluate ck s1 env e (s2, Rval v))
==>
evaluate ck s1 env (Handle e pes) (s2, Rval v))

/\ (! ck s1 s2 env e pes v bv.
(evaluate ck env s1 e (s2, Rerr (Rraise v)) /\
evaluate_match ck env s2 v pes v bv)
==>
evaluate ck env s1 (Handle e pes) bv)

/\ (! ck s1 s2 env e pes a.
(evaluate ck env s1 e (s2, Rerr (Rabort a)))
==>
evaluate ck env s1 (Handle e pes) (s2, Rerr (Rabort a)))

/\ (! ck env cn es vs s s' v.
(do_con_check env.c cn (LENGTH es) /\
(build_conv env.c cn (REVERSE vs) = SOME v) /\
evaluate_list ck env s (REVERSE es) (s', Rval vs))
==>
evaluate ck env s (Con cn es) (s', Rval v))

/\ (! ck env cn es s.
(~ (do_con_check env.c cn (LENGTH es)))
==>
evaluate ck env s (Con cn es) (s, Rerr (Rabort Rtype_error)))

/\ (! ck env cn es err s s'.
(do_con_check env.c cn (LENGTH es) /\
evaluate_list ck env s (REVERSE es) (s', Rerr err))
==>
evaluate ck env s (Con cn es) (s', Rerr err))

/\ (! ck env n v s.
(nsLookup env.v n = SOME v)
==>
evaluate ck env s (Var n) (s, Rval v))

/\ (! ck env n s.
(nsLookup env.v n = NONE)
==>
evaluate ck env s (Var n) (s, Rerr (Rabort Rtype_error)))

/\ (! ck env n e s.
T
==>
evaluate ck env s (Fun n e) (s, Rval (Closure env n e)))

/\ (! ck env es vs env' e bv s1 s2.
(evaluate_list ck env s1 (REVERSE es) (s2, Rval vs) /\
(do_opapp (REVERSE vs) = SOME (env', e)) /\
(ck ==> ~ (s2.clock =( 0))) /\
evaluate ck env' (if ck then ( s2 with<| clock := s2.clock -  1 |>) else s2) e bv)
==>
evaluate ck env s1 (App Opapp es) bv)

/\ (! ck env es vs env' e s1 s2.
(evaluate_list ck env s1 (REVERSE es) (s2, Rval vs) /\
(do_opapp (REVERSE vs) = SOME (env', e)) /\
(s2.clock = 0) /\
ck)
==>
evaluate ck env s1 (App Opapp es) (s2, Rerr (Rabort Rtimeout_error)))

/\ (! ck env es vs s1 s2.
(evaluate_list ck env s1 (REVERSE es) (s2, Rval vs) /\
(do_opapp (REVERSE vs) = NONE))
==>
evaluate ck env s1 (App Opapp es) (s2, Rerr (Rabort Rtype_error)))

/\ (! ck env op es vs res s1 s2 refs' ffi'.
(evaluate_list ck env s1 (REVERSE es) (s2, Rval vs) /\
(do_app (s2.refs,s2.ffi) op (REVERSE vs) = SOME ((refs',ffi'), res)) /\
(op <> Opapp))
==>
evaluate ck env s1 (App op es) (( s2 with<| refs := refs'; ffi :=ffi' |>), res))

/\ (! ck env op es vs s1 s2.
(evaluate_list ck env s1 (REVERSE es) (s2, Rval vs) /\
(do_app (s2.refs,s2.ffi) op (REVERSE vs) = NONE) /\
(op <> Opapp))
==>
evaluate ck env s1 (App op es) (s2, Rerr (Rabort Rtype_error)))

/\ (! ck env op es err s1 s2.
(evaluate_list ck env s1 (REVERSE es) (s2, Rerr err))
==>
evaluate ck env s1 (App op es) (s2, Rerr err))

/\ (! ck env op e1 e2 v e' bv s1 s2.
(evaluate ck env s1 e1 (s2, Rval v) /\
(do_log op v e2 = SOME (Exp e')) /\
evaluate ck env s2 e' bv)
==>
evaluate ck env s1 (Log op e1 e2) bv)

/\ (! ck env op e1 e2 v bv s1 s2.
(evaluate ck env s1 e1 (s2, Rval v) /\
(do_log op v e2 = SOME (Val bv)))
==>
evaluate ck env s1 (Log op e1 e2) (s2, Rval bv))

/\ (! ck env op e1 e2 v s1 s2.
(evaluate ck env s1 e1 (s2, Rval v) /\
(do_log op v e2 = NONE))
==>
evaluate ck env s1 (Log op e1 e2) (s2, Rerr (Rabort Rtype_error)))

/\ (! ck env op e1 e2 err s s'.
(evaluate ck env s e1 (s', Rerr err))
==>
evaluate ck env s (Log op e1 e2) (s', Rerr err))

/\ (! ck env e1 e2 e3 v e' bv s1 s2.
(evaluate ck env s1 e1 (s2, Rval v) /\
(do_if v e2 e3 = SOME e') /\
evaluate ck env s2 e' bv)
==>
evaluate ck env s1 (If e1 e2 e3) bv)

/\ (! ck env e1 e2 e3 v s1 s2.
(evaluate ck env s1 e1 (s2, Rval v) /\
(do_if v e2 e3 = NONE))
==>
evaluate ck env s1 (If e1 e2 e3) (s2, Rerr (Rabort Rtype_error)))

/\ (! ck env e1 e2 e3 err s s'.
(evaluate ck env s e1 (s', Rerr err))
==>
evaluate ck env s (If e1 e2 e3) (s', Rerr err))

/\ (! ck env e pes v bv s1 s2.
(evaluate ck env s1 e (s2, Rval v) /\
evaluate_match ck env s2 v pes (Conv (SOME ("Bind", TypeExn (Short "Bind"))) []) bv)
==>
evaluate ck env s1 (Mat e pes) bv)

/\ (! ck env e pes err s s'.
(evaluate ck env s e (s', Rerr err))
==>
evaluate ck env s (Mat e pes) (s', Rerr err))

/\ (! ck env n e1 e2 v bv s1 s2.
(evaluate ck env s1 e1 (s2, Rval v) /\
evaluate ck ( env with<| v := nsOptBind n v env.v |>) s2 e2 bv)
==>
evaluate ck env s1 (Let n e1 e2) bv)

/\ (! ck env n e1 e2 err s s'.
(evaluate ck env s e1 (s', Rerr err))
==>
evaluate ck env s (Let n e1 e2) (s', Rerr err))

/\ (! ck env funs e bv s.
(ALL_DISTINCT (MAP (\ (x,y,z) .  x) funs) /\
evaluate ck ( env with<| v := build_rec_env funs env env.v |>) s e bv)
==>
evaluate ck env s (Letrec funs e) bv)

/\ (! ck env funs e s.
(~ (ALL_DISTINCT (MAP (\ (x,y,z) .  x) funs)))
==>
evaluate ck env s (Letrec funs e) (s, Rerr (Rabort Rtype_error)))

/\ (! ck env e t s bv.
(evaluate ck env s e bv)
==>
evaluate ck env s (Tannot e t) bv)

/\ (! ck env e l s bv.
(evaluate ck env s e bv)
==>
evaluate ck env s (Lannot e l) bv)

/\ (! ck env s.
T
==>
evaluate_list ck env s [] (s, Rval []))

/\ (! ck env e es v vs s1 s2 s3.
(evaluate ck env s1 e (s2, Rval v) /\
evaluate_list ck env s2 es (s3, Rval vs))
==>
evaluate_list ck env s1 (e::es) (s3, Rval (v::vs)))

/\ (! ck env e es err s s'.
(evaluate ck env s e (s', Rerr err))
==>
evaluate_list ck env s (e::es) (s', Rerr err))

/\ (! ck env e es v err s1 s2 s3.
(evaluate ck env s1 e (s2, Rval v) /\
evaluate_list ck env s2 es (s3, Rerr err))
==>
evaluate_list ck env s1 (e::es) (s3, Rerr err))

/\ (! ck env v err_v s.
T
==>
evaluate_match ck env s v [] err_v (s, Rerr (Rraise err_v)))

/\ (! ck env env' v p pes e bv err_v s.
(ALL_DISTINCT (pat_bindings p []) /\
(pmatch env.c s.refs p v [] = Match env') /\
evaluate ck ( env with<| v := nsAppend (alist_to_ns env') env.v |>) s e bv)
==>
evaluate_match ck env s v ((p,e)::pes) err_v bv)

/\ (! ck env v p e pes bv s err_v.
(ALL_DISTINCT (pat_bindings p []) /\
(pmatch env.c s.refs p v [] = No_match) /\
evaluate_match ck env s v pes err_v bv)
==>
evaluate_match ck env s v ((p,e)::pes) err_v bv)

/\ (! ck env v p e pes s err_v.
(pmatch env.c s.refs p v [] = Match_type_error)
==>
evaluate_match ck env s v ((p,e)::pes) err_v (s, Rerr (Rabort Rtype_error)))

/\ (! ck env v p e pes s err_v.
(~ (ALL_DISTINCT (pat_bindings p [])))
==>
evaluate_match ck env s v ((p,e)::pes) err_v (s, Rerr (Rabort Rtype_error)))`;

(* The set tid_or_exn part of the state tracks all of the types and exceptions
 * that have been declared *)
val _ = Hol_reln ` (! ck mn env p e v env' s1 s2.
(evaluate ck env s1 e (s2, Rval v) /\
ALL_DISTINCT (pat_bindings p []) /\
(pmatch env.c s2.refs p v [] = Match env'))
==>
evaluate_dec ck mn env s1 (Dlet p e) (s2, Rval <| v := (alist_to_ns env'); c := nsEmpty |>))

/\ (! ck mn env p e v s1 s2.
(evaluate ck env s1 e (s2, Rval v) /\
ALL_DISTINCT (pat_bindings p []) /\
(pmatch env.c s2.refs p v [] = No_match))
==>
evaluate_dec ck mn env s1 (Dlet p e) (s2, Rerr (Rraise Bindv)))

/\ (! ck mn env p e v s1 s2.
(evaluate ck env s1 e (s2, Rval v) /\
ALL_DISTINCT (pat_bindings p []) /\
(pmatch env.c s2.refs p v [] = Match_type_error))
==>
evaluate_dec ck mn env s1 (Dlet p e) (s2, Rerr (Rabort Rtype_error)))

/\ (! ck mn env p e s.
(~ (ALL_DISTINCT (pat_bindings p [])))
==>
evaluate_dec ck mn env s (Dlet p e) (s, Rerr (Rabort Rtype_error)))

/\ (! ck mn env p e err s s'.
(evaluate ck env s e (s', Rerr err) /\
ALL_DISTINCT (pat_bindings p []))
==>
evaluate_dec ck mn env s (Dlet p e) (s', Rerr err))

/\ (! ck mn env funs s.
(ALL_DISTINCT (MAP (\ (x,y,z) .  x) funs))
==>
evaluate_dec ck mn env s (Dletrec funs) (s, Rval <| v := (build_rec_env funs env nsEmpty); c := nsEmpty |>))

/\ (! ck mn env funs s.
(~ (ALL_DISTINCT (MAP (\ (x,y,z) .  x) funs)))
==>
evaluate_dec ck mn env s (Dletrec funs) (s, Rerr (Rabort Rtype_error)))

/\ (! ck mn env tds s new_tdecs.
(check_dup_ctors tds /\
(new_tdecs = type_defs_to_new_tdecs mn tds) /\
DISJOINT new_tdecs s.defined_types /\
ALL_DISTINCT (MAP (\ (tvs,tn,ctors) .  tn) tds))
==>
evaluate_dec ck mn env s (Dtype tds) (( s with<| defined_types := new_tdecs UNION s.defined_types |>), Rval <| v := nsEmpty; c := (build_tdefs mn tds) |>))

/\ (! ck mn env tds s.
(~ (check_dup_ctors tds) \/
(~ (DISJOINT (type_defs_to_new_tdecs mn tds) s.defined_types) \/
~ (ALL_DISTINCT (MAP (\ (tvs,tn,ctors) .  tn) tds))))
==>
evaluate_dec ck mn env s (Dtype tds) (s, Rerr (Rabort Rtype_error)))

/\ (! ck mn env tvs tn t s.
T
==>
evaluate_dec ck mn env s (Dtabbrev tvs tn t) (s, Rval <| v := nsEmpty; c := nsEmpty |>))

/\ (! ck mn env cn ts s.
(~ (TypeExn (mk_id mn cn) IN s.defined_types))
==>
evaluate_dec ck mn env s (Dexn cn ts) (( s with<| defined_types := {TypeExn (mk_id mn cn)} UNION s.defined_types |>), Rval  <| v := nsEmpty; c := (nsSing cn (LENGTH ts, TypeExn (mk_id mn cn))) |>))

/\ (! ck mn env cn ts s.
(TypeExn (mk_id mn cn) IN s.defined_types)
==>
evaluate_dec ck mn env s (Dexn cn ts) (s, Rerr (Rabort Rtype_error)))`;

val _ = Hol_reln ` (! ck mn env s.
T
==>
evaluate_decs ck mn env s [] (s, Rval <| v := nsEmpty; c := nsEmpty |>))

/\ (! ck mn s1 s2 env d ds e.
(evaluate_dec ck mn env s1 d (s2, Rerr e))
==>
evaluate_decs ck mn env s1 (d::ds) (s2, Rerr e))

/\ (! ck mn s1 s2 s3 env d ds new_env r.
(evaluate_dec ck mn env s1 d (s2, Rval new_env) /\
evaluate_decs ck mn (extend_dec_env new_env env) s2 ds (s3, r))
==>
evaluate_decs ck mn env s1 (d::ds) (s3, combine_dec_result new_env r))`;

val _ = Hol_reln ` (! ck s1 s2 env d new_env.
(evaluate_dec ck [] env s1 d (s2, Rval new_env))
==>
evaluate_top ck env s1 (Tdec d) (s2, Rval new_env))
/\ (! ck s1 s2 env d err.
(evaluate_dec ck [] env s1 d (s2, Rerr err))
==>
evaluate_top ck env s1 (Tdec d) (s2, Rerr err))

/\ (! ck s1 s2 env ds mn specs new_env.
(~ ([mn] IN s1.defined_mods) /\
no_dup_types ds /\
evaluate_decs ck [mn] env s1 ds (s2, Rval new_env))
==>
evaluate_top ck env s1 (Tmod mn specs ds) (( s2 with<| defined_mods := {[mn]} UNION s2.defined_mods |>), Rval <| v := (nsLift mn new_env.v); c := (nsLift mn new_env.c) |>))

/\ (! ck s1 s2 env ds mn specs err.
(~ ([mn] IN s1.defined_mods) /\
no_dup_types ds /\
evaluate_decs ck [mn] env s1 ds (s2, Rerr err))
==>
evaluate_top ck env s1 (Tmod mn specs ds) (( s2 with<| defined_mods := {[mn]} UNION s2.defined_mods |>), Rerr err))

/\ (! ck s1 env ds mn specs.
(~ (no_dup_types ds))
==>
evaluate_top ck env s1 (Tmod mn specs ds) (s1, Rerr (Rabort Rtype_error)))

/\ (! ck env s mn specs ds.
([mn] IN s.defined_mods)
==>
evaluate_top ck env s (Tmod mn specs ds) (s, Rerr (Rabort Rtype_error)))`;

val _ = Hol_reln ` (! ck env s.
T
==>
evaluate_prog ck env s [] (s, Rval <| v := nsEmpty; c := nsEmpty |>))

/\ (! ck s1 s2 s3 env top tops new_env r.
(evaluate_top ck env s1 top (s2, Rval new_env) /\
evaluate_prog ck (extend_dec_env new_env env) s2 tops (s3,r))
==>
evaluate_prog ck env s1 (top::tops) (s3, combine_dec_result new_env r))

/\ (! ck s1 s2 env top tops err.
(evaluate_top ck env s1 top (s2, Rerr err))
==>
evaluate_prog ck env s1 (top::tops) (s2, Rerr err))`;


(*val evaluate_whole_prog : forall 'ffi. Eq 'ffi => bool -> sem_env v -> state 'ffi -> prog ->
          state 'ffi * result (sem_env v) v -> bool*)
val _ = Define `
 (evaluate_whole_prog ck env s1 tops (s2, res) =  
(if no_dup_mods tops s1.defined_mods /\ no_dup_top_types tops s1.defined_types then
    evaluate_prog ck env s1 tops (s2, res)
  else    
(s1 = s2) /\ (res = Rerr (Rabort Rtype_error))))`;


(*val dec_diverges : forall 'ffi. sem_env v -> state 'ffi -> dec -> bool*)
val _ = Define `
 (dec_diverges env st d =  
((case d of
      Dlet p e => ALL_DISTINCT (pat_bindings p []) /\ e_diverges env (st.refs, st.ffi) e
    | Dletrec funs => F
    | Dtype tds => F
    | Dtabbrev tvs tn t => F
    | Dexn cn ts => F
  )))`;


val _ = Hol_reln ` (! mn st env d ds.
(dec_diverges env st d)
==>
decs_diverges mn env st (d::ds))

/\ (! mn s1 s2 env d ds new_env.
(evaluate_dec F mn env s1 d (s2, Rval new_env) /\
decs_diverges mn (extend_dec_env new_env env) s2 ds)
==>
decs_diverges mn env s1 (d::ds))`;

val _ = Hol_reln ` (! st env d.
(dec_diverges env st d)
==>
top_diverges env st (Tdec d))

/\ (! env s1 ds mn specs.
(~ ([mn] IN s1.defined_mods) /\
no_dup_types ds /\
decs_diverges [mn] env s1 ds)
==>
top_diverges env s1 (Tmod mn specs ds))`;

val _ = Hol_reln ` (! st env top tops.
(top_diverges env st top)
==>
prog_diverges env st (top::tops))

/\ (! s1 s2 env top tops new_env.
(evaluate_top F env s1 top (s2, Rval new_env) /\
prog_diverges (extend_dec_env new_env env) s2 tops)
==>
prog_diverges env s1 (top::tops))`;
val _ = export_theory()

