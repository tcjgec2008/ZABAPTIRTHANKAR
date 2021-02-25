METHOD is_sitem_sap_exist.
  DATA lv_content_data TYPE int4.
  SELECT SINGLE subid FROM srtm_datax INTO lv_content_data
     WHERE trigid     = c_data_key_new-data_trigid
       AND trigoffset = c_data_key_new-data_trigoffset
       AND subid      = c_data_key_new-subid_smdb_content_latest_sap.
  IF sy-subrc = 0.
    rv_result = abap_true.
  ELSE.
    rv_result = abap_false.
  ENDIF.
ENDMETHOD.