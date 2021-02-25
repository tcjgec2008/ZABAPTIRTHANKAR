METHOD compare_value.

  DATA: lv_comp_option       TYPE /sdf/cl_rc_chk_utility=>ty_option,
        lv_check_count       TYPE i,
        lv_check_count_str   TYPE string,
        lv_actual_count_str  TYPE string.

  "Count & Count Option: default value is set in parent class CONSTRUCTOR
  lv_check_count = ms_check-check_count.
  lv_comp_option = ms_check-check_count_option.

  ev_result_int       = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.
  lv_actual_count_str = iv_actual_count.
  lv_check_count_str  = lv_check_count.


*--------------------------------------------------------------------*
* Check the result

  CASE lv_comp_option.
    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-equal_to.
      IF iv_actual_count = lv_check_count.
        ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.
      ENDIF.
      CONCATENATE '=' lv_check_count_str INTO lv_check_count_str.

    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-not_more_than.
      IF iv_actual_count <= lv_check_count.
        ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.
      ENDIF.
      CONCATENATE '<=' lv_check_count_str INTO lv_check_count_str.

    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-not_less_than.
      IF iv_actual_count >= lv_check_count.
        ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.
      ENDIF.
      CONCATENATE '>=' lv_check_count_str INTO lv_check_count_str.

    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-not_equal_to.
      IF iv_actual_count <> lv_check_count.
        ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.
      ENDIF.
      CONCATENATE '<>' lv_check_count_str INTO lv_check_count_str.

    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-more_than.
      IF iv_actual_count > lv_check_count.
        ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.
      ENDIF.
      CONCATENATE '>' lv_check_count_str INTO lv_check_count_str.

    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-less_than.
      IF iv_actual_count < lv_check_count.
        ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.
      ENDIF.
      CONCATENATE '<' lv_check_count_str INTO lv_check_count_str.

  ENDCASE.


*--------------------------------------------------------------------*
* Prepare the technical information why the item is relevant/irrelevant

  IF ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.

    "Item is relevant. &P1&. Relevant critieria is &P2& and number found is &P3&.
    ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '073'
      iv_para1   = iv_object_checked
      iv_para2   = lv_check_count_str
      iv_para3   = lv_actual_count_str ).
  ELSE.

    "Item is irrelevant. &P1&. Relevant critieria is &P2& and number found is &P3&.
    ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '074'
      iv_para1   = iv_object_checked
      iv_para2   = lv_check_count_str
      iv_para3   = lv_actual_count_str ).
  ENDIF.

ENDMETHOD.