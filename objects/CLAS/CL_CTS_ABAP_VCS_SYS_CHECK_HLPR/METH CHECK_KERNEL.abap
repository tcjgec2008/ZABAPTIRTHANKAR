  method check_kernel.
    try.
        data(config) = me->system->get_config_by_key( if_cts_abap_vcs_system=>co_sysconf_jar_path ).
        if not config is initial.
          me->read_file( config ).
          append value #( status_key = co_kernel_client value = co_success category = co_cat_kernel ) to status.
        else.
          append value #( status_key = co_kernel_client value = co_error category = co_cat_kernel ) to status.
        endif.
      catch cx_root.
        append value #( status_key = co_kernel_client value = co_error category = co_cat_kernel ) to status.
    endtry.
    try.
        config = me->system->get_config_by_key( if_cts_abap_vcs_system=>co_sysconf_java ).
        data(file_handler) = new cl_cts_abap_vcs_file_handler( ).
        data(separator) = file_handler->get_dir_separator( ).
        data: lv_length  type i.
        lv_length = strlen( config ).
        lv_length = lv_length - 1.

        if config+lv_length(1) = file_handler->get_dir_separator( ) or config+lv_length(1) = '/'.
          append value #( status_key = co_kernel_java value = co_error category = co_cat_kernel ) to status.
        elseif config = 'java'.
          append value #( status_key = co_kernel_java value = co_warning category = co_cat_kernel ) to status.
        elseif not config is initial.
          me->read_file( config ).
          append value #( status_key = co_kernel_java value = co_success category = co_cat_kernel ) to status.
        else.
          append value #( status_key = co_kernel_java value = co_error category = co_cat_kernel ) to status.
        endif.
      catch cx_root.
        append value #( status_key = co_kernel_java value = co_error category = co_cat_kernel ) to status.
    endtry.
  endmethod.