FUNCTION /sdf/gen_funcs_s4_relevan_chk.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_TEST_API) TYPE  FLAG OPTIONAL
*"     VALUE(IV_CONV_TARGET_STACK) TYPE  CHAR20
*"     VALUE(IV_RESULT_EXPIRE_DAY) TYPE  I DEFAULT 10
*"  EXPORTING
*"     VALUE(EV_ERR_MESG) TYPE  STRING
*"     VALUE(EV_RESULT_XSTR) TYPE  XSTRING
*"     VALUE(EV_CONSIS_XSTR) TYPE  XSTRING
*"----------------------------------------------------------------------

**********************************************************************
* API for
* 1. Report AGSRC_START_ANALYSIS run in remote SolMan system
* 2. Rport TMW_RC_DOWNLOAD_ANALYSIS_DATA run locally for S/4HANA
* 3. Report TMW_BW_RC_DOWNLOAD_ANALYS_DATA run locally for BW/4HANA
* S/4HANA  73554900103300002096 1709 SP0
* BW/4HANA 73554900103300001974 SP0
**********************************************************************

  DATA: lo_rc_manager       TYPE REF TO /sdf/cl_rc_manager,
        lt_result_relv      TYPE /sdf/cl_rc_chk_utility=>ty_check_result_tab,
        ls_result           TYPE /sdf/cl_rc_chk_utility=>ty_check_result_str,
        lt_rel_chk_result   TYPE /sdf/cl_rc_chk_utility=>ty_rc_rele_chk_result_tab,
        ls_rel_chk_result   LIKE LINE OF lt_rel_chk_result,
        lv_note             TYPE cwbntnumm,
        ls_note_status      TYPE /sdf/cl_rc_chk_utility=>ty_note_stat_str,
        ls_hdr_info         TYPE /sdf/cl_rc_chk_utility=>ty_relev_chk_header_str,
        lt_cons_chk_result  TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_result_tab,
        lt_cons_header_info TYPE salv_wd_t_string,
        ls_cons_header_info TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_header_str,
        lv_str_tmp          TYPE string,
        lv_mesg_text        TYPE string,
        lv_timestamp_cur    TYPE timestamp,
        lv_timestamp_old    TYPE timestamp,
        lv_age_second       TYPE i,
        lv_exp_second       TYPE i,
        lv_a_new_check      TYPE boolean.

  IF iv_conv_target_stack IS INITIAL.
    "Provide S/4HANA conversion target to perform Simplification Item relevancy check
    ev_err_mesg = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '112' ) .
    RETURN.
  ENDIF.


*--------------------------------------------------------------------*
* Check that the currnet note has minimum version -->TMW_RC_DOWNLOAD_ANALYSIS_DATA

  lv_note = /sdf/cl_rc_chk_utility=>c_framework_note.
  ls_note_status = /sdf/cl_rc_chk_utility=>check_note_status(
    iv_note_number  = lv_note
    iv_action       = /sdf/cl_rc_chk_utility=>c_sap_note-action_rc_relev_chk
    iv_target_stack = iv_conv_target_stack ).
  IF ls_note_status-min_ver_implmented = /sdf/cl_rc_chk_utility=>c_status-no.
    "Minimum required version of note &P1& is &P2& but implemented version is &P3&.
    ev_err_mesg = /sdf/cl_rc_chk_utility=>get_text_str(
     iv_txt_key = 'B11'
     iv_para1   = /sdf/cl_rc_chk_utility=>c_framework_note
     iv_para2   = ls_note_status-min_required_ver_str
     iv_para3   = ls_note_status-current_version_str ).
    RETURN.
  ENDIF.


*--------------------------------------------------------------------*
* Check the relevance check can be performed

  /sdf/cl_rc_manager=>get_instance(
    EXPORTING
      iv_target_stack = iv_conv_target_stack
    RECEIVING
      ro_rc_manager   = lo_rc_manager
    EXCEPTIONS
      error           = 1
      OTHERS          = 2 ).
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'W' NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO ev_err_mesg.
    RETURN.
  ENDIF.
  IF iv_test_api IS NOT INITIAL.
    RETURN.
  ENDIF.


*--------------------------------------------------------------------*
* Start of the relevance check

  "Save buffered check result if the check was performed within 5 days
  /sdf/cl_rc_chk_utility=>sitem_relevance_result_get(
     EXPORTING
       iv_target_stack   = iv_conv_target_stack
     IMPORTING
       et_rel_chk_result = lt_result_relv
       es_header_info    = ls_hdr_info ).
  IF ls_hdr_info-end_time_utc IS NOT INITIAL.
    GET TIME STAMP FIELD lv_timestamp_cur.
    lv_timestamp_old = ls_hdr_info-end_time_utc.
    CALL FUNCTION 'TIMECALC_DIFF'
      EXPORTING
        timestamp1 = lv_timestamp_old
        timestamp2 = lv_timestamp_cur
        timezone   = 'UTC'
      IMPORTING
        difference = lv_age_second.
    lv_exp_second = 60 * 60 * 24 * iv_result_expire_day.
    IF lv_age_second > lv_exp_second.
      CLEAR lt_result_relv.
    ELSE.
      IF sy-batch = abap_true.
        CLEAR lv_mesg_text.
        "lv_mesg_text = 'Buffered relevance data less than 30 days( &P1& ) is used.'.
        lv_str_tmp = lv_timestamp_old.
        "REPLACE '&1' IN lv_mesg_text WITH lv_str_tmp.
        lv_mesg_text = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = 'B15'
          iv_para1   = lv_str_tmp
        ).
        MESSAGE lv_mesg_text TYPE 'I'.
      ENDIF.
    ENDIF.
  ELSE.
    "Clear the result to trigger a new check for the header information
    CLEAR lt_result_relv.
  ENDIF.

  "Trigger a new check if the note has been updated since last check
  IF ls_hdr_info-fwk_note_current_ver IS NOT INITIAL
    AND ls_hdr_info-fwk_note_current_ver < ls_note_status-current_version.
    CLEAR lt_result_relv.
  ENDIF.

  lv_a_new_check = abap_false.

  IF lt_result_relv IS INITIAL.
    lv_a_new_check = abap_true.
    lo_rc_manager->perform_relevance_check(
      IMPORTING
        et_result      = lt_result_relv
        es_header_info = ls_hdr_info ).
  ENDIF.


*--------------------------------------------------------------------*
* Return the result

  LOOP AT lt_result_relv INTO ls_result.
    ls_rel_chk_result-sitem_guid                = ls_result-sitem_guid.
    ls_rel_chk_result-applicable                = ls_result-applicable.
    ls_rel_chk_result-applicable_stat           = ls_result-applicable_stat.
    ls_rel_chk_result-match_target_rel_category = ls_result-match_target_rel_category.
    ls_rel_chk_result-relevant_stat             = ls_result-relevant_stat.
    ls_rel_chk_result-relevant_stat_int         = ls_result-relevant_stat_int.
    ls_rel_chk_result-summary                   = ls_result-summary.
    ls_rel_chk_result-summary_int               = ls_result-summary_int.
    ls_rel_chk_result-sql_str_int               = ls_result-sql_str_int.
    APPEND ls_rel_chk_result TO lt_rel_chk_result.
  ENDLOOP.

  " remove user info
  CLEAR ls_hdr_info-check_user.

  CALL TRANSFORMATION id
    SOURCE sitem_rele_check_result = lt_rel_chk_result
           conversion_target_stack = iv_conv_target_stack
           sitem_rele_chk_hdr_info = ls_hdr_info
    RESULT XML ev_result_xstr.

*--------------------------------------------------------------------*
* Start of the Consistency check

  CHECK ev_consis_xstr IS SUPPLIED.

  ls_note_status = /sdf/cl_rc_chk_utility=>check_note_status(
    iv_note_number  = lv_note
    iv_action       = /sdf/cl_rc_chk_utility=>c_sap_note-action_rc_sitm_sum_chk
    iv_target_stack = iv_conv_target_stack ).
  IF ls_note_status-min_ver_implmented = /sdf/cl_rc_chk_utility=>c_status-no.
    "Minimum required version of note &P1& is &P2& but implemented version is &P3&.
    ev_err_mesg = /sdf/cl_rc_chk_utility=>get_text_str(
     iv_txt_key = 'B11'
     iv_para1   = /sdf/cl_rc_chk_utility=>c_framework_note
     iv_para2   = ls_note_status-min_required_ver_str
     iv_para3   = ls_note_status-current_version_str ).
    RETURN.
  ENDIF.

  /sdf/cl_rc_chk_utility=>sitem_consistency_result_get(
    EXPORTING
      iv_target_stack     = iv_conv_target_stack
    IMPORTING
      et_cons_chk_result  = lt_cons_chk_result
      et_cons_header_info = lt_cons_header_info
      es_header_info      = ls_cons_header_info ).

  IF ls_cons_header_info-end_time_utc IS NOT INITIAL.
    GET TIME STAMP FIELD lv_timestamp_cur.
    lv_timestamp_old = ls_cons_header_info-end_time_utc.
    CALL FUNCTION 'TIMECALC_DIFF'
      EXPORTING
        timestamp1 = lv_timestamp_old
        timestamp2 = lv_timestamp_cur
        timezone   = 'UTC'
      IMPORTING
        difference = lv_age_second.
    lv_exp_second = 60 * 60 * 24 * iv_result_expire_day.
    IF lv_age_second > lv_exp_second.
      "Clear the result to trigger a new check
      CLEAR lt_cons_header_info.
    ELSE.
      IF sy-batch = abap_true.
        CLEAR lv_mesg_text.
*        lv_mesg_text = 'Buffered consistency data less than 30 days( &P1& ) is used.'.
        lv_str_tmp = lv_timestamp_old.
*        REPLACE '&1' IN lv_mesg_text WITH lv_str_tmp.
        lv_mesg_text = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = 'B16'
          iv_para1   = lv_str_tmp
        ).
        MESSAGE lv_mesg_text TYPE 'I'.
      ENDIF.
    ENDIF.
  ELSE.
    "Clear the result to trigger a new check
    CLEAR lt_cons_header_info.
  ENDIF.

  "Trigger a new check if the note has been updated since last check
  IF ls_cons_header_info-fwk_note_current_ver IS NOT INITIAL
    AND ls_cons_header_info-fwk_note_current_ver < ls_note_status-current_version.
    CLEAR lt_cons_header_info.
  ENDIF.

  "Trigger a new check if consistency check result is empty
  "                    Or relevent result is newly got
  IF lt_cons_header_info IS INITIAL OR lv_a_new_check = abap_true.

    lo_rc_manager->perform_consistency_check(
      EXPORTING
        it_all_sitem    = lt_result_relv
        it_check_sitem  = lt_result_relv ).

    /sdf/cl_rc_chk_utility=>sitem_consistency_result_get(
      EXPORTING
        iv_target_stack     = iv_conv_target_stack
      IMPORTING
        et_cons_chk_result  = lt_cons_chk_result
        et_cons_header_info = lt_cons_header_info
        es_header_info      = ls_cons_header_info ).

  ENDIF.

  CALL TRANSFORMATION id
    SOURCE sitem_consis_check_result = lt_cons_chk_result
           conversion_target_stack   = iv_conv_target_stack
           sitem_consis_chk_hdr_info = lt_cons_header_info
    RESULT XML ev_consis_xstr.

ENDFUNCTION.