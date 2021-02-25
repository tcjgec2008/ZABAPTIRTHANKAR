METHOD get_target_s4_version.

  TYPES: BEGIN OF str_sort_pv.
  INCLUDE TYPE /sdf/cl_rc_chk_utility=>ty_conv_target_stack_str.
  TYPES:
    pv_seq TYPE numc10,
  END OF str_sort_pv.

  CONSTANTS:
       lc_appl_comp           TYPE string VALUE 'SAP_APPL',
       lc_s4hana_comp         TYPE string VALUE 'S4CORE'.

  DATA:
    lt_spam_cvers            TYPE TABLE OF spam_cvers,
    lv_version_number        TYPE saprelease,
    lv_sp_number             TYPE saprelease,
    ls_target_stack          TYPE ty_conv_target_stack_str,
    lt_conv_targ_stack       TYPE ty_conv_target_stack_tab,
    lt_ppms_prod_version     TYPE ty_ppms_prod_version_tab,
    ls_ppms_prod_version     TYPE ty_ppms_prod_version_str,
    lt_table                 TYPE TABLE OF str_sort_pv,
    ls_table                 TYPE str_sort_pv,
    lv_append_flag           TYPE boolean.

  FIELD-SYMBOLS:
       <fs_spam_cvers>       TYPE spam_cvers,
       <fs_version>          TYPE ty_conv_target_stack_str,
       <fs_stack>            TYPE ty_ppms_stack_str.

  "Get local system component stack list
  CALL FUNCTION 'OCS_GET_INSTALLED_COMPS'
    TABLES
      tt_comptab = lt_spam_cvers.
  READ TABLE lt_spam_cvers WITH KEY component = lc_s4hana_comp ASSIGNING <fs_spam_cvers>.
  IF sy-subrc = 0.
    lv_version_number = <fs_spam_cvers>-release.
    lv_sp_number      = <fs_spam_cvers>-extrelease.
  ENDIF.

  "Get S/4HANA conversion target release
  /sdf/cl_rc_chk_utility=>get_smdb_content(
    IMPORTING
      et_conv_target_stack   = lt_conv_targ_stack
      et_ppms_prod_version   = lt_ppms_prod_version
      et_ppms_stack          = et_stack
    EXCEPTIONS
      smdb_contnet_not_found = 1
      error                  = 2
      OTHERS                 = 3 ).
  CASE sy-subrc.
    WHEN 0.

    WHEN 1.
      RAISE smdb_contnet_not_found.
    WHEN OTHERS.
      RAISE error.
  ENDCASE.

  "Sequence guaranteed within API function
  LOOP AT lt_conv_targ_stack INTO ls_target_stack.
    MOVE-CORRESPONDING ls_target_stack TO ls_table.
    READ TABLE lt_ppms_prod_version WITH KEY prd_version_ppms_id = ls_target_stack-prod_ver_number INTO ls_ppms_prod_version.
    IF sy-subrc = 0.
      ls_table-pv_seq = ls_ppms_prod_version-sw_comp_release.
    ENDIF.
    APPEND ls_table TO lt_table.
  ENDLOOP.

  SORT lt_table BY pv_seq stack_sort_seq.
  CLEAR et_version.

  LOOP AT lt_table INTO ls_table.

    IF lv_version_number IS INITIAL.
      lv_append_flag = abap_true.
    ELSE.
      IF lv_append_flag = abap_false.
        IF ls_table-pv_seq > lv_version_number.
          lv_append_flag = abap_true.
        ELSE.
          IF ls_table-pv_seq = lv_version_number AND ls_table-stack_sort_seq > lv_sp_number.
            lv_append_flag = abap_true.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    IF lv_append_flag = abap_false.
      CONTINUE.
    ENDIF.

    CLEAR ls_target_stack.
    MOVE-CORRESPONDING ls_table TO ls_target_stack.
    APPEND ls_target_stack TO et_version.

  ENDLOOP.

  IF /sdf/cl_rc_chk_utility=>is_test_mode( ) = abap_false.
    LOOP AT et_version ASSIGNING <fs_version>.
      READ TABLE et_stack WITH KEY stack_ppms_id = <fs_version>-stack_number ASSIGNING <fs_stack>.
      IF sy-subrc = 0.
        IF <fs_stack>-stack_status IS INITIAL AND <fs_version>-stack_release_date IS INITIAL.
          DELETE et_version WHERE stack_number = <fs_stack>-stack_ppms_id.
        ELSE.
          IF <fs_stack>-stack_status IS NOT INITIAL AND <fs_stack>-stack_status <> 'RELEASED'.
            DELETE et_version WHERE stack_number = <fs_stack>-stack_ppms_id.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDMETHOD.