  METHOD get_parameter_values.

    DATA: ls_parameter      TYPE LINE OF tihttpnvp.

    CLEAR: ev_sitem_guid, ev_detailed_check, ev_swc, ev_swc_version, ev_swc_sp_lvl.

    LOOP AT it_parameter INTO ls_parameter.
      CASE ls_parameter-name.
        WHEN c_pre_chk_param_key-sitem_guid.
          ev_sitem_guid = ls_parameter-value.
        WHEN c_pre_chk_param_key-detailed_check.
          ev_detailed_check = ls_parameter-value.
        WHEN c_pre_chk_param_key-target_swc.
          ev_swc = ls_parameter-value.
        WHEN c_pre_chk_param_key-target_swc_version.
          ev_swc_version = ls_parameter-value.
        WHEN c_pre_chk_param_key-target_support_pack.
          ev_swc_sp_lvl = ls_parameter-value.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.