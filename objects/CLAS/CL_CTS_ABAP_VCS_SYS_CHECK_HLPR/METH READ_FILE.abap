  method read_file.
    data lv_file type eps2filnam.
    data lv_path type eps2path.
    data lv_value type string.

    lv_value = config_value.
    data lv_position type i value 0.
    data(file_handler) = new cl_cts_abap_vcs_file_handler( ).
    data(separator) = file_handler->get_dir_separator( ).
    data(lv_length) = strlen( lv_value ).
    lv_length = lv_length - 1.

    if lv_length > 0 and lv_value+lv_length(1) = separator.
      lv_value = lv_value(lv_length).
    endif.

    while lv_position < lv_length.
      search lv_value+lv_position for separator.
      if sy-subrc = 0.
        lv_position = lv_position + sy-fdpos + 1.
      else.
        lv_file = lv_value+lv_position.
        lv_length = strlen( lv_value ) - strlen( lv_file ).
        lv_path = lv_value(lv_length).
        lv_position = lv_length.
      endif.
    endwhile.

    call function 'EPS_OPEN_INPUT_FILE'
      exporting
        iv_long_file_name      = lv_file
        iv_long_dir_name       = lv_path
      exceptions
        invalid_eps_subdir     = 1
        sapgparam_failed       = 2
        build_directory_failed = 3
        no_authorization       = 4
        build_path_failed      = 5
        open_failed            = 6
        read_directory_failed  = 7
        read_attributes_failed = 8
        others                 = 9.
    if sy-subrc <> 0.
      raise exception type cx_cts_abap_vcs_exception.
    else.
      call function 'EPS_CLOSE_FILE'
        exporting
          iv_long_file_name = lv_file
          iv_long_dir_name  = lv_path.
    endif.
  endmethod.