METHOD migrate_data.

  "Migrate application data
  "Not required after RTC, side effect is overwritting of SAP content. Refer to IM 1780362447
  "migrate_data( ).

*  DATA:lt_content_old      TYPE TABLE OF rmpspro_mailmime,
*       ls_content_old      TYPE rmpspro_mailmime,
*       ls_content_new      TYPE srtm_datax,
*       ls_target_stack     TYPE ty_conv_target_stack_str,
*       lv_data_oid         TYPE sysuuid_x,
*       lt_rel_chk_result   TYPE ty_check_result_tab,
*       lt_header_info      TYPE salv_wd_t_string,
*       lv_data_xml         TYPE xstring.
*
*  CONSTANTS:
*    BEGIN OF c_data_key_old,
*          smdb_content_latest_sap TYPE sysuuid_x VALUE '0000C9EAA3AE1ED6B7CCA2E27794C91C',"#NO_TEXT
*          smdb_content_upload     TYPE sysuuid_x VALUE '2DF96459C068D41DE10000000A4233DC',"#NO_TEXT
*          item_status             TYPE sysuuid_x VALUE '0000C9EAA3AE1ED6B7CCACEE5A818947',"#NO_TEXT
*          calculation_key         TYPE sysuuid_x VALUE 'C1E89158C254D35FE10000000A4233DC',"#NO_TEXT
*          cons_skip_sitem         TYPE sysuuid_x VALUE '0A4233DC1DD258FA0E02200400000000',"#NO_TEXT
*          cons_result_last        TYPE sysuuid_x VALUE '03324759F8A5D31DE10000000A4233DC',"#NO_TEXT
*        END OF c_data_key_old.
*
***--------------------------------------------------------------------*
*** Run only the migration for the first time
**
**  SELECT SINGLE * FROM srtm_datax INTO ls_content_new
**    WHERE trigid     = c_data_key_new-data_trigid
**      AND trigoffset = c_data_key_new-data_trigoffset.
**  CHECK sy-subrc <> 0.
*
*
**--------------------------------------------------------------------*
** Migrate data from client dependent table to client independent table
** IM 1780324121 SUM:Precheck report result and exemption are client dependent
*
*  SELECT SINGLE * FROM rmpspro_mailmime CLIENT SPECIFIED
*    INTO ls_content_old
*    WHERE oid = c_data_key_old-smdb_content_latest_sap.
*  IF sy-subrc = 0.
*    ls_content_new-trigid     = c_data_key_new-data_trigid.
*    ls_content_new-trigoffset = c_data_key_new-data_trigoffset.
*    ls_content_new-subid      = c_data_key_new-subid_smdb_content_latest_sap.
*    ls_content_new-ddate      = sy-datum.
*    ls_content_new-dtime      = sy-uzeit.
*    ls_content_new-xtext      = ls_content_old-mime.
*    MODIFY srtm_datax FROM ls_content_new.
*    DELETE FROM rmpspro_mailmime  WHERE oid = ls_content_old-oid.
*  ENDIF.
*
*
*  SELECT SINGLE * FROM rmpspro_mailmime CLIENT SPECIFIED
*    INTO ls_content_old
*    WHERE oid = c_data_key_old-smdb_content_upload.
*  IF sy-subrc = 0.
*    ls_content_new-trigid     = c_data_key_new-data_trigid.
*    ls_content_new-trigoffset = c_data_key_new-data_trigoffset.
*    ls_content_new-subid      = c_data_key_new-subid_smdb_content_upload.
*    ls_content_new-ddate      = sy-datum.
*    ls_content_new-dtime      = sy-uzeit.
*    ls_content_new-xtext      = ls_content_old-mime.
*    MODIFY srtm_datax FROM ls_content_new.
*    DELETE FROM rmpspro_mailmime  WHERE oid = ls_content_old-oid.
*  ENDIF.
*
*
**  SELECT SINGLE * FROM rmpspro_mailmime CLIENT SPECIFIED INTO ls_content_old
**    WHERE oid = c_data_key_old-item_status.
**  IF sy-subrc = 0.
**    ls_content_new-trigid     = c_data_key_new-data_trigid.
**    ls_content_new-trigoffset = c_data_key_new-data_trigoffset.
**    ls_content_new-subid      = c_data_key_new-subid_item_status.
**    ls_content_new-ddate      = sy-datum.
**    ls_content_new-dtime      = sy-uzeit.
**    ls_content_new-xtext      = ls_content_old-mime.
**    MODIFY srtm_datax FROM ls_content_new.
**    DELETE FROM rmpspro_mailmime  WHERE oid = ls_content_old-oid.
**  ENDIF.
*
*  "Don't migrate previous check result which should have contained target stack key
*  "Take it as 1709 SP0
**  SELECT SINGLE * FROM rmpspro_mailmime CLIENT SPECIFIED
**    INTO ls_content_old
**    WHERE oid = c_data_key_old-cons_skip_sitem.
**  IF sy-subrc = 0.
**    ls_content_new-trigid     = c_data_key_new-data_trigid.
**    ls_content_new-trigoffset = c_data_key_new-data_trigoffset.
**    ls_content_new-subid      = c_data_key_new-subid_cons_skip_sitem.
**    ls_content_new-ddate      = sy-datum.
**    ls_content_new-dtime      = sy-uzeit.
**    ls_content_new-xtext      = ls_content_old-mime.
**    MODIFY srtm_datax FROM ls_content_new.
**    DELETE FROM rmpspro_mailmime WHERE oid = ls_content_old-oid.
**  ENDIF.
*  DELETE FROM rmpspro_mailmime WHERE oid = c_data_key_old-cons_skip_sitem.
*
**  "Don't migrate previous check result which should have contained target stack key
**  "Take it as 1709 SP0
**  SELECT SINGLE * FROM rmpspro_mailmime CLIENT SPECIFIED
**    INTO ls_content_old
**    WHERE oid = c_data_key_old-cons_result_last.
**  IF sy-subrc = 0.
**    ls_content_new-trigid     = c_data_key_new-data_trigid.
**    ls_content_new-trigoffset = c_data_key_new-data_trigoffset.
**    ls_content_new-subid      = c_data_key_new-subid_cons_result_last.
**    ls_content_new-ddate      = sy-datum.
**    ls_content_new-dtime      = sy-uzeit.
**    ls_content_new-xtext      = ls_content_old-mime.
**    MODIFY srtm_datax FROM ls_content_new.
**    DELETE FROM rmpspro_mailmime WHERE oid = ls_content_old-oid.
**  ENDIF.
*  DELETE FROM rmpspro_mailmime WHERE oid = c_data_key_old-cons_result_last.
*
*
**--------------------------------------------------------------------*
** Migrate relevance check result
*
*  smdb_content_load(
*    EXCEPTIONS
*      error  = 1
*      OTHERS = 2 ).
*  CHECK st_conv_target_stack IS NOT INITIAL.
*
*  LOOP AT st_conv_target_stack INTO ls_target_stack.
*
*    lv_data_oid = ls_target_stack-stack_number.
*    CLEAR ls_content_old.
*    SELECT SINGLE * FROM rmpspro_mailmime CLIENT SPECIFIED
*      INTO ls_content_old
*      WHERE oid = lv_data_oid.
*    IF sy-subrc <> 0 OR ls_content_old-mime IS INITIAL.
*      CONTINUE.
*    ENDIF.
*
*    TRY.
*        lv_data_xml = ls_content_old-mime.
*
*        CLEAR: lt_rel_chk_result, lt_header_info.
*        CALL TRANSFORMATION id SOURCE XML lv_data_xml
*          RESULT rel_chk_result = lt_rel_chk_result
*                 rel_chk_header = lt_header_info.
*        IF lt_rel_chk_result IS INITIAL.
*          CONTINUE.
*        ENDIF.
*        /sdf/cl_rc_chk_utility=>sitem_relevance_result_save(
*          iv_target_stack   = ls_target_stack-stack_number
*          it_rel_chk_result = lt_rel_chk_result
*          it_header_info    = lt_header_info ).
*
*      CATCH cx_root INTO so_exception.
*
*    ENDTRY.
*    DELETE FROM rmpspro_mailmime WHERE oid = lv_data_oid.
*
*  ENDLOOP.

ENDMETHOD.