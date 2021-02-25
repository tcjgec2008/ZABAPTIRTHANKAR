METHOD perform_check.

  TYPES:
    BEGIN OF ty_sel_tab_str,
      sign   TYPE char1,
      option TYPE char2,
      low    TYPE char100,
      high   TYPE char100,
    END OF ty_sel_tab_str.

  DATA: lv_table_name          TYPE tabname,
        lt_check_db            TYPE /sdf/cl_rc_chk_utility=>ty_smdb_check_db_tab,
        ls_check_db            TYPE /sdf/cl_rc_chk_utility=>ty_smdb_check_db_str,
        lv_actual_count        TYPE i,
        lv_where_clause        TYPE string,
        lt_where_cluse         TYPE TABLE OF string,
        lt_hrcond              TYPE /sdf/cl_rc_chk_utility=>ty_sql_condition_tab,
        ls_hrcond              TYPE /sdf/cl_rc_chk_utility=>ty_sql_condition_str,
        lv_subrc               LIKE sy-subrc,
        lt_where_clause        TYPE /sdf/cl_rc_chk_utility=>ty_where_clause_tab,
        lo_exc                 TYPE REF TO cx_sy_sql_error,
        lv_field_name_str      type string,
        lt_not_between_field   TYPE /sdf/cl_rc_chk_utility=>ty_smdb_check_db_tab,
        lt_not_contain_field   TYPE /sdf/cl_rc_chk_utility=>ty_smdb_check_db_tab,
        lt_not_between_index   TYPE TABLE OF i,
        lt_not_contain_index   TYPE TABLE OF i,
        lv_str                 TYPE string,
        lv_up_to_rows          TYPE i,
        lv_where               TYPE /sdf/cl_rc_chk_utility=>ty_where_clause_str-line,
        lv_field_value_length  TYPE i,
        lv_field_defin_length  TYPE i,
        lt_field_definition    TYPE dfies_table,
        ls_field_definition    TYPE dfies,
        ls_db_field            TYPE dfies,
        lv_tabclass            TYPE tabclass,
        lv_cursor              TYPE cursor,
        lv_flag                TYPE flag,
        lv_where_condition     TYPE string,
        lt_whitelist           TYPE string_hashed_table,
        lv_whitelist           TYPE string.
  FIELD-SYMBOLS:
        <fs_where>             TYPE /sdf/cl_rc_chk_utility=>ty_where_clause_str.

  CLEAR: ev_result_int, ev_summary_int.

*--------------------------------------------------------------------*
* Preparation for Database based simple check

  ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.

  "Translate to upper case in CONSTRUCTOR since the table name is case sensitive
  lv_table_name = ms_check-check_identifier.


*--------------------------------------------------------------------*
* Load the DB based check rule definition
* If the table does not exist in the system, then the item is not relevant.

  "Function DB_EXISTS_TABLE it not reliable
  "Fails for cluster table like BSEG -> IM 1770285863
  "Fails to report ARBFND_C_MSGCUST as not exist -> IM 1780285413
  CALL FUNCTION 'DDIF_NAMETAB_GET'
    EXPORTING
      tabname   = lv_table_name
      all_types = 'X'
    IMPORTING
      ddobjtype = lv_tabclass
    EXCEPTIONS
      not_found = 1
      OTHERS    = 2.
  IF sy-subrc <> 0
     OR lv_tabclass = 'INTTAB' "INTTAB ->  Structure
     OR lv_tabclass = 'APPEND'."APPEND -> Append structure
    ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.
    mv_dummy_str = lv_table_name.
    "Item is not relevant. The database table &P1& has not been found.
    ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '021' iv_para1 = mv_dummy_str ).
    RETURN.
  ENDIF.

  /sdf/cl_rc_chk_utility=>get_smdb_content(
    IMPORTING
      et_check_db = lt_check_db
    EXCEPTIONS
      OTHERS      = 0 )."No exception expected; already checked before

  DELETE lt_check_db WHERE sitem_guid <> ms_check-sitem_guid
                        OR check_guid <> ms_check-check_guid.


*--------------------------------------------------------------------*
* Check the field name difinition

  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname   = lv_table_name
    TABLES
      dfies_tab = lt_field_definition
    EXCEPTIONS
      OTHERS    = 0."No need to handle exception here since it's checked before and after

  "If the field is not found in the table; most probaly it's caused of missing add-on of inactive swith
  "In the case; we decided to reply on the content and determine it as not relevant.
  "Refer to IM 1770395188
  LOOP AT lt_check_db INTO ls_check_db.
    READ TABLE lt_field_definition INTO ls_field_definition
      WITH KEY fieldname = ls_check_db-field_name.
    IF sy-subrc <> 0.
      ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.
      lv_field_name_str = ls_check_db-field_name.
      mv_dummy_str = lv_table_name.
      "Item is not relevant. The database table &P1& has no table field defined.
      "Item is not relevant. The field &P1& is not found in table &P2&. This may due to inactive switch or missing add-on.
      ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '022'
        iv_para1   = lv_field_name_str
        iv_para2   = mv_dummy_str ).
      RETURN.
    ENDIF.
  ENDLOOP.


*--------------------------------------------------------------------*
* Build the where clause
* https://blogs.sap.com/2013/04/16/writing-dynamic-where-clause-in-abap-select-query/

  DELETE lt_check_db WHERE sitem_guid <> ms_check-sitem_guid
                        OR check_guid <> ms_check-check_guid.
  LOOP AT lt_check_db INTO ls_check_db.

    "Clean up the string
    ls_check_db-sel_value_low   = cleanup_string( ls_check_db-sel_value_low ).
    ls_check_db-sel_value_high  = cleanup_string( ls_check_db-sel_value_high ).

    "Not Between & Not Contains is not suppored by RH_DYNAMIC_WHERE_BUILD
    "Replace them with supported condition and replace back after the dynamic SQL is generated
    IF ls_check_db-sel_option = /sdf/cl_rc_chk_utility=>c_field_option-not_between.
      ls_check_db-sel_option = /sdf/cl_rc_chk_utility=>c_field_option-between.
      "APPEND sy-tabix TO lt_not_between_index.
      APPEND ls_check_db TO lt_not_between_field.
    ENDIF.
    IF ls_check_db-sel_option = /sdf/cl_rc_chk_utility=>c_field_option-not_contains.
      ls_check_db-sel_option = /sdf/cl_rc_chk_utility=>c_field_option-contains.
      "APPEND sy-tabix TO lt_not_contain_index.
      APPEND ls_check_db TO lt_not_contain_field.
    ENDIF.

    "Refer to IM 1770194534; the maximum allowed length is 2 times of the filed definition
    IF ls_check_db-sel_option = /sdf/cl_rc_chk_utility=>c_field_option-contains.
      ls_check_db-sel_option = 'LK'."Refer to internal implementation of /SDF/GEN_FUNCS_S4_DY_SQL_BUILD

      CLEAR ls_field_definition.
      READ TABLE lt_field_definition INTO ls_field_definition
        WITH KEY fieldname = ls_check_db-field_name.
      lv_field_defin_length = ls_field_definition-leng + ls_field_definition-leng.

      lv_field_value_length = STRLEN( ls_check_db-sel_value_low ).
      ADD 2 TO lv_field_value_length.
      IF lv_field_value_length <= lv_field_defin_length.
        CONCATENATE '%' ls_check_db-sel_value_low '%' INTO ls_check_db-sel_value_low.
      ELSE.

        lv_field_value_length = STRLEN( ls_check_db-sel_value_low ).
        ADD 1 TO lv_field_value_length.
        IF lv_field_value_length <= lv_field_defin_length.
          CONCATENATE '%' ls_check_db-sel_value_low INTO ls_check_db-sel_value_low.
        ELSE.

          lv_field_value_length = STRLEN( ls_check_db-sel_value_low ).
          IF lv_field_value_length <= lv_field_defin_length.
            ls_check_db-sel_value_low = ls_check_db-sel_value_low.
          ELSE.

            ev_summary_int = lv_table_name.
            lv_str = ls_check_db-sel_value_low.
            mv_dummy_str = ls_field_definition-leng.
            "Database &P1& based check cannot be executed: value &P2& longer than allowed &P3&
            ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str(
              iv_txt_key = '033'
              iv_para1   = ev_summary_int
              iv_para2   = lv_str
              iv_para3   = mv_dummy_str ).
            ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-rule_issue.
            RETURN.
          ENDIF.
        ENDIF.

      ENDIF.

    ENDIF.

    ls_hrcond-field = ls_check_db-field_name.
    ls_hrcond-opera = ls_check_db-sel_option.
    ls_hrcond-low   = ls_check_db-sel_value_low.
    ls_hrcond-high  = ls_check_db-sel_value_high.
    APPEND ls_hrcond TO lt_hrcond.

  ENDLOOP.

  IF lt_hrcond IS NOT INITIAL.

    CALL FUNCTION '/SDF/GEN_FUNCS_S4_DY_SQL_BUILD'
      EXPORTING
        iv_dbtable_name = lv_table_name
        it_condtab      = lt_hrcond
      IMPORTING
        et_where_clause = lt_where_clause
      EXCEPTIONS
        no_db_field     = 1
        empty_condtab   = 2
        unknown_db      = 3
        wrong_condition = 4
        OTHERS          = 5.
    IF sy-subrc <> 0.
      ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-rule_issue.
      mv_dummy_str = lv_table_name.
      "Database table &P1& based check cannot be executed; check rule definition
      ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '023' iv_para1 = mv_dummy_str ).
      RETURN.
    ENDIF.

    LOOP AT lt_where_clause ASSIGNING <fs_where>.

      "We should not use the index for option replacement since the postion of the selection
      "condition might not be same for the same field for lt_hrcond and lt_where_clause

      "Replace AND with OR in case the where condition should be linked with OR
      lv_str = 'AND '.
      IF ms_check-check_condition = /sdf/cl_rc_chk_utility=>c_check_condition-or
        AND sy-tabix <> 1."Don't replace the first line
        FIND FIRST OCCURRENCE OF lv_str IN <fs_where>-line.
        IF sy-subrc = 0.
          REPLACE FIRST OCCURRENCE OF lv_str IN <fs_where>-line WITH 'OR ' .
        ENDIF.
      ENDIF.

      "Postprocessing to support IS NOT EMPTY
      "IS NOT EMPTY: NE ' ' --> change to RFCDEST NE space
      lv_str = 'NE '' '''.
      FIND FIRST OCCURRENCE OF lv_str IN <fs_where>-line.
      IF sy-subrc = 0.
        "Do not use IS NOT NULL because of the ambitious NULL condition
        "REPLACE FIRST OCCURRENCE OF lv_str IN <fs_where> WITH 'IS NOT NULL'.
        REPLACE FIRST OCCURRENCE OF lv_str IN <fs_where>-line WITH 'NE space'. "#EC NOTEXT
      ENDIF.
      "IS NOT EMPTY: NM ' ' --> change to RFCDEST NE space
      lv_str = 'NM '' '''.
      FIND FIRST OCCURRENCE OF lv_str IN <fs_where>-line.
      IF sy-subrc = 0.
        REPLACE FIRST OCCURRENCE OF lv_str IN <fs_where>-line WITH 'NE space'. "#EC NOTEXT
      ENDIF.

      "Postprocessing to support IS EMPTY
      "IS EMPTY: EQ ' ' --> further preparation
      lv_str = 'EQ '' '''.
      FIND FIRST OCCURRENCE OF lv_str IN <fs_where>-line.
      IF sy-subrc = 0.
        lv_where = prepare_check_4_empty( <fs_where>-line ).
        <fs_where>-line = lv_where.
      ENDIF.
      "IS EMPTY: EP ' ' --> further preparation
      lv_str = 'EP '' '''.
      FIND FIRST OCCURRENCE OF lv_str IN <fs_where>-line.
      IF sy-subrc = 0.
        lv_where = prepare_check_4_empty( <fs_where>-line ).
        <fs_where>-line = lv_where.
      ENDIF.

      "Post processing to support Not Between & Not Contains
      IF lt_not_between_field IS NOT INITIAL OR lt_not_contain_field IS NOT INITIAL.
        LOOP AT lt_not_between_field INTO ls_check_db.
          FIND FIRST OCCURRENCE OF ls_check_db-field_name IN <fs_where>-line.
          IF sy-subrc = 0.
            REPLACE ALL OCCURRENCES OF ' BETWEEN ' IN <fs_where>-line WITH ' NOT BETWEEN ' .
          ENDIF.
        ENDLOOP.

        LOOP AT lt_not_contain_field INTO ls_check_db.
          FIND FIRST OCCURRENCE OF ls_check_db-field_name IN <fs_where>-line.
          IF sy-subrc = 0.
            REPLACE ALL OCCURRENCES OF ' LIKE ' IN <fs_where>-line WITH ' NOT LIKE ' .
          ENDIF.
        ENDLOOP.
      ENDIF.


      "-----------------------------------------------------------------------------------------
      " For bug fix: the DATS and TIMS data type cann't adjust by space to check empty value
      DATA:
        lv_where_replace TYPE string,
        lv_init_dats TYPE dats,
        lv_init_tims TYPE tims.

      CLEAR: ls_field_definition, lv_where_replace.
      READ TABLE lt_field_definition WITH KEY  fieldname = ls_check_db-field_name INTO ls_field_definition.
      IF ls_field_definition-datatype = 'DATS'.
        lv_where_replace = lv_init_dats.
      ELSEIF ls_field_definition-datatype = 'TIMS'.
        lv_where_replace = lv_init_tims.
      ENDIF.

      IF lv_where_replace IS NOT INITIAL.
        FIND FIRST OCCURRENCE OF 'EQ space' IN <fs_where>-line.  "#EC NOTEXT
        IF sy-subrc = 0.
          CONCATENATE 'EQ' lv_where_replace INTO lv_where_replace SEPARATED BY space.
          REPLACE ALL OCCURRENCES OF 'EQ space' IN <fs_where>-line WITH lv_where_replace.  "#EC NOTEXT
        ENDIF.

        FIND FIRST OCCURRENCE OF 'NE space' IN <fs_where>-line. "#EC NOTEXT
        IF sy-subrc = 0.
          CONCATENATE 'NE' lv_where_replace INTO lv_where_replace SEPARATED BY space.
          REPLACE ALL OCCURRENCES OF 'NE space' IN <fs_where>-line WITH lv_where_replace.  "#EC NOTEXT
        ENDIF.
      ENDIF.
      "-----------------------------------------------------------------------------------------

      IF lv_where_condition IS INITIAL.
        lv_where_condition = <fs_where>-line.
      ELSE.
        CONCATENATE lv_where_condition <fs_where>-line INTO lv_where_condition SEPARATED BY space.
      ENDIF.

    ENDLOOP.

    CONDENSE lv_where_condition.
    INSERT lv_where_condition INTO TABLE lt_whitelist.
    TRY.
        CALL METHOD ('CL_ABAP_DYN_PRG')=>check_whitelist_tab
          EXPORTING
            val       = lv_where_condition
            whitelist = lt_whitelist
          RECEIVING
            val_str   = lv_where_condition.
      CATCH cx_root.
    ENDTRY.

  ENDIF.

  lv_whitelist = lv_table_name.
  TRY.
      CALL METHOD ('CL_ABAP_DYN_PRG')=>check_whitelist_str
        EXPORTING
          val       = lv_table_name
          whitelist = lv_whitelist
        RECEIVING
          val_str   = lv_table_name.
    CATCH cx_root.
  ENDTRY.

*--------------------------------------------------------------------*
* Execute the dynamic SQL
* Do the check with CLIENT SPECIFIED so the results consists of whatever is present
* in any client of the system. Strong argument for this would be, that in the end
* the customer can only convert or upgrade the whole system and not individual clients.
* Though there is also a (weaker) argument against this. If a customer has multiple
* productive clients in the same system, or if a hoster is running multiple customers
* in separate clients of the same systems it might be nice to be able to do the checks in individual clients.
* In the end the conversion is of course again all or nothing.
*------------------------------------------
* 2018-10-26 Tony Liu
* Since the performance is not good for COUNT(*), I just change it to SELECT SINGLE if the up to rows is 1.
* If the up to rows GT 1, I will select content into internal table and count the lines.


  TRY .
      FIELD-SYMBOLS:
        <fs_structure> TYPE ANY,
        <fs_table>     TYPE ANY TABLE.
      DATA:
        ls_structure TYPE REF TO data,
        lr_table     TYPE REF TO data.

      "Use UP To n ROWS to avoid full table scan
      lv_up_to_rows = get_table_select_up_to_rows( ).

      lv_actual_count = 0.

      IF /sdf/cl_rc_chk_utility=>sv_db_type = 'SYBASE' AND lv_tabclass = 'CLUSTER'.
        CREATE DATA ls_structure TYPE (lv_table_name).
        ASSIGN ls_structure->* TO <fs_structure>.

        mv_dummy_str = lv_up_to_rows.
        CONCATENATE 'SELECT * FROM' lv_table_name 'CLIENT SPECIFIED' 'UP TO' mv_dummy_str 'ROWS' INTO ev_sql_str_int SEPARATED BY space.

        IF lv_where_condition IS NOT INITIAL.
          OPEN CURSOR WITH HOLD lv_cursor FOR SELECT *
                  FROM (lv_table_name) CLIENT SPECIFIED UP TO lv_up_to_rows ROWS
                  WHERE (lv_where_condition).

          CONCATENATE ev_sql_str_int 'WHERE' INTO ev_sql_str_int SEPARATED BY space.
          CONCATENATE ev_sql_str_int lv_where_condition INTO ev_sql_str_int SEPARATED BY space.

        ELSE.
          OPEN CURSOR WITH HOLD lv_cursor FOR SELECT *
               FROM (lv_table_name) CLIENT SPECIFIED UP TO lv_up_to_rows ROWS.

        ENDIF.

        DO.
          IF lv_flag = 'X'.
            EXIT.
          ELSE.
            FETCH NEXT CURSOR lv_cursor INTO <fs_structure>.
            IF sy-subrc <> 0.
              lv_flag = 'X'.
            ELSE.
              lv_actual_count = lv_actual_count + 1.
            ENDIF.
          ENDIF.
        ENDDO.
        CLOSE CURSOR lv_cursor.

     ELSE. " /sdf/cl_rc_chk_utility=>sv_db_type <> 'SYBASE' OR lv_tabclass <> 'CLUSTER'.

      IF lv_up_to_rows = 1.

        CREATE DATA ls_structure TYPE (lv_table_name).
        ASSIGN ls_structure->* TO <fs_structure>.

        CONCATENATE 'SELECT SINGLE * FROM' lv_table_name 'CLIENT SPECIFIED' INTO ev_sql_str_int SEPARATED BY space.

        IF lv_where_condition IS NOT INITIAL.

          SELECT SINGLE * INTO <fs_structure>
            FROM (lv_table_name) CLIENT SPECIFIED WHERE (lv_where_condition).
          IF sy-subrc = 0.
            lv_actual_count = 1.
          ENDIF.

          CONCATENATE ev_sql_str_int 'WHERE' INTO ev_sql_str_int SEPARATED BY space.
          CONCATENATE ev_sql_str_int lv_where_condition INTO ev_sql_str_int SEPARATED BY space.

        ELSE.

          SELECT SINGLE * INTO <fs_structure>
            FROM (lv_table_name) CLIENT SPECIFIED.
          IF sy-subrc = 0.
            lv_actual_count = 1.
          ENDIF.

        ENDIF.

      ELSE.

        IF lv_up_to_rows > 1000.

          CREATE DATA ls_structure TYPE (lv_table_name).
          ASSIGN ls_structure->* TO <fs_structure>.

          mv_dummy_str = lv_up_to_rows.
          CONCATENATE 'SELECT * FROM' lv_table_name 'CLIENT SPECIFIED' 'UP TO' mv_dummy_str 'ROWS' INTO ev_sql_str_int SEPARATED BY space.

          IF lv_where_condition IS NOT INITIAL.

            SELECT * INTO <fs_structure>
              FROM (lv_table_name) CLIENT SPECIFIED
              UP TO lv_up_to_rows ROWS WHERE (lv_where_condition).
              lv_actual_count = lv_actual_count + 1.
            ENDSELECT.

            CONCATENATE ev_sql_str_int 'WHERE' INTO ev_sql_str_int SEPARATED BY space.
            CONCATENATE ev_sql_str_int lv_where_condition INTO ev_sql_str_int SEPARATED BY space.

          ELSE.

            SELECT * INTO <fs_structure>
              FROM (lv_table_name) CLIENT SPECIFIED UP TO lv_up_to_rows ROWS.
              lv_actual_count = lv_actual_count + 1.
            ENDSELECT.

          ENDIF.

        ELSE.

          CREATE DATA lr_table TYPE TABLE OF (lv_table_name).
          ASSIGN lr_table->* TO <fs_table>.

          mv_dummy_str = lv_up_to_rows.
      CONCATENATE 'SELECT COUNT * FROM' lv_table_name 'CLIENT SPECIFIED'
                  'UP TO' mv_dummy_str 'ROWS'
                  INTO ev_sql_str_int SEPARATED BY space.

          IF lv_where_condition IS NOT INITIAL.

            SELECT * INTO CORRESPONDING FIELDS OF TABLE <fs_table>
               FROM (lv_table_name) CLIENT SPECIFIED
               UP TO lv_up_to_rows ROWS
               WHERE (lv_where_condition).

            CONCATENATE ev_sql_str_int 'WHERE' INTO ev_sql_str_int SEPARATED BY space.
            CONCATENATE ev_sql_str_int lv_where_condition INTO ev_sql_str_int SEPARATED BY space.

          ELSE.

            SELECT * INTO CORRESPONDING FIELDS OF TABLE <fs_table>
              FROM (lv_table_name) CLIENT SPECIFIED
              UP TO lv_up_to_rows ROWS.

          ENDIF.

          lv_actual_count = LINES( <fs_table> ).

        ENDIF.

      ENDIF.

     ENDIF.

    CATCH cx_sy_dynamic_osql_error cx_sy_open_sql_error cx_sy_sql_error INTO lo_exc.

      ev_summary_int = lv_table_name.
      mv_dummy_str = lo_exc->get_text( ).
      "Database table &P1& based check cannot be executed; check rule definition: &P2&
      ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '029'
        iv_para1   = ev_summary_int
        iv_para2   = mv_dummy_str ).
      ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-rule_issue.
      RETURN.

  ENDTRY.


*--------------------------------------------------------------------*
* Check the result

  CONCATENATE 'DB table ''' lv_table_name ''' based check' "#EC NOTEXT
    INTO mv_dummy_str.
  compare_value(
    EXPORTING
      iv_actual_count   = lv_actual_count
      iv_object_checked = mv_dummy_str
    IMPORTING
      ev_result_int     = ev_result_int
      ev_summary_int    = ev_summary_int ).

ENDMETHOD.