METHOD sitem_skip_stat_update_single.

  DATA:lt_sitem_skip        TYPE ty_sitem_skip_tab,
       lt_cons_chk_result   TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_result_tab,
       lt_cons_chk_hdr_info TYPE salv_wd_t_string,
       ls_header_info       TYPE ty_consis_chk_header_str,
       lt_clas_chk_result   TYPE /sdf/cl_rc_chk_utility=>ty_pre_cons_chk_result_tab.
  FIELD-SYMBOLS:
       <fs_item_skip>       TYPE ty_sitem_skip_str,
       <fs_item_result>     TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_result_str,
       <fs_clas_chk_result> TYPE /sdf/cl_rc_chk_utility=>ty_pre_cons_chk_result_str.

  CHECK is_sitem_skip IS NOT INITIAL.

*--------------------------------------------------------------------*
* Merge the lastes skipped status

  sitem_skip_stat_get(
    EXPORTING
      iv_target_stack = iv_target_stack
    IMPORTING
      et_sitem_skip   = lt_sitem_skip ).

  READ TABLE lt_sitem_skip ASSIGNING <fs_item_skip>
    WITH KEY sitem_guid = is_sitem_skip-sitem_guid.
  IF sy-subrc = 0.
    MOVE-CORRESPONDING is_sitem_skip TO <fs_item_skip>.
  ELSE.
    APPEND is_sitem_skip TO lt_sitem_skip.
  ENDIF.


*--------------------------------------------------------------------*
* Store the data into DB

  sitem_skip_stat_update_mass(
    iv_target_stack = iv_target_stack
    it_sitem_skip   = lt_sitem_skip ).


*--------------------------------------------------------------------*
* Update consistency check result

  sitem_consistency_result_get(
    EXPORTING
      iv_target_stack     = iv_target_stack
    IMPORTING
      et_cons_chk_result  = lt_cons_chk_result
      et_cons_header_info = lt_cons_chk_hdr_info
      es_header_info      = ls_header_info ).
  LOOP AT lt_cons_chk_result ASSIGNING <fs_item_result>
    WHERE sitem_guid = is_sitem_skip-sitem_guid.
    IF is_sitem_skip-skip_status = /sdf/cl_rc_chk_utility=>c_sitem_skip_status-no.
      IF <fs_item_result>-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
        <fs_item_result>-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable.
      ENDIF.
    ELSE.
      IF <fs_item_result>-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable.
        <fs_item_result>-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
      ENDIF.
    ENDIF.
    <fs_item_result>-skip_status = is_sitem_skip-skip_status.

    "change the sub-check result when click exemption button in check result
    IF iv_exemp_action = abap_true.

      CALL TRANSFORMATION id
        SOURCE XML <fs_item_result>-chk_clas_result_xstr
        RESULT clas_chk_result = lt_clas_chk_result.

      LOOP AT lt_clas_chk_result ASSIGNING <fs_clas_chk_result>
        WHERE return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable.
          <fs_clas_chk_result>-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
      ENDLOOP.

      CALL TRANSFORMATION id
        SOURCE clas_chk_result = lt_clas_chk_result
        RESULT XML <fs_item_result>-chk_clas_result_xstr.

    ENDIF.

  ENDLOOP.

  sitem_consistency_result_save(
    iv_target_stack     = iv_target_stack
    it_cons_chk_result  = lt_cons_chk_result
    it_cons_header_info = lt_cons_chk_hdr_info
    is_header_info      = ls_header_info ).

ENDMETHOD.