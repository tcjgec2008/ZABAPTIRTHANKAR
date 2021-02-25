METHOD perform_consistency_check.

  DATA: ls_sitem             TYPE /sdf/cl_rc_chk_utility=>ty_smdb_item_str,
        ls_result            TYPE /sdf/cl_rc_chk_utility=>ty_check_result_str,
        ls_app_comp          TYPE /sdf/cl_rc_chk_utility=>ty_smdb_app_comp_str,
        ls_targ_rel          TYPE /sdf/cl_rc_chk_utility=>ty_smdb_target_str,
        lv_overall_msg_level TYPE symsgty VALUE 'I',
        lv_overall_msg_sum   TYPE symsgty VALUE 'I',
        lv_highest_rc        TYPE /sdf/cl_rc_chk_utility=>ty_return_code VALUE /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success,
        lt_cons_chk_result   TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_result_tab,
        lt_cons_chk_re_pre   TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_result_tab,
        lv_item_chked_before TYPE flag,
        lt_cons_chk_war      TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_result_tab,
        lt_cons_chk_error    TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_result_tab,
        lt_cons_chk_abortion TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_result_tab,
        ls_cons_chk_result   TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_result_str,
        lt_clas_chk_result   TYPE /sdf/cl_rc_chk_utility=>ty_pre_cons_chk_result_tab,
        ls_clas_chk_result   TYPE /sdf/cl_rc_chk_utility=>ty_pre_cons_chk_result_str,
        ls_header_info       TYPE ihttpnvp,
        lv_message_type      TYPE symsgty,
        lv_message_type_sum  TYPE symsgty,
        lv_message_level     TYPE ballevel,
        lt_cons_chk_hdr_info TYPE salv_wd_t_string,
        lt_cons_chk_hdr_pre  TYPE salv_wd_t_string,
        lt_cons_check_item   TYPE /sdf/cl_rc_chk_utility=>ty_smdb_check_tab,
        ls_cons_check_item   TYPE /sdf/cl_rc_chk_utility=>ty_smdb_check_str,
        lt_sitem_irrelevant  TYPE /sdf/cl_rc_chk_utility=>ty_check_result_tab,
        lt_sitem_manul_check TYPE /sdf/cl_rc_chk_utility=>ty_check_result_tab,
        lv_sitem_skipped     TYPE i,
        lv_exemp_stat_sum    TYPE boolean,
        lv_string            TYPE string,
        lv_string_sum        TYPE string,
        lv_str_tmp           TYPE string,
        lv_str_tmp_sum       TYPE string,
        lv_str_tmp1          TYPE string,
        lt_sitem_skip        TYPE /sdf/cl_rc_chk_utility=>ty_sitem_skip_tab,
        lt_conv_targ_stack   TYPE /sdf/cl_rc_chk_utility=>ty_conv_target_stack_tab,
        ls_target_stack      TYPE /sdf/cl_rc_chk_utility=>ty_conv_target_stack_str,
        lv_note              TYPE cwbntnumm,
        ls_note_status       TYPE /sdf/cl_rc_chk_utility=>ty_note_stat_str,
        lv_smdb_source       TYPE string,
        ls_message           TYPE /sdf/cl_rc_chk_utility=>ty_message_str,
        lt_message           TYPE /sdf/cl_rc_chk_utility=>ty_message_tab,
        lv_file_name         TYPE tstrf01-filename,
        lv_file_name_full    TYPE tstrf01-file,
        ls_cons_hdr_info     TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_header_str.

  DATA: ls_ppms_prod_ver_target TYPE /sdf/cl_rc_chk_utility=>ty_ppms_prod_version_str,
        ls_ppms_prod_ver_min    TYPE /sdf/cl_rc_chk_utility=>ty_ppms_prod_version_str,
        ls_ppms_prod_ver_min_s4 TYPE /sdf/cl_rc_chk_utility=>ty_ppms_prod_version_str,
        lv_str_prod_ver_min     TYPE string,
        lv_str_note             TYPE string.

  FIELD-SYMBOLS:
        <fs_check_sitem>     TYPE /sdf/cl_rc_chk_utility=>ty_check_result_str,
        <fs_sitem_skip>      TYPE /sdf/cl_rc_chk_utility=>ty_sitem_skip_str,
        <fs_con_check>       TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_result_str.

  CLEAR: et_check_result.
  mt_check_result = it_all_sitem.

*--------------------------------------------------------------------*
* Keep the simplification items that are relevant for consistency check

  LOOP AT it_check_sitem ASSIGNING <fs_check_sitem>.

    "Exclude only 100% sure irrelevant items
    "To be on the safe side; keep all possibly relevant items including chk_cls_issue & rule_issue
    IF <fs_check_sitem>-relevant_stat_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.
      APPEND <fs_check_sitem> TO lt_sitem_irrelevant.
      ADD 1 TO lv_sitem_skipped.
      CONTINUE.
    ENDIF.

    "Exclude items need manual check
    IF <fs_check_sitem>-relevant_stat_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-manual_check.
      APPEND <fs_check_sitem> TO lt_sitem_manul_check.
      ADD 1 TO lv_sitem_skipped.
      CONTINUE.
    ENDIF.

    "Check if pre-check is defined -> otherwise take it as manual check as well
    READ TABLE mt_check INTO ls_cons_check_item
      WITH KEY sitem_guid = <fs_check_sitem>-sitem_guid
               check_type = /sdf/cl_rc_chk_utility=>c_check_type-pre_check_new.
    IF sy-subrc <> 0.
      APPEND <fs_check_sitem> TO lt_sitem_manul_check."lt_sitem_no_chk_clas.
      ADD 1 TO lv_sitem_skipped.
      CONTINUE.
    ENDIF.

*    IF /sdf/cl_rc_chk_utility=>sv_test_system = abap_true."""""""""TODO: For testing purpose only
*      IF ls_cons_check_item-check_identifier = 'CLS4SIC_FI_GL'.
*        ls_cons_check_item-check_identifier = '/SDF/YF_CONSISTENCY_RC7'.
*      ENDIF.
*      IF ls_cons_check_item-check_identifier = 'CLS4SIC_A_LMN_VERS'."'CLS4SIC_ACCRUAL_DEFERRAL'.
*        ls_cons_check_item-check_identifier = '/SDF/YF_CONSISTENCY_RC712'.
*      ENDIF.
*    ENDIF.

    IF ls_cons_check_item-check_class_usage = /sdf/cl_rc_chk_utility=>c_chk_clas_usage-consistency
      OR ls_cons_check_item-check_class_usage = /sdf/cl_rc_chk_utility=>c_chk_clas_usage-rel_and_consis.
      APPEND ls_cons_check_item TO lt_cons_check_item.
    ENDIF.

  ENDLOOP.


*--------------------------------------------------------------------*
* Perform the consistency check
  GET TIME STAMP FIELD ls_cons_hdr_info-start_time_utc.

  CALL FUNCTION '/SDF/GEN_FUNCS_S4_CONS_CHK_MAS'
    EXPORTING
      it_check_item   = lt_cons_check_item
      it_sitem        = mt_sitem
      iv_target_stack = mv_target_stack
      iv_detailed_chk = iv_detailed_chk
      iv_sum_mode     = iv_sum_mode
    IMPORTING
      et_result       = lt_cons_chk_result
      et_header_info  = lt_cons_chk_hdr_info.

  GET TIME STAMP FIELD ls_cons_hdr_info-end_time_utc.
  CALL FUNCTION 'TIMECALC_DIFF'
    EXPORTING
      timestamp1 = ls_cons_hdr_info-start_time_utc
      timestamp2 = ls_cons_hdr_info-end_time_utc
      timezone   = 'UTC'
    IMPORTING
      difference = ls_cons_hdr_info-running_time_in_seconds.

  ls_cons_hdr_info-system_name             = sy-sysid.
  ls_cons_hdr_info-system_client           = sy-mandt.
  ls_cons_hdr_info-fwk_note_number         = /sdf/cl_rc_chk_utility=>c_framework_note.
  ls_note_status = /sdf/cl_rc_chk_utility=>check_note_status(
    iv_note_number  = ls_cons_hdr_info-fwk_note_number
    iv_action       = /sdf/cl_rc_chk_utility=>c_sap_note-action_rc_sitm_sum_chk
    iv_target_stack = mv_target_stack ).
  ls_cons_hdr_info-fwk_note_current_ver    = ls_note_status-current_version.
  ls_cons_hdr_info-fwk_note_min_req_ver    = ls_note_status-min_required_ver.
  ls_cons_hdr_info-fwk_note_latest_impled  = ls_note_status-latest_ver_implemented.

  "Persist the check result
  IF iv_detailed_chk IS INITIAL.
    /sdf/cl_rc_chk_utility=>sitem_consistency_result_save(
      iv_target_stack     = mv_target_stack
      it_cons_chk_result  = lt_cons_chk_result
      it_cons_header_info = lt_cons_chk_hdr_info
      is_header_info      = ls_cons_hdr_info  ).
  ELSE.
    "Merge the result
    /sdf/cl_rc_chk_utility=>sitem_consistency_result_get(
      EXPORTING
        iv_target_stack     = mv_target_stack
      IMPORTING
        et_cons_chk_result  = lt_cons_chk_re_pre
        et_cons_header_info = lt_cons_chk_hdr_pre ).
    READ TABLE lt_cons_chk_result INTO ls_cons_chk_result INDEX 1.
    LOOP AT lt_cons_chk_re_pre ASSIGNING <fs_con_check>
      WHERE sitem_guid = ls_cons_chk_result-sitem_guid.
      <fs_con_check> = ls_cons_chk_result.
      lv_item_chked_before = abap_true.
    ENDLOOP.
    IF lv_item_chked_before = abap_false.
      APPEND ls_cons_chk_result TO lt_cons_chk_re_pre.
    ENDIF.
    /sdf/cl_rc_chk_utility=>sitem_consistency_result_save(
      iv_target_stack     = mv_target_stack
      it_cons_chk_result  = lt_cons_chk_re_pre
      it_cons_header_info = lt_cons_chk_hdr_pre
      is_header_info      = ls_cons_hdr_info ).
  ENDIF.

  "Pre-process the check result
  LOOP AT lt_cons_chk_result INTO ls_cons_chk_result.

    "Take the highest return code
    IF ls_cons_chk_result-return_code > lv_highest_rc.
      lv_highest_rc = ls_cons_chk_result-return_code.
    ENDIF.

*    CASE ls_cons_chk_result-return_code.
*      WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
*        APPEND  ls_cons_chk_result TO lt_cons_chk_war.
*      WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable
*        OR /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error
*        OR /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion.
*        APPEND  ls_cons_chk_result TO lt_cons_chk_error.
*    ENDCASE.
  ENDLOOP.

*--------------------------------------------------------------------*
* Consolidate item skippable error status
* Skip status is updated in function /SDF/GEN_FUNCS_S4_CONS_CHK_SIG
* In SUM, we need change the return from framework code to SUM code.
* PHASE 1:   if retun code is 0  => 0
*            if retun code is 7  => 4 in any case, whether it#s exempted or not
*            if retun code is 4,8  => 4
*            if retun code is 12 => 8
*
* PHASE2:    if retun code is 0  => 0
*            if retun code is 4  => 4
*            if retun code is 7 => 4 if exempted or 8 if not exempted
*            if retun code is 8,12 => 8
*

  IF iv_sum_mode = abap_true
    AND lv_highest_rc = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable
    AND /sdf/cl_rc_chk_utility=>get_sum_phase( ) = /sdf/cl_rc_chk_utility=>c_sum_phase-second.

    /sdf/cl_rc_chk_utility=>sitem_skip_stat_get(
      EXPORTING
        iv_target_stack = mv_target_stack
      IMPORTING
        et_sitem_skip   = lt_sitem_skip ).

    lv_exemp_stat_sum = abap_true.

    LOOP AT lt_cons_chk_result INTO ls_cons_chk_result WHERE skip_status = /sdf/cl_rc_chk_utility=>c_sitem_skip_status-yes.
      READ TABLE lt_sitem_skip WITH KEY sitem_guid = ls_cons_chk_result-sitem_guid ASSIGNING <fs_sitem_skip>.
      IF sy-subrc <> 0.
        lv_exemp_stat_sum = abap_false.
      ENDIF.
    ENDLOOP.

  ENDIF.

  CASE lv_highest_rc.
    WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
      lv_overall_msg_level = 'I'.
      lv_overall_msg_sum = 'I'.
    WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
      lv_overall_msg_level = 'W'.
      lv_overall_msg_sum = 'W'.
    WHEN OTHERS.
      lv_overall_msg_level = 'E'.
      lv_overall_msg_sum = 'E'.

      "Change the sitem return status for SUM Log
      IF iv_sum_mode = abap_true.
        IF /sdf/cl_rc_chk_utility=>get_sum_phase( ) = /sdf/cl_rc_chk_utility=>c_sum_phase-first.
          CASE lv_highest_rc.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion.
              lv_overall_msg_sum = 'E'.
            WHEN OTHERS.
              lv_overall_msg_sum = 'W'.
          ENDCASE.
        ENDIF.
        IF /sdf/cl_rc_chk_utility=>get_sum_phase( ) = /sdf/cl_rc_chk_utility=>c_sum_phase-second.
          CASE lv_highest_rc.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion
              OR /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error.
              lv_overall_msg_sum = 'E'.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable.
              IF lv_exemp_stat_sum = abap_true.
                lv_message_type_sum = 'W'.
              ELSE.
                lv_message_type_sum = 'E'.
              ENDIF.
          ENDCASE.
        ENDIF.
      ENDIF.

  ENDCASE.


*--------------------------------------------------------------------*
* Perform additional check on header level

  lv_smdb_source = /sdf/cl_rc_chk_utility=>smdb_content_source_get( ).
  IF lv_smdb_source = /sdf/cl_rc_chk_utility=>c_parameter-smdb_source_sap.
    "Simplification Item Catalog source: get the latest version from SAP
    ls_message-mesg_str  = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '071' ).
    ls_message-mesg_type = 'I'.
    APPEND ls_message TO lt_message.

    IF /sdf/cl_rc_chk_utility=>sv_smdb_fetched_from_sap IS INITIAL.
      IF /sdf/cl_rc_chk_utility=>sv_is_ds_used = abap_true.
        "Latest simplificatin items not fetched; check Download Service connection
        ls_message-mesg_str = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '177' ).
      ELSE.
        "Latest simplificatin items not fetched; check SAP-SUPPORT_PORTAL HTTP connection
        ls_message-mesg_str = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '172' ).
      ENDIF.
      ls_message-mesg_type = 'W'.
      APPEND ls_message TO lt_message.
    ENDIF.

  ELSE.
    "Simplification Item Catalog source: the local version
    ls_message-mesg_str  = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '072' ).
    ls_message-mesg_type = 'I'.
    APPEND ls_message TO lt_message.
  ENDIF.

  "Get Simplification Item downloaded time
  /sdf/cl_rc_chk_utility=>get_smdb_content(
    IMPORTING
      ev_time_utc_str = lv_str_tmp
    EXCEPTIONS
      OTHERS          = 0 )."Checked before not error expect here
  IF lv_str_tmp IS NOT INITIAL.
    "Used Simplification Item Catalog was downloaded from SAP at &P1&
    ls_message-mesg_str = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '139'
      iv_para1   = lv_str_tmp ).
    ls_message-mesg_type = 'I'.
    APPEND ls_message TO lt_message.
  ENDIF.

  "Display the target product version
  /sdf/cl_rc_chk_utility=>get_smdb_content(
    IMPORTING
      et_conv_target_stack = lt_conv_targ_stack
    EXCEPTIONS
      OTHERS               = 0 )."Checked before not error expect here
  READ TABLE lt_conv_targ_stack INTO ls_target_stack
    WITH KEY stack_number = mv_target_stack.
  IF sy-subrc = 0.
    "Display the target product version
    ls_message-mesg_str  = /sdf/cl_rc_chk_utility=>get_conversion_target_str( mv_target_stack ).
    ls_message-mesg_type = 'I'.
    APPEND ls_message TO lt_message.
  ENDIF.

*  "Check target version >= 1709
*  IF ls_target_stack-prod_ver_number = /sdf/cl_rc_s4sic_sample=>c_ppms-s4hana_prd_ver_1511
*    OR ls_target_stack-prod_ver_number = /sdf/cl_rc_s4sic_sample=>c_ppms-s4hana_prd_ver_1610.
*
*    lv_str_tmp = ls_target_stack-prod_ver_name.
*    "Target version is &P1& but minimum S/4HANA 1709 is supported
*    ls_message-mesg_str  = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '036' iv_para1 = lv_str_tmp ).
*    ls_message-mesg_type = 'E'.
*    APPEND ls_message TO lt_message.
*  ENDIF.

  " get ppms data for target version
  READ TABLE mt_ppms_prod_version INTO ls_ppms_prod_ver_target
    WITH KEY prd_version_ppms_id = ls_target_stack-prod_ver_number.

  IF mt_cvers IS INITIAL.
    SELECT * FROM cvers INTO TABLE mt_cvers.
  ENDIF.

  " get ppms data for minimum supported version of conversion, currenly is 1809
  READ TABLE mt_ppms_prod_version INTO ls_ppms_prod_ver_min
    WITH KEY prd_version_ppms_id = mv_prod_ver_number_min.

  " Check target version >= minimum supported version of conversion, currenly is 1809,
  " if no, show related message according to https://sapjira.wdf.sap.corp/browse/STCSROADMAPVIEWERANDSIC-29
  " https://sapjira.wdf.sap.corp/browse/STCSROADMAPVIEWERANDSIC-1250
  IF ls_ppms_prod_ver_target-prd_version_sequence < ls_ppms_prod_ver_min-prd_version_sequence.
    lv_str_tmp          = ls_target_stack-prod_ver_name.
    lv_str_prod_ver_min = ls_ppms_prod_ver_min-prd_version_desc.

    " check If SAP_APPL component is in CVERS table
    READ TABLE mt_cvers WITH KEY component = 'SAP_APPL' TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      " get note string
      CASE ls_target_stack-prod_ver_number.
        WHEN /sdf/cl_rc_s4sic_sample=>c_ppms-s4hana_prd_ver_1511.
          lv_str_note = '2189824'.
        WHEN /sdf/cl_rc_s4sic_sample=>c_ppms-s4hana_prd_ver_1610.
          lv_str_note = '2346431'.
        WHEN /sdf/cl_rc_s4sic_sample=>c_ppms-s4hana_prd_ver_1709.
          lv_str_note = '2482453'.
        WHEN OTHERS.
      ENDCASE.

      "The target release &P1& is no longer supported for a system conversion.
      ls_message-mesg_str  = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '165'
        iv_para1 = lv_str_tmp
      ).
      ls_message-mesg_type = 'E'.
      APPEND ls_message TO lt_message.

      "Please see the release information note &P1&. Please choose at least &P2&.
      ls_message-mesg_str  = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '166'
        iv_para1 = lv_str_note
        iv_para2 = lv_str_prod_ver_min
      ).
      ls_message-mesg_type = 'E'.
      APPEND ls_message TO lt_message.
    ENDIF.

  ENDIF.

  " get ppms data for minimum supported version of upgrade, currenly is 1709
  READ TABLE mt_ppms_prod_version INTO ls_ppms_prod_ver_min_s4
    WITH KEY prd_version_ppms_id = mv_prod_ver_number_min_s4.

  " Check target version >= minimum supported version of upgrade, currenly is 1709
  " https://sapjira.wdf.sap.corp/browse/STCSROADMAPVIEWERANDSIC-1250
  IF ls_ppms_prod_ver_target-prd_version_sequence < ls_ppms_prod_ver_min_s4-prd_version_sequence.
    lv_str_tmp          = ls_target_stack-prod_ver_name.
    lv_str_prod_ver_min = ls_ppms_prod_ver_min_s4-prd_version_desc.

    READ TABLE mt_cvers WITH KEY component = 'S4CORE' TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      " get note string
      CASE ls_target_stack-prod_ver_number.
        WHEN /sdf/cl_rc_s4sic_sample=>c_ppms-s4hana_prd_ver_1610.
          lv_str_note = '2331947'.
        WHEN OTHERS.
      ENDCASE.

      "The minimum upgrade target release with this report is &P1&.
      ls_message-mesg_str  = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '167'
        iv_para1 = lv_str_prod_ver_min
      ).
      ls_message-mesg_type = 'E'.
      APPEND ls_message TO lt_message.

      "Please see SAP Note &P1& for the upgrade to &P2&.#
      ls_message-mesg_str  = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '168'
        iv_para1 = lv_str_note
        iv_para2 = lv_str_tmp
      ).
    ls_message-mesg_type = 'E'.
    APPEND ls_message TO lt_message.
  ENDIF.

  ENDIF.

  lv_note = /sdf/cl_rc_chk_utility=>c_framework_note.
  ls_note_status = /sdf/cl_rc_chk_utility=>check_note_status(
    iv_note_number  = lv_note
    iv_action       = /sdf/cl_rc_chk_utility=>c_sap_note-action_rc_sitm_sum_chk
    iv_target_stack = mv_target_stack ).
  IF ls_note_status-latest_ver_implemented <> /sdf/cl_rc_chk_utility=>c_status-yes.

    IF ls_note_status-min_ver_implmented = /sdf/cl_rc_chk_utility=>c_status-no.
      IF ls_note_status-implemented = abap_true.
        "Minimum required version of note &P1& is &P2& but implemented version is &P3&.
        ls_message-mesg_str = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = 'B11'
          iv_para1   = /sdf/cl_rc_chk_utility=>c_framework_note
          iv_para2   = ls_note_status-min_required_ver_str
          iv_para3   = ls_note_status-current_version_str ).
      ELSE.
        "Minimum required version &P1& of note &P2& not implemented.
        ls_message-mesg_str = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = 'B12'
          iv_para1   = ls_note_status-min_required_ver_str
          iv_para2   = /sdf/cl_rc_chk_utility=>c_framework_note ).
      ENDIF.
      ls_message-mesg_type = 'E'.
    ELSE.
      "Implemented version &P2& of SAP Note &P1& is not up to date.
      ls_message-mesg_str = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = 'B17'
        iv_para1   = /sdf/cl_rc_chk_utility=>c_framework_note
        iv_para2   = ls_note_status-current_version_str ).
      ls_message-mesg_type = 'W'.
    ENDIF.
    APPEND ls_message TO lt_message.

  ELSE.
    "Latest version (&P1&) of note &P2& has been implemented.
    ls_message-mesg_str = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = 'B01'
      iv_para1   = ls_note_status-current_version_str
      iv_para2   = /sdf/cl_rc_chk_utility=>c_framework_note ).
    ls_message-mesg_type = 'I'.
    APPEND ls_message TO lt_message.
  ENDIF.

  lv_note = /sdf/cl_rc_chk_utility=>c_chk_clas_tci_note.
  CLEAR ls_note_status.
  ls_note_status = /sdf/cl_rc_chk_utility=>check_note_status(
    iv_note_number  = lv_note
    iv_action       = /sdf/cl_rc_chk_utility=>c_sap_note-action_rc_sitm_sum_chk
    iv_target_stack = mv_target_stack ).
  IF ls_note_status-latest_ver_implemented <> /sdf/cl_rc_chk_utility=>c_status-yes.

    IF ls_note_status-min_ver_implmented = /sdf/cl_rc_chk_utility=>c_status-no.
      IF ls_note_status-implemented = abap_true.
        "Minimum required version of note &P1& is &P2& but implemented version is &P3&.
        ls_message-mesg_str = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = 'B11'
          iv_para1   = /sdf/cl_rc_chk_utility=>c_chk_clas_tci_note
          iv_para2   = ls_note_status-min_required_ver_str
          iv_para3   = ls_note_status-current_version_str ).
      ELSE.
        "Minimum required version &P1& of note &P2& not implemented.
        ls_message-mesg_str = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = 'B12'
          iv_para1   = ls_note_status-min_required_ver_str
          iv_para2   = /sdf/cl_rc_chk_utility=>c_chk_clas_tci_note ).
      ENDIF.
      ls_message-mesg_type = 'E'.
    ELSE.
      "Implemented version &P2& of SAP Note &P1& is not up to date.
      ls_message-mesg_str = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = 'B17'
        iv_para1   = /sdf/cl_rc_chk_utility=>c_chk_clas_tci_note
        iv_para2   = ls_note_status-current_version_str ).
      ls_message-mesg_type = 'W'.
    ENDIF.
    APPEND ls_message TO lt_message.

  ELSE.
    "Latest version (&P1&) of note &P2& has been implemented.
    ls_message-mesg_str = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = 'B01'
      iv_para1   = ls_note_status-current_version_str
      iv_para2   = /sdf/cl_rc_chk_utility=>c_chk_clas_tci_note ).
    ls_message-mesg_type = 'I'.
    APPEND ls_message TO lt_message.
  ENDIF.

  "Write SUM log file location in SUM mode
  IF iv_sum_mode = abap_true.

    CONCATENATE /sdf/cl_rc_chk_utility=>c_app_log-sum_log_file_name '.' sy-sysid INTO lv_file_name.
    "Executed the FM in a development system where the SUM path DIR_PUT does not exist then /put/ is written like /usr/sap/put/tmp/S4_SIF_TRANSITION_CHECKS.SI8
    "Execute the FM in an upgrade test system where the SUM pahs DIR_PUT exists. Then the expected file path is gotten like /usr/sap/SI8/SUM/abap/tmp/S4_SIF_TRANSITION_CHECKS.SI8
    CALL FUNCTION 'STRF_SETNAME'
      EXPORTING
        dirtype    = /sdf/cl_rc_chk_utility=>c_app_log-sum_log_type_p
        filename   = lv_file_name
        subdir     = 'tmp'
      IMPORTING
        file       = lv_file_name_full
      EXCEPTIONS
        wrong_call = 1
        OTHERS     = 2.
    IF lv_file_name_full IS NOT INITIAL.
      lv_str_tmp = lv_file_name_full.
      "Software Update Manager(SUM) log file: &P1&
      ls_message-mesg_str = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '155'
        iv_para1   = lv_str_tmp ).
      ls_message-mesg_type = 'I'.
      APPEND ls_message TO lt_message.
    ENDIF.
  ENDIF.

  "Change overal message level according to header check
  READ TABLE lt_message TRANSPORTING NO FIELDS
    WITH KEY mesg_type = 'E'.
  IF sy-subrc = 0.
    lv_overall_msg_level = 'E'.
    lv_overall_msg_sum = 'E'.
  ENDIF.
  READ TABLE lt_message TRANSPORTING NO FIELDS
    WITH KEY mesg_type = 'W'.
  IF sy-subrc = 0.
    IF lv_overall_msg_level = 'I'.
      lv_overall_msg_level = 'W'.
      lv_overall_msg_sum = 'W'.
    ENDIF.
  ENDIF.


*--------------------------------------------------------------------*
* Write the check result to application log for the header information

  /sdf/cl_rc_chk_utility=>app_log_cons_chk_init(
    iv_sum_mode     = iv_sum_mode
    iv_detailed_chk = iv_detailed_chk ).

  "Consistency check overall information
  lv_string = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '104' ).
  /sdf/cl_rc_chk_utility=>app_log_add_free_text(
    iv_mesg_text  = lv_string
    iv_mesg_type  = lv_overall_msg_level
    iv_mesg_type_sum  = lv_overall_msg_sum
    iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_1 ).
  LOOP AT lt_cons_chk_hdr_info INTO lv_string.
    /sdf/cl_rc_chk_utility=>app_log_add_free_text(
      iv_mesg_text  = lv_string
      iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_2 ).
  ENDLOOP.

  LOOP AT lt_message INTO ls_message.
    /sdf/cl_rc_chk_utility=>app_log_add_free_text(
      iv_mesg_text  = ls_message-mesg_str
      iv_mesg_type  = ls_message-mesg_type
      iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_2 ).
  ENDLOOP.


*--------------------------------------------------------------------*
* Write application log for the items can not be checked

  lv_str_tmp = lv_sitem_skipped.
  lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
    iv_txt_key = '118'
    iv_para1   = lv_str_tmp )."Items skipped for consistency check:
  /sdf/cl_rc_chk_utility=>app_log_add_free_text(
    iv_mesg_text  = lv_string
    iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_2 ).

  "Irrlevant items
  IF lt_sitem_irrelevant IS NOT INITIAL.

    lv_str_tmp = LINES( lt_sitem_irrelevant ).
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '119'
      iv_para1   = lv_str_tmp )."&P1& items skipped for consistency check since they are irrlevant
    /sdf/cl_rc_chk_utility=>app_log_add_free_text(
      iv_mesg_text  = lv_string
      iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_3 ).

    LOOP AT lt_sitem_irrelevant ASSIGNING <fs_check_sitem>.
      lv_string = <fs_check_sitem>-sitem_id.
      /sdf/cl_rc_chk_utility=>app_log_add_free_text(
        iv_mesg_text  = lv_string
        iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_4 ).
    ENDLOOP.
  ENDIF.

  "Items need manual check
  IF lt_sitem_manul_check IS NOT INITIAL.

    lv_str_tmp = LINES( lt_sitem_manul_check ).
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '120'
      iv_para1   = lv_str_tmp )."&P1& items skipped for consistency check since manual check is needed
    /sdf/cl_rc_chk_utility=>app_log_add_free_text(
      iv_mesg_text  = lv_string
      iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_3 ).

    LOOP AT lt_sitem_manul_check ASSIGNING <fs_check_sitem>.
      lv_string = <fs_check_sitem>-sitem_id.
      /sdf/cl_rc_chk_utility=>app_log_add_free_text(
        iv_mesg_text  = lv_string
        iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_4 ).
    ENDLOOP.
  ENDIF.

*  "Item without check class
*  IF lt_sitem_no_chk_clas IS NOT INITIAL.
*
*    lv_str_tmp = LINES( lt_sitem_no_chk_clas ).
*    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
*      iv_txt_key = '121'
*      iv_para1   = lv_str_tmp )."'&P1& items skipped for consistency check since check class not defined
*    /sdf/cl_rc_chk_utility=>app_log_add_free_text(
*      iv_mesg_text  = lv_string
*      iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_3 ).
*
*    LOOP AT lt_sitem_no_chk_clas ASSIGNING <fs_check_sitem>.
*
*      lv_string = <fs_check_sitem>-sitem_id.
*      /sdf/cl_rc_chk_utility=>app_log_add_free_text(
*        iv_mesg_text  = lv_string
*        iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_4 ).
*    ENDLOOP.
*  ENDIF.


*--------------------------------------------------------------------*
* Write header application log for items with error or warning

  "Number of relevant Simplfiction Item to be checked: &P1&
  lv_str_tmp =  LINES( lt_cons_check_item ).
  lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
    iv_txt_key = '106'
    iv_para1   = lv_str_tmp ).
  /sdf/cl_rc_chk_utility=>app_log_add_free_text(
    iv_mesg_text  = lv_string
    iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_2 ).


*--------------------------------------------------------------------*
* Consolidate item skippable error status
* Skip status is updated in function /SDF/GEN_FUNCS_S4_CONS_CHK_SIG

  /sdf/cl_rc_chk_utility=>sitem_skip_stat_get(
    EXPORTING
      iv_target_stack = mv_target_stack
    IMPORTING
      et_sitem_skip   = lt_sitem_skip ).

*--------------------------------------------------------------------*
* Write the check result to application log for each Simplification Item

  LOOP AT lt_cons_chk_result INTO ls_cons_chk_result.

    READ TABLE mt_sitem INTO ls_sitem
      WITH KEY guid = ls_cons_chk_result-sitem_guid.
    lv_str_tmp = ls_sitem-sitem_id.

    "Check exempted or not
    CLEAR lv_exemp_stat_sum.

    READ TABLE lt_sitem_skip WITH KEY sitem_guid = ls_cons_chk_result-sitem_guid ASSIGNING <fs_sitem_skip>.
    IF sy-subrc = 0 AND <fs_sitem_skip>-skip_status = /sdf/cl_rc_chk_utility=>c_sitem_skip_status-yes.
      lv_exemp_stat_sum = abap_true.
    ENDIF.

    "Consitency check for &P1& (&P2&)
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '111'
      iv_para1   = lv_str_tmp ).

    CASE ls_cons_chk_result-return_code.
      WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
        lv_message_type = 'I'.
      WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
        lv_message_type = 'W'.
      WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable
        OR /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error
        OR /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion.
        lv_message_type = 'E'.
    ENDCASE.

    "Change the sitem return status for SUM Log
    IF iv_sum_mode = abap_true.
      IF /sdf/cl_rc_chk_utility=>get_sum_phase( ) = /sdf/cl_rc_chk_utility=>c_sum_phase-first.
        CASE ls_cons_chk_result-return_code.
          WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
            lv_message_type_sum = 'I'.
          WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion.
            lv_message_type_sum = 'E'.
          WHEN OTHERS.
            lv_message_type_sum = 'W'.
        ENDCASE.
      ENDIF.
      IF /sdf/cl_rc_chk_utility=>get_sum_phase( ) = /sdf/cl_rc_chk_utility=>c_sum_phase-second.
        CASE ls_cons_chk_result-return_code.
          WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
            lv_message_type_sum = 'I'.
          WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion
            OR /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error.
            lv_message_type_sum = 'E'.
          WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
            lv_message_type_sum = 'W'.
          WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable.
            IF lv_exemp_stat_sum = abap_true.
              lv_message_type_sum = 'W'.
            ELSE.
              lv_message_type_sum = 'E'.
            ENDIF.
        ENDCASE.
      ENDIF.
    ENDIF.

    /sdf/cl_rc_chk_utility=>app_log_add_free_text(
      iv_mesg_text      = lv_string
      iv_mesg_type      = lv_message_type
      iv_mesg_type_sum  = lv_message_type_sum
      iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_2 ).


    "Highest consistency check return code: &P1&
    lv_str_tmp = ls_cons_chk_result-return_code.
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '140'
      iv_para1   = lv_str_tmp ).

    "Change the sitem return code for SUM log
    IF iv_sum_mode = abap_true.
      IF /sdf/cl_rc_chk_utility=>get_sum_phase( ) = /sdf/cl_rc_chk_utility=>c_sum_phase-first.
        CASE ls_cons_chk_result-return_code.
          WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
            lv_str_tmp = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
          WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion.
            lv_str_tmp = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error.
          WHEN OTHERS.
            lv_str_tmp = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
        ENDCASE.
      ENDIF.
      IF /sdf/cl_rc_chk_utility=>get_sum_phase( ) = /sdf/cl_rc_chk_utility=>c_sum_phase-second.
        CASE ls_cons_chk_result-return_code.
          WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
            lv_str_tmp = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
          WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion
            OR /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error.
            lv_str_tmp = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error.
          WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
            lv_str_tmp = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
          WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable.
            IF lv_exemp_stat_sum = abap_true.
              lv_str_tmp = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
            ELSE.
              lv_str_tmp = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error.
            ENDIF.
        ENDCASE.
      ENDIF.
    ENDIF.

    lv_string_sum = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '140'
      iv_para1   = lv_str_tmp ).

    /sdf/cl_rc_chk_utility=>app_log_add_free_text(
      iv_mesg_type      = lv_message_type
      iv_mesg_text      = lv_string
      iv_mesg_text_sum  = lv_string_sum
      iv_mesg_type_sum  = lv_message_type_sum
      iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_3 ).


    IF ls_cons_chk_result-skip_status = /sdf/cl_rc_chk_utility=>c_sitem_skip_status-no.
      "Only for RC = 7 item that has not been exempted
      IF ls_cons_chk_result-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable.
        "Consistency error found but it can be exempted in simplication item list
        lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = '122' ).
        /sdf/cl_rc_chk_utility=>app_log_add_free_text(
          iv_mesg_text  = lv_string
          iv_mesg_type  = 'W'
          iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_3 ).
      ELSE.
        "Skippable consistency error found, exemption can be applied after other errors are resolved.
        lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = '154' ).
        /sdf/cl_rc_chk_utility=>app_log_add_free_text(
          iv_mesg_text  = lv_string
          iv_mesg_type  = 'W'
          iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_3 ).
      ENDIF.
    ENDIF.

    "Header data for information only
    LOOP AT ls_cons_chk_result-header_info_table INTO ls_header_info.
      lv_message_type = ls_header_info-name.
      /sdf/cl_rc_chk_utility=>app_log_add_free_text(
        iv_mesg_type  = lv_message_type
        iv_mesg_text  = ls_header_info-value
        iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_3 ).
    ENDLOOP.

    IF ls_cons_chk_result-chk_clas_result_xstr IS INITIAL.
      CONTINUE.
    ENDIF.

    "Consistency check result...
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '130' ).
    /sdf/cl_rc_chk_utility=>app_log_add_free_text(
      iv_mesg_type  = 'I'
      iv_mesg_text  = lv_string
      iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_3 ).

    CLEAR lt_clas_chk_result.
    CALL TRANSFORMATION id
      SOURCE XML ls_cons_chk_result-chk_clas_result_xstr
      RESULT clas_chk_result = lt_clas_chk_result.

    LOOP AT lt_clas_chk_result INTO ls_clas_chk_result.

      "Return code returned from check class
      CASE ls_clas_chk_result-return_code.
        WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
          lv_message_type = 'I'.
        WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
          lv_message_type = 'W'.
        WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable
          OR /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error
          OR /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion.
          lv_message_type = 'E'.
      ENDCASE.

      "Check sub-check the SUM return status for SUM log
      IF iv_sum_mode = abap_true.
        IF /sdf/cl_rc_chk_utility=>get_sum_phase( ) = /sdf/cl_rc_chk_utility=>c_sum_phase-first.
          CASE ls_clas_chk_result-return_code.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
              lv_message_type_sum = 'I'.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion.
              lv_message_type_sum = 'E'.
            WHEN OTHERS.
              lv_message_type_sum = 'W'.
          ENDCASE.
        ENDIF.
        IF /sdf/cl_rc_chk_utility=>get_sum_phase( ) = /sdf/cl_rc_chk_utility=>c_sum_phase-second.
          CASE ls_clas_chk_result-return_code.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
              lv_message_type_sum = 'I'.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion
              OR /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error.
              lv_message_type_sum = 'E'.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
              lv_message_type_sum = 'W'.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable.
              IF lv_exemp_stat_sum = abap_true.
                lv_message_type_sum = 'W'.
              ELSE.
                lv_message_type_sum = 'E'.
              ENDIF.
          ENDCASE.
        ENDIF.
      ENDIF.

      CLEAR: lv_str_tmp, lv_str_tmp_sum.
      lv_str_tmp = ls_clas_chk_result-check_sub_id.
      lv_str_tmp1 = ls_clas_chk_result-return_code.

       "Check sub-check the SUM return code for SUM log
      IF iv_sum_mode = abap_true.
        IF /sdf/cl_rc_chk_utility=>get_sum_phase( ) = /sdf/cl_rc_chk_utility=>c_sum_phase-first.
          CASE ls_clas_chk_result-return_code.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
              lv_str_tmp_sum = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion.
              lv_str_tmp_sum = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error.
            WHEN OTHERS.
              lv_str_tmp_sum = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
          ENDCASE.
        ENDIF.
        IF /sdf/cl_rc_chk_utility=>get_sum_phase( ) = /sdf/cl_rc_chk_utility=>c_sum_phase-second.
          CASE ls_clas_chk_result-return_code.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
              lv_str_tmp_sum = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion
              OR /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error.
              lv_str_tmp_sum = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
              lv_str_tmp_sum = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
            WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable.
              IF lv_exemp_stat_sum = abap_true.
                lv_str_tmp_sum = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
              ELSE.
                lv_str_tmp_sum = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error.
              ENDIF.
          ENDCASE.
        ENDIF.
      ENDIF.

      IF lv_str_tmp IS INITIAL.
        "Check return code = [&P1&]
        lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = '147'
          iv_para1   = lv_str_tmp1 ).

        lv_string_sum = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = '147'
          iv_para1   = lv_str_tmp_sum ).
      ELSE.
        "Check Sub-ID: "&P1&", return code = [&P2&]
        lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = '129'
          iv_para1   = lv_str_tmp
          iv_para2   = lv_str_tmp1 ).

        lv_string_sum = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = '129'
          iv_para1   = lv_str_tmp
          iv_para2   = lv_str_tmp_sum ).

      ENDIF.

      /sdf/cl_rc_chk_utility=>app_log_add_free_text(
        iv_mesg_type      = lv_message_type
        iv_mesg_type_sum  = lv_message_type_sum
        iv_mesg_text      = lv_string
        iv_mesg_text_sum  = lv_string_sum
        iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_3 ).

      "Messages returned from check class
      LOOP AT ls_clas_chk_result-descriptions INTO lv_string.
        /sdf/cl_rc_chk_utility=>app_log_add_free_text(
          iv_mesg_type  = lv_message_type
          iv_mesg_type_sum  = lv_message_type_sum
          iv_mesg_text      = lv_string
          iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_4 ).
      ENDLOOP.

    ENDLOOP.
  ENDLOOP.


  "Update previous skippable item status or remove the items not skippable anymore
  LOOP AT lt_sitem_skip ASSIGNING <fs_sitem_skip>.
    READ TABLE lt_cons_chk_result INTO ls_cons_chk_result
      WITH KEY sitem_guid = <fs_sitem_skip>-sitem_guid.
    IF sy-subrc <> 0 OR ls_cons_chk_result-skip_status IS INITIAL.
      IF iv_sum_mode = abap_true.
        IF /sdf/cl_rc_chk_utility=>get_sum_phase( ) <> /sdf/cl_rc_chk_utility=>c_sum_phase-first.
          DELETE lt_sitem_skip.
        ENDIF.
      ELSE.
        DELETE lt_sitem_skip.
      ENDIF.
    ELSE.
      <fs_sitem_skip>-skip_status = ls_cons_chk_result-skip_status.
    ENDIF.
  ENDLOOP.

  "Add new skippable items
  LOOP AT lt_cons_chk_result INTO ls_cons_chk_result
    WHERE skip_status IS NOT INITIAL.

    READ TABLE lt_sitem_skip TRANSPORTING NO FIELDS
      WITH KEY sitem_guid = ls_cons_chk_result-sitem_guid.
    IF sy-subrc <> 0.
      APPEND INITIAL LINE TO lt_sitem_skip ASSIGNING <fs_sitem_skip>.
      <fs_sitem_skip>-sitem_guid        = ls_cons_chk_result-sitem_guid.
      <fs_sitem_skip>-skip_status       = ls_cons_chk_result-skip_status.
      <fs_sitem_skip>-last_checked_at   = ls_cons_chk_result-start_time.
      <fs_sitem_skip>-last_checked_by   = sy-uname.
    ENDIF.

  ENDLOOP.

  IF iv_detailed_chk IS INITIAL.
    /sdf/cl_rc_chk_utility=>sitem_skip_stat_update_mass(
      iv_target_stack = mv_target_stack
      it_sitem_skip   = lt_sitem_skip ).
  ELSE.
    READ TABLE lt_sitem_skip ASSIGNING <fs_sitem_skip> INDEX 1.
    IF sy-subrc = 0.
      /sdf/cl_rc_chk_utility=>sitem_skip_stat_update_single(
        iv_target_stack = mv_target_stack
        is_sitem_skip   = <fs_sitem_skip> ).
    ENDIF.
  ENDIF.


*--------------------------------------------------------------------*
* Post processing

  "Consolidate lastest consistency check result
  add_consis_result_to_rel_chk( ).
  et_check_result = mt_check_result.

  IF iv_sum_mode = abap_true. "Write SUM log file in SUM mode

    /sdf/cl_rc_chk_utility=>app_log_sum_log_write( ).

  ELSE. "Display the check result if not in SUM mode

    /sdf/cl_rc_chk_utility=>app_log_disp_cons_chk( ).

  ENDIF.

ENDMETHOD.