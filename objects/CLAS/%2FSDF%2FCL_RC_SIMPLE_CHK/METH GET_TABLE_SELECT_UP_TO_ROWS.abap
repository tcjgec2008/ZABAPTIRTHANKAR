METHOD get_table_select_up_to_rows.

  DATA: lv_comp_option       TYPE /sdf/cl_rc_chk_utility=>ty_option,
        lv_check_count       TYPE i.

  "Count & Count Option: default value is set in parent class CONSTRUCTOR
  lv_check_count = ms_check-check_count.
  lv_comp_option = ms_check-check_count_option.

*--------------------------------------------------------------------*
* Prepare UP To n ROWS for open SQL select to avoid full table scan
* If UP To n ROWS is not used; SELECT COUNT need full table scan for some DB
* refer to message 179482 2017

  CASE lv_comp_option.
    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-equal_to.
      rv_up_to_rows = lv_check_count + 1.

    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-not_more_than. "<=
      rv_up_to_rows = lv_check_count + 1.

    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-not_less_than. ">=
      rv_up_to_rows = lv_check_count + 1.

    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-not_equal_to.
      rv_up_to_rows = lv_check_count + 1.

    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-more_than.
      rv_up_to_rows = lv_check_count + 1.

    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-less_than.
      rv_up_to_rows = lv_check_count + 1.
  ENDCASE.

ENDMETHOD.