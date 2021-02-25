METHOD smdb_content_fetch_from_sap.

  DATA:lv_file_data        TYPE xstring,
       ls_content_data     TYPE srtm_datax,
       lv_content          TYPE xstring,
       lr_client           TYPE REF TO if_http_client,
       lv_request_uri      TYPE string,
       lv_subrc            TYPE sysubrc,
       lv_msg              TYPE string,
       lv_status_code      TYPE i,
       lv_status_text      TYPE string,
       lv_system_type      TYPE string.

  DATA: lv_is_ds_used     TYPE boolean,
        lv_dwld_serv_dest TYPE rfcdest,
        lv_url            TYPE string,
        lv_param          TYPE string.

  sv_smdb_fetched_from_sap = abap_false.

*--------------------------------------------------------------------*
* Fetch the Transition DB content from OSS system

  IF iv_system_type IS INITIAL.
    lv_system_type = sv_system_type.
  ELSE.
    lv_system_type = iv_system_type.
  ENDIF.

  get_download_service_info(
    IMPORTING
      ev_dwld_serv_dest = lv_dwld_serv_dest
      ev_is_ds_used     = lv_is_ds_used
  ).

 IF lv_is_ds_used = abap_true.
   IF lv_dwld_serv_dest IS INITIAL.
     rv_success = abap_false.
     RETURN.
   ENDIF.

* Check existence of the FM in the remote destination.
    CALL FUNCTION 'FUNCTION_EXISTS' DESTINATION lv_dwld_serv_dest
      EXPORTING
        funcname           = '/SDF/GEN_FUNCS_S4_SICMETA'
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
      rv_success = abap_false.
      RETURN.
    ENDIF.

    CONCATENATE '?SYSTEM_TYPE=' lv_system_type INTO lv_param.
    CONCATENATE 'https://apps.support.sap.com/odata/spn/smdb_srv/FileSet(''SICMETA.ZIP'')/$value' lv_param INTO lv_url.

    CALL FUNCTION '/SDF/GEN_FUNCS_S4_SICMETA' DESTINATION lv_dwld_serv_dest
      EXPORTING
        iv_url                = lv_url
      IMPORTING
        ev_content            = lv_content
        ev_msg                = lv_msg
      EXCEPTIONS
        system_failure        = 1
        communication_failure = 2
        OTHERS                = 3.
    IF sy-subrc <> 0.
      rv_success = abap_false.
      RETURN.
    ENDIF.
 ELSE.

  CALL FUNCTION 'FUNCTION_EXISTS'
    EXPORTING
      funcname           = 'ICM_ACTIVE'
    EXCEPTIONS
      function_not_exist = 1
      OTHERS             = 2.
  IF sy-subrc = 0.
    CALL FUNCTION 'ICM_ACTIVE'
      EXCEPTIONS
        icm_not_active = 1
        OTHERS         = 2.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
  ENDIF.

  cl_http_client=>create_by_destination(
    EXPORTING
      destination              = c_support_dest " SAP-SUPPORT_PORTAL
    IMPORTING
      client                   = lr_client
    EXCEPTIONS
      argument_not_found       = 1
      destination_not_found    = 2
      destination_no_authority = 3
      plugin_not_active        = 4
      OTHERS                   = 5
  ).
  CHECK sy-subrc = 0.

  lv_request_uri = '/odata/spn/smdb_srv/FileSet(''SICMETA.ZIP'')/$value'.
  lr_client->request->set_header_field(
    EXPORTING
      name  = if_http_header_fields_sap=>request_uri
      value = lv_request_uri
  ).
  lr_client->request->set_header_field(
    EXPORTING
      name  = c_parameter-sys_type_key "'SYSTEM_TYPE'
      value = lv_system_type
  ).

  lr_client->propertytype_logon_popup = if_http_client=>co_disabled.

  lr_client->send(
    EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      OTHERS                     = 4
  ).
  IF sy-subrc <> 0.
    lr_client->get_last_error(
      IMPORTING
        code    = lv_subrc
        message = lv_msg
    ).
    lr_client->close( ).
    RETURN.
  ENDIF.

  lr_client->receive(
    EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      OTHERS                     = 4
  ).
  IF sy-subrc <> 0.
    lr_client->get_last_error(
      IMPORTING
        code    = lv_subrc
        message = lv_msg
    ).
    lr_client->close( ).
    RETURN.
  ENDIF.

  lr_client->response->get_status(
    IMPORTING
      code   = lv_status_code
      reason = lv_status_text
  ).

  CHECK lv_status_code = 200.

  lv_content = lr_client->response->get_data( ).

  lr_client->close( ).

 ENDIF.

  CHECK lv_content IS NOT INITIAL.

*--------------------------------------------------------------------*
* Store the data into DB

  TRY.
      CALL TRANSFORMATION id SOURCE XML lv_content
        RESULT smdb_content = lv_file_data.
    CATCH cx_st_error.
      RETURN.
  ENDTRY.

  ls_content_data-trigid     = c_data_key_new-data_trigid.
  ls_content_data-trigoffset = c_data_key_new-data_trigoffset.
  ls_content_data-subid      = c_data_key_new-subid_smdb_content_latest_sap.
  ls_content_data-ddate      = sy-datum.
  ls_content_data-dtime      = sy-uzeit.
  ls_content_data-xtext      = lv_file_data.
  MODIFY srtm_datax FROM ls_content_data.

  sv_smdb_fetched_from_sap = abap_true.
  rv_success = abap_true.

ENDMETHOD.