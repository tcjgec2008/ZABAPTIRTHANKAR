  METHOD check_consistency.
*--------------------------------------------------------------------*
*   Return codes:
*   - 0 Success
*   - 4 warning,
*   - 7 error skippable by exemption
*   - 8 error during check; some necessary steps of pre-processing have not been executed.
*   - 12 error, further processing not possible. Abort pre-processing.
*--------------------------------------------------------------------*
* PRECONDITION
    REFRESH et_chk_result.

* DEFINITIONS
    DATA:
      ls_chk_result TYPE LINE OF ty_pre_cons_chk_result_tab,
      ls_parameter  TYPE LINE OF tihttpnvp,
      lv_msg_text   TYPE string.

* BODY
    READ TABLE it_parameter INTO ls_parameter WITH KEY name = gc_pre_chk_param_key-detailed_check.
    gb_detailed_check = ls_parameter-value.

    et_chk_result = _do_checks( ).

    IF ( et_chk_result IS INITIAL ).
*     at least one message must be returned; otherwise the SIC framework issues an error message:
      lv_msg_text = 'No issues found'.                      "#EC NOTEXT

      ls_chk_result-return_code = gc_return_code-success.
      ls_chk_result-check_sub_id = gc_check_sub_id-fiaa_no_issues.   " 'FIAA_NO_ISSUES'.
      APPEND lv_msg_text TO ls_chk_result-descriptions.

      APPEND ls_chk_result TO et_chk_result.
    ENDIF.


* POSTCONDITION
    "None

  ENDMETHOD.