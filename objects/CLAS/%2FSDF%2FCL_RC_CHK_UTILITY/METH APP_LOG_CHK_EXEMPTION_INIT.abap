METHOD app_log_chk_exemption_init.

  DATA: ls_log TYPE bal_s_log.

*--------------------------------------------------------------------*
* Create APPL LOG HANDLE
* Refer to /TMWFLOW/GLOBAL_CONS_CHECK in ST 7.1 (Z_YF_SD7B5) or AGS_TD_CHK_QGM_CONFIG in ST 7.2
* Refer to R_S4_PRE_TRANSITION_CHECKS -> method _open_application_log

  CLEAR: mv_sum_mode, ms_log_write_db, ms_log_msg.

  ms_log_write_db-extnumber = c_app_log-ext_num_cons_check_skip.
  ms_log_write_db-object    = c_app_log-object."'RC_S4HANAPC'
  ms_log_write_db-subobject = c_app_log-sub_obj_cons_check_skip.

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