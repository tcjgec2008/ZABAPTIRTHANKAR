method _BUILD_ERROR_LIST.

  data:
    lt_error_list        type salv_wd_t_string,
    ls_chk_result        like line of r_chk_results.

  lt_error_list = i_error_list.

  sort lt_error_list.
  delete adjacent duplicates from lt_error_list.

  ls_chk_result-check_sub_id = i_check_sub_id.
  ls_chk_result-descriptions = lt_error_list.
  if lt_error_list is not initial.
    ls_chk_result-return_code  = c_cons_chk_return_code-error.
  else.
    ls_chk_result-return_code  = c_cons_chk_return_code-success.
  endif.

  append ls_chk_result to r_chk_results.

endmethod.