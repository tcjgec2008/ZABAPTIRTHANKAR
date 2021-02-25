METHOD app_log_sum_log_init.

  DATA: ls_class_key TYPE seoclskey.

*--------------------------------------------------------------------*
* Create SUM logger instance

  TYPE-POOLS: seoc.
  TRY.

      ls_class_key-clsname = c_app_log-sum_logger_class_name.
      CALL FUNCTION 'SEO_CLASS_GET'
        EXPORTING
          clskey       = ls_class_key
          version      = seoc_version_active
        EXCEPTIONS
          not_existing = 1
          is_interface = 1
          OTHERS       = 1.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO sv_message.
        sv_message = get_text_str( iv_txt_key = '039' iv_para1 = sv_message )."SUM log error: &P1&
        MESSAGE sv_message TYPE 'W' RAISING sum_log_err.
      ENDIF.
      CREATE OBJECT so_sum_logger TYPE (c_app_log-sum_logger_class_name) "('CL_UPG_LOGGER_620')
        EXPORTING
          iv_filename = c_app_log-sum_log_file_name
          iv_logtype  = c_app_log-sum_log_type_p
          iv_report   = sy-repid
          iv_module   = c_app_log-sum_module_id.

    CATCH cx_root.                                       "#EC CATCH_ALL

      RETURN.
  ENDTRY.

  IF so_sum_logger IS NOT BOUND.
    "SUM log class &P1& instance cannot be created
    sv_message = c_app_log-sum_logger_class_name.
    sv_message = get_text_str( iv_txt_key = '038' iv_para1 = sv_message ).
    MESSAGE sv_message TYPE 'W' RAISING sum_log_err.
  ENDIF.

ENDMETHOD.