METHOD smdb_content_upload_time_get.

  DATA: lt_header           TYPE /sdf/cl_rc_chk_utility=>ty_name_value_pair_tab,
        ls_header           TYPE /sdf/cl_rc_chk_utility=>ty_name_value_pair_str,
        lo_zip_object       TYPE REF TO cl_abap_zip,
        lv_data_xstr        TYPE xstring,
        lv_timestamp_l      TYPE timestampl,
        lv_date             TYPE dats,
        lv_time             TYPE tims.

  CLEAR: rv_time_utc.

*--------------------------------------------------------------------*
* Get time stamp when content is last downloaded

  CHECK iv_file_data IS NOT INITIAL.

  "Extract the zip data
  CREATE OBJECT lo_zip_object.
  lo_zip_object->load(
    EXPORTING
      zip    = iv_file_data
    EXCEPTIONS
      OTHERS = 1 ).
  CHECK sy-subrc = 0.

  lo_zip_object->get(
    EXPORTING
      name      = c_file_name-header
    IMPORTING
      content   = lv_data_xstr
    EXCEPTIONS
        OTHERS  = 1 ).
  CHECK sy-subrc = 0 AND lv_data_xstr IS NOT INITIAL.

  TRY.
      CALL TRANSFORMATION id SOURCE XML lv_data_xstr
        RESULT header = lt_header.
      READ TABLE lt_header INTO ls_header
        WITH KEY name = c_file_name-hdr_time_utc.
      IF sy-subrc = 0.
        lv_timestamp_l = ls_header-value.
        CONVERT TIME STAMP lv_timestamp_l TIME ZONE c_time_zone_utc INTO DATE lv_date TIME lv_time.
        CONVERT DATE lv_date TIME lv_time INTO TIME STAMP rv_time_utc TIME ZONE c_time_zone_utc.
      ENDIF.

    CATCH cx_st_error INTO so_exception.
  ENDTRY.

ENDMETHOD.