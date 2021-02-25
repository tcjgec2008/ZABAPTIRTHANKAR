METHOD smdb_content_time_get.

  DATA: ls_content_data     TYPE srtm_datax,
        lv_timestamp_c(50)  TYPE c.

  CLEAR: ev_time_utc_sap, ev_time_utc_sap_str, ev_time_utc_manual, ev_time_utc_manual_str.

*--------------------------------------------------------------------*
* Get time stamp when content is downloaded/feteched from SAP

  IF ev_time_utc_sap IS REQUESTED OR ev_time_utc_sap_str IS REQUESTED.

    SELECT SINGLE * FROM srtm_datax INTO ls_content_data
      WHERE trigid     = c_data_key_new-data_trigid
        AND trigoffset = c_data_key_new-data_trigoffset
        AND subid      = c_data_key_new-subid_smdb_content_latest_sap.
    IF sy-subrc = 0.
      ev_time_utc_sap = smdb_content_upload_time_get( iv_file_data = ls_content_data-xtext ).
      IF ev_time_utc_sap IS NOT INITIAL.
        WRITE ev_time_utc_sap TO lv_timestamp_c TIME ZONE c_time_zone_utc.
        CONCATENATE lv_timestamp_c 'UTC' INTO ev_time_utc_sap_str SEPARATED BY space.
      ENDIF.
    ENDIF.
  ENDIF.


*--------------------------------------------------------------------*
* Get time stamp of content manully uploaded

  IF ev_time_utc_manual IS REQUESTED OR ev_time_utc_manual_str IS REQUESTED.

    SELECT SINGLE * FROM srtm_datax INTO ls_content_data
      WHERE trigid     = c_data_key_new-data_trigid
        AND trigoffset = c_data_key_new-data_trigoffset
        AND subid      = c_data_key_new-subid_smdb_content_upload.
    IF sy-subrc = 0.
      ev_time_utc_manual = smdb_content_upload_time_get( iv_file_data = ls_content_data-xtext ).
      IF ev_time_utc_manual IS NOT INITIAL.
        WRITE ev_time_utc_manual TO lv_timestamp_c TIME ZONE c_time_zone_utc.
        CONCATENATE lv_timestamp_c 'UTC' INTO ev_time_utc_manual_str SEPARATED BY space.
      ENDIF.
    ENDIF.
  ENDIF.

ENDMETHOD.