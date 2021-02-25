METHOD check_consistency.


  DATA: ls_check_result      TYPE /sdf/cl_rc_chk_utility=>ty_pre_cons_chk_result_str,
        lv_description       TYPE string.

  CLEAR: et_chk_result.

*--------------------------------------------------------------------*
* Check deprecated fields WEGXX and STUFE

  ls_check_result-return_code = c_cons_chk_return_code-success.
  lv_description = 'Validation for WEGXX and STUFE fields was successful. These fields will not impact the migration of pricing table KONV.'."#EC NOTEXT
  APPEND lv_description TO ls_check_result-descriptions.
  APPEND ls_check_result TO et_chk_result.

  ls_check_result-return_code = c_cons_chk_return_code-warning.
  lv_description = 'Action Required: WEGXX and STUFE fields might be filled in the pricing table KONV. See SAP Note 2188695'."#EC NOTEXT
  APPEND lv_description TO ls_check_result-descriptions.
  APPEND ls_check_result TO et_chk_result.


*  DATA: ls_check_result      TYPE /sdf/cl_rc_chk_utility=>ty_pre_cons_chk_result_str,
*        lv_description       TYPE string.
*
*  CLEAR: et_chk_result.
*
***********************************************************************
** Sample code according to https://wiki.wdf.sap.corp/wiki/x/lPo0bw
** Based on class CL_S4_CHECKS_PRICING (P7D)
***********************************************************************
*
**--------------------------------------------------------------------*
** Check deprecated fields WEGXX and STUFE
*
*  ls_check_result-return_code = check_wegxx_stufe_notin_tables( ).
*  IF ls_check_result-return_code = c_cons_chk_return_code-success.
*    lv_description = 'Validation for WEGXX and STUFE fields was successful. These fields will not impact the migration of pricing table KONV.'."#EC NOTEXT
*    APPEND lv_description TO ls_check_result-descriptions.
*  ELSEIF treat_wegxx_stufe_as_error( ) = abap_true.
*    lv_description = 'Action Required: WEGXX and STUFE fields might be filled in the pricing table KONV. See SAP Note 2188695'."#EC NOTEXT
*    APPEND lv_description TO ls_check_result-descriptions.
*  ELSE.
*    ls_check_result-return_code = c_cons_chk_return_code-warning. " change from error to warning
*    lv_description = 'WEGXX and STUFE fields might be filled in the pricing table KONV. however, as the entry "NOTE_2188695" has been found in table TSADCORR, data will not be migrated. This might result in data loss.'."#EC NOTEXT
*    APPEND lv_description TO ls_check_result-descriptions.
*  ENDIF.
*  APPEND ls_check_result TO et_chk_result.
*
*
**--------------------------------------------------------------------*
** Check customer-specific fields in KONV
*
*  ls_check_result-return_code = check_konv_not_extended( ).
*  IF ls_check_result-return_code = c_cons_chk_return_code-success.
*    lv_description = 'The pricing table KONV has not been enhanced and no customer-specific fields were found. the migration of KONV can occur.'."#EC NOTEXT
*    APPEND lv_description TO ls_check_result-descriptions.
*  ELSE.
*    lv_description = 'Action required: pricing table KONV has been enhanced with customer-specific fields. During the upgrade phase SPDD, append the fields to prcd_elements. See sap note 2189301'."#EC NOTEXT
*    APPEND lv_description TO ls_check_result-descriptions.
*  ENDIF.
*  APPEND ls_check_result TO et_chk_result.
*
*
*
**--------------------------------------------------------------------*
** Check ZAEHK is not partitioned in KONV
*
*  ls_check_result-return_code = check_not_partitioned_by_zaehk( ).
*  IF ls_check_result-return_code = c_cons_chk_return_code-success.
*    IF sy-dbsys = 'HDB'.
*      lv_description = 'The pricing table KONV has not been partitioned by key field ZAEHK. The migration of KONV can occur.'."#EC NOTEXT
*      APPEND lv_description TO ls_check_result-descriptions.
*    ELSE.
*      lv_description = 'Pricing table KONV partitioning by zaehk is not applicable on non-HANA DB. the migration of konv can occur.'."#EC NOTEXT
*      APPEND lv_description TO ls_check_result-descriptions.
*    ENDIF.
*  ELSE.
*    lv_description = 'Action required: pricing table KONV is partitioned by key field ZAEHK. Migration cannot proceed without re-partitioning. See sap note 2347065'."#EC NOTEXT
*    APPEND lv_description TO ls_check_result-descriptions.
*  ENDIF.
*  APPEND ls_check_result TO et_chk_result.

ENDMETHOD.