METHOD prepare_check_class_parameter.

  DATA: ls_sitem         TYPE ty_smdb_item_str,
        ls_targ_prod_ver TYPE ty_ppms_prod_version_str,
        ls_targ_stack    TYPE ty_ppms_stack_str,
        ls_parameter     TYPE ihttpnvp.

  CLEAR rt_parameter.
  get_smdb_content(
    EXCEPTIONS
      OTHERS   = 0 )."already checked before; no exception possible here
  READ TABLE st_sitem INTO ls_sitem
    WITH KEY guid = iv_sitem_guid.
  CHECK sy-subrc = 0.

*--------------------------------------------------------------------*
* Simplification Item information

  ls_parameter-name  = /sdf/cl_rc_s4sic_sample=>c_pre_chk_param_key-sitem_guid.
  ls_parameter-value = ls_sitem-guid.
  APPEND ls_parameter TO rt_parameter.

  ls_parameter-name  = /sdf/cl_rc_s4sic_sample=>c_pre_chk_param_key-sitem_id.
  ls_parameter-value = ls_sitem-sitem_id.
  APPEND ls_parameter TO rt_parameter.

  ls_parameter-name  = /sdf/cl_rc_s4sic_sample=>c_pre_chk_param_key-sitem_title.
  ls_parameter-value = ls_sitem-title_en.
  APPEND ls_parameter TO rt_parameter.

  ls_parameter-name  = /sdf/cl_rc_s4sic_sample=>c_pre_chk_param_key-sitem_app_area.
  ls_parameter-value = ls_sitem-app_area.
  APPEND ls_parameter TO rt_parameter.


*--------------------------------------------------------------------*
* Target product version and stack information
* PPMS content completeless is ensured when SMDB content is downloaded

  READ TABLE st_ppms_stack INTO ls_targ_stack
    WITH KEY stack_ppms_id = iv_target_stack.
  READ TABLE st_ppms_prod_version INTO ls_targ_prod_ver
    WITH KEY prd_version_ppms_id = ls_targ_stack-prd_version_ppms_id.

  ls_parameter-name  = /sdf/cl_rc_s4sic_sample=>c_pre_chk_param_key-target_swc.
  ls_parameter-value = ls_targ_prod_ver-sw_comp_tech_name.
  APPEND ls_parameter TO rt_parameter.

  ls_parameter-name  = /sdf/cl_rc_s4sic_sample=>c_pre_chk_param_key-target_swc_version.
  ls_parameter-value = ls_targ_prod_ver-sw_comp_release.
  APPEND ls_parameter TO rt_parameter.

  ls_parameter-name  = /sdf/cl_rc_s4sic_sample=>c_pre_chk_param_key-target_support_pack.
  ls_parameter-value = ls_targ_stack-stack_sp_name.
  APPEND ls_parameter TO rt_parameter.


*--------------------------------------------------------------------*
* Whether to perform detailed consistency check

  ls_parameter-name  = /sdf/cl_rc_s4sic_sample=>c_pre_chk_param_key-detailed_check.
  ls_parameter-value = iv_detailed_chk.
  APPEND ls_parameter TO rt_parameter.

ENDMETHOD.