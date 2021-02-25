FUNCTION /sdf/gen_funcs_s4_targ_stk_get.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  EXPORTING
*"     VALUE(EV_ERR_MESG) TYPE  STRING
*"     VALUE(EV_RESULT_XSTR) TYPE  XSTRING
*"     VALUE(EV_BW_RESULT_XSTR) TYPE  XSTRING
*"----------------------------------------------------------------------

**********************************************************************
* API for TMW* report running locally to collect analysis data
**********************************************************************

  DATA: lt_s4_target_stack TYPE /sdf/cl_rc_chk_utility=>ty_conv_target_stack_tab,
        lt_bw_target_stack TYPE /sdf/cl_rc_chk_utility=>ty_conv_target_stack_tab.

  "Force to update the SIC content from SAP. Refer to IM 1880623094
  /sdf/cl_rc_chk_utility=>smdb_content_fetch_from_sap( ).

  "Get S/4HANA and BW/4HANA conversion target release
  /sdf/cl_rc_chk_utility=>get_smdb_content(
    IMPORTING
      et_conv_target_stack    = lt_s4_target_stack
      et_bw_conv_target_stack = lt_bw_target_stack
    EXCEPTIONS
      smdb_contnet_not_found  = 1
      error                   = 2
      OTHERS                  = 3 ).
  IF sy-subrc <> 0.
    IF /sdf/cl_rc_chk_utility=>sv_is_ds_used = abap_true.
      "Simplification item catalog not found. Check Download Service connection or upload a version manually.
      ev_err_mesg = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '175' ) .
    ELSE.
      "Simplification item catalog not found. Check SAP-SUPPORT_PORTAL connection or upload a version manually.
      ev_err_mesg = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '170' ) .
    ENDIF.
    RETURN.
  ENDIF.

  "Return the result
  CALL TRANSFORMATION id
    SOURCE conv_targ_stack = lt_s4_target_stack
    RESULT XML ev_result_xstr.

  CALL TRANSFORMATION id
    SOURCE bw_target_stack = lt_bw_target_stack
    RESULT XML ev_bw_result_xstr.

ENDFUNCTION.