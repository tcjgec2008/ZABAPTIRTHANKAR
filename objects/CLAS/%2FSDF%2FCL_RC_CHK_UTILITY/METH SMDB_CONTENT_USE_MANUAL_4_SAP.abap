METHOD smdb_content_use_manual_4_sap.

  DATA: ls_content_data     TYPE srtm_datax.

  SELECT SINGLE * FROM srtm_datax INTO ls_content_data
    WHERE trigid     = c_data_key_new-data_trigid
      AND trigoffset = c_data_key_new-data_trigoffset
      AND subid      = c_data_key_new-subid_smdb_content_upload.
  CHECK sy-subrc = 0.

  ls_content_data-subid = c_data_key_new-subid_smdb_content_latest_sap.
  MODIFY srtm_datax FROM ls_content_data.

ENDMETHOD.