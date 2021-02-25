METHOD do_sfwparam_check.

  DATA: ls_chk_result TYPE ty_pre_cons_chk_result_str,
        value         TYPE sfwparamvalue.

* ###########################################################################################################################
* Check for parameter SBCSETS_ACTIVATE_IN_CLIENTS in SFWPARAM

  CLEAR ls_chk_result.
  ls_chk_result-check_sub_id = 'DO_SFWPARAM_CHECK'.

  SELECT SINGLE value FROM sfwparam INTO value WHERE name = 'SBCSETS_ACTIVATE_IN_CLIENTS' AND value = 'X'.

  IF sy-subrc = 0.
    ls_chk_result-return_code = c_cons_chk_return_code-error_skippable.
    APPEND 'Switch Framework parameter SBCSETS_ACTIVATE_IN_CLIENTS is set in table SFWPARAM,'(s01) TO ls_chk_result-descriptions.
    APPEND 'which is definitely not recommended during an upgrade or system conversion.'(s02) TO ls_chk_result-descriptions.
    APPEND 'This will overwrite significant parts of your customer specific customizing!'(s03) TO ls_chk_result-descriptions.
    APPEND 'Please check SAP Note 2035728 for further information and how to fix.'(n02) TO ls_chk_result-descriptions.
    APPEND ls_chk_result TO ct_chk_result.
  ENDIF.

ENDMETHOD.