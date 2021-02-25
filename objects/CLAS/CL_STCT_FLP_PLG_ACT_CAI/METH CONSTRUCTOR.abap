  METHOD constructor.

    super->constructor( 'STCT_UI_FLP_PLG_ACT_CAI' ).

    if_stctm_task~p_component = 'FIORI'.
    if_stctm_task~p_phase     = cl_stc_task_utilities=>c_phase-config.
    if_stctm_task~p_multiple_usage = abap_false.

    " required predecessor
    APPEND 'CL_STCT_CREATE_REQUEST_WBENCH' TO if_stctm_task~pt_predecessor.
    APPEND 'CL_STCT_CREATE_REQUEST_CUST' TO if_stctm_task~pt_predecessor.

  ENDMETHOD.