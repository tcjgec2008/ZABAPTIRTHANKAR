METHOD app_log_exists.

  DATA: lt_object          TYPE bal_r_obj,
        ls_object          TYPE bal_s_obj,
        ls_log_filter      TYPE bal_s_lfil.

*--------------------------------------------------------------------*
* Display the application log

  ls_object-sign   = 'I'.
  ls_object-option = 'EQ'.
  ls_object-low    = /sdf/cl_rc_chk_utility=>c_app_log-object.
  APPEND ls_object TO lt_object.
  ls_log_filter-object = lt_object.

*--------------------------------------------------------------------*
* Searc and load the log handler

  CALL FUNCTION 'BAL_DB_SEARCH'
    EXPORTING
      i_s_log_filter     = ls_log_filter
    EXCEPTIONS
      log_not_found      = 1
      no_filter_criteria = 2
      OTHERS             = 3.
  IF sy-subrc = 0.
    rv_log_exists = abap_true.
  ENDIF.

ENDMETHOD.