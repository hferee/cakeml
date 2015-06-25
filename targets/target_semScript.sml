open HolKernel Parse boolLib bossLib;
open wordsTheory lcsymtacs ffiTheory asmTheory;

val _ = new_theory "target_sem";

(* -- execute target machine with interference from environement -- *)

val () = Datatype `
  error_type = Internal | IO_mismatch `

val () = Datatype `
  machine_result = Result | TimeOut | Error error_type `;

val _ = Datatype `
  machine_config =
   <| prog_addresses : ('a word) set
    (* FFI-specific configurations *)
    ; ffi_entry_pcs : ('a word) list
    ; ptr_reg : num
    ; len_reg : num
    (* major interference by FFI calls *)
    ; ffi_interfer : num -> num -> word8 list -> 'b -> 'b
    (* minor interference during exeuction *)
    ; next_interfer : num -> 'b -> 'b
    (* program exits successfully at halt_pc *)
    ; halt_pc : 'a word
    (* assembly configuration *)
    ; asm_config : 'a asm_config
    (* target next-state fuction etc. *)
    ; f : ('a,'b,'c) target_funs
    |>`

val list_find_def = Define `
  (list_find x [] = NONE) /\
  (list_find x (y::ys) =
     if x = y then SOME (0:num) else
       case list_find x ys of
       | NONE => NONE
       | SOME n => SOME (n+1))`

val read_bytearray_def = Define `
  (read_bytearray a 0 get_byte = SOME []) /\
  (read_bytearray a (SUC n) get_byte =
     case get_byte a of
     | NONE => NONE
     | SOME b => case read_bytearray (a+1w) n get_byte of
                 | NONE => NONE
                 | SOME bs => SOME (b::bs))`

val shift_seq_def = Define `
  shift_seq k s = \i. s (i + k:num)`;

val mEval_def = Define `
  mEval config io k (ms:'a) =
    if k = 0 then (TimeOut,ms,io)
    else
      if config.f.get_pc ms IN config.prog_addresses then
        let ms1 = config.f.next ms in
        let ms2 = config.next_interfer 0 ms1 in
        let config = config with next_interfer :=
                       shift_seq 1 config.next_interfer in
          if EVERY config.f.state_ok [ms;ms1;ms2] then
            mEval config io (k - 1) ms2
          else
            (Error Internal,ms,io)
      else if config.f.get_pc ms = config.halt_pc then
        (Result,ms,io)
      else
        case list_find (config.f.get_pc ms) config.ffi_entry_pcs of
        | NONE => (Error Internal,ms,io)
        | SOME ffi_index =>
          case read_bytearray (config.f.get_reg ms config.ptr_reg)
                 (w2n (config.f.get_reg ms config.len_reg))
                 (\a. if a IN config.prog_addresses
                      then SOME (config.f.get_byte ms a) else NONE) of
          | NONE => (Error Internal,ms,io)
          | SOME bytes =>
            let ffi = config.ffi_interfer 0 ffi_index in
            let config = config with ffi_interfer :=
                           shift_seq 1 config.ffi_interfer in
            let (new_bytes,new_io) = call_FFI ffi_index bytes io in
              if new_io = NONE then (Error IO_mismatch,ms,new_io) else
                mEval config new_io (k - 1:num) (ffi new_bytes ms)`


(* -- observable -- *)

val LPREFIX_def = Define `
  LPREFIX l1 l2 =
    case toList l1 of
    | NONE => (l1 = l2)
    | SOME xs =>
        case toList l2 of
        | NONE => LTAKE (LENGTH xs) l2 = SOME xs
        | SOME ys => isPREFIX xs ys`

val machine_sem_def = Define `
  (machine_sem config ms (Terminate io_list) =
     ?k ms'.
       (mEval config (SOME (fromList io_list)) k ms = (Result,ms',SOME LNIL))) /\
  (machine_sem config ms (Diverge io_trace) =
     (!k. (FST (mEval config (SOME io_trace) k ms) = TimeOut)) /\
     (!io. LPREFIX io io_trace /\ io <> io_trace ==>
           ?k. (FST (mEval config (SOME io) k ms) <> TimeOut))) /\
  (machine_sem config ms Fail =
     ?k io. FST (mEval config io k ms) = Error Internal)`

(* Note: we need to prove that every well-typed program has some
   behaviour, i.e. machine_sem config ms should never be the empty set
   for well-typed programs. *)

(* The semantics that was defined above is exact regarding to the IO
   traces it accepts. In some proofs, it might be easier to use a less
   exact semantics. The following variant admits any extension of an
   divergent I/O trace. *)

val imprecise_machine_sem_def = Define `
  (imprecise_machine_sem config ms (Terminate io_list) =
     ?k ms'.
       mEval config (SOME (fromList io_list)) k ms = (Result,ms',SOME LNIL)) /\
  (imprecise_machine_sem config ms (Diverge io_trace) =
     !k. (FST (mEval config (SOME io_trace) k ms) = TimeOut))`

val call_FFI_LAPPEND = prove(
  ``(call_FFI x' x (SOME io_trace) = (q,SOME r)) ==>
    (call_FFI x' x (SOME (LAPPEND io_trace l)) = (q,SOME (LAPPEND r l)))``,
  fs [call_FFI_def]
  \\ BasicProvers.EVERY_CASE_TAC \\ fs [LET_DEF]
  \\ SRW_TAC [] [] \\ fs [llistTheory.LAPPEND]
  \\ `(io_trace = [||]) \/ ?h t. io_trace = h:::t` by
          METIS_TAC [llistTheory.llist_CASES]
  \\ fs [] \\ SRW_TAC [] [] \\ fs []);

val mEval_LAPPEND_io = prove(
  ``!k ms io_trace config.
      (FST (mEval config (SOME io_trace) k ms) = TimeOut) ==>
      (FST (mEval config (SOME (LAPPEND io_trace l)) k ms) = TimeOut)``,
  Induct THEN1 (ONCE_REWRITE_TAC [mEval_def] \\ fs [])
  \\ ONCE_REWRITE_TAC [mEval_def] \\ fs [] \\ REPEAT STRIP_TAC
  \\ BasicProvers.EVERY_CASE_TAC \\ fs [LET_DEF]
  \\ SRW_TAC [] [] \\ fs [] \\ fs []
  \\ Cases_on `call_FFI x' x (SOME io_trace)` \\ fs []
  \\ Cases_on `r` \\ fs []
  \\ IMP_RES_TAC call_FFI_LAPPEND
  \\ fs [] \\ SRW_TAC [] []);

val imprecise_machine_sem_LAPPEND = store_thm(
   "imprecise_machine_sem_LAPPEND",
  ``(Diverge io_trace) IN machine_sem config ms ==>
    !l. (Diverge (LAPPEND io_trace l)) IN
             imprecise_machine_sem config ms``,
  fs [IN_DEF,machine_sem_def,imprecise_machine_sem_def]
  \\ METIS_TAC [mEval_LAPPEND_io]);

val _ = export_theory();
