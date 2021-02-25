METHOD app_log_sum_log_write.

  DATA: ls_sum_log  TYPE ty_sum_log_str.

*--------------------------------------------------------------------*
* Writ log to SUM log file
* Refer to S_PRE_TRANSITION_CHECKS_TOP -> method _write_message_to_sum_log_file
* The log can be read in AL11 under folder /usr/sap/D3D/SUM/abap/tmp/S4_SIF_TRANSITION_CHECKS.D3D
* The Sapup log scanner reads the file from the tmp directory, scans it and posts its data
* into the log file in the log directory.

  app_log_sum_log_init(
    EXCEPTIONS
      sum_log_err = 1
      OTHERS      = 2 ).
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'W' NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    RETURN.
  ENDIF.


*--------------------------------------------------------------------*
* Write log message one by one

  CHECK so_sum_logger IS BOUND.
  LOOP AT st_sum_log INTO ls_sum_log.
    app_log_add_to_sum_log_file(
      iv_mesg_text = ls_sum_log-mesg_text
      iv_mesg_type = ls_sum_log-mesg_type ).
  ENDLOOP.
  CALL METHOD so_sum_logger->('CLOSE_LOG').

ENDMETHOD.