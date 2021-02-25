METHOD get_buz_impact_note.

  DATA: ls_note            TYPE /sdf/cl_rc_chk_utility=>ty_smdb_note_str,
        lv_note_str        TYPE string.
  FIELD-SYMBOLS:
        <fs_item_result>   TYPE /sdf/cl_rc_chk_utility=>ty_check_result_str.

  SORT mt_note BY sap_note ASCENDING.
  LOOP AT mt_check_result ASSIGNING <fs_item_result>.

    CLEAR: lv_note_str, ls_note.
    LOOP AT mt_note INTO ls_note
      WHERE guid      = <fs_item_result>-sitem_guid
        AND note_type = /sdf/cl_rc_chk_utility=>c_note_type-buz_impact.
      IF lv_note_str IS INITIAL.
        lv_note_str = ls_note-sap_note.
      ELSE.
        CONCATENATE lv_note_str /sdf/cl_rc_chk_utility=>c_note_seperator ls_note-sap_note INTO lv_note_str.
      ENDIF.
    ENDLOOP.
    <fs_item_result>-buz_imp_note = lv_note_str.
    <fs_item_result>-note_descr   = ls_note-sap_note_desc.
  ENDLOOP.

ENDMETHOD.