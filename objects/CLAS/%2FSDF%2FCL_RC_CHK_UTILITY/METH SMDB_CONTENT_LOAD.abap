METHOD smdb_content_load.

  DATA: lv_data_xstr        TYPE xstring,
        ls_check            TYPE ty_smdb_check_str,
        ls_check_db         TYPE ty_smdb_check_db_str,
        ls_content_data     TYPE srtm_datax,
        lt_ppms_prod_ver    TYPE ty_ppms_prod_version_tab,
        lv_test_mode        TYPE flag,
        lv_old_tci_note     TYPE cwbntnumm,
        ls_header           TYPE /sdf/cl_rc_chk_utility=>ty_name_value_pair_str,
        lv_timestamp_c(50)  TYPE c,
        lo_zip_object       TYPE REF TO cl_abap_zip.

  FIELD-SYMBOLS:
        <fs_note>           TYPE ty_smdb_note_str,
        <fs_check>          TYPE ty_smdb_check_str.

  CLEAR: ev_smdb_zip_xtr, et_header, et_sitem, et_target_release, et_source_release, et_check, et_check_db,
         et_conv_target_stack, et_bw_conv_target_stack, et_note, et_app_comp,
         et_ppms_product, et_ppms_prod_version, et_ppms_stack,
         et_piece_list, ev_time_utc, ev_time_utc_str, et_smdb_note_req, et_rc_note_req.

*--------------------------------------------------------------------*
* Extract the zip data

  IF sv_content_source = c_parameter-smdb_source_sap.
    SELECT SINGLE * FROM srtm_datax INTO ls_content_data
      WHERE trigid     = c_data_key_new-data_trigid
        AND trigoffset = c_data_key_new-data_trigoffset
        AND subid      = c_data_key_new-subid_smdb_content_latest_sap.

    IF sy-subrc <> 0.

      SELECT SINGLE * FROM srtm_datax INTO ls_content_data
        WHERE trigid     = c_data_key_new-data_trigid
          AND trigoffset = c_data_key_new-data_trigoffset
          AND subid      = c_data_key_new-subid_smdb_content_upload.

      IF sy-subrc = 0.
        smdb_content_source_save( iv_smdb_source = c_parameter-smdb_source_manual ).
      ENDIF.

    ENDIF.
  ELSE.
    SELECT SINGLE * FROM srtm_datax INTO ls_content_data
      WHERE trigid     = c_data_key_new-data_trigid
        AND trigoffset = c_data_key_new-data_trigoffset
        AND subid      = c_data_key_new-subid_smdb_content_upload.

    IF sy-subrc <> 0.

      SELECT SINGLE * FROM srtm_datax INTO ls_content_data
        WHERE trigid     = c_data_key_new-data_trigid
          AND trigoffset = c_data_key_new-data_trigoffset
          AND subid      = c_data_key_new-subid_smdb_content_latest_sap.

      IF sy-subrc = 0.
        smdb_content_source_save( iv_smdb_source = c_parameter-smdb_source_sap ).
      ENDIF.

    ENDIF.
  ENDIF.
  ev_smdb_zip_xtr = ls_content_data-xtext.
  IF ev_smdb_zip_xtr IS INITIAL.
    RAISE error.
  ENDIF.

  CREATE OBJECT lo_zip_object.
  lo_zip_object->load(
    EXPORTING
      zip    = ev_smdb_zip_xtr
    EXCEPTIONS
      OTHERS = 1 ).
  IF sy-subrc <> 0.
    RAISE error.
  ENDIF.


*--------------------------------------------------------------------*
* Load header data

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-header
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT header = et_header.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.

  READ TABLE et_header INTO ls_header
    WITH KEY name = c_file_name-hdr_time_utc.
  IF sy-subrc = 0.
    ev_time_utc = ls_header-value.
    WRITE ev_time_utc TO lv_timestamp_c TIME ZONE c_time_zone_utc.
    CONCATENATE lv_timestamp_c 'UTC' INTO ev_time_utc_str SEPARATED BY space.

*    "Convert UTC to user's specified format (System -> User Profile -> Own Data):
*    WRITE ev_time_utc TO lv_timestamp_c TIME ZONE 'UTC'.sy-zonlo.
*    "Add timezone to time/date string
*    CONCATENATE lv_timestamp_c sy-zonlo INTO ev_time_local_str SEPARATED BY space.

  ENDIF.


*--------------------------------------------------------------------*
* Load Simplification Item

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-transition_db_item
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT transition_db_item = et_sitem.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.


*--------------------------------------------------------------------*
* Load source release

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-source_release
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT source_release = et_source_release.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.


*--------------------------------------------------------------------*
* Load target release

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-target_release
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT target_release = et_target_release.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.


*--------------------------------------------------------------------*
* Load check

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-check_new
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT check_new = et_check.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.
  lv_old_tci_note = '2418800'.
  LOOP AT et_check ASSIGNING <fs_check>
    WHERE check_type = c_check_type-pre_check_new.
    IF <fs_check>-sap_note IS INITIAL OR <fs_check>-sap_note = lv_old_tci_note.
      <fs_check>-sap_note = /sdf/cl_rc_chk_utility=>c_chk_clas_tci_note.
    ENDIF.
  ENDLOOP.


*--------------------------------------------------------------------*
* Load check - database based rule

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-check_db_new
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT check_db_new = et_check_db.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.


*--------------------------------------------------------------------*
* Load S/4HANA conversion target release

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-conv_target_stack
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT conv_target_stack = et_conv_target_stack.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.


*--------------------------------------------------------------------*
* Load BW/4HANA conversion target release

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-bw_conv_target_stack
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT conv_target_stack = et_bw_conv_target_stack.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.


*--------------------------------------------------------------------*
* Load S/4HANA note

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-note
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT note = et_note.
        LOOP AT et_note ASSIGNING <fs_note>.
          SHIFT <fs_note>-sap_note LEFT DELETING LEADING '0'.
        ENDLOOP.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.


*--------------------------------------------------------------------*
* Load application component

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-application_component
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT application_component = et_app_comp.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.


*--------------------------------------------------------------------*
* Load piece list

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-piece_list
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT piece_list = et_piece_list.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.


*--------------------------------------------------------------------*
* Load PPMS information

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-ppms_product
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT ppms_product = et_ppms_product.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-ppms_prod_version
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT ppms_prod_version = et_ppms_prod_version.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-ppms_stack
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT ppms_stack = et_ppms_stack.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.


*--------------------------------------------------------------------*
* Load SAP note requirement

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-note_requirement
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT smdb_note_req = et_smdb_note_req
                 rc_note_req   = et_rc_note_req.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.


*--------------------------------------------------------------------*
* Load lob master data

  CLEAR lv_data_xstr.
  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-lob_ba
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  IF sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.
    TRY.
        CALL TRANSFORMATION id SOURCE XML lv_data_xstr
          RESULT sic_lob = et_lob.
      CATCH cx_st_error INTO so_exception.
        sv_message = so_exception->get_text( ).
        MESSAGE sv_message TYPE 'E' RAISING error.
    ENDTRY.
  ENDIF.

ENDMETHOD.