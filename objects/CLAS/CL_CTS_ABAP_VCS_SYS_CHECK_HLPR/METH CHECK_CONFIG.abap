  method check_config.
    data data_handler type ref to if_cts_abap_vcs_data_handler.
    data lv_config_value type scts_abap_vcs_config_value.
    data_handler = new cl_cts_abap_vcs_data_handler( ).

    lv_config_value = data_handler->get_config_by_key( identifier = conv #( sy-sysid ) key = if_cts_abap_vcs_system=>co_sysconf_java type = if_cts_abap_vcs_config_handler=>co_type_system ).
    if lv_config_value is initial or lv_config_value = if_cts_abap_vcs_data_handler=>co_empty_resultset.
      append value #( status_key = co_config_java value = co_error category = co_cat_config ) to status.
    else.
      append value #( status_key = co_config_java value = co_success category = co_cat_config ) to status.
    endif.

    lv_config_value = data_handler->get_config_by_key( identifier = conv #( sy-sysid ) key = if_cts_abap_vcs_system=>co_sysconf_jar_path type = if_cts_abap_vcs_config_handler=>co_type_system ).
    if lv_config_value is initial or lv_config_value = if_cts_abap_vcs_data_handler=>co_empty_resultset.
      append value #( status_key = co_config_client value = co_error category = co_cat_config ) to status.
    else.
      append value #( status_key = co_config_client value = co_success category = co_cat_config ) to status.
    endif.

    lv_config_value = data_handler->get_config_by_key( identifier = conv #( sy-sysid ) key = if_cts_abap_vcs_system=>co_sysconf_vcs_path type = if_cts_abap_vcs_config_handler=>co_type_system ).
    if lv_config_value is initial or lv_config_value = if_cts_abap_vcs_data_handler=>co_empty_resultset.
      append value #( status_key = co_config_path value = co_error category = co_cat_config ) to status.
    else.
      data(file_handler) = new cl_cts_abap_vcs_file_handler( ).
      data(separator) = file_handler->get_dir_separator( ).
      data(lv_dir) = |{ co_config_path_value }{ separator }|.
      data lv_length type i.
      data lv_length2 type i.
      lv_length = strlen( lv_config_value ).
      lv_length2 = lv_length - 5.
      lv_length = lv_length.
      lv_length = lv_length - 4.
      if lv_config_value+lv_length = co_config_path_value or
        lv_config_value+lv_length2(5) = lv_dir.
        try.
            me->check_directory( lv_config_value ).
            append value #( status_key = co_config_path value = co_success category = co_cat_config ) to status.
          catch cx_root.
            append value #( status_key = co_config_path value = co_error category = co_cat_config ) to status.
        endtry.
      else.
        append value #( status_key = co_config_path value = co_error category = co_cat_config ) to status.
      endif.
    endif.
  endmethod.