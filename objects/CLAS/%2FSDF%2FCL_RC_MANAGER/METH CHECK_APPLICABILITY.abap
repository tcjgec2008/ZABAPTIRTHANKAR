METHOD check_applicability.

  DATA: lv_source_match     TYPE flag,
        lv_target_match     TYPE flag,
        ls_target_release   TYPE /sdf/cl_rc_chk_utility=>ty_smdb_target_str.
  FIELD-SYMBOLS:
        <fs_item_result>    TYPE /sdf/cl_rc_chk_utility=>ty_check_result_str.

*--------------------------------------------------------------------*
* Check whether the item is applicable based on source/target release
* Product version and stack PPMS ID should not be used to calculate Target release validality;
* the reason is that the sequence of PPMS ID is not guaranteed.
* We should use manually maintained PPMS meta data in backend system

  LOOP AT mt_check_result ASSIGNING <fs_item_result>.

    "Conditional stop for trouble shooting
    IF /sdf/cl_rc_chk_utility=>sv_conditional_stop = abap_true.
      CALL FUNCTION /sdf/cl_rc_chk_utility=>sv_test_function
        EXPORTING
          is_check_result = <fs_item_result>.
    ENDIF.

    "Check based on Simplification Item source/target release validality
    CLEAR: lv_source_match, lv_target_match, ls_target_release.
    lv_source_match = check_applicable_source_releas( <fs_item_result>-sitem_guid ).
    IF lv_source_match = abap_true.
      check_applicable_target_releas(
        EXPORTING
          iv_sitem_guid       = <fs_item_result>-sitem_guid
        IMPORTING
          ev_target_match     = lv_target_match
          es_match_target_rel = ls_target_release ).
    ENDIF.

    IF lv_source_match = abap_false OR lv_target_match = abap_false.
      "'Not Applicable'
      <fs_item_result>-applicable      = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '005' ).
      <fs_item_result>-applicable_stat = /sdf/cl_rc_chk_utility=>c_applicable_status-no.
      IF lv_source_match = abap_false.
        "Item is not relevant. Source release does not match.
        <fs_item_result>-summary_int    = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '006' ).
      ELSE.
        "Item is not relevant. Target release does not match.
        <fs_item_result>-summary_int    = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '007' ).
      ENDIF.
    ELSE.
      "'Applicable'
      <fs_item_result>-applicable                = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '004' ).
      <fs_item_result>-applicable_stat           = /sdf/cl_rc_chk_utility=>c_applicable_status-yes.
      <fs_item_result>-match_target_rel_category = ls_target_release-category.
    ENDIF.

  ENDLOOP.


*--------------------------------------------------------------------*
* Add the text as tooltip

  LOOP AT mt_check_result ASSIGNING <fs_item_result>.
    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        name       = <fs_item_result>-applicable_stat
        info       = <fs_item_result>-applicable
        add_stdinf = space
      IMPORTING
        RESULT     = <fs_item_result>-applicable_stat_disp
      EXCEPTIONS
        OTHERS     = 0.
  ENDLOOP.

ENDMETHOD.