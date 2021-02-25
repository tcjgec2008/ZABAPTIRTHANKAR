METHOD sitem_consistency_result_get.

  DATA:ls_data       TYPE srtm_datax,
       lv_data_xml   TYPE xstring,
       lt_per_data   TYPE ty_check_result_persist_tab,
       ls_per_data   TYPE ty_check_result_persist_str.

  CLEAR: et_cons_chk_result, et_cons_header_info, es_header_info.

  CHECK iv_target_stack IS NOT INITIAL.

  SELECT SINGLE * FROM srtm_datax INTO ls_data
    WHERE trigid     = c_data_key_new-data_trigid
      AND trigoffset = c_data_key_new-data_trigoffset
      AND subid      = c_data_key_new-subid_cons_result_last.
  CHECK sy-subrc = 0.

  TRY.

      lv_data_xml = ls_data-xtext.
      CALL TRANSFORMATION id SOURCE XML lv_data_xml
        RESULT per_data = lt_per_data.
      READ TABLE lt_per_data INTO ls_per_data
        WITH KEY target_stack = iv_target_stack.
      CHECK sy-subrc = 0.

      lv_data_xml = ls_per_data-result_xstr.
      CALL TRANSFORMATION id SOURCE XML lv_data_xml
        RESULT cons_chk_result = et_cons_chk_result
               cons_chk_header = et_cons_header_info
               cons_hdr_info   = es_header_info.
    CATCH cx_root INTO so_exception.

  ENDTRY.

ENDMETHOD.