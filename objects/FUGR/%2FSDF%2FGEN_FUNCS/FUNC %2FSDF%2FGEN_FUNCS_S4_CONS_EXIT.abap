FUNCTION /sdf/gen_funcs_s4_cons_exit.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_TARGET_STACK) TYPE  /SDF/CL_RC_CHK_UTILITY=>TY_BORMNR
*"     VALUE(IV_SITEM_GUID) TYPE  GUID_32
*"     VALUE(IV_SITEM_ID) TYPE  STRING
*"  EXPORTING
*"     REFERENCE(ET_CHK_RESULT) TYPE
*"/SDF/CL_RC_CHK_UTILITY=>TY_PRE_CONS_CHK_RESULT_TAB
*"----------------------------------------------------------------------
  "----------------------------------------------------------------------
  "*"Local Interface:
  "  IMPORTING
  "     VALUE(IV_TARGET_STACK) TYPE  /SDF/CL_RC_CHK_UTILITY=>TY_BORMNR
  "     VALUE(IV_SITEM_GUID) TYPE  GUID_32
  "     VALUE(IV_SITEM_ID) TYPE  STRING
  "  EXPORTING
  "     REFERENCE(ET_CHK_RESULT) TYPE
  "        /SDF/CL_RC_CHK_UTILITY=>TY_PRE_CONS_CHK_RESULT_TAB
  "----------------------------------------------------------------------

  DATA: lv_exit_func  TYPE rs38l_fnam.

  CLEAR et_chk_result.

*--------------------------------------------------------------------*
* Execute customer exit to overrule the standard implementation
* Refer to SAP Note 2641675

  lv_exit_func = 'Z_S4RC_CONSISTENCY_CHK_EXIT'.
  CALL FUNCTION 'FUNCTION_EXISTS'
    EXPORTING
      funcname           = lv_exit_func
    EXCEPTIONS
      function_not_exist = 1
      OTHERS             = 2.
  IF sy-subrc = 0.
    CALL FUNCTION lv_exit_func
      EXPORTING
        iv_target_stack = iv_target_stack
        iv_sitem_guid   = iv_sitem_guid
        iv_sitem_id     = iv_sitem_id
      IMPORTING
        et_chk_result   = et_chk_result.
  ENDIF.

ENDFUNCTION.