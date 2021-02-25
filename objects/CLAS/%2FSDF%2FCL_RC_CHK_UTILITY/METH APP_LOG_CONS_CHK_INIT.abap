METHOD app_log_cons_chk_init.

  DATA: ls_log TYPE bal_s_log.

  mv_sum_mode = iv_sum_mode.

*--------------------------------------------------------------------*
* Create APPL LOG HANDLE
* Refer to /TMWFLOW/GLOBAL_CONS_CHECK in ST 7.1 (Z_YF_SD7B5) or AGS_TD_CHK_QGM_CONFIG in ST 7.2
* Refer to R_S4_PRE_TRANSITION_CHECKS -> method _open_application_log

  CLEAR: ms_log_write_db, ms_log_msg.

  IF iv_detailed_chk = abap_true.
    ms_log_write_db-extnumber = c_app_log-ext_num_cons_check_sel.
  ELSE.
    ms_log_write_db-extnumber = c_app_log-ext_num_cons_check_all.
  ENDIF.
  ms_log_write_db-object    = c_app_log-object."'RC_S4HANAPC'
  ms_log_write_db-subobject = iv_sub_object.

  ms_log_msg-msg_count = 999.
  ms_log_msg-alsort    = c_app_log-alsort_init.

  "Initialize application log
  CALL FUNCTION 'APPL_LOG_INIT'
    EXPORTING
      object    = ms_log_write_db-object
      subobject = ms_log_write_db-subobject
    EXCEPTIONS
      OTHERS    = 0.


*--------------------------------------------------------------------*
* Initialize SUM log

  CLEAR st_sum_log.

ENDMETHOD.