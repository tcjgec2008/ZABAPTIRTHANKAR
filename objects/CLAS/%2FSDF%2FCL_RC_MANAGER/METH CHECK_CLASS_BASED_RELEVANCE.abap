METHOD check_class_based_relevance.

  DATA: lv_note         TYPE cwbntnumm,
        ls_note_status  TYPE /sdf/cl_rc_chk_utility=>ty_note_stat_str,
        lv_class_name   TYPE /sdf/cl_rc_chk_utility=>ty_check_id,
        lv_class_exist  TYPE flag,
        lv_method_exist TYPE flag,
        lv_string       TYPE string,
        lv_str_class    TYPE string,
        lv_str_note     TYPE string,
        lv_str_method   TYPE string,
        lt_parameter    TYPE tihttpnvp,
        lo_exception    TYPE REF TO cx_root.

  lv_str_class  = is_check-check_identifier.
  lv_str_note   = is_check-sap_note.
  lv_str_method = /sdf/cl_rc_chk_utility=>c_method-check_relevance.

*--------------------------------------------------------------------*
* Check whether the relevant SAP note is out of date -> allowed

  lv_note = is_check-sap_note.
*  lv_update_note = /sdf/cl_rc_chk_utility=>check_if_need_to_update_note( lv_note ).
*  IF lv_update_note = abap_true."Note out of date
**    "Relevance cannot be determined automatically because SAP Note &P1& not implemented or out-of-date.
**    ev_description = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'C03'  iv_para1 = lv_str_note ).
**    "Not as strict as consistency check; since most check class is only for consistency
**    "and it's very likely that the class is not for relevance check
**    "We fallback to simple check in this case
**    ev_relevance   =  /sdf/cl_rc_s4sic_sample=>c_pre_chk_relevance-unknown."error.
**    RETURN.
*  ENDIF.

*  ls_note_status = /sdf/cl_rc_chk_utility=>check_note_status(
*    iv_note_number  = lv_note
*    iv_action       = /sdf/cl_rc_chk_utility=>c_sap_note-action_rc_relev_chk
*    iv_target_stack = mv_target_stack ).
*  IF ls_note_status-min_ver_implmented <> /sdf/cl_rc_chk_utility=>c_status-yes.
*    "Check class might be out-of-date. Implement latest version of SAP Note &P1&. Local version is &P2&
*    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
*      iv_txt_key = '113'
*      iv_para1   = lv_str_note
*      iv_para2   = ls_note_status-current_version_str ).
*  ELSE.
*    "Latest version (&P1&) of note &P2& has been implemented.
*    lv_string = /sdf/cl_rc_chk_utility=>get_text_str(
*      iv_txt_key = '149'
*      iv_para1   = ls_note_status-current_version_str
*      iv_para2   = lv_str_note ).
*  ENDIF.


*--------------------------------------------------------------------*
* Check whether the class exists -> not allowed

  lv_class_name = is_check-check_identifier.
  lv_class_exist =  /sdf/cl_rc_chk_utility=>is_class_exist( lv_class_name ).
  IF lv_class_exist <> abap_true.
    "Check class &P1& not exists in the system; check note &P2& implementation status
    ev_description = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '103'
      iv_para1   = lv_str_class
      iv_para2   = lv_str_note ).
    ev_relevance = /sdf/cl_rc_s4sic_sample=>c_pre_chk_relevance-error.
    RETURN.
  ENDIF.


*--------------------------------------------------------------------*
* Check whether the method exists -> allowed
* Possible that the class is implemented but the method does not exists
* if the class is only for consistency check

  lv_method_exist = /sdf/cl_rc_chk_utility=>is_method_exist(
    iv_class_name  = lv_class_name
    iv_method_name = /sdf/cl_rc_chk_utility=>c_method-check_relevance ).
  IF lv_method_exist <> abap_true.
    "'Method &P1& of class &P2& not exists; check note &P3& implementation
    ev_description = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '109'
      iv_para1   = lv_str_method
      iv_para2   = lv_str_class
      iv_para3   = lv_str_note ).
    ev_relevance = /sdf/cl_rc_s4sic_sample=>c_pre_chk_relevance-unknown.
    RETURN.
  ENDIF.


*--------------------------------------------------------------------*
* Perform the check

  TRY.

      lt_parameter = /sdf/cl_rc_chk_utility=>prepare_check_class_parameter(
        iv_sitem_guid   = is_check-sitem_guid
        iv_target_stack = mv_target_stack ).
      CALL METHOD (lv_class_name)=>(/sdf/cl_rc_chk_utility=>c_method-check_relevance)
        EXPORTING
          it_parameter   = lt_parameter
        IMPORTING
          ev_relevance   = ev_relevance
          ev_description = ev_description.

    CATCH cx_root INTO lo_exception.                     "#EC CATCH_ALL

      "Dynamic call of class &P1& method &P2& failed: &P3&
      lv_string = lo_exception->get_text( ).
      ev_description = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '110'
        iv_para1   = lv_str_class
        iv_para2   = lv_str_method
        iv_para3   = lv_string ).
      ev_relevance =  /sdf/cl_rc_s4sic_sample=>c_pre_chk_relevance-error.

  ENDTRY.

ENDMETHOD.