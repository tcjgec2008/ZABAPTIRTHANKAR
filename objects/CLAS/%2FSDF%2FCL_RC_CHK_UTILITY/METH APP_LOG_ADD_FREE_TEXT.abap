METHOD app_log_add_free_text.

*--------------------------------------------------------------------*
* Create APPL LOG HANDLE
* Refer to R_S4_PRE_TRANSITION_CHECKS -> method _write_message_to_logs

  DATA: lt_message     TYPE TABLE OF string,
        lv_length      TYPE i,
        lv_message     TYPE string,
        lv_string      TYPE string,
        lv_string_rest TYPE string,
        ls_sum_log     TYPE ty_sum_log_str.

  CHECK iv_mesg_text IS NOT INITIAL AND iv_mesg_type IS NOT INITIAL.

*--------------------------------------------------------------------*
* Split the message text since maximum displayable length for a text is 90
* Refer to FORM profile_fields_detlevel_append in LSBAL_DISPLAY_BASEF10

  IF STRLEN( iv_mesg_text ) <= c_app_log-txt_length.

    lv_message = iv_mesg_text.
    APPEND lv_message TO lt_message.

  ELSE.

    lv_string = iv_mesg_text.
    WHILE lv_string IS NOT INITIAL.
      split_string(
        EXPORTING
          iv_string      = lv_string
          iv_text_length = c_app_log-txt_length
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

    app_log_add_single_line(
      iv_mesg_text  = lv_message
      iv_mesg_type  = iv_mesg_type
      iv_mesg_level = iv_mesg_level ).

  ENDLOOP.


*--------------------------------------------------------------------*
* Record SUM log file

  IF iv_mesg_text_sum IS NOT INITIAL.
    ls_sum_log-mesg_text = iv_mesg_text_sum.
  ELSE.
    ls_sum_log-mesg_text = iv_mesg_text.
  ENDIF.

  IF iv_mesg_type_sum IS NOT INITIAL.
    ls_sum_log-mesg_type = iv_mesg_type_sum.
  ELSE.
    ls_sum_log-mesg_type = iv_mesg_type.
  ENDIF.
  APPEND ls_sum_log TO st_sum_log.

ENDMETHOD.