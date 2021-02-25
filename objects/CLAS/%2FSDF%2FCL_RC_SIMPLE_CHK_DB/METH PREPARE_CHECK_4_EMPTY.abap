METHOD prepare_check_4_empty.

  DATA: lv_position_end      TYPE i,
        lv_position_start    TYPE i,
        lv_str               TYPE string,
        lv_field_name_raw    TYPE char100,
        lv_field_name        TYPE hrcond-low,
        lv_connect_str       TYPE string.

*--------------------------------------------------------------------*
* In Open SQL single '= space' or 'IS NULL' is not reliable to determine
* whether a field is empty; the reason is that this really depends on the
* data type and DB field setting.
* So we use a combination of '= space' and 'IS NULL'

  rv_where_clause = iv_where_clause.

  "IS EMPTY: EQ ' ' --> ( DESCRIPTION EQ space or DESCRIPTION IS NULL )
  lv_str = 'EQ '' '''.
  FIND FIRST OCCURRENCE OF lv_str IN iv_where_clause MATCH OFFSET lv_position_end.
  IF sy-subrc = 0.
    lv_field_name_raw = rv_where_clause+lv_position_start(lv_position_end).
  ENDIF.

  "IS EMPTY: EP ' ' --> ( DESCRIPTION EQ space or DESCRIPTION IS NULL )
  lv_str = 'EP '' '''.
  FIND FIRST OCCURRENCE OF lv_str IN iv_where_clause MATCH OFFSET lv_position_end.
  IF sy-subrc = 0.
    lv_field_name_raw = rv_where_clause+lv_position_start(lv_position_end).
  ENDIF.


*--------------------------------------------------------------------*
* Handle AND ( DESCRIPTION EQ space or DESCRIPTION IS NULL )

  CASE ms_check-check_condition.
    WHEN /sdf/cl_rc_chk_utility=>c_check_condition-or.
      FIND FIRST OCCURRENCE OF /sdf/cl_rc_chk_utility=>c_check_condition-or IN iv_where_clause.
      IF sy-subrc = 0.
        lv_position_start = 3.
        lv_connect_str = 'OR'.

      ENDIF.
    WHEN /sdf/cl_rc_chk_utility=>c_check_condition-and.
      FIND FIRST OCCURRENCE OF /sdf/cl_rc_chk_utility=>c_check_condition-and IN iv_where_clause.
      IF sy-subrc = 0.
        lv_position_start = 4.
        lv_connect_str = 'AND'.
      ENDIF.
  ENDCASE.

  IF lv_position_start > 0.
    lv_field_name_raw = lv_field_name_raw+lv_position_start.
  ENDIF.

*--------------------------------------------------------------------*
* Concatenate the final result

  lv_field_name = cleanup_string( lv_field_name_raw ).
  CONCATENATE '(' lv_field_name_raw 'EQ space or' lv_field_name_raw 'IS NULL )' "#EC NOTEXT
    INTO rv_where_clause SEPARATED BY space.

  IF lv_connect_str IS NOT INITIAL.
    CONCATENATE lv_connect_str rv_where_clause INTO rv_where_clause SEPARATED BY space.
  ENDIF.

ENDMETHOD.