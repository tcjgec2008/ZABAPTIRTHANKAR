METHOD smdb_content_source_get.

  DATA:ls_data       TYPE srtm_datax,
       lv_data_xml   TYPE xstring.

  SELECT SINGLE * FROM srtm_datax INTO ls_data
    WHERE trigid     = c_data_key_new-data_trigid
      AND trigoffset = c_data_key_new-data_trigoffset
      AND subid      = c_data_key_new-subid_simpl_item_catalog_src.
  IF sy-subrc = 0.

    TRY.

        lv_data_xml = ls_data-xtext.
        CALL TRANSFORMATION id SOURCE XML lv_data_xml
          RESULT simpl_item_catalog_src = rv_smdb_source.
        RETURN.
      CATCH cx_root INTO so_exception.

    ENDTRY.
  ELSE.

    smdb_content_source_save( c_parameter-smdb_source_sap ).
    "Fetch from SAP by default
    rv_smdb_source = c_parameter-smdb_source_sap.

  ENDIF.

ENDMETHOD.