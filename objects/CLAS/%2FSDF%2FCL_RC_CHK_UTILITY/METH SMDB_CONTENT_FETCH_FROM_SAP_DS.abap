METHOD smdb_content_fetch_from_sap_ds.

  DATA: lv_request  TYPE xstring,
        lv_class    TYPE string,
        lx_excep    TYPE REF TO cx_root,
        lo_client   TYPE REF TO object.

  lv_class = 'CL_SDS_HTTP_CLIENT'.
  TRY .
      CALL METHOD (lv_class)=>get_instance
        RECEIVING
          ro_instance = lo_client.

      CALL METHOD lo_client->('IF_SDS_HTTP_CLIENT~SEND_REQUEST')
        EXPORTING
          iv_url      = iv_url
          iv_request  = lv_request
          iv_username = ''
          iv_password = ''
        RECEIVING
          rv_response = ev_content.
    CATCH cx_root INTO lx_excep.
      ev_msg = lx_excep->get_text( ).
  ENDTRY.

ENDMETHOD.