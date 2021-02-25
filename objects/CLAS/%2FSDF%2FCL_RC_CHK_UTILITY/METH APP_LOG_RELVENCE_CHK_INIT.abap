METHOD app_log_relvence_chk_init.

  DATA: ls_log TYPE bal_s_log.

*--------------------------------------------------------------------*
* Create APPL LOG HANDLE

  CLEAR: ms_log_write_db, ms_log_msg, mv_sum_mode, st_sum_log.

  ms_log_write_db-extnumber = c_app_log-ext_num_relevancy_check.
  ms_log_write_db-object    = c_app_log-object."'RC_S4HANAPC'
  ms_log_write_db-subobject = c_app_log-sub_obj_relevancy_check.

  ms_log_msg-msg_count = 999.
  ms_log_msg-alsort    = c_app_log-alsort_init.

  "Initialize application log
  CALL FUNCTION 'APPL_LOG_INIT'
    EXPORTING
      object    = ms_log_write_db-object
      subobject = ms_log_write_db-subobject
    EXCEPTIONS
      OTHERS    = 0.

ENDMETHOD.