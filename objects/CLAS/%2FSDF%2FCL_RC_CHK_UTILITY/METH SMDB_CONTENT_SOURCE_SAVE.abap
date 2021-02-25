METHOD smdb_content_source_save.

  DATA:ls_data       TYPE srtm_datax,
       lv_data_xml   TYPE xstring,
       lv_fetch_succ type boolean.

  CHECK iv_smdb_source = c_parameter-smdb_source_sap
    OR iv_smdb_source = c_parameter-smdb_source_manual.

*--------------------------------------------------------------------*
* Store the data into DB

  lv_data_xml = ls_data-xtext.
  CALL TRANSFORMATION id
    SOURCE simpl_item_catalog_src = iv_smdb_source
    RESULT XML lv_data_xml.

  ls_data-trigid     = c_data_key_new-data_trigid.
  ls_data-trigoffset = c_data_key_new-data_trigoffset.
  ls_data-subid      = c_data_key_new-subid_simpl_item_catalog_src.
  ls_data-ddate      = sy-datum.
  ls_data-dtime      = sy-uzeit.
  ls_data-xtext      = lv_data_xml.
  MODIFY srtm_datax FROM ls_data.

  COMMIT WORK.

  "!!!Fetch again; otherwise the content might get lost during source switch and content upload
*  IF iv_smdb_source = c_parameter-smdb_source_sap.
*    smdb_content_fetch_from_sap( ).
*  ENDIF.

  sv_content_source = iv_smdb_source.

ENDMETHOD.