signature ml_monad_translatorLib = 
sig
    include ml_translatorLib

    type monadic_translation_parameters = ml_monadStoreLib.monadic_translation_parameters
    type store_translation_result = ml_monadStoreLib.store_translation_result

    (* Functions to initialize the translation *)
    val start_static_init_fixed_store_translation :
	(string * thm * thm * thm) list ->
	(string * thm * thm * thm * thm * thm * thm * thm) list ->
	string -> hol_type -> thm -> (thm * thm) list ->  string list ->
	(thm * thm) option ->
        monadic_translation_parameters * store_translation_result *
        (thm * thm) list

    val start_dynamic_init_fixed_store_translation :
	(string * thm * thm) list ->
	(string * thm * thm * thm * thm * thm * thm) list -> string ->
	hol_type -> thm -> (thm * thm) list -> string list -> thm option ->
        monadic_translation_parameters * (thm * thm) list

    (* Other functions to initialize the translation - the above ones should be preferred *)
    val init_translation :
        monadic_translation_parameters -> (thm * thm) list ->
	(thm * thm * thm * thm * thm * thm) list -> (thm * thm) list ->
        thm option -> thm -> string list -> thm option -> unit
    val add_raise_handle_functions : (thm * thm) list -> thm -> (thm * thm) list

    (* Translation functions *)
    val m_translate : thm -> thm
    val m_translate_run : thm -> thm
end
