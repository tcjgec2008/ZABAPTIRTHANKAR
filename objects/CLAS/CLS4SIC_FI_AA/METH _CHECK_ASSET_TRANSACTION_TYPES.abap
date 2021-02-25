METHOD _check_asset_transaction_types.
*--------------------------------------------------------------------*
* Transaction type category 'Write-up'(5) with classification
* 'Retirement'(2) is not supported anymore;
* check that this combination is not used anymore
*--------------------------------------------------------------------*
* PRECONDITION
  CHECK gv_source_release <> gc_source_release-s4hana.

* DEFINITIONS
  DATA: lt_asset_ttype_grp   TYPE STANDARD TABLE OF bwagrp,
        lt_asset_ttype       TYPE STANDARD TABLE OF bwasl,
        lt_range_asset_ttype TYPE RANGE OF bwasl,
        ls_range_asset_ttype LIKE LINE OF lt_range_asset_ttype,
        ls_anep              TYPE anep.
  FIELD-SYMBOLS: <ls_asset_ttype> TYPE bwasl.

* BODY
  SELECT bwagrp FROM tabwg CLIENT SPECIFIED
                  INTO TABLE lt_asset_ttype_grp
                WHERE mandt = mv_client
                  AND bwatyp = '5'
                  AND gitcol = '2'.

  CHECK lt_asset_ttype_grp IS NOT INITIAL.

  SELECT bwasl FROM tabw CLIENT SPECIFIED
                 INTO TABLE lt_asset_ttype
                 FOR ALL ENTRIES IN lt_asset_ttype_grp
                 WHERE mandt = mv_client
                   AND bwagrp = lt_asset_ttype_grp-table_line.

  LOOP AT lt_asset_ttype ASSIGNING <ls_asset_ttype>.
    ls_range_asset_ttype-sign = 'I'.
    ls_range_asset_ttype-option = 'EQ'.
    ls_range_asset_ttype-low = <ls_asset_ttype>.
    APPEND ls_range_asset_ttype TO lt_range_asset_ttype.
  ENDLOOP.

  " With ACDOCA some tables are replaced by compatability views
  " DDL Sources use @ClientHandling.algorithm: #SESSION_VARIABLE, which does
  " not allow the usage of CLIENT SPECIFIED anymore -> usage of USING CLIENT necessary
  SELECT SINGLE * FROM anep
                  USING CLIENT @mv_client
                  INTO @ls_anep
                  WHERE bwasl IN @lt_range_asset_ttype.
  IF sy-subrc = 0.
    "Error
    _add_check_message(
      EXPORTING
        iv_description  = 'Transaction type category ''Write-up''(5) with classification ''Retirement''(2) is not supported anymore.'
        iv_return_code  = gc_return_code-error_skippable
        iv_check_sub_id = gc_check_sub_id-fiia_cust_tabw
    ).
  ENDIF.

* POSTCONDITION
  "None

ENDMETHOD.