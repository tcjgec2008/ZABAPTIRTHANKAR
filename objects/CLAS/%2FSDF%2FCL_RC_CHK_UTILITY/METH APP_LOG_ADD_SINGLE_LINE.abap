METHOD app_log_add_single_line.

**********************************************************************
* Refer to /TMWFLOW/AL_INIT_WRITE_DB
**********************************************************************

  DATA:ls_header    TYPE balhdri,
       lv_date      TYPE sy-datum,
       ls_balmi     TYPE balmi,
       lt_number    TYPE TABLE OF balnri.

  DATA:
    BEGIN OF ls_string,
      part1   TYPE symsgv,
      part2   TYPE symsgv,
      part3   TYPE symsgv,
      part4   TYPE symsgv,
    END OF ls_string.

*--------------------------------------------------------------------*
* Write the header into the buffer of the corresponding object and supobject

  lv_date = syst-datum + c_app_log-log_keep_period.

  ls_header-aldate_del = lv_date.
  ls_header-extnumber  = ms_log_write_db-extnumber.
  ls_header-object     = ms_log_write_db-object.
  ls_header-subobject  = ms_log_write_db-subobject.
  ls_header-aldate     = sy-datum.
  ls_header-altime     = sy-uzeit.
  ls_header-aluser     = sy-uname.
  ls_header-altcode    = sy-tcode.
  ls_header-alprog     = sy-repid.

  CALL FUNCTION 'APPL_LOG_WRITE_HEADER'
    EXPORTING
      header       = ls_header
    IMPORTING
      e_log_handle = mv_log_handle.


*--------------------------------------------------------------------*
* Write a single message to the buffer in insert mode
* map the import inforation into the structure processed in the form
* Refer to BAL_LOG_MSG_ADD_FREE_TEXT and

  ls_string          = iv_mesg_text.
  ls_balmi-msgty     = iv_mesg_type.
  ls_balmi-msgid     = c_app_log-free_text_msgid.
  ls_balmi-msgno     = c_app_log-free_text_msgno.
  ls_balmi-msgv1     = ls_string-part1.
  ls_balmi-msgv2     = ls_string-part2.
  ls_balmi-msgv3     = ls_string-part3.
  ls_balmi-msgv4     = ls_string-part4.
  ls_balmi-detlevel  = iv_mesg_level.
  "ls_balmi-probclass = '1'. " Very Important

  CALL FUNCTION 'APPL_LOG_WRITE_SINGLE_MESSAGE'
    EXPORTING
      update_or_insert = c_app_log-insert
      MESSAGE          = ls_balmi
    EXCEPTIONS
      OTHERS           = 1.
  IF sy-subrc <> 0 AND sy-msgid IS NOT INITIAL
    AND mv_sum_mode = abap_false.

    MESSAGE ID   sy-msgid TYPE 'I' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4."#EC CI_USE_WANTED

  ENDIF.


*--------------------------------------------------------------------*
* Write the log to the database

  CALL FUNCTION 'APPL_LOG_WRITE_DB'
    TABLES
      object_with_lognumber = lt_number.

ENDMETHOD.