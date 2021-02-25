FUNCTION /sdf/gen_funcs_s4_cons_chk_sig .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_TARGET_STACK) TYPE  CHAR20
*"     VALUE(IV_SITEM_GUID) TYPE  GUID_32
*"     VALUE(IV_SITEM_ID) TYPE  STRING
*"     VALUE(IV_CHECK_CLASS) TYPE  STRING
*"     VALUE(IV_SAP_NOTE) TYPE  CWBNTNUMM
*"     VALUE(IT_PARAMETER) TYPE  TIHTTPNVP
*"     VALUE(IV_SUM_MODE) TYPE  FLAG DEFAULT SPACE
*"  EXPORTING
*"     VALUE(EV_RESULT_XSTR) TYPE  XSTRING
*"----------------------------------------------------------------------

  DATA: ls_result             TYPE /sdf/cl_rc_chk_utility=>ty_consis_chk_result_str,
        lv_class_exist        TYPE flag,
        lv_method_exist       TYPE flag,
        lv_str_tmp            TYPE string,
        lv_str_tmp1           TYPE string,
        lv_str_tmp2           TYPE string,
        lv_str_class          TYPE string,
        lv_str_note           TYPE string,
        lv_str_method         TYPE string,
        lt_clas_chk_result    TYPE /sdf/cl_rc_chk_utility=>ty_pre_cons_chk_result_tab,
        ls_clas_chk_result    TYPE /sdf/cl_rc_chk_utility=>ty_pre_cons_chk_result_str,
        lo_exception          TYPE REF TO cx_root,
        ls_rmpspro            TYPE rmpspro_mailmime,
        lt_sitem_skip         TYPE /sdf/cl_rc_chk_utility=>ty_sitem_skip_tab,
        ls_sitem_skip         TYPE /sdf/cl_rc_chk_utility=>ty_sitem_skip_str,
        lt_log_tmp            TYPE salv_wd_t_string,
        ls_header_info        TYPE ihttpnvp,
        lv_return_code_found  TYPE flag,
        ls_note_status        TYPE /sdf/cl_rc_chk_utility=>ty_note_stat_str,
        lv_sum_phase          TYPE char1,
        lv_skip_ist_sum_phase TYPE i,
        lv_chk_mesg_num_limit TYPE i VALUE 10000,
        lv_check_class_note   TYPE cwbntnumm.
  FIELD-SYMBOLS:
        <fs_clas_chk_result>  TYPE /sdf/cl_rc_chk_utility=>ty_pre_cons_chk_result_str.

  CLEAR ev_result_xstr.
  CHECK iv_sitem_guid IS NOT INITIAL.

  lv_str_class  = iv_check_class.
  lv_str_note   = iv_sap_note.
  SHIFT lv_str_note LEFT DELETING LEADING '0'.
  lv_str_method = /sdf/cl_rc_chk_utility=>c_method-check_consistency.

  DEFINE add_log_single.
    if sy-batch = abap_true.
      message ls_header_info-value type 'I'.
    endif.
    append ls_header_info to ls_result-header_info_table.
  END-OF-DEFINITION.


  DEFINE finalize_check.
    /sdf/cl_rc_chk_utility=>get_timestamp(
      importing
        ev_timestamp_utc         = ls_result-end_time
        ev_timestamp_wh_timezone = ls_result-end_time_wh_timezone ).

    call function 'TIMECALC_DIFF'
      exporting
        timestamp1 = ls_result-start_time
        timestamp2 = ls_result-end_time
        timezone   = 'UTC'
      importing
        difference = ls_result-running_time_in_seconds.

    "Consitency check ended at &P1&
    ls_header_info-name  = 'I'.
    ls_header_info-value = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '101'
      iv_para1   = ls_result-end_time_wh_timezone ).
    add_log_single.

    "Consistency check running time: &P1& seconds
    lv_str_tmp = ls_result-running_time_in_seconds.
    ls_header_info-name  = 'I'.
    ls_header_info-value = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '105'
      iv_para1   = lv_str_tmp ).
    add_log_single.

    "Persistent the result
    call transformation id
      source check_result = ls_result
      result xml ev_result_xstr.
    return.
  END-OF-DEFINITION.


*--------------------------------------------------------------------*
* Start of the check

  /sdf/cl_rc_chk_utility=>get_timestamp(
    IMPORTING
      ev_timestamp_utc         = ls_result-start_time
      ev_timestamp_wh_timezone = ls_result-start_time_wh_timezone ).
  "Consitency check started at &P1&
  ls_header_info-name  = 'I'.
  ls_header_info-value = /sdf/cl_rc_chk_utility=>get_text_str(
    iv_txt_key = '100'
    iv_para1   = ls_result-start_time_wh_timezone ).
  add_log_single.

  "Preparation; so far we suppose there only on check class per item
  ls_result-sitem_guid  = iv_sitem_guid.
  ls_result-sitem_id    = iv_sitem_id.
  ls_result-check_class = iv_check_class.
  ls_result-sap_note    = iv_sap_note.

  "Corresponding check class:
  ls_header_info-name  = 'I'.
  ls_header_info-value = /sdf/cl_rc_chk_utility=>get_text_str(
    iv_txt_key = '108'
    iv_para1   = iv_check_class ).
  add_log_single.


*--------------------------------------------------------------------*
* Insert a customer exit

  CALL FUNCTION '/SDF/GEN_FUNCS_S4_CONS_EXIT'
    EXPORTING
      iv_target_stack = iv_target_stack
      iv_sitem_guid   = iv_sitem_guid
      iv_sitem_id     = iv_sitem_id
    IMPORTING
      et_chk_result   = lt_clas_chk_result.
  IF lt_clas_chk_result IS NOT INITIAL.

    "Consistency check overwritten by custom exit
    ls_header_info-name  = 'W'.
    ls_header_info-value = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '156' ).
    add_log_single.

  ENDIF.


*--------------------------------------------------------------------*
* Call consistency check class is custom exit does not exist

  IF lt_clas_chk_result IS INITIAL.

    "Check whether the class not exists -> not allowed
    lv_class_exist = /sdf/cl_rc_chk_utility=>is_class_exist( ls_result-check_class ).
    IF lv_class_exist <> abap_true.
      "Class &P1& not found; check note &P2& implementation status
      ls_header_info-name  = 'E'.
      ls_header_info-value = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '103'
        iv_para1   = lv_str_class
        iv_para2   = lv_str_note ).
      add_log_single.
      ls_result-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion.
      finalize_check.
    ENDIF.

    "Check whether the relevant SAP note is out-of-date -> allowed
    "This is also checked when user choose to execute consistency check
    ls_note_status = /sdf/cl_rc_chk_utility=>check_note_status(
      iv_note_number  = iv_sap_note
      iv_action       = /sdf/cl_rc_chk_utility=>c_sap_note-action_rc_sitm_sum_chk
      iv_target_stack = iv_target_stack ).
    IF ls_note_status-latest_ver_implemented <> /sdf/cl_rc_chk_utility=>c_status-yes.
      "Check class might be out-of-date. Implement latest version of SAP Note &P1&. Implemented version: &P2&.
      ls_header_info-name  = 'W'.
      ls_header_info-value = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '113'
        iv_para1   = lv_str_note
        iv_para2   = ls_note_status-current_version_str ).
      add_log_single.
    ELSE.
      "Do not repeat the text log for TCI note since it's already reported before
      lv_check_class_note = /sdf/cl_rc_chk_utility=>c_chk_clas_tci_note.
      IF iv_sap_note <> lv_check_class_note.
        "Latest version (&P1&) of note &P2& has been implemented.
        ls_header_info-name  = 'S'.
        ls_header_info-value = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = 'B01'
          iv_para1   = ls_note_status-current_version_str
          iv_para2   = lv_str_note ).
        add_log_single.
      ENDIF.
    ENDIF.

    "Check whether the method is not implemented -> allowed with warning
    "Possible that the class implemented but not for consistency check
    lv_method_exist = /sdf/cl_rc_chk_utility=>is_method_exist(
      iv_class_name  = ls_result-check_class
      iv_method_name = /sdf/cl_rc_chk_utility=>c_method-check_consistency ).
    IF lv_method_exist <> abap_true.
      "'Relevance cannot be determined automatically; method &P1& of class &P2& not exists
      ls_header_info-name  = 'W'.
      ls_header_info-value = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '114'
        iv_para1   = lv_str_method
        iv_para2   = lv_str_class ).
      add_log_single.
      IF ls_note_status-latest_ver_implemented <> /sdf/cl_rc_chk_utility=>c_status-yes."Take it as error if the note is obsolete
        ls_result-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion.
      ELSE."Take it as warning if the not is up-to-date
        ls_result-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
      ENDIF.
      finalize_check.
    ENDIF.

    "Perform the check if consistency method exists
    TRY.
        CLEAR lt_clas_chk_result.
        CALL METHOD (iv_check_class)=>(/sdf/cl_rc_chk_utility=>c_method-check_consistency)
          EXPORTING
            it_parameter  = it_parameter
          IMPORTING
            et_chk_result = lt_clas_chk_result.

      CATCH cx_root INTO lo_exception.                   "#EC CATCH_ALL

        "Dynamic call of class &P1& method &P2& failed: &P3&
        lv_str_tmp = lo_exception->get_text( ).
        ls_header_info-name  = 'E'.
        ls_header_info-value = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = '110'
          iv_para1   = lv_str_class
          iv_para2   = lv_str_method
          iv_para3   = lv_str_tmp ).
        add_log_single.

        ls_result-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion.
        finalize_check.
    ENDTRY.
  ENDIF.


*--------------------------------------------------------------------*
* Process the check result

  CLEAR lv_return_code_found.
  LOOP AT lt_clas_chk_result INTO ls_clas_chk_result
    WHERE return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success
       OR return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning
       OR return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable
       OR return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error
       OR return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion.
    lv_return_code_found = abap_true.
    EXIT.
  ENDLOOP.

  IF lt_clas_chk_result IS INITIAL OR lv_return_code_found IS INITIAL.
    "No consistency check result returned from check class &P1&
    ls_header_info-name  = 'E'.
    ls_header_info-value = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '143'
      iv_para1   = lv_str_class
      iv_para2   = lv_str_note ).
    add_log_single.
    ls_result-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-abortion.
    finalize_check.
  ENDIF.

*  "For first  SUM phase: 7 ->4 in any case
*  "For second SUM phase: 7 ->7 if not exempted or 7->4 if exempted (same handling as other cases)
*  IF iv_sum_mode = abap_true.
*    lv_sum_phase = /sdf/cl_rc_chk_utility=>get_sum_phase( ).
*
*    IF lv_sum_phase = /sdf/cl_rc_chk_utility=>c_sum_phase-first.
*
*      LOOP AT lt_clas_chk_result ASSIGNING <fs_clas_chk_result>
*        WHERE return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable.
*        <fs_clas_chk_result>-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
*        ADD 1 TO lv_skip_ist_sum_phase.
*      ENDLOOP.
*      IF lv_skip_ist_sum_phase > 0.
*        "&P1& skippable error converted to warning automatically in SUM first phase
*        lv_str_tmp = lv_skip_ist_sum_phase.
*        ls_header_info-name  = 'W'.
*        ls_header_info-value = /sdf/cl_rc_chk_utility=>get_text_str(
*          iv_txt_key = '153'
*          iv_para1   = lv_str_tmp ).
*        add_log_single.
*      ENDIF.
*    ENDIF.
*  ENDIF.

  ls_result-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
  LOOP AT lt_clas_chk_result ASSIGNING <fs_clas_chk_result>.
    "Take the highest return code
    IF ls_result-return_code < <fs_clas_chk_result>-return_code.
      ls_result-return_code = <fs_clas_chk_result>-return_code.
    ENDIF.
    "check_sub_id not used so far
    IF <fs_clas_chk_result>-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable.
      ls_result-skippable_error = abap_true.
    ENDIF.

    "Keep up to 10000 message texts to prevent out-of-memory dump
    "Refer to 29732/2018 MEM_ALLOC_FAILED
    IF LINES( <fs_clas_chk_result>-descriptions ) > lv_chk_mesg_num_limit."10000
      "&P1& check texts are returned for &P2&. Only the first &P3& are kept to reduce resource consumption.
      lv_str_tmp = LINES( <fs_clas_chk_result>-descriptions ).
      lv_str_tmp1 = <fs_clas_chk_result>-check_sub_id.
      lv_str_tmp2 = lv_chk_mesg_num_limit.
      ls_header_info-name  = 'W'.
      ls_header_info-value = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '161' "Number of check result returned: &P1&.
        iv_para1   = lv_str_tmp
        iv_para2   = lv_str_tmp1
        iv_para3   = lv_str_tmp2 ).
      add_log_single.
      DELETE <fs_clas_chk_result>-descriptions FROM lv_chk_mesg_num_limit.
    ENDIF.
  ENDLOOP.

*  Do not change success to warning if TCI note is not up-to-date
*  IF ls_note_status-latest_ver_implemented <> /sdf/cl_rc_chk_utility=>c_status-yes
*    AND ls_result-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-success.
*    ls_result-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
*  ENDIF.

  "Item skip status is consolidated in method /SDF/CL_RC_MANAGER->PERFORM_CONSISTENCY_CHECK
  IF ls_result-skippable_error = abap_true.

    /sdf/cl_rc_chk_utility=>sitem_skip_stat_get(
      EXPORTING
        iv_target_stack = iv_target_stack
      IMPORTING
        et_sitem_skip   = lt_sitem_skip ).
    READ TABLE lt_sitem_skip INTO ls_sitem_skip
      WITH KEY sitem_guid = iv_sitem_guid.
    IF ls_sitem_skip-skip_status = /sdf/cl_rc_chk_utility=>c_sitem_skip_status-yes.

      IF ls_result-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable.
        ls_result-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
      ENDIF.

      ls_result-skip_status = /sdf/cl_rc_chk_utility=>c_sitem_skip_status-yes.

      "Consistency error found and it has been exempted by &P1& before at &P2&
      lv_str_tmp  = ls_sitem_skip-last_changed_by.
      lv_str_tmp1 = ls_sitem_skip-last_changed_at.
      ls_header_info-name  = 'W'.
      ls_header_info-value = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '123'
        iv_para1   = lv_str_tmp
        iv_para2   = lv_str_tmp1 ).
      add_log_single.

      LOOP AT lt_clas_chk_result ASSIGNING <fs_clas_chk_result>
        WHERE return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-error_skippable.
        <fs_clas_chk_result>-return_code = /sdf/cl_rc_s4sic_sample=>c_cons_chk_return_code-warning.
      ENDLOOP.
    ELSE.
      ls_result-skip_status = /sdf/cl_rc_chk_utility=>c_sitem_skip_status-no.
    ENDIF.
  ENDIF.

  CALL TRANSFORMATION id
    SOURCE clas_chk_result = lt_clas_chk_result
    RESULT XML ls_result-chk_clas_result_xstr.

  finalize_check.

ENDFUNCTION.