METHOD check_note_status.

  DATA: lv_note_impl_status TYPE cwbprstat,
        lv_rfcmessage       TYPE char255,
        ls_note             TYPE bcwbn_note,
        ls_note_req_latest  TYPE ty_note_req_str,
        lv_msg              TYPE string,
        ls_note_req         TYPE ty_rc_note_req_str,
        lv_note             TYPE cwbntnumm,
        lt_note_key         TYPE bcwbn_note_keys_vs,
        lv_note_str         TYPE string,
        lv_note_chng_read   TYPE flag,
        ls_smdb_note_req    TYPE ty_smdb_note_req_str,
        lt_cwbntci          TYPE TABLE OF cwbntci,
        ls_cwbntci          TYPE cwbntci,
        ls_cwbcikeyvs       TYPE cwbcikeyvs,
        ls_old_corr_instru  TYPE bcwbn_corr_instruction.

  CHECK iv_note_number IS NOT INITIAL.

  READ TABLE st_note_stat INTO rs_note_status
    WITH KEY number       = iv_note_number
             action       = iv_action
             target_stack = iv_target_stack.
  CHECK sy-subrc <> 0.

  lv_note_str = iv_note_number.
  SHIFT lv_note_str LEFT DELETING LEADING '0'.

  rs_note_status-number                 = iv_note_number.
  rs_note_status-action                 = iv_action.
  rs_note_status-target_stack           = iv_target_stack.
  rs_note_status-latest_ver_implemented = c_status-unknown.
  rs_note_status-min_ver_implmented     = c_status-unknown.


*--------------------------------------------------------------------*
* Update the note status

  READ TABLE st_updated_note TRANSPORTING NO FIELDS
    WITH KEY table_line = iv_note_number.
  IF sy-subrc <> 0.
    ls_note-key-numm = iv_note_number.
    CALL FUNCTION 'SCWB_NOTE_ENQUEUE'
      EXPORTING
        is_note = ls_note
      EXCEPTIONS
        OTHERS  = 1.
    IF sy-subrc = 0.
      CALL FUNCTION 'SCWB_NOTE_UPDATE'
        EXPORTING
          iv_write_sol_mgr_reference = abap_true
        CHANGING
          cs_note                    = ls_note
        EXCEPTIONS
          OTHERS                     = 0.

      CALL FUNCTION 'SCWB_NOTE_DEQUEUE'
        EXPORTING
          is_note = ls_note.
    ENDIF.
    APPEND iv_note_number TO st_updated_note.
  ENDIF.


*--------------------------------------------------------------------*
* Read note local status

  CLEAR ls_note.
  ls_note-key-numm = iv_note_number.
  CALL FUNCTION 'SCWB_NOTE_READ'
    EXPORTING
      iv_read_attributes          = 'X'
      iv_read_customer_attributes = 'X' "To read process status in CWBNTCUST-PRSTATUS
    CHANGING
      cs_note                     = ls_note
    EXCEPTIONS
      note_not_found              = 1 "Only indicate whether the note is downloaded
      corr_instruction_not_found  = 2
      OTHERS                      = 8.
  IF sy-subrc = 1.
    IF sv_test_system = abap_true."For CVB system only
      rs_note_status-implemented            = abap_true.
      rs_note_status-status                 = c_sap_note-implemented_upto_date.
      rs_note_status-latest_ver_implemented = c_status-yes.
      rs_note_status-min_ver_implmented     = c_status-yes.
      "Latest version of SAP Note &P1& implemented
      "rs_note_status-status_desc           = get_text_str( iv_txt_key = 'B01' iv_para1 = lv_note_str ).
    ELSE.
      rs_note_status-implemented            = abap_false.
      rs_note_status-status                 = c_sap_note-not_downloaded.
      rs_note_status-latest_ver_implemented = c_status-no.
      rs_note_status-min_ver_implmented     = c_status-no.
      "Required SAP Note &P1& not implemented
      "rs_note_status-status_desc           = get_text_str( iv_txt_key = 'B10' iv_para1 = lv_note_str ).
    ENDIF.
    RETURN.
  ENDIF.

  rs_note_status-current_version = ls_note-key-versno.
  lv_note_impl_status = ls_note-customer_attributes-prstatus.
  IF   lv_note_impl_status = c_sap_note-prstat_initial
    OR lv_note_impl_status = c_sap_note-prstat_not_implemented
    OR lv_note_impl_status = c_sap_note-prstat_no_valid_cinst
    OR lv_note_impl_status = c_sap_note-prstat_obsolete.
    "Note isn't implemented => message and return
    "MESSAGE i047(scwn) WITH ls_note-key-numm.
    rs_note_status-implemented = abap_false.
  ELSE.
    rs_note_status-implemented = abap_true.
  ENDIF.


*--------------------------------------------------------------------*
* Replace the real framework note with dummy test note

  IF rs_note_status-implemented = abap_false
    AND iv_note_number = /sdf/cl_rc_chk_utility=>c_framework_note.

    lv_note = /sdf/cl_rc_chk_utility=>c_framework_test_note.
    rs_note_status = /sdf/cl_rc_chk_utility=>check_note_status(
      iv_note_number  = lv_note
      iv_action       = iv_action
      iv_target_stack = iv_target_stack ).
    RETURN.

  ENDIF.


*--------------------------------------------------------------------*
* Check whether the latest version is implemented

  IF lv_note_impl_status   = c_sap_note-prstat_old_vrs_impl
    OR lv_note_impl_status = c_sap_note-prstat_incompl_impl
    OR lv_note_impl_status = c_sap_note-prstat_obsolete.

    rs_note_status-status = c_sap_note-implemented_outof_date.
    rs_note_status-latest_ver_implemented = c_status-no.

    "In case the note is known as obsolte; then read the implemented
    "version by checking the correction instruction status
    SELECT * FROM cwbntci INTO TABLE lt_cwbntci "#EC CI_BYPASS "#EC CI_GENBUFF
      WHERE  numm = iv_note_number
      ORDER BY versno DESCENDING.
    DELETE lt_cwbntci WHERE versno = rs_note_status-current_version.
    LOOP AT lt_cwbntci INTO ls_cwbntci.

      ls_cwbcikeyvs-insta  = ls_cwbntci-ciinsta.
      ls_cwbcikeyvs-pakid  = ls_cwbntci-cipakid.
      ls_cwbcikeyvs-aleid  = ls_cwbntci-cialeid.
      ls_cwbcikeyvs-versno = ls_cwbntci-civersno.

      CLEAR: ls_old_corr_instru.
      CALL FUNCTION 'SCWB_CINST_CHECK_OLD_VRS_IMPL'
        EXPORTING
          is_cikey                     = ls_cwbcikeyvs
        IMPORTING
          es_corr_instruction_impl_vrs = ls_old_corr_instru.
      IF ls_old_corr_instru-note_key-versno  IS NOT INITIAL.
        rs_note_status-current_version = ls_old_corr_instru-note_key-versno.
        EXIT.
      ENDIF.

    ENDLOOP.

  ELSE.
    APPEND ls_note-key TO lt_note_key.
    IF lt_note_key IS NOT INITIAL.

      get_sapnote_require_and_latest(
        EXPORTING
          iv_note_number  = iv_note_number
          iv_action       = iv_action
          iv_target_stack = iv_target_stack
        IMPORTING
          es_note_req     = ls_note_req_latest
          ev_msg          = lv_msg
      ).
      IF ls_note_req_latest IS NOT INITIAL and lv_msg IS INITIAL.
        lv_note_chng_read = abap_true.
      ENDIF.

    ENDIF.

    IF lv_note_chng_read IS INITIAL.
      IF rs_note_status-implemented = abap_true.
        rs_note_status-status = c_sap_note-implemented_stat_unknown.
        "Obsolete version of SAP note implemented
        "rs_note_status-status_desc  = get_text_str( iv_txt_key = 'B06' iv_para1 = lv_note_str ).
      ELSE.
        rs_note_status-status = c_sap_note-not_implemen_stat_unknown.
        "Obsolete version of SAP note has been downloaded and not implemented
        "rs_note_status-status_desc = get_text_str( iv_txt_key = 'B07' iv_para1 = lv_note_str ).
      ENDIF.
      rs_note_status-latest_ver_implemented = c_status-unknown.

    ELSE.
      IF ls_note_req_latest-latest_note_version > rs_note_status-current_version.
        IF rs_note_status-implemented = abap_true.
          rs_note_status-status       = c_sap_note-implemented_outof_date.
          "Obsolete version of SAP note implemented
          "rs_note_status-status_desc  = get_text_str( iv_txt_key = 'B02' iv_para1 = lv_note_str ).
        ELSE.
          rs_note_status-status = c_sap_note-not_implemen_outof_date.
          "Obsolete version of SAP note has been downloaded and not implemented
          "rs_note_status-status_desc = get_text_str( iv_txt_key = 'B04' iv_para1 = lv_note_str ).
        ENDIF.
      ELSE.
        IF rs_note_status-implemented = abap_true.
          rs_note_status-status      = c_sap_note-implemented_upto_date.
          "Latest version of SAP note implemented
          "rs_note_status-status_desc = get_text_str( iv_txt_key = 'B01' iv_para1 = lv_note_str ).
        ELSE.
          rs_note_status-status      = c_sap_note-not_implemen_upto_date.
          "Latest version of SAP note downloaded but not implemented
          "rs_note_status-status_desc = get_text_str( iv_txt_key = 'B03' iv_para1 = lv_note_str ).
        ENDIF.
      ENDIF.
    ENDIF.

    IF  rs_note_status-status = /sdf/cl_rc_chk_utility=>c_sap_note-implemented_upto_date
     OR rs_note_status-status = /sdf/cl_rc_chk_utility=>c_sap_note-implemented_stat_unknown.
      rs_note_status-latest_ver_implemented = c_status-yes.
    ELSE.
      rs_note_status-latest_ver_implemented = c_status-no.
    ENDIF.
  ENDIF.

  IF rs_note_status-current_version IS INITIAL.
    rs_note_status-current_version_str = '0'.
  ELSE.
    rs_note_status-current_version_str = rs_note_status-current_version.
    SHIFT rs_note_status-current_version_str LEFT DELETING LEADING '0'.
  ENDIF.

*--------------------------------------------------------------------*
* Latest version implemented always means the minimum version is implemented

  IF rs_note_status-latest_ver_implemented = c_status-yes.
    rs_note_status-min_ver_implmented = c_status-yes.
    APPEND rs_note_status TO st_note_stat.
    RETURN.
  ENDIF.


*--------------------------------------------------------------------*
* Get the minimum version of the note remotely

  get_sapnote_require_and_latest(
    EXPORTING
      iv_note_number  = iv_note_number
      iv_action       = iv_action
      iv_target_stack = iv_target_stack
    IMPORTING
      es_note_req     = ls_note_req_latest
      ev_msg          = lv_msg
  ).
  IF ls_note_req_latest IS NOT INITIAL and lv_msg IS INITIAL.
    ls_note_req-sap_note = ls_note_req_latest-sap_note.
    ls_note_req-min_note_version = ls_note_req_latest-min_note_version.
  ENDIF.

*--------------------------------------------------------------------*
* Get the minimum version of the note locally
* as fallback in cass the system is not connected to SAP
* refer to FM /SPN/SOLMAN_RC_GET_NOTE_REQMNT

  IF ls_note_req IS INITIAL.

    READ TABLE st_smdb_note_req INTO ls_smdb_note_req
      WITH KEY stack_ppms_id = iv_target_stack
               sap_note      = iv_note_number.
    IF sy-subrc = 0.
      ls_note_req-sap_note         = ls_smdb_note_req-sap_note.
      ls_note_req-min_note_version = ls_smdb_note_req-min_note_version.
    ELSE.

      READ TABLE st_rc_note_req INTO ls_note_req
        WITH KEY application = c_sap_note-application_read_chk
                 appl_action = iv_action
                 sap_note    = iv_note_number.
    ENDIF.

  ENDIF.


*--------------------------------------------------------------------*
* Check if the minimum version of the note is implemented

  IF ls_note_req IS NOT INITIAL.
    rs_note_status-min_required_ver     = ls_note_req-min_note_version.
    rs_note_status-min_required_ver_str = ls_note_req-min_note_version.
    SHIFT rs_note_status-min_required_ver_str LEFT DELETING LEADING '0'.
    IF rs_note_status-current_version >= rs_note_status-min_required_ver
      AND rs_note_status-implemented = abap_true.

      rs_note_status-min_ver_implmented = c_status-yes.

    ELSE.
      rs_note_status-min_ver_implmented = c_status-no.
    ENDIF.
  ENDIF.
  APPEND rs_note_status TO st_note_stat.

ENDMETHOD.