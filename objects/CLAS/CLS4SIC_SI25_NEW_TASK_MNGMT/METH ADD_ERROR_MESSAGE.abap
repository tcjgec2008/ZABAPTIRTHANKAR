  METHOD add_error_message.
    DATA lv_message TYPE string.
    DATA: ls_check_result TYPE ty_pre_cons_chk_result_str.

    CLEAR et_chk_result.
    ls_check_result-check_sub_id = 'SI25_NEW_TASK_MNGMT'.
    ls_check_result-return_code  = c_cons_chk_return_code-error.
    CONCATENATE gc_tm_check_wff_restart_manual 'Parameter should be maintained in table ' gc_s4sic_param_table_name 'for manual or automatic migration. See SAP Note 2927227' INTO lv_message  SEPARATED BY space.
    INSERT lv_message INTO TABLE ls_check_result-descriptions.
    INSERT ls_check_result INTO TABLE et_chk_result.

  ENDMETHOD.