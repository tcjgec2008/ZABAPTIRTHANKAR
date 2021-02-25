METHOD CONSTRUCTOR.

  super->constructor( 'STCT_UI_SET_SYSALIAS_SAP_CLASS' ).

  if_stctm_task~p_phase     = cl_stc_task_utilities=>c_phase-config.
  if_stctm_task~p_component = 'GATEWAY'.
  if_stctm_task~p_multiple_usage = abap_true.

  " required predecessor
  APPEND 'CL_STCT_CREATE_REQUEST_WBENCH' TO if_stctm_task~pt_predecessor.

  mv_initial = abap_true.

ENDMETHOD.