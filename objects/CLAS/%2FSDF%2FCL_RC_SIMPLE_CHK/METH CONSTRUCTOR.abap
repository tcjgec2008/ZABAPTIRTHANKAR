METHOD constructor.

  ms_check = is_check.

  "Translate to upper case since the object (e.g. table name) might be case sensitive
  TRANSLATE ms_check-check_identifier TO UPPER CASE.

  "Count: default is 0
  IF ms_check-check_count < 0.
    ms_check-check_count = 0.
  ENDIF.

  "Count Option: default is Greater
  IF ms_check-check_count_option IS INITIAL.
    ms_check-check_count_option = /sdf/cl_rc_chk_utility=>c_entry_option-more_than.
  ENDIF.

  mv_check_count_option_str = ms_check-check_count_option.
  CASE ms_check-check_count_option.
    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-equal_to.
      mv_check_count_option_str = 'Equal to'.               "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-not_more_than.
      mv_check_count_option_str = 'Less than or Equal to'.  "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-not_less_than.
      mv_check_count_option_str = 'Greater than or Equal to'."#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-not_equal_to.
      mv_check_count_option_str = 'Not Equal to'.           "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-more_than.
      mv_check_count_option_str = 'Greater than'.           "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_entry_option-less_than.
      mv_check_count_option_str = 'Less than'.              "#EC NOTEXT
  ENDCASE.

ENDMETHOD.