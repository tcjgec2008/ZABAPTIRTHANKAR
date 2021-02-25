method _BUILD_RESULT_TABLE.

  data:
    lv_lines   type i,
    lv_limit   type i,
    lv_diff    type i,
    lv_string type string,
    ls_detailed_check type ihttpnvp.

  field-symbols:
    <chk_result>  type ty_pre_cons_chk_result_str,
    <description> type string.

  check c_chk_result_tab is not initial.
  assert i_client is not initial.

  read table it_runtime_parameter into ls_detailed_check with key name = 'DETAILED_CHECK'.

  loop at c_chk_result_tab assigning <chk_result>.
    concatenate sy-sysid(3) '/' i_client(3) ': ' <chk_result>-check_sub_id
           into <chk_result>-check_sub_id respecting blanks.

    "---------------------------------------------------------------
    "--- In high level check we only display 3 findings at max
    "--- and add a summary line
    "---------------------------------------------------------------
    lv_lines = lines( <chk_result>-descriptions ).
    if ls_detailed_check-value = 'X'.
      lv_limit = lv_lines.
    else.
      lv_limit = 3.
    endif.

    loop at <chk_result>-descriptions assigning <description> from 1 to lv_limit.
      concatenate sy-sysid(3) '/' i_client(3) ': ' <description>
             into <description> respecting blanks.
    endloop.

    "--- Summary line
    if lv_lines > lv_limit.
      delete <chk_result>-descriptions from lv_limit + 1.
      lv_diff = lv_lines - lv_limit.
      lv_string = lv_diff.
      append initial line to <chk_result>-descriptions assigning <description>.
      concatenate sy-sysid(3) '/' i_client(3) ': ' '... and ' lv_string ' more findings -'
                 ' Execute detailed check for a complete list'
            into <description> respecting blanks.
    endif.
  endloop.

endmethod.