  METHOD add_success_message.
    DATA lv_message TYPE string.
    DATA: ls_check_result TYPE ty_pre_cons_chk_result_str.

    CLEAR et_chk_result.
    ls_check_result-check_sub_id = 'SI25_NEW_TASK_MNGMT'.
    ls_check_result-return_code  = c_cons_chk_return_code-success.
    CONCATENATE gc_tm_check_wff_restart_manual 'Entry ' gc_tm_check_wff_restart_manual' sucessfully maintained for' INTO lv_message  SEPARATED BY space.
    if iv_param_value = c_migration_run_mode-manual.
       CONCATENATE lv_message 'Manual migration' INTO lv_message  SEPARATED BY space.
    else.
      CONCATENATE lv_message 'Automatic migration' INTO lv_message  SEPARATED BY space.
    endif.

    INSERT lv_message INTO TABLE ls_check_result-descriptions.
    INSERT ls_check_result INTO TABLE et_chk_result.

  ENDMETHOD.