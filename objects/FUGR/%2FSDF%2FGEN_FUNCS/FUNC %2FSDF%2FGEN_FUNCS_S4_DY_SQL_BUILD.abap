*46A ANDBCEK008263 Veralteten FB get_fieldtab ersetzen
FUNCTION /sdf/gen_funcs_s4_dy_sql_build.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_DBTABLE_NAME) TYPE  TABNAME
*"     REFERENCE(IT_CONDTAB) TYPE
*"/SDF/CL_RC_CHK_UTILITY=>TY_SQL_CONDITION_TAB
*"  EXPORTING
*"     REFERENCE(ET_WHERE_CLAUSE) TYPE
*"/SDF/CL_RC_CHK_UTILITY=>TY_WHERE_CLAUSE_TAB
*"     REFERENCE(ET_FIELD_DEFINITION) TYPE  DFIES_TABLE
*"  EXCEPTIONS
*"      EMPTY_CONDTAB
*"      NO_DB_FIELD
*"      UNKNOWN_DB
*"      WRONG_CONDITION
*"----------------------------------------------------------------------

**********************************************************************
* Based on FM RH_DYNAMIC_WHERE_BUILD with limitation for value length
* Potentially we can also use FM CRS_CREATE_WHERE_CONDITION
**********************************************************************

  DATA: lt_cond_tab_t   TYPE /sdf/cl_rc_chk_utility=>ty_sql_condition_tab,
        ls_cond_tab     TYPE /sdf/cl_rc_chk_utility=>ty_sql_condition_str,
        ls_where_clause TYPE /sdf/cl_rc_chk_utility=>ty_where_clause_str,
        lv_where_clause TYPE /sdf/cl_rc_chk_utility=>ty_where_clause_str-line,
        ls_db_field     TYPE dfies,
        lv_tabix        LIKE sy-tabix.

  DATA : BEGIN OF eq_tab OCCURS 1,
           field LIKE dfies-fieldname,
           count TYPE i,
         END   OF eq_tab.
  RANGES : unfield FOR eq_tab-field.

  CLEAR: et_where_clause, et_field_definition.

  CHECK iv_dbtable_name <> space.


*--------------------------------------------------------------------*
* Validate table name and field names

  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname        = iv_dbtable_name
    TABLES
      dfies_tab      = et_field_definition
    EXCEPTIONS
      not_found      = 1
      internal_error = 2
      OTHERS         = 3.
  IF sy-subrc <> 0.
    RAISE unknown_db.
  ENDIF.
  SORT et_field_definition BY tabname fieldname.

  LOOP AT it_condtab INTO ls_cond_tab.
    IF iv_dbtable_name <> space.
      ls_db_field-tabname   = iv_dbtable_name.
      ls_db_field-fieldname = ls_cond_tab-field.
      READ TABLE et_field_definition TRANSPORTING NO FIELDS
           WITH KEY tabname   = ls_db_field-tabname
                    fieldname = ls_db_field-fieldname.
      IF sy-subrc GT 0.
        RAISE no_db_field.
      ENDIF.
    ENDIF.
    COLLECT ls_cond_tab INTO lt_cond_tab_t.
  ENDLOOP.
  IF sy-subrc <> 0.
    RAISE empty_condtab.
  ENDIF.


*--------------------------------------------------------------------*
* Validate the condition

  CLEAR unfield.
  unfield-option = 'EQ'.
  unfield-sign   = 'I'.
  APPEND unfield.

  SORT lt_cond_tab_t.
  LOOP AT lt_cond_tab_t INTO ls_cond_tab.

* Multiple BT/<> condition for same field is fine; we trust the SIC condition maintained
*    IF ls_cond_tab-field IN unfield
*      AND ls_cond_tab-opera <> 'BT'.
*      RAISE wrong_condition.
*    ENDIF.

    IF ls_cond_tab-opera = 'IN'.
      RAISE wrong_condition.
    ENDIF.

    IF ls_cond_tab-opera = 'BT' AND
       ls_cond_tab-high  = space.
      RAISE wrong_condition.
    ENDIF.

    IF ls_cond_tab-opera <> 'EQ'.
      READ TABLE eq_tab WITH KEY field = ls_cond_tab-field.
      IF sy-subrc = 0.
        RAISE wrong_condition.
      ENDIF.
      unfield-low = ls_cond_tab-field.
      APPEND unfield.
    ELSE.
      eq_tab-field = ls_cond_tab-field.
      eq_tab-count = 1.
      COLLECT eq_tab.
    ENDIF.
  ENDLOOP.


*--------------------------------------------------------------------*
* Build the SQL clause

  IF LINES( eq_tab ) GT 0.
    LOOP AT eq_tab WHERE count GT 1.
      READ TABLE lt_cond_tab_t TRANSPORTING NO FIELDS BINARY SEARCH
           WITH KEY field = eq_tab-field.
      CHECK sy-subrc = 0.
      lv_tabix = sy-tabix.
      CONCATENATE 'AND' eq_tab-field 'IN (' INTO lv_where_clause
                                            SEPARATED BY space.
      DO.
        CONCATENATE lv_where_clause '''' INTO lv_where_clause.
        READ TABLE lt_cond_tab_t INTO ls_cond_tab INDEX lv_tabix.
        IF sy-subrc <> 0 OR ls_cond_tab-field <> eq_tab-field.
          EXIT.
        ENDIF.
        IF ls_cond_tab-low <> space.
          CONCATENATE lv_where_clause ls_cond_tab-low '''' INTO lv_where_clause.
        ELSE.
          CONCATENATE lv_where_clause '''' INTO lv_where_clause SEPARATED BY space.
        ENDIF.
        IF sy-index = eq_tab-count.
          CONCATENATE lv_where_clause ')' INTO lv_where_clause.
        ELSE.
          CONCATENATE lv_where_clause ',' INTO lv_where_clause SEPARATED BY space.
        ENDIF.
        ls_where_clause-line = lv_where_clause.
        APPEND ls_where_clause TO et_where_clause.
        DELETE lt_cond_tab_t INDEX lv_tabix.
        CLEAR lv_where_clause.
      ENDDO.
    ENDLOOP.
  ENDIF.

*OBJNR BETWEEN 'B1' OR 'B1ZZZZZ'
*OR OBJNR BETWEEN 'BV' AND 'BVZZZZZ'
*OR OBJNR BETWEEN 'R3' AND 'R3ZZZZZ'
*
*    SELECT SINGLE * FROM jbdobj1 INTO ls_jbdobj1
*      WHERE ( objnr BETWEEN 'B1' AND 'B1ZZZZZ' )
*        OR ( objnr BETWEEN 'BV' AND 'BVZZZZZ' )
*        OR ( objnr BETWEEN 'R3' AND 'R3ZZZZZ' ).

  LOOP AT lt_cond_tab_t INTO ls_cond_tab.
    CLEAR lv_where_clause.
    CASE ls_cond_tab-opera.
      WHEN 'BT'.
        CONCATENATE 'AND' '(' ls_cond_tab-field
                    'BETWEEN' ''''  INTO lv_where_clause SEPARATED BY space.
        IF ls_cond_tab-low <> space.
          CONCATENATE lv_where_clause ls_cond_tab-low '''' INTO lv_where_clause.
        ELSE.
          CONCATENATE lv_where_clause '''' INTO lv_where_clause SEPARATED BY space.
        ENDIF.
        CONCATENATE lv_where_clause 'AND' '''' INTO lv_where_clause SEPARATED BY space.
        IF ls_cond_tab-high <> space.
          CONCATENATE lv_where_clause ls_cond_tab-high '''' ')' INTO lv_where_clause.
        ELSE.
          CONCATENATE lv_where_clause '''' ')' INTO lv_where_clause SEPARATED BY space.
        ENDIF.

      WHEN 'LK'.
        TRANSLATE ls_cond_tab-low USING '*%+_'.
        CONCATENATE 'AND' ls_cond_tab-field
                    'LIKE' ''''  INTO lv_where_clause SEPARATED BY space.
        IF ls_cond_tab-low <> space.
          CONCATENATE lv_where_clause ls_cond_tab-low '''' INTO lv_where_clause.
        ELSE.
          CONCATENATE lv_where_clause '''' INTO lv_where_clause SEPARATED BY space.
        ENDIF.

      WHEN OTHERS.
        CONCATENATE 'AND' ls_cond_tab-field
                    ls_cond_tab-opera ''''  INTO lv_where_clause SEPARATED BY space.
        IF ls_cond_tab-low <> space.
          CONCATENATE lv_where_clause ls_cond_tab-low '''' INTO lv_where_clause.
        ELSE.
          CONCATENATE lv_where_clause '''' INTO lv_where_clause SEPARATED BY space.
        ENDIF.
    ENDCASE.
    ls_where_clause-line = lv_where_clause.
    APPEND ls_where_clause TO et_where_clause.
  ENDLOOP.

  READ TABLE et_where_clause INTO ls_where_clause INDEX 1.
  lv_where_clause = ls_where_clause-line.
  IF lv_where_clause(4) = 'AND '.
    SHIFT lv_where_clause BY 4 PLACES LEFT.
    ls_where_clause-line = lv_where_clause.
    MODIFY et_where_clause INDEX sy-tabix FROM ls_where_clause.
  ENDIF.

ENDFUNCTION.