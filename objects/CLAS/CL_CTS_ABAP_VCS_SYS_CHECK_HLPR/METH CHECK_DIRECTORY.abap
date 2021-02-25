  method check_directory.

    data lv_dir_name  type eps2filnam.
    data lt_file_list type eps2filis.

    clear lv_dir_name.
    lv_dir_name = config_value.

    clear lt_file_list.
    call function 'EPS2_GET_DIRECTORY_LISTING'
      exporting
        iv_dir_name            = lv_dir_name
      tables
        dir_list               = lt_file_list
      exceptions
        invalid_eps_subdir     = 1
        sapgparam_failed       = 2
        build_directory_failed = 3
        no_authorization       = 4
        build_path_failed      = 5
        read_directory_failed  = 6
        empty_directory_list   = 7
        others                 = 8.

*   The directory exists and has some content or the directory exists but it's empty ...
    if sy-subrc = 0 or sy-subrc = 7.
      return.
    elseif sy-subrc <> 0.
      raise exception type cx_cts_abap_vcs_exception.
    endif.

  endmethod.