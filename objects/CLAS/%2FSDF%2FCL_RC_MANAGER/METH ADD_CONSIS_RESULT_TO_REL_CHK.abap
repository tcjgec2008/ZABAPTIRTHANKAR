METHOD add_consis_result_to_rel_chk.

  DATA: lt_cons_chk_result   TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_result_tab,
        ls_cons_chk_result   TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_result_str,
        "lt_header_text       TYPE salv_wd_t_string,
        lv_test_mode         TYPE flag,
        ls_header_info       TYPE /sdf/cl_rc_chk_utility=>ty_relev_chk_header_str,
        lt_check_result      TYPE /sdf/cl_rc_chk_utility=>ty_check_result_tab,
        ls_check_result      TYPE /sdf/cl_rc_chk_utility=>ty_check_result_str.
  FIELD-SYMBOLS:
        <fs_item_result>     TYPE /sdf/cl_rc_chk_utility=>ty_check_result_str.


*--------------------------------------------------------------------*
* Get last consistency check result and merge it to the result list

  /sdf/cl_rc_chk_utility=>sitem_consistency_result_get(
    EXPORTING
      iv_target_stack    = mv_target_stack
    IMPORTING
      et_cons_chk_result = lt_cons_chk_result ).

  LOOP AT mt_check_result ASSIGNING <fs_item_result>
    WHERE relevant_stat_int  <> /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.

    READ TABLE lt_cons_chk_result INTO ls_cons_chk_result
      WITH KEY sitem_guid = <fs_item_result>-sitem_guid.
    IF sy-subrc = 0.

      <fs_item_result>-consistency_return_code = ls_cons_chk_result-return_code.
      "Calculated in FM /SDF/GEN_FUNCS_S4_CONS_CHK_SIG
      CASE ls_cons_chk_result-return_code.
        WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
          <fs_item_result>-consistency_stat_disp = /sdf/cl_rc_chk_utility=>c_si_cons_stat-success.
        WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
          <fs_item_result>-consistency_stat_disp = /sdf/cl_rc_chk_utility=>c_si_cons_stat-warning.
        WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error
          OR /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable.
          <fs_item_result>-consistency_stat_disp = /sdf/cl_rc_chk_utility=>c_si_cons_stat-error.
        WHEN /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion.
          <fs_item_result>-consistency_stat_disp = /sdf/cl_rc_chk_utility=>c_si_cons_stat-abortion.
*        WHEN OTHERS.
*          <fs_item_result>-consistency_stat_disp = /sdf/cl_rc_chk_utility=>c_si_cons_stat-not_applicalbe.
      ENDCASE.

      IF ls_cons_chk_result-skip_status = /sdf/cl_rc_chk_utility=>c_sitem_skip_status-yes.
        <fs_item_result>-exemption_stat_disp    = ls_cons_chk_result-skip_status.
        <fs_item_result>-exemption_stat_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '137' )."Inconsistency Exempted

      ELSEIF ls_cons_chk_result-skip_status = /sdf/cl_rc_chk_utility=>c_sitem_skip_status-no.
        <fs_item_result>-exemption_stat_disp    = ls_cons_chk_result-skip_status.
        <fs_item_result>-exemption_stat_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '138' )."Inconsistency Can be Exempted
      ELSE.
        <fs_item_result>-exemption_stat_disp    = /sdf/cl_rc_chk_utility=>c_sitem_skip_status-not_applicalbe.
        <fs_item_result>-exemption_stat_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '136' )."Not Applicable
      ENDIF.

    ELSE.
      <fs_item_result>-consistency_stat_disp = /sdf/cl_rc_chk_utility=>c_si_cons_stat-not_applicalbe.

      <fs_item_result>-exemption_stat_disp    = /sdf/cl_rc_chk_utility=>c_sitem_skip_status-not_applicalbe.
      <fs_item_result>-exemption_stat_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '136' )."Not Applicable
    ENDIF.

  ENDLOOP.


*--------------------------------------------------------------------*
* Sort by relevance status

  CONSTANTS:
    BEGIN OF c_cons_stat_seq,
          success         TYPE char4 VALUE '0050',
          warning         TYPE char4 VALUE '0040',
          error           TYPE char4 VALUE '0030',
          abortion        TYPE char4 VALUE '0020',
          not_applicalbe  TYPE char4 VALUE '0060',
          others          TYPE char4 VALUE '0070',
        END OF c_cons_stat_seq .

  CONSTANTS:
    BEGIN OF c_rel_stat_seq,
            yes            TYPE char4 VALUE '0001',  "Relevant
            manual_check   TYPE char4 VALUE '0005',  "Need manual check
            chk_cls_issue  TYPE char4 VALUE '0010',  "Check class not exists of out-of-date
            rule_issue     TYPE char4 VALUE '0015',  "Check rule issue
            miss_usg_data  TYPE char4 VALUE '0020',  "Missing usage (ST03N) data for entry point
            no             TYPE char4 VALUE '0100',  "Irrelevant
        END OF c_rel_stat_seq .

  LOOP AT mt_check_result ASSIGNING <fs_item_result>.
    CASE <fs_item_result>-relevant_stat_int.
      WHEN /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.
        <fs_item_result>-relevant_stat = c_rel_stat_seq-yes.

      WHEN /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.
        <fs_item_result>-relevant_stat = c_rel_stat_seq-no.

      WHEN /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-manual_check.
        <fs_item_result>-relevant_stat = c_rel_stat_seq-manual_check.

      WHEN /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-chk_cls_issue.
        <fs_item_result>-relevant_stat = c_rel_stat_seq-chk_cls_issue.

      WHEN /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-rule_issue.
        <fs_item_result>-relevant_stat = c_rel_stat_seq-rule_issue.

      WHEN /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-miss_usg_data.
        <fs_item_result>-relevant_stat = c_rel_stat_seq-miss_usg_data.
    ENDCASE.

    CASE <fs_item_result>-consistency_stat_disp.
      WHEN /sdf/cl_rc_chk_utility=>c_si_cons_stat-success.
        <fs_item_result>-consistency_stat_disp = c_cons_stat_seq-success.

      WHEN /sdf/cl_rc_chk_utility=>c_si_cons_stat-warning.
        <fs_item_result>-consistency_stat_disp = c_cons_stat_seq-warning.

      WHEN /sdf/cl_rc_chk_utility=>c_si_cons_stat-error.
        <fs_item_result>-consistency_stat_disp = c_cons_stat_seq-error.

      WHEN /sdf/cl_rc_chk_utility=>c_si_cons_stat-abortion.
        <fs_item_result>-consistency_stat_disp = c_cons_stat_seq-abortion.

      WHEN /sdf/cl_rc_chk_utility=>c_si_cons_stat-not_applicalbe.
        <fs_item_result>-consistency_stat_disp = c_cons_stat_seq-not_applicalbe.

      WHEN OTHERS.
        <fs_item_result>-consistency_stat_disp = c_cons_stat_seq-others.
    ENDCASE.

  ENDLOOP.
  SORT mt_check_result BY consistency_stat_disp relevant_stat sitem_id.

  LOOP AT mt_check_result ASSIGNING <fs_item_result>.
    CASE <fs_item_result>-relevant_stat_int.
      WHEN /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.

        "Check performed, item is probably relevant. Check business impact note.
        <fs_item_result>-relevant_stat    = /sdf/cl_rc_chk_utility=>c_si_rele_stat-yes.
        <fs_item_result>-relevant_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'C10' )."Probably relevant
        <fs_item_result>-summary          = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'C00' ).

      WHEN /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.

        "Check performed, item not relevant.
        <fs_item_result>-relevant_stat    = /sdf/cl_rc_chk_utility=>c_si_rele_stat-no.
        <fs_item_result>-relevant_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'C11' )."Not relevant.
        <fs_item_result>-summary          = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'C01' ).

      WHEN /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-manual_check.

        "Relevancy cannot be automatically determined. Check business impact note.
        <fs_item_result>-relevant_stat    = /sdf/cl_rc_chk_utility=>c_si_rele_stat-manual_check.
        <fs_item_result>-relevant_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'C12' )."Relevance unknown.
        <fs_item_result>-summary          = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'C02' ).

      WHEN /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-chk_cls_issue.

        "Relevance cannot be determined automatically because SAP Note &P1& not implemented or out-of-date.
        <fs_item_result>-relevant_stat    = /sdf/cl_rc_chk_utility=>c_si_rele_stat-chk_cls_issue.
        <fs_item_result>-relevant_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'C12' )."Relevance unknown.
        <fs_item_result>-summary          = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'C03'  iv_para1 = <fs_item_result>-check_class_note ).

      WHEN /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-rule_issue.

        "Relevancy cannot be automatically determined. Check business impact note.
        <fs_item_result>-relevant_stat    = /sdf/cl_rc_chk_utility=>c_si_rele_stat-rule_issue.
        <fs_item_result>-relevant_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'C12' )."Relevance unknown.
        <fs_item_result>-summary          = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'C02' ).

      WHEN /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-miss_usg_data.

        <fs_item_result>-relevant_stat    = /sdf/cl_rc_chk_utility=>c_si_rele_stat-miss_usg_data.
        <fs_item_result>-relevant_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'C12' )."Relevance unknown.
        "Relevance cannot be determined automatically because no enough ST03N data exists
        <fs_item_result>-summary          = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'C05' ).

    ENDCASE.

    CASE <fs_item_result>-consistency_stat_disp.
      WHEN c_cons_stat_seq-success.
        <fs_item_result>-consistency_stat_disp    = /sdf/cl_rc_chk_utility=>c_si_cons_stat-success.
        <fs_item_result>-consistency_stat_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '132' )."No Inconsistency

      WHEN c_cons_stat_seq-warning.
        <fs_item_result>-consistency_stat_disp    = /sdf/cl_rc_chk_utility=>c_si_cons_stat-warning.
        <fs_item_result>-consistency_stat_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '133' )."Inconsistency at Level Warning

      WHEN c_cons_stat_seq-error.
        <fs_item_result>-consistency_stat_disp    = /sdf/cl_rc_chk_utility=>c_si_cons_stat-error.
        <fs_item_result>-consistency_stat_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '134' )."Inconsistency at Level Error

      WHEN c_cons_stat_seq-abortion.
        <fs_item_result>-consistency_stat_disp    = /sdf/cl_rc_chk_utility=>c_si_cons_stat-abortion.
        <fs_item_result>-consistency_stat_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '135' )."Inconsistency at Level Abortion

      WHEN c_cons_stat_seq-not_applicalbe.
        <fs_item_result>-consistency_stat_disp    = /sdf/cl_rc_chk_utility=>c_si_cons_stat-not_applicalbe.
        <fs_item_result>-consistency_stat_tooltip = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '136' )."Not Applicable

      WHEN OTHERS.
        CLEAR <fs_item_result>-consistency_stat_disp.
    ENDCASE.

  ENDLOOP.

  LOOP AT mt_check_result ASSIGNING <fs_item_result>
    WHERE summary_int IS INITIAL.
    <fs_item_result>-summary_int = <fs_item_result>-summary.
  ENDLOOP.

  lv_test_mode = /sdf/cl_rc_chk_utility=>check_is_test_mode( ).
  IF lv_test_mode = abap_true.
    SORT mt_check_result BY sitem_guid seq_area sitem_id ASCENDING.
  ENDIF.


*--------------------------------------------------------------------*
* Add the text as tooltip for relevance column

  LOOP AT mt_check_result ASSIGNING <fs_item_result>.

    IF <fs_item_result>-relevant_stat IS NOT INITIAL.
      CALL FUNCTION 'ICON_CREATE'
        EXPORTING
          name       = <fs_item_result>-relevant_stat
          info       = <fs_item_result>-relevant_tooltip
          add_stdinf = space
        IMPORTING
          RESULT     = <fs_item_result>-relevant_stat_disp
        EXCEPTIONS
          OTHERS     = 1.
      IF sy-subrc <> 0.
        <fs_item_result>-relevant_stat_disp = <fs_item_result>-relevant_stat.
      ENDIF.
    ENDIF.

    IF <fs_item_result>-consistency_stat_disp IS NOT INITIAL.
      CALL FUNCTION 'ICON_CREATE'
        EXPORTING
          name       = <fs_item_result>-consistency_stat_disp
          info       = <fs_item_result>-consistency_stat_tooltip
          add_stdinf = space
        IMPORTING
          RESULT     = <fs_item_result>-consistency_stat_disp
        EXCEPTIONS
          OTHERS     = 0.
    ENDIF.

    IF <fs_item_result>-exemption_stat_disp IS NOT INITIAL.
      CALL FUNCTION 'ICON_CREATE'
        EXPORTING
          name       = <fs_item_result>-exemption_stat_disp
          info       = <fs_item_result>-exemption_stat_tooltip
          add_stdinf = space
        IMPORTING
          RESULT     = <fs_item_result>-exemption_stat_disp
        EXCEPTIONS
          OTHERS     = 0.
    ENDIF.
  ENDLOOP.


*--------------------------------------------------------------------*
* Persistent the merged result

  "Update all the result if all items are checked
  IF LINES( mt_sitem ) = LINES( mt_check_result ).
    ls_header_info  = is_header_info.
    lt_check_result = mt_check_result.
  ENDIF.

  "Merge new partially check result with previous fully check result
  IF ls_header_info IS INITIAL.
    /sdf/cl_rc_chk_utility=>sitem_relevance_result_get(
      EXPORTING
        iv_target_stack   = mv_target_stack
      IMPORTING
        et_rel_chk_result = lt_check_result
        es_header_info    = ls_header_info ).
    LOOP AT lt_check_result ASSIGNING <fs_item_result>.
      READ TABLE mt_check_result INTO ls_check_result
        WITH KEY sitem_guid = <fs_item_result>-sitem_guid.
      IF sy-subrc = 0.
        <fs_item_result> = ls_check_result.
      ENDIF.
    ENDLOOP.
  ENDIF.

  /sdf/cl_rc_chk_utility=>sitem_relevance_result_save(
    iv_target_stack   = mv_target_stack
    it_rel_chk_result = lt_check_result
    is_header_info    = ls_header_info ).

ENDMETHOD.