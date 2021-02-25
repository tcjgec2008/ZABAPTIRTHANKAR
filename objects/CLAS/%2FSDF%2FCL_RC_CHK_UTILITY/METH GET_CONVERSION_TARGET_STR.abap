METHOD get_conversion_target_str.

  DATA: lt_conv_targ_stack   TYPE /sdf/cl_rc_chk_utility=>ty_conv_target_stack_tab,
        ls_target_stack      TYPE /sdf/cl_rc_chk_utility=>ty_conv_target_stack_str,
        lv_str_prod_ver      TYPE string,
        lv_str_stack         TYPE string.

  get_smdb_content(
    IMPORTING
      et_conv_target_stack = lt_conv_targ_stack
    EXCEPTIONS
      OTHERS               = 0 )."Checked before not error expect here

  READ TABLE lt_conv_targ_stack INTO ls_target_stack
    WITH KEY stack_number = iv_target_stack.
  CHECK sy-subrc = 0.

  lv_str_prod_ver = ls_target_stack-prod_ver_name.
  lv_str_stack    = ls_target_stack-stack_name.

  "Target version: &P1& [&P2&]
  rv_target_str = /sdf/cl_rc_chk_utility=>get_text_str(
    iv_txt_key = '141'
    iv_para1   = lv_str_prod_ver
    iv_para2   = lv_str_stack ).

ENDMETHOD.