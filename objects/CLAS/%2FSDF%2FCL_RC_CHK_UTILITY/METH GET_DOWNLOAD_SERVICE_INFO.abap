METHOD get_download_service_info.

  DATA: lv_table_name       TYPE tabname,
        lv_where_condition  TYPE string,
        ls_tableline        TYPE REF TO data.

  FIELD-SYMBOLS : <fs_tableline> TYPE ANY,
                  <fs_fieldval>  TYPE ANY.

  IF sv_is_ds_used IS NOT INITIAL.
    ev_is_ds_used = sv_is_ds_used.
    ev_dwld_serv_dest = sv_dwld_serv_dest.
    RETURN.
  ENDIF.

  lv_table_name = 'CWB_DWNLD_PROC'.
  CALL FUNCTION 'DDIF_NAMETAB_GET'
    EXPORTING
      tabname   = lv_table_name
      all_types = 'X'
    EXCEPTIONS
      not_found = 1
      OTHERS    = 2.
  IF sy-subrc <> 0.
    ev_is_ds_used = abap_false.
    sv_is_ds_used = ev_is_ds_used.
    CLEAR: ev_dwld_serv_dest, sv_dwld_serv_dest.
    RETURN.
  ENDIF.

  CREATE DATA ls_tableline TYPE (lv_table_name).
  ASSIGN ls_tableline->* TO <fs_tableline>.

  lv_where_condition = `CWB_PROC = '3' AND RFC_TRGT_NAME = 'DS'`.

  SELECT SINGLE ('RFCDEST') FROM (lv_table_name)
    INTO CORRESPONDING FIELDS OF <fs_tableline>
    WHERE (lv_where_condition).
  IF sy-subrc = 0.
    ASSIGN COMPONENT 'RFCDEST' OF STRUCTURE <fs_tableline> TO <fs_fieldval>.
    ev_dwld_serv_dest = <fs_fieldval>.
    sv_dwld_serv_dest = ev_dwld_serv_dest.
    ev_is_ds_used = abap_true.
    sv_is_ds_used = ev_is_ds_used.
  ELSE.
    ev_is_ds_used = abap_false.
    sv_is_ds_used = ev_is_ds_used.
    CLEAR: ev_dwld_serv_dest, sv_dwld_serv_dest.
  ENDIF.

ENDMETHOD.