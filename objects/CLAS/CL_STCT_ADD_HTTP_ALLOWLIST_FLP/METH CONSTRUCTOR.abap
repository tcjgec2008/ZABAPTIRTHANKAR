  METHOD CONSTRUCTOR.

    super->constructor( 'STCT_UI_ADD_HTTP_ALLOWLIST_FLP' ).
    if_stctm_task~p_phase     = cl_stc_task_utilities=>c_phase-config.
    if_stctm_task~p_component = 'SECURITY'.
    if_stctm_task~p_multiple_usage = abap_false.

  ENDMETHOD.