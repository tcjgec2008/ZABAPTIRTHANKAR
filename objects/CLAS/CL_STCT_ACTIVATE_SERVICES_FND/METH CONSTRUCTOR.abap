  METHOD CONSTRUCTOR.

    if_stctm_task~p_component = 'GATEWAY'.
    if_stctm_task~p_phase     = cl_stc_task_utilities=>c_phase-config.
    if_stctm_task~p_multiple_usage = abap_false.

  ENDMETHOD.                    "CONSTRUCTOR