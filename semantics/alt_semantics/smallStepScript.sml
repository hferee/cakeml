(*Generated by Lem from smallStep.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasives_extraTheory libTheory namespaceTheory astTheory ffiTheory semanticPrimitivesTheory;

val _ = numLib.prefer_num();



val _ = new_theory "smallStep"

(*open import Pervasives_extra*)
(*open import Lib*)
(*open import Ast*)
(*open import Namespace*)
(*open import SemanticPrimitives*)
(*open import Ffi*)

(* Small-step semantics for expression only.  Modules and definitions have
 * big-step semantics only *)

(* Evaluation contexts
 * The hole is denoted by the unit type
 * The env argument contains bindings for the free variables of expressions in
     the context *)
val _ = Hol_datatype `
 ctxt_frame =
    Craise of unit
  | Chandle of unit => (pat # exp) list
  | Capp of op => v list => unit => exp list
  | Clog of lop => unit => exp
  | Cif of unit => exp => exp
  (* The value is raised if none of the patterns match *)
  | Cmat of unit => (pat # exp) list => v
  | Clet of  varN option => unit => exp
  (* Evaluating a constructor's arguments
   * The v list should be in reverse order. *)
  | Ccon of  ( (modN, conN)id)option => v list => unit => exp list
  | Ctannot of unit => t
  | Clannot of unit => locn`;

val _ = type_abbrev( "ctxt" , ``: ctxt_frame # v sem_env``);

(* State for CEK-style expression evaluation
 * - constructor data
 * - the store
 * - the environment for the free variables of the current expression
 * - the current expression to evaluate, or a value if finished
 * - the context stack (continuation) of what to do once the current expression
 *   is finished.  Each entry has an environment for it's free variables *)

val _ = type_abbrev((*  'ffi *) "small_state" , ``: v sem_env # ('ffi, v) store_ffi # exp_or_val # ctxt list``);

val _ = Hol_datatype `
 e_step_result =
    Estep of 'ffi small_state
  | Eabort of abort
  | Estuck`;


(* The semantics are deterministic, and presented functionally instead of
 * relationally for proof rather that readability; the steps are very small: we
 * push individual frames onto the context stack instead of finding a redex in a
 * single step *)

(*val push : forall 'ffi. sem_env v -> store_ffi 'ffi v -> exp -> ctxt_frame -> list ctxt -> e_step_result 'ffi*)
val _ = Define `
 (push env s e c' cs = (Estep (env, s, Exp e, ((c',env)::cs))))`;


(*val return : forall 'ffi. sem_env v -> store_ffi 'ffi v -> v -> list ctxt -> e_step_result 'ffi*)
val _ = Define `
 (return env s v c = (Estep (env, s, Val v, c)))`;


(*val application : forall 'ffi. op -> sem_env v -> store_ffi 'ffi v -> list v -> list ctxt -> e_step_result 'ffi*)
val _ = Define `
 (application op env s vs c =  
((case op of
      Opapp =>
      (case do_opapp vs of
          SOME (env,e) => Estep (env, s, Exp e, c)
        | NONE => Eabort Rtype_error
      )
    | _ =>
      (case do_app s op vs of
          SOME (s',r) =>
          (case r of
              Rerr (Rraise v) => Estep (env,s',Val v,((Craise () ,env)::c))
            | Rerr (Rabort a) => Eabort a
            | Rval v => return env s' v c
          )
        | NONE => Eabort Rtype_error
      )
    )))`;


(* apply a context to a value *)
(*val continue : forall 'ffi. store_ffi 'ffi v -> v -> list ctxt -> e_step_result 'ffi*)
val _ = Define `
 (continue s v cs =  
((case cs of
      [] => Estuck
    | (Craise () , env) :: c=>
        (case c of
            [] => Estuck
          | ((Chandle ()  pes,env') :: c) =>
              Estep (env,s,Val v,((Cmat ()  pes v, env')::c))
          | _::c => Estep (env,s,Val v,((Craise () ,env)::c))
        )
    | (Chandle ()  pes, env) :: c =>
        return env s v c
    | (Capp op vs ()  [], env) :: c =>
        application op env s (v::vs) c
    | (Capp op vs ()  (e::es), env) :: c =>
        push env s e (Capp op (v::vs) ()  es) c
    | (Clog l ()  e, env) :: c =>
        (case do_log l v e of
            SOME (Exp e) => Estep (env, s, Exp e, c)
          | SOME (Val v) => return env s v c
          | NONE => Eabort Rtype_error
        )
    | (Cif ()  e1 e2, env) :: c =>
        (case do_if v e1 e2 of
            SOME e => Estep (env, s, Exp e, c)
          | NONE => Eabort Rtype_error
        )
    | (Cmat ()  [] err_v, env) :: c =>
        Estep (env, s, Val err_v, ((Craise () , env) ::c))
    | (Cmat ()  ((p,e)::pes) err_v, env) :: c =>
        if ALL_DISTINCT (pat_bindings p []) then
          (case pmatch env.c (FST s) p v [] of
              Match_type_error => Eabort Rtype_error
            | No_match => Estep (env, s, Val v, ((Cmat ()  pes err_v,env)::c))
            | Match env' => Estep (( env with<| v := nsAppend (alist_to_ns env') env.v |>), s, Exp e, c)
          )
        else
          Eabort Rtype_error
    | (Clet n ()  e, env) :: c =>
        Estep (( env with<| v := nsOptBind n v env.v |>), s, Exp e, c)
    | (Ccon n vs ()  [], env) :: c =>
        if do_con_check env.c n (LENGTH vs + 1) then
           (case build_conv env.c n (v::vs) of
               NONE => Eabort Rtype_error
             | SOME v => return env s v c
           )
        else
          Eabort Rtype_error
    | (Ccon n vs ()  (e::es), env) :: c =>
        if do_con_check env.c n (((LENGTH vs + 1) + 1) + LENGTH es) then
          push env s e (Ccon n (v::vs) ()  es) c
        else
          Eabort Rtype_error
    | (Ctannot ()  t, env) :: c =>
        return env s v c
    | (Clannot ()  l, env) :: c =>
        return env s v c
  )))`;


(* The single step expression evaluator.  Returns None if there is nothing to
 * do, but no type error.  Returns Type_error on encountering free variables,
 * mis-applied (or non-existent) constructors, and when the wrong kind of value
 * if given to a primitive.  Returns Bind_error when no pattern in a match
 * matches the value.  Otherwise it returns the next state *)

(*val e_step : forall 'ffi. small_state 'ffi -> e_step_result 'ffi*)
val _ = Define `
 (e_step (env, s, ev, c) =  
((case ev of
      Val v  =>
        continue s v c
    | Exp e =>
        (case e of
            Lit l => return env s (Litv l) c
          | Raise e =>
              push env s e (Craise () ) c
          | Handle e pes =>
              push env s e (Chandle ()  pes) c
          | Con n es =>
              if do_con_check env.c n (LENGTH es) then
                (case REVERSE es of
                    [] =>
                      (case build_conv env.c n [] of
                          NONE => Eabort Rtype_error
                        | SOME v => return env s v c
                      )
                  | e::es =>
                      push env s e (Ccon n [] ()  es) c
                )
              else
                Eabort Rtype_error
          | Var n =>
              (case nsLookup env.v n of
                  NONE => Eabort Rtype_error
                | SOME v =>
                    return env s v c
              )
          | Fun n e => return env s (Closure env n e) c
          | App op es =>
              (case REVERSE es of
                  [] => application op env s [] c
                | (e::es) => push env s e (Capp op [] ()  es) c
              )
          | Log l e1 e2 => push env s e1 (Clog l ()  e2) c
          | If e1 e2 e3 => push env s e1 (Cif ()  e2 e3) c
          | Mat e pes => push env s e (Cmat ()  pes (Conv (SOME ("Bind", TypeExn (Short "Bind"))) [])) c
          | Let n e1 e2 => push env s e1 (Clet n ()  e2) c
          | Letrec funs e =>
              if ~ (ALL_DISTINCT (MAP (\ (x,y,z) .  x) funs)) then
                Eabort Rtype_error
              else
                Estep (( env with<| v := build_rec_env funs env env.v |>),
                       s, Exp e, c)
          | Tannot e t => push env s e (Ctannot ()  t) c
          | Lannot e l => push env s e (Clannot ()  l) c
        )
  )))`;


(* Define a semantic function using the steps *)

(*val e_step_reln : forall 'ffi. small_state 'ffi -> small_state 'ffi -> bool*)
(*val small_eval : forall 'ffi. sem_env v -> store_ffi 'ffi v -> exp -> list ctxt -> store_ffi 'ffi v * result v v -> bool*)

val _ = Define `
 (e_step_reln st1 st2 =
  (e_step st1 = Estep st2))`;


 val _ = Define `

(small_eval env s e c (s', Rval v) =  
(? env'. (RTC (e_step_reln)) (env,s,Exp e,c) (env',s',Val v,[])))
/\
(small_eval env s e c (s', Rerr (Rraise v)) =  
(? env' env''. (RTC (e_step_reln)) (env,s,Exp e,c) (env',s',Val v,[(Craise () , env'')])))
/\
(small_eval env s e c (s', Rerr (Rabort a)) =  
(? env' e' c'.
    (RTC (e_step_reln)) (env,s,Exp e,c) (env',s',e',c') /\
    (e_step (env',s',e',c') = Eabort a)))`;


(*val e_diverges : forall 'ffi. sem_env v -> store_ffi 'ffi v -> exp -> bool*)
val _ = Define `
 (e_diverges env s e =  
(! env' s' e' c'.
    (RTC (e_step_reln)) (env,s,Exp e,[]) (env',s',e',c')
    ==>
(? env'' s'' e'' c''.
      e_step_reln (env',s',e',c') (env'',s'',e'',c''))))`;

val _ = export_theory()

