METHOD get_sapnote_require_and_latest.
  DATA: ls_note_req_lat TYPE ty_note_req_buf_str,
        lr_client       TYPE REF TO if_http_client,
        lv_request_uri  TYPE string,
        lv_note_number  TYPE string,
        lv_target_stack TYPE string,
        lv_data         TYPE xstring,
        lv_subrc        TYPE sysubrc,
        lv_status_code  TYPE i,
        lv_status_text  TYPE string,
        lr_exception    TYPE REF TO cx_st_error.

  DATA: lv_is_ds_used     TYPE boolean,
        lv_dwld_serv_dest TYPE rfcdest,
        lv_url            TYPE string,
        lv_param          TYPE string.

  READ TABLE st_note_req_latest INTO ls_note_req_lat
    WITH KEY sap_note     = iv_note_number
             action       = iv_action
             target_stack = iv_target_stack.
  IF sy-subrc = 0.
    es_note_req-sap_note            = ls_note_req_lat-sap_note.
    es_note_req-min_note_version    = ls_note_req_lat-min_note_version.
    es_note_req-latest_note_version = ls_note_req_lat-latest_note_version.
    RETURN.
  ENDIF.

  get_download_service_info(
    IMPORTING
      ev_dwld_serv_dest = lv_dwld_serv_dest
      ev_is_ds_used     = lv_is_ds_used
  ).

 IF lv_is_ds_used = abap_true.

   IF lv_dwld_serv_dest IS INITIAL.
     ev_msg = 'Download service destionation not maintained'. "#EC NOTEXT
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
      ev_msg = 'Remote function not exist'. "#EC NOTEXT
      RETURN.
    ENDIF.

    CONCATENATE '?NOTE_REQ_APPLITION=' 'RC4S4HANA' INTO lv_param.
    CONCATENATE lv_param '&NOTE_REQ_APPL_ACTION=' iv_action INTO lv_param.
    CONCATENATE lv_param '&NOTE_REQ_NOTE_NUMBER=' iv_note_number INTO lv_param.
    IF iv_target_stack IS NOT INITIAL.
      CONCATENATE lv_param '&NOTE_REQ_PPMS_STACK=' iv_target_stack INTO lv_param.
    ENDIF.
    CONCATENATE 'https://apps.support.sap.com/odata/spn/smdb_srv/FileSet(''REQNOTE'')/$value' lv_param INTO lv_url.

    CALL FUNCTION '/SDF/GEN_FUNCS_S4_SICMETA' DESTINATION lv_dwld_serv_dest
      EXPORTING
        iv_url                = lv_url
      IMPORTING
        ev_content            = lv_data
        ev_msg                = ev_msg
      EXCEPTIONS
        system_failure        = 1
        communication_failure = 2
        OTHERS                = 3.
    IF sy-subrc <> 0.
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
      destination              = c_support_dest
    IMPORTING
      client                   = lr_client
    EXCEPTIONS
      argument_not_found       = 1
      destination_not_found    = 2
      destination_no_authority = 3
      plugin_not_active        = 4
      OTHERS                   = 5
  ).
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        ev_msg = 'Create failed: Argument not found'.       "#EC NOTEXT
      WHEN 2.
        ev_msg = 'Create failed: destionation not found'.   "#EC NOTEXT
      WHEN 4.
        ev_msg = 'Create failed: destionation no authority'. "#EC NOTEXT
      WHEN 3.
        ev_msg = 'Create failed: plugin not active'.        "#EC NOTEXT
      WHEN OTHERS.
        ev_msg = 'Create failed'.                           "#EC NOTEXT
    ENDCASE.
    RETURN.
  ENDIF.

  lv_request_uri = '/odata/spn/smdb_srv/FileSet(''REQNOTE'')/$value'.
  lr_client->request->set_header_field(
    EXPORTING
      name  = if_http_header_fields_sap=>request_uri
      value = lv_request_uri
  ).
  lr_client->request->set_header_field(
    EXPORTING
      name  = 'NOTE_REQ_APPLITION'
      value = 'RC4S4HANA'
  ).
  lr_client->request->set_header_field(
    EXPORTING
      name  = 'NOTE_REQ_APPL_ACTION'
      value = iv_action
  ).
  lv_note_number = iv_note_number.
  lr_client->request->set_header_field(
    EXPORTING
      name  = 'NOTE_REQ_NOTE_NUMBER'
      value = lv_note_number
  ).
  IF iv_target_stack IS NOT INITIAL.
    lv_target_stack = iv_target_stack.
    lr_client->request->set_header_field(
      EXPORTING
        name  = 'NOTE_REQ_PPMS_STACK'
        value = lv_target_stack
    ).
  ENDIF.

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
        message = ev_msg
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
        message = ev_msg
    ).
    lr_client->close( ).
    RETURN.
  ENDIF.

  lr_client->response->get_status(
    IMPORTING
      code   = lv_status_code
      reason = lv_status_text
  ).

  IF lv_status_code <> 200.
    ev_msg = lv_status_text.
    RETURN.
  ENDIF.

  lv_data = lr_client->response->get_data( ).

  lr_client->close( ).

 ENDIF.

  IF lv_data IS INITIAL.
    ev_msg = 'No data in response'.             "#EC NOTEXT
    RETURN.
  ENDIF.

  TRY.
      CALL TRANSFORMATION id SOURCE XML lv_data
        RESULT note_req = es_note_req.
    CATCH cx_st_error INTO lr_exception.
      ev_msg = lr_exception->get_text( ).
  ENDTRY.

  IF es_note_req IS NOT INITIAL.
    CLEAR ls_note_req_lat.
    ls_note_req_lat-sap_note     = iv_note_number.
    ls_note_req_lat-action       = iv_action.
    ls_note_req_lat-target_stack = iv_target_stack.
    ls_note_req_lat-min_note_version    = es_note_req-min_note_version.
    ls_note_req_lat-latest_note_version = es_note_req-latest_note_version.
    APPEND ls_note_req_lat TO st_note_req_latest.
  ENDIF.

ENDMETHOD.