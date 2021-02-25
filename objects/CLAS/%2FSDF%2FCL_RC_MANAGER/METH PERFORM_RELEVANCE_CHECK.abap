METHOD perform_relevance_check.

  DATA: ls_sitem             TYPE /sdf/cl_rc_chk_utility=>ty_smdb_item_str,
        ls_result            TYPE /sdf/cl_rc_chk_utility=>ty_check_result_str,
        ls_app_comp          TYPE /sdf/cl_rc_chk_utility=>ty_smdb_app_comp_str,
        ls_targ_rel          TYPE /sdf/cl_rc_chk_utility=>ty_smdb_target_str,
        ls_conv_target       TYPE /sdf/cl_rc_chk_utility=>ty_conv_target_stack_str,
        lv_string            TYPE string,
        lv_str_tmp           TYPE string,
        lv_note              TYPE cwbntnumm,
        ls_note_status       TYPE /sdf/cl_rc_chk_utility=>ty_note_stat_str,
        lv_message_type      TYPE symsgty,
        lv_smdb_source       TYPE string,
        lv_time_utc_str      TYPE string,
        lt_warning_info      TYPE salv_wd_t_string,
        lt_error_info        TYPE salv_wd_t_string,
        lv_st03n_info_str    TYPE string,
        lt_header_text       TYPE TABLE OF string.

  FIELD-SYMBOLS:
        <fs_result>          TYPE /sdf/cl_rc_chk_utility=>ty_check_result_str.

  DEFINE add_header_text.
    append lv_string to lt_header_text.
    if sy-batch = abap_true.
      message lv_string type 'I'.
    endif.
  END-OF-DEFINITION.

  CLEAR:et_result, es_header_info, mt_check_result.

  READ TABLE mt_conv_target_stack INTO ls_conv_target
    WITH KEY stack_number = mv_target_stack.
  CHECK sy-subrc = 0.
  mv_target_prod_ver = ls_conv_target-prod_ver_number.

*--------------------------------------------------------------------*
* Start of check - add header information

  "Relevance check performed in system &P1& by user &P2&
  CONCATENATE sy-sysid '/' sy-mandt INTO lv_str_tmp.
  lv_string = sy-uname.
  lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
    iv_txt_key = '080'
    iv_para1   = lv_str_tmp
    iv_para2   = lv_string ).
  add_header_text.

  "Check start time
  /sdf/cl_rc_chk_utility=>get_timestamp(
    IMPORTING
      ev_timestamp_utc         = es_header_info-start_time_utc
      ev_timestamp_wh_timezone = es_header_info-start_time_wh_timezone ).
  lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
    iv_txt_key = '100'
    iv_para1   = es_header_info-start_time_wh_timezone ).
  add_header_text.

  lv_note = /sdf/cl_rc_chk_utility=>c_framework_note.
  ls_note_status = /sdf/cl_rc_chk_utility=>check_note_status(
    iv_note_number  = lv_note
    iv_action       = /sdf/cl_rc_chk_utility=>c_sap_note-action_rc_relev_chk
    iv_target_stack = mv_target_stack ).
  IF ls_note_status-latest_ver_implemented <> /sdf/cl_rc_chk_utility=>c_status-yes.

    IF ls_note_status-min_ver_implmented = /sdf/cl_rc_chk_utility=>c_status-no.
      IF ls_note_status-implemented = abap_true.
        "Minimum required version of note &P1& is &P2& but implemented version is &P3&.
        lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = 'B11'
          iv_para1   = /sdf/cl_rc_chk_utility=>c_framework_note
          iv_para2   = ls_note_status-min_required_ver_str
          iv_para3   = ls_note_status-current_version_str ).
      ELSE.
        "Minimum required version &P1& of note &P2& not implemented.
        lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = 'B12'
          iv_para1   = ls_note_status-min_required_ver_str
          iv_para2   = /sdf/cl_rc_chk_utility=>c_framework_note ).
      ENDIF.
      add_header_text.
      APPEND lv_string TO lt_error_info.
    ELSE.
      "Implemented version &P2& of SAP Note &P1& is not up to date.Implemented version &P2& of SAP Note &P1& is not up to date.
      lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = 'B17'
        iv_para1   = /sdf/cl_rc_chk_utility=>c_framework_note
        iv_para2   = ls_note_status-current_version_str ).
      add_header_text.
      APPEND lv_string TO lt_warning_info.
    ENDIF.

  ELSE.
    "Latest version (&P1&) of note &P2& has been implemented.
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = 'B01'
      iv_para1   = ls_note_status-current_version_str
      iv_para2   = /sdf/cl_rc_chk_utility=>c_framework_note ).
    add_header_text.
  ENDIF.


  lv_note = /sdf/cl_rc_chk_utility=>c_chk_clas_tci_note.
  CLEAR ls_note_status.
  ls_note_status = /sdf/cl_rc_chk_utility=>check_note_status(
    iv_note_number  = lv_note
    iv_action       = /sdf/cl_rc_chk_utility=>c_sap_note-action_rc_relev_chk
    iv_target_stack = mv_target_stack ).
  IF ls_note_status-latest_ver_implemented <> /sdf/cl_rc_chk_utility=>c_status-yes.

    IF ls_note_status-min_ver_implmented = /sdf/cl_rc_chk_utility=>c_status-no.
      IF ls_note_status-implemented = abap_true.
        "Minimum required version of note &P1& is &P2& but implemented version is &P3&.
        lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = 'B11'
          iv_para1   = /sdf/cl_rc_chk_utility=>c_chk_clas_tci_note
          iv_para2   = ls_note_status-min_required_ver_str
          iv_para3   = ls_note_status-current_version_str ).
      ELSE.
        "Minimum required version &P1& of note &P2& not implemented.
        lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
          iv_txt_key = 'B12'
          iv_para1   = ls_note_status-min_required_ver_str
          iv_para2   = /sdf/cl_rc_chk_utility=>c_chk_clas_tci_note ).
      ENDIF.
      add_header_text.
      APPEND lv_string TO lt_error_info.
    ELSE.
      "Implemented version &P2& of SAP Note &P1& is not up to date.
      lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = 'B17'
        iv_para1   = /sdf/cl_rc_chk_utility=>c_chk_clas_tci_note
        iv_para2   = ls_note_status-current_version_str ).
      add_header_text.
      APPEND lv_string TO lt_warning_info.
    ENDIF.

  ELSE.
    "Latest version (&P1&) of note &P2& has been implemented.
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = 'B01'
      iv_para1   = ls_note_status-current_version_str
      iv_para2   = /sdf/cl_rc_chk_utility=>c_chk_clas_tci_note ).
    add_header_text.
  ENDIF.

  "Display the target product version
  lv_string = /sdf/cl_rc_chk_utility=>get_conversion_target_str( mv_target_stack ).
  add_header_text.

  "Simplification Item Catalog source & timestamp
  /sdf/cl_rc_chk_utility=>get_smdb_content(
    IMPORTING
      ev_time_utc_str = lv_time_utc_str
    EXCEPTIONS
      OTHERS          = 0 )."Checked before not error expect here

  lv_smdb_source = /sdf/cl_rc_chk_utility=>smdb_content_source_get( ).
  IF lv_smdb_source = /sdf/cl_rc_chk_utility=>c_parameter-smdb_source_sap.
    "Simplification Item Catalog source: get the latest version from SAP
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '071' ).
    add_header_text.

    IF /sdf/cl_rc_chk_utility=>sv_smdb_fetched_from_sap IS INITIAL.
      IF /sdf/cl_rc_chk_utility=>sv_is_ds_used = abap_true.
        "Latest simplificatin items not fetched; check Download Service connection
        lv_string = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '177' ).
      ELSE.
        "Latest simplificatin items not fetched; check SAP-SUPPORT_PORTAL HTTP connection
        lv_string = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '172' ).
      ENDIF.
      add_header_text.
    ENDIF.

  ELSE.
    "Simplification Item Catalog source: the local version
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '072' ).
    add_header_text.
  ENDIF.

  "Used Simplification Item Catalog was downloaded from SAP at &P1&
  lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
    iv_txt_key = '139'
    iv_para1   = lv_time_utc_str ).
  add_header_text.

  "Log whether in background mode
  IF sy-batch = abap_true.
    lv_str_tmp = 'Yes'.
  ELSE.
    lv_str_tmp = 'No'.
  ENDIF.
  "Check performed in background mode (sy-batch): &P1&
  lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
    iv_txt_key = '149'
    iv_para1   = lv_str_tmp ).
  add_header_text.

  "Read the uploaded ST03N data through report TMW_RC_MANAGE_ST03N_DATA
  /sdf/cl_rc_chk_utility=>get_uploaded_st03n_data(
    IMPORTING
      ev_info_str = lv_st03n_info_str ).
  IF lv_st03n_info_str IS NOT INITIAL.
    "Manually uploaded ST03N data is used for relevance check.
    lv_string = lv_st03n_info_str.
    add_header_text.
  ENDIF.


*--------------------------------------------------------------------*
* Preparation for initial SItem list
* PPMS content completeless is ensured when SMDB content is downloaded

  IF it_check_sitem IS NOT INITIAL.
    "&P1& simplification item to be checked
    lv_str_tmp = LINES( it_check_sitem ).
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '157'
      iv_para1   = lv_str_tmp ).
    add_header_text.
  ELSE.
    "All simplification item to be checked
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '158' ).
    add_header_text.
  ENDIF.

  LOOP AT mt_sitem INTO ls_sitem.

    "Remove SItem not interested if checked Sitems are specified
    IF it_check_sitem IS NOT INITIAL.
      READ TABLE it_check_sitem TRANSPORTING NO FIELDS
        WITH KEY guid = ls_sitem-guid.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
    ENDIF.

    CLEAR ls_result.
    ls_result-sitem_guid          = ls_sitem-guid.
    ls_result-sitem_id            = ls_sitem-sitem_id.
    ls_result-seq_area            = ls_sitem-seq_area.
    ls_result-title_en            = ls_sitem-title_en.
    ls_result-app_area            = ls_sitem-app_area.
    ls_result-proc_status         = ls_sitem-proc_status_text_en.
    ls_result-proc_stat_disp      = ls_sitem-proc_status_text_en.
    ls_result-check_condition     = ls_sitem-check_condition.
    ls_result-expected_relev_stat = ls_sitem-expected_relev_stat.

    "Concatenante Application Component
    LOOP AT mt_app_component INTO ls_app_comp
      WHERE guid = ls_sitem-guid.

      IF ls_result-app_components IS INITIAL.
        ls_result-app_components = ls_app_comp-app_comp.
      ELSE.
        CONCATENATE ls_result-app_components ',' ls_app_comp-app_comp INTO ls_result-app_components.
      ENDIF.
    ENDLOOP.

    "Get Catetory
    READ TABLE mt_target_release INTO ls_targ_rel
      WITH KEY guid = ls_sitem-guid.
    IF sy-subrc = 0.
      ls_result-category_text = ls_targ_rel-category_text_en.
    ENDIF.

    APPEND ls_result TO mt_check_result.

  ENDLOOP.


*--------------------------------------------------------------------*
* Calculate for Business Impact Note

  get_buz_impact_note( ).


*--------------------------------------------------------------------*
* Check whether the item is applicable based on source/target release

  check_applicability( ).


*--------------------------------------------------------------------*
* Calculate relevance

  check_relevance( ).


*--------------------------------------------------------------------*
* End of the check - add header information

  "Check end time
  /sdf/cl_rc_chk_utility=>get_timestamp(
    IMPORTING
      ev_timestamp_utc         = es_header_info-end_time_utc
      ev_timestamp_wh_timezone = es_header_info-end_time_wh_timezone ).
  CALL FUNCTION 'TIMECALC_DIFF'
    EXPORTING
      timestamp1 = es_header_info-start_time_utc
      timestamp2 = es_header_info-end_time_utc
      timezone   = 'UTC'
    IMPORTING
      difference = es_header_info-running_time_in_seconds.
  lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
    iv_txt_key = '101'
    iv_para1   = es_header_info-end_time_wh_timezone ).
  add_header_text.

  "Check total run time is &P1& seconds
  lv_string = es_header_info-running_time_in_seconds.
  lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
    iv_txt_key = '102'
    iv_para1   = lv_string ).
  add_header_text.

  "Add log seperator for easier reading
  IF sy-batch = abap_true.
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '081'
      iv_para1   = lv_string ).
    MESSAGE lv_string TYPE 'I'.
  ENDIF.

  /sdf/cl_rc_chk_utility=>get_smdb_content(
    IMPORTING
      ev_time_utc          = es_header_info-simp_item_cat_ver_utc
    EXCEPTIONS
      smdb_contnet_not_found = 1
      error                  = 2
      OTHERS                 = 3 ).

  es_header_info-system_name             = sy-sysid.
  es_header_info-system_client           = sy-mandt.
  es_header_info-check_user              = sy-uname.
  es_header_info-no_enough_st03_data     = /sdf/cl_rc_chk_utility=>sv_no_enough_st03_data.
  es_header_info-fwk_note_number         = /sdf/cl_rc_chk_utility=>c_framework_note.
  ls_note_status = /sdf/cl_rc_chk_utility=>check_note_status(
    iv_note_number  = es_header_info-fwk_note_number
    iv_action       = /sdf/cl_rc_chk_utility=>c_sap_note-action_rc_relev_chk
    iv_target_stack = mv_target_stack ).
  es_header_info-fwk_note_current_ver    = ls_note_status-current_version.
  es_header_info-fwk_note_min_req_ver    = ls_note_status-min_required_ver.
  es_header_info-fwk_note_latest_impled  = ls_note_status-latest_ver_implemented.


*--------------------------------------------------------------------*
* Consolidate lastest consistency check result

  add_consis_result_to_rel_chk( es_header_info ).
  et_result = mt_check_result.


*--------------------------------------------------------------------*
* Write the check result to application log

  /sdf/cl_rc_chk_utility=>app_log_relvence_chk_init( ).

  "Relevancy check overall information
  lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
    iv_txt_key = '047' ).
  /sdf/cl_rc_chk_utility=>app_log_add_free_text(
    iv_mesg_text  = lv_string
    iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_1 ).

  "Header information
  LOOP AT lt_header_text INTO lv_string.

    lv_message_type = 'I'.

    READ TABLE lt_warning_info TRANSPORTING NO FIELDS
      WITH KEY table_line = lv_string.
    IF sy-subrc = 0.
      lv_message_type = 'W'.
    ENDIF.

    READ TABLE lt_error_info TRANSPORTING NO FIELDS
      WITH KEY table_line = lv_string.
    IF sy-subrc = 0.
      lv_message_type = 'E'.
    ENDIF.

    /sdf/cl_rc_chk_utility=>app_log_add_free_text(
      iv_mesg_text  = lv_string
      iv_mesg_type  = lv_message_type
      iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_2 ).
  ENDLOOP.

  "Log result of each item
  LOOP AT et_result ASSIGNING <fs_result>.

    "Check item "&P1&"
    lv_str_tmp = <fs_result>-sitem_id.
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '111'
      iv_para1   = lv_str_tmp ).
    /sdf/cl_rc_chk_utility=>app_log_add_free_text(
      iv_mesg_text  = lv_string
      iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_2 ).

    IF <fs_result>-relevant_stat_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.
      lv_message_type = 'I'.
    ELSE.
      lv_message_type = 'W'.
    ENDIF.

    "Relevance: &P1&
    lv_str_tmp = <fs_result>-relevant_stat_int.
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '045'
      iv_para1   = lv_str_tmp ).
    /sdf/cl_rc_chk_utility=>app_log_add_free_text(
      iv_mesg_text  = lv_string
      iv_mesg_type  = lv_message_type
      iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_3 ).

    "Summary: &P1&
    lv_str_tmp = <fs_result>-summary.
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '046'
      iv_para1   = lv_str_tmp ).
    /sdf/cl_rc_chk_utility=>app_log_add_free_text(
      iv_mesg_text  = lv_string
      iv_mesg_type  = lv_message_type
      iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_3 ).

    "Technical Summary: &P1&
    lv_str_tmp = <fs_result>-summary_int.
    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '046'
      iv_para1   = lv_str_tmp ).
    /sdf/cl_rc_chk_utility=>app_log_add_free_text(
      iv_mesg_text  = lv_string
      iv_mesg_type  = lv_message_type
      iv_mesg_level = /sdf/cl_rc_chk_utility=>c_app_log-level_3 ).

  ENDLOOP.

ENDMETHOD.