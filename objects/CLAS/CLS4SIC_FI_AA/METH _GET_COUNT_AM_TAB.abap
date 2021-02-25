METHOD _get_count_am_tab.
*--------------------------------------------------------------------*
*  replacement for function module 'GET_COUNT_AM_TAB'
*--------------------------------------------------------------------*
* PRECONDITION
  CLEAR ev_count.

* DEFINITIONS
  DATA: lv_string TYPE string,
        lt_pack   TYPE string_hashed_table.
  CONSTANTS: lc_anek_tabname TYPE dd02d-tabname VALUE 'ANEK'.

* BODY
  lv_string = 'AA'.
  INSERT lv_string INTO TABLE lt_pack.
  lv_string = 'AB'.
  INSERT lv_string INTO TABLE lt_pack.
  lv_string = 'FINS_FAA_DB'.
  INSERT lv_string INTO TABLE lt_pack.

  TRY.
      CALL METHOD cl_abap_dyn_prg=>check_table_or_view_name_tab
        EXPORTING
          val      = lc_anek_tabname
          packages = lt_pack.
    CATCH cx_abap_not_a_table.
      RAISE input_false.
    CATCH cx_abap_not_in_package.
      RAISE input_false.
  ENDTRY.

  CLEAR ev_count.
  IF lc_anek_tabname IS INITIAL OR iv_comp_code IS INITIAL.
    RAISE input_false.
  ENDIF.

  " With ACDOCA some tables are replaced by compatability views
  " DDL Sources use @ClientHandling.algorithm: #SESSION_VARIABLE, which does
  " not allow the usage of CLIENT SPECIFIED anymore -> usage of USING CLIENT necessary
  SELECT COUNT(*) FROM (lc_anek_tabname)
    USING CLIENT @mv_client
    INTO @ev_count
    WHERE bukrs = @iv_comp_code
        AND (it_dopt).

* POSTCONDITION
  "None

ENDMETHOD.