open preamble
     semanticsPropsTheory backendProofTheory x64_configProofTheory
     wordcountProgTheory wordcountCompileTheory

val _ = new_theory"wordcountProof";

val _ = temp_clear_overloads_on"STRCAT";

val wordcount_io_events_def = new_specification("wordcount_io_events_def",["wordcount_io_events"],
  wordcount_semantics |> Q.GENL[`inp`,`files`,`pname`,`fname`]
  |> SIMP_RULE bool_ss [SKOLEM_THM,GSYM RIGHT_EXISTS_IMP_THM]);

val (wordcount_sem,wordcount_output) = wordcount_io_events_def |> SPEC_ALL |> UNDISCH |> CONJ_PAIR
val (wordcount_not_fail,wordcount_sem_sing) = MATCH_MP semantics_prog_Terminate_not_Fail wordcount_sem |> CONJ_PAIR

val compile_correct_applied =
  MATCH_MP compile_correct wordcount_compiled
  |> SIMP_RULE(srw_ss())[LET_THM,ml_progTheory.init_state_env_thm,GSYM AND_IMP_INTRO]
  |> C MATCH_MP wordcount_not_fail
  |> C MATCH_MP x64_backend_config_ok
  |> REWRITE_RULE[wordcount_sem_sing]

val wordcount_compiled_thm =
  CONJ compile_correct_applied wordcount_output
  |> DISCH_ALL
  |> curry save_thm "wordcount_compiled_thm";

val _ = export_theory();
