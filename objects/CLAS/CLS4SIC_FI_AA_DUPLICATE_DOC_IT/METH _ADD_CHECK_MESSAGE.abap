  METHOD _add_check_message.
*--------------------------------------------------------------------*
*   message handler
*--------------------------------------------------------------------*
* PRECONDITION
    CHECK iv_description IS NOT INITIAL.

* DEFINITIONS
    DATA: ls_check_result TYPE ty_pre_cons_chk_result_str,
          lv_description  LIKE LINE OF ls_check_result-descriptions.
    FIELD-SYMBOLS: <ls_check_result> TYPE ty_pre_cons_chk_result_str.

* BODY
    "Program works cross client => add client info to message
    CONCATENATE '( Client' mv_client ')' iv_description INTO lv_description SEPARATED BY space.

    READ TABLE mt_check_results ASSIGNING <ls_check_result>
                                WITH KEY check_sub_id = iv_check_sub_id.
    IF sy-subrc = 0.
      APPEND lv_description TO <ls_check_result>-descriptions.
    ELSE.
      ls_check_result-return_code = iv_return_code.
      ls_check_result-check_sub_id = iv_check_sub_id.
      APPEND lv_description TO ls_check_result-descriptions.
      APPEND ls_check_result TO mt_check_results.
    ENDIF.

* POSTCONDITION
    "None
  ENDMETHOD.