METHOD perform_check.

  DATA: lv_buz_fct_name     TYPE sfw_bfunction,
        lv_buz_fct_state    TYPE sfw_r3state,
        lv_buz_fct_stat_str TYPE string,
        lv_count            TYPE i.

  CLEAR: ev_result_int, ev_summary_int.

  ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.
  CLEAR ev_summary_int.

*--------------------------------------------------------------------*
* Preparation for Business Function based simple check

  lv_buz_fct_name  = ms_check-check_identifier.
  lv_buz_fct_state = ms_check-bf_chk_state.
  IF lv_buz_fct_state IS INITIAL.
    lv_buz_fct_state = /sdf/cl_rc_chk_utility=>c_bf_status-active.
  ENDIF.

  CASE lv_buz_fct_state.
    WHEN /sdf/cl_rc_chk_utility=>c_bf_status-active.
      lv_buz_fct_stat_str = 'Active'.                       "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_bf_status-inactive.
      lv_buz_fct_stat_str = 'Inactive'.                     "#EC NOTEXT
  ENDCASE.
  CONCATENATE lv_buz_fct_name '/' lv_buz_fct_stat_str INTO mv_dummy_str.

  IF lv_buz_fct_state <> /sdf/cl_rc_chk_utility=>c_bf_status-active
    AND lv_buz_fct_state <> /sdf/cl_rc_chk_utility=>c_bf_status-inactive.

    ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-rule_issue.
    "Business Function check is not supported: &P1&
    ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '026' iv_para1 = mv_dummy_str ).
    RETURN.
  ENDIF.


*--------------------------------------------------------------------*
* Perform Business Function based simple check
* Necessary to check both SFW_ACTIVE_B2 and SFW_ACTIVE_BFUNC.
* Because for customer systems and many internal systems where BFs are activated system-wide,
* BF state is stored in the cross client table SFW_ACTIVE_B2. And for some internal test
* systems where we activate BFs for system cost reasons  on a per client basis, BF state
* is stored in table SFW_ACTIVE_BFUNC (and SFW_ACTIVE_B2 for enterprise extensions).
* This way we will be able to test the simple checks internally across multiple industries
* without the need to have one test system per industry.

  "Client depedent Business Function
  "Select with CLIENT SPECIFIED because we want to know if a BF is active regardless in which client
  SELECT COUNT( * ) FROM sfw_active_bfunc CLIENT SPECIFIED INTO lv_count
    UP TO 1 ROWS
    WHERE bfunction = lv_buz_fct_name
      AND version   = /sdf/cl_rc_chk_utility=>c_bf_status-active.
  IF sy-subrc <> 0.
    "Cross-client Business Function
    SELECT COUNT( * ) FROM sfw_active_b2 INTO lv_count
      UP TO 1 ROWS
      WHERE bfunction = lv_buz_fct_name
        AND version   = /sdf/cl_rc_chk_utility=>c_bf_status-active.
  ENDIF.

  "Reversion since we look for ACTIVE status in the SQL above
  IF lv_buz_fct_state = /sdf/cl_rc_chk_utility=>c_bf_status-inactive.
    IF lv_count = 0.
      lv_count =  1.
    ELSE.
      lv_count = 0.
    ENDIF.
  ENDIF.

  mv_dummy_str = lv_buz_fct_name.
  IF lv_count > 0.
    ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.

    CASE lv_buz_fct_state.
      WHEN /sdf/cl_rc_chk_utility=>c_bf_status-active.
        "Item is relevant. Business function &P1& is active
        ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '067' iv_para1 = mv_dummy_str ).
      WHEN /sdf/cl_rc_chk_utility=>c_bf_status-inactive.
        "Item is relevant. Business function &P1& is inactive
        ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '068' iv_para1 = mv_dummy_str ).
    ENDCASE.

  ELSE.
    ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.
    CASE lv_buz_fct_state.
      WHEN /sdf/cl_rc_chk_utility=>c_bf_status-active.
        "Item is not relevant. Business function &P1& is inactive
        ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '070' iv_para1 = mv_dummy_str ).
      WHEN /sdf/cl_rc_chk_utility=>c_bf_status-inactive.
        "Item is not relevant. Business function &P1& is active
        ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '069' iv_para1 = mv_dummy_str ).
    ENDCASE.
  ENDIF.

ENDMETHOD.