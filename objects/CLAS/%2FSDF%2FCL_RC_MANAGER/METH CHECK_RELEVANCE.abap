METHOD check_relevance.

  DATA: ls_check              TYPE /sdf/cl_rc_chk_utility=>ty_smdb_check_str,
        lo_check              TYPE REF TO /sdf/cl_rc_simple_chk,
        lv_manual_check       TYPE flag,
        lv_check_result_int   TYPE char30,
        lv_summary_int        TYPE string,
        lv_sql_str_int        type string,
        lv_str_tmp            TYPE string,
        lv_str_tmp1           TYPE string,
        lv_check_class        TYPE string,
        lv_relevance          TYPE char1,
        lv_note               TYPE cwbntnumm,
        ls_note_status        TYPE /sdf/cl_rc_chk_utility=>ty_note_stat_str.

  FIELD-SYMBOLS:
        <fs_item_result>      TYPE /sdf/cl_rc_chk_utility=>ty_check_result_str.

*--------------------------------------------------------------------*
* Check whether the item is relevant based on simple check rule

  LOOP AT mt_check_result ASSIGNING <fs_item_result>.

    IF sy-batch = abap_true.
      lv_str_tmp1 = <fs_item_result>-sitem_id.
      lv_str_tmp = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '111'
        iv_para1   = lv_str_tmp1 ).
      MESSAGE lv_str_tmp TYPE 'I'.
    ENDIF.

    "Conditional stop for trouble shooting
    IF /sdf/cl_rc_chk_utility=>sv_conditional_stop = abap_true.
      CALL FUNCTION /sdf/cl_rc_chk_utility=>sv_test_function
        EXPORTING
          is_check_result = <fs_item_result>.
    ENDIF.

    "No need to perform simple check if SItem is not qualified by source/target release
    IF <fs_item_result>-applicable_stat = /sdf/cl_rc_chk_utility=>c_applicable_status-no.
      "'Irrelevant'
      "<fs_item_result>-relevant          = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '009' ).
      <fs_item_result>-relevant_stat_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.
      "No need to write summary which is already done in CHECK_APPLICABILITY
      CONTINUE.
    ENDIF.

    "If manual check is defined -> no need to check other rule
    READ TABLE mt_check TRANSPORTING NO FIELDS
      WITH KEY sitem_guid = <fs_item_result>-sitem_guid
               check_type = /sdf/cl_rc_chk_utility=>c_check_type-manual.
    IF sy-subrc = 0.
      <fs_item_result>-relevant_stat_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-manual_check.
      "Manual check need to be conduct
      <fs_item_result>-summary_int       = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '014' ).
      CONTINUE.
    ENDIF.
    "Check if only old manual check is defined --> also treated as manual check for compatability reason
    READ TABLE mt_check TRANSPORTING NO FIELDS
      WITH KEY sitem_guid       = <fs_item_result>-sitem_guid
               check_type       = /sdf/cl_rc_chk_utility=>c_check_type-pre_check_old
               check_identifier = 'MANUAL_PRECHECK'.
    IF sy-subrc = 0.
      CLEAR lv_manual_check.
      LOOP AT mt_check INTO ls_check
        WHERE sitem_guid  = <fs_item_result>-sitem_guid
          AND (   check_type       <> /sdf/cl_rc_chk_utility=>c_check_type-pre_check_old
               OR check_identifier <> 'MANUAL_PRECHECK' ).
        lv_manual_check = abap_true.
      ENDLOOP.

      IF lv_manual_check = abap_true.
        <fs_item_result>-relevant_stat_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-manual_check.
        "Manual check need to be conduct
        <fs_item_result>-summary_int       = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '014' ).
        CONTINUE.
      ENDIF.
    ENDIF.

    "Take the SItem relevance as unknown if no check rule is defined at all
    "Old check class is ignored
    CLEAR ls_check.
    LOOP AT mt_check INTO ls_check
      WHERE sitem_guid =  <fs_item_result>-sitem_guid
        AND check_type <> /sdf/cl_rc_chk_utility=>c_check_type-pre_check_old.
      EXIT.
    ENDLOOP.
    IF ls_check IS INITIAL.
      "Check rule not defined
      <fs_item_result>-relevant_stat_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-rule_issue.
      READ TABLE mt_check TRANSPORTING NO FIELDS
        WITH KEY sitem_guid = <fs_item_result>-sitem_guid
                 check_type = /sdf/cl_rc_chk_utility=>c_check_type-pre_check_old.
      IF sy-subrc = 0."Relevance cannot be determined; only old pre-check based rule is defined
        <fs_item_result>-summary_int = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '013' ).
      ELSE."Relevance cannot be determined; check rule not defined'
        <fs_item_result>-summary_int = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '012' ).
      ENDIF.
      CONTINUE.
    ENDIF.

    "Perform simple check -> has higher priority than check class
    LOOP AT mt_check INTO ls_check
      WHERE sitem_guid = <fs_item_result>-sitem_guid.

      "Only simple check will be executed
      IF    ls_check-check_type <> /sdf/cl_rc_chk_utility=>c_check_type-table
        AND ls_check-check_type <> /sdf/cl_rc_chk_utility=>c_check_type-idoc
        AND ls_check-check_type <> /sdf/cl_rc_chk_utility=>c_check_type-buz_func
        AND ls_check-check_type <> /sdf/cl_rc_chk_utility=>c_check_type-entry_point.
        CONTINUE.
      ENDIF.

      lo_check = /sdf/cl_rc_simple_chk=>get_instance( is_check = ls_check ).
      CLEAR: lv_check_result_int, lv_summary_int.
      lo_check->perform_check(
        IMPORTING
          ev_result_int  = lv_check_result_int
          ev_summary_int = lv_summary_int
          ev_sql_str_int = lv_sql_str_int ).

      "In case only one check is defined; the single check determines the item relevancy directly
      <fs_item_result>-summary_int = lv_summary_int.
      <fs_item_result>-sql_str_int = lv_sql_str_int.
      IF lv_check_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.
        "Relevant
        <fs_item_result>-relevant_stat_int = lv_check_result_int.

      ELSEIF lv_check_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-rule_issue.
        "Issue found with the check rule
        <fs_item_result>-relevant_stat_int = lv_check_result_int.
        "Do not continue the following checks
        EXIT.
      ELSE.
        "Irrelevant
        <fs_item_result>-relevant_stat_int = lv_check_result_int.
      ENDIF.

      "Check for checks if connected with AND
      IF lv_check_result_int                 = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no
        AND <fs_item_result>-check_condition = /sdf/cl_rc_chk_utility=>c_check_condition-and.
        EXIT.
      ENDIF.

      "Check for checks if connected with OR
      IF lv_check_result_int                 = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes
        AND <fs_item_result>-check_condition = /sdf/cl_rc_chk_utility=>c_check_condition-or.
        EXIT.
      ENDIF.

    ENDLOOP.
    "Only perform check class based check if simple check passed
    IF <fs_item_result>-relevant_stat_int IS NOT INITIAL
      AND <fs_item_result>-relevant_stat_int <> /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.
      CONTINUE.
    ENDIF.

    "Check if new pre-check class is defined
    CLEAR ls_check.
    READ TABLE mt_check INTO ls_check
      WITH KEY sitem_guid = <fs_item_result>-sitem_guid
               check_type = /sdf/cl_rc_chk_utility=>c_check_type-pre_check_new.
    IF ls_check-check_class_usage = /sdf/cl_rc_chk_utility=>c_chk_clas_usage-relevance
      OR ls_check-check_class_usage = /sdf/cl_rc_chk_utility=>c_chk_clas_usage-rel_and_consis.

      "if the note number is not maintained; default one will be assigned in /SDF/CL_RC_CHK_UTILITY->SMDB_CONTENT_LOAD
      <fs_item_result>-check_class_note = ls_check-sap_note.
      CLEAR: lv_relevance, lv_summary_int.
      lv_check_class = ls_check-check_identifier.

      check_class_based_relevance(
        EXPORTING
          is_check       = ls_check
        IMPORTING
          ev_relevance   = lv_relevance
          ev_description = lv_summary_int ).
      CASE lv_relevance.
        WHEN /sdf/cl_rc_s4sic_sample=>c_pre_chk_relevance-yes.
          <fs_item_result>-relevant_stat_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.
          "Relevant as checked by &P1&: &P2&
          <fs_item_result>-summary_int       = /sdf/cl_rc_chk_utility=>get_text_str(
            iv_txt_key = 'C08'
            iv_para1   = lv_check_class
            iv_para2   = lv_summary_int ).
          CONTINUE.

        WHEN /sdf/cl_rc_s4sic_sample=>c_pre_chk_relevance-no.
          <fs_item_result>-relevant_stat_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.
          "Irrelevant as checked by &P1&: &P2&.
          <fs_item_result>-summary_int       = /sdf/cl_rc_chk_utility=>get_text_str(
            iv_txt_key = 'C09'
            iv_para1   = lv_check_class
            iv_para2   = lv_summary_int ).
          CONTINUE.

        WHEN /sdf/cl_rc_s4sic_sample=>c_pre_chk_relevance-error.
          <fs_item_result>-relevant_stat_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-chk_cls_issue.
          <fs_item_result>-summary_int       = lv_summary_int.
          CONTINUE.

        WHEN /sdf/cl_rc_s4sic_sample=>c_pre_chk_relevance-unknown.
          "Report issue only if the relevancy is not determined by Simple Check rule
          IF <fs_item_result>-relevant_stat_int IS INITIAL.
            "In case the relevance cannot be determined by Check Class
            <fs_item_result>-relevant_stat_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-rule_issue.
            "Relevance not determied by check class &P1& or simple check; check note &P2& implementation status
            lv_summary_int = ls_check-check_identifier.
            lv_str_tmp     = ls_check-sap_note.
            <fs_item_result>-summary_int       = /sdf/cl_rc_chk_utility=>get_text_str(
              iv_txt_key = 'C04'
              iv_para1   = lv_summary_int
              iv_para2   = lv_str_tmp ).
          ENDIF.
      ENDCASE.

      "Check whether the relevant SAP note is out of date -> allowed
      lv_note = ls_check-sap_note.
      ls_note_status = /sdf/cl_rc_chk_utility=>check_note_status(
        iv_note_number  = lv_note
        iv_action       = /sdf/cl_rc_chk_utility=>c_sap_note-action_rc_relev_chk
        iv_target_stack = mv_target_stack ).
      IF ls_note_status-latest_ver_implemented <> /sdf/cl_rc_chk_utility=>c_status-yes.
        lv_str_tmp1 = lv_note.
        SHIFT lv_str_tmp1 LEFT DELETING LEADING '0'.
        "( Containing SAP Note &P1& out-of-date. Current implemented version: &P2&)
        lv_str_tmp = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = 'C13'
          iv_para1 = lv_str_tmp1
          iv_para2 = ls_note_status-current_version_str ).
        CONCATENATE <fs_item_result>-summary_int lv_str_tmp INTO <fs_item_result>-summary_int SEPARATED BY space.
      ENDIF.

    ENDIF.

    IF <fs_item_result>-relevant_stat_int IS INITIAL.
      <fs_item_result>-relevant_stat_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-rule_issue.
      "Relevance cannot be determined; check rule issue found
      <fs_item_result>-summary_int = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '011' ).
    ENDIF.
  ENDLOOP.

  LOOP AT mt_check_result ASSIGNING <fs_item_result>.
    "For testing only
    IF <fs_item_result>-expected_relev_stat IS NOT INITIAL.
      IF <fs_item_result>-expected_relev_stat = <fs_item_result>-relevant_stat_int.
        <fs_item_result>-test_result_stat = /sdf/cl_rc_chk_utility=>c_applicable_status-yes.
      ELSE.
        <fs_item_result>-test_result_stat = /sdf/cl_rc_chk_utility=>c_applicable_status-no.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDMETHOD.