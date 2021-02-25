method CONSTRUCTOR.

  if_stctm_task~p_phase     = cl_stc_task_utilities=>c_phase-config.
  if_stctm_task~p_component = 'GATEWAY'.
  if_stctm_task~p_multiple_usage = abap_true.

  " required predecessor
  append 'CL_STCT_CREATE_REQUEST_CUST' to if_stctm_task~pt_predecessor.

endmethod.