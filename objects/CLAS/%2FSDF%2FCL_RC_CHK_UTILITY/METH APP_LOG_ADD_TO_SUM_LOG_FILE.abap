METHOD app_log_add_to_sum_log_file.

*--------------------------------------------------------------------*
* Writ log to SUM log file
* Refer to S_PRE_TRANSITION_CHECKS_TOP -> method _write_message_to_sum_log_file
* !!! The log interface does only support texts with at most 131 characters !!!
* !!! But 6 characters have to be subtracted for 3 x 2 " " to enclose 3 message variables !!!
* !!! Therefore, text length is 125. !!!


  DATA: lv_message_v1        TYPE symsgv,
        lv_length            TYPE i,
        lv_strlen            TYPE i,
        lt_message           TYPE TABLE OF string,
        lv_message           TYPE string,
        lv_string            TYPE string,
        lv_string_rest       TYPE string.

  CHECK so_sum_logger IS BOUND.
  CHECK iv_mesg_type IS NOT INITIAL.

*--------------------------------------------------------------------*
* Write empty string

  lv_length = STRLEN( iv_mesg_text ).
  IF iv_mesg_text IS INITIAL
    OR iv_mesg_text EQ `--`
    OR iv_mesg_text(lv_length) CO `*`."CO: Contains Only.

    CALL METHOD so_sum_logger->('WRITE_LOG_LINE_S')
      EXPORTING
        iv_severity = iv_mesg_type
        iv_ag       = 'TG'
        iv_msgnr    = '011'
        iv_var1     = ' '.
    RETURN.

  ENDIF.


*--------------------------------------------------------------------*
* Split the message text since maximum displayable length for a text is 90
* Refer to FORM profile_fields_detlevel_append in LSBAL_DISPLAY_BASEF10

  IF STRLEN( iv_mesg_text ) <= c_app_log-sum_log_txt_length.

    lv_message = iv_mesg_text.
    APPEND lv_message TO lt_message.

  ELSE.

    lv_string = iv_mesg_text.
    WHILE lv_string IS NOT INITIAL.
      split_string(
        EXPORTING
          iv_string      = lv_string
          iv_text_length = c_app_log-sum_log_txt_length
        IMPORTING
          ev_msgv        = lv_message
          ev_rest        = lv_string_rest ).
      APPEND lv_message TO lt_message.
      lv_string = lv_string_rest.

    ENDWHILE.
  ENDIF.


*--------------------------------------------------------------------*
* Insert the message one by one

  LOOP AT lt_message INTO lv_message.

    lv_message_v1 = lv_message.
    CALL METHOD so_sum_logger->('WRITE_LOG_LINE_S')
      EXPORTING
        iv_severity = iv_mesg_type
        iv_ag       = 'TG'
        iv_msgnr    = '011'
        iv_var1     = lv_message_v1.

  ENDLOOP.

ENDMETHOD.