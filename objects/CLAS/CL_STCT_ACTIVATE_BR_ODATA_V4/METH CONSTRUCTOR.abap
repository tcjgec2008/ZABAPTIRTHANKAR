  METHOD CONSTRUCTOR.

    super->constructor( ).

    if_stctm_task~p_component = 'FIORI'.
    if_stctm_task~p_phase     = cl_stc_task_utilities=>c_phase-config.
    if_stctm_task~p_multiple_usage = abap_false.

  ENDMETHOD.