METHOD do_unicode_check.

  DATA: ls_chk_result TYPE ty_pre_cons_chk_result_str,
        lp_unicode    TYPE trpari-flag.

* ###########################################################################################################################
* Check if the system is a Unicode system.
* Only Unicode systems can be converted to SAP S/4HANA.

  CLEAR ls_chk_result.
  ls_chk_result-check_sub_id = 'DO_UNICODE_CHECK'.

  CALL FUNCTION 'TR_GET_IS_UNICODE_SYSTEM'
    IMPORTING
      ev_is_unicode_system = lp_unicode.

  IF lp_unicode IS INITIAL.
    ls_chk_result-return_code = c_cons_chk_return_code-abortion.
    APPEND 'This is not a Unicode system! Please convert the system to Unicode first.'(u01) TO ls_chk_result-descriptions.
    APPEND 'Only once this is done, you can do a System Conversion to SAP S/4HANA.'(u02) TO ls_chk_result-descriptions.
    APPEND ls_chk_result TO ct_chk_result.
  ENDIF.

ENDMETHOD.