METHOD sitem_consistency_result_del.

  DATA:ls_data       TYPE srtm_datax,
       lv_data_xml   TYPE xstring,
       lt_per_data   TYPE ty_check_result_persist_tab,
       ls_per_data   TYPE ty_check_result_persist_str.

  CHECK iv_target_stack IS NOT INITIAL.

*--------------------------------------------------------------------*
* Get result

  TRY.

      SELECT SINGLE * FROM srtm_datax INTO ls_data
        WHERE trigid     = c_data_key_new-data_trigid
          AND trigoffset = c_data_key_new-data_trigoffset
          AND subid      = c_data_key_new-subid_cons_result_last.
      IF sy-subrc = 0.
        lv_data_xml = ls_data-xtext.
        CALL TRANSFORMATION id SOURCE XML lv_data_xml
          RESULT per_data = lt_per_data.
      ENDIF.

    CATCH cx_root INTO so_exception.
  ENDTRY.


*--------------------------------------------------------------------*
* Delete the result of target stack

  DELETE lt_per_data WHERE target_stack = iv_target_stack.


*--------------------------------------------------------------------*
* Store the data into DB

  CALL TRANSFORMATION id
    SOURCE per_data = lt_per_data
    RESULT XML lv_data_xml.

  ls_data-trigid     = c_data_key_new-data_trigid.
  ls_data-trigoffset = c_data_key_new-data_trigoffset.
  ls_data-subid      = c_data_key_new-subid_cons_result_last.
  ls_data-ddate      = sy-datum.
  ls_data-dtime      = sy-uzeit.
  ls_data-xtext      = lv_data_xml.
  MODIFY srtm_datax FROM ls_data.

ENDMETHOD.