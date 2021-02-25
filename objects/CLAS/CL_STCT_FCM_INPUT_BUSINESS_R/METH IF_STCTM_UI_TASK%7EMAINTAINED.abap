  METHOD if_stctm_ui_task~maintained.

    DATA: ls_task TYPE cl_stctm_tasklist=>ts_task.
    DATA: lo_task TYPE REF TO cl_stct_fcm_select_business_r.
    DATA: lx_cast_exc TYPE REF TO cx_sy_move_cast_error ##NEEDED.

    DATA: lt_business_roles TYPE stct_agr_br_table.
    DATA: ls_business_roles TYPE stct_agr_br.
    DATA: lt_business_roles_tmp TYPE stct_agr_br_table.

    DATA: ls_editor TYPE stct_editor.
    DATA: lv_entries TYPE i.
    DATA: lv_entries1 TYPE i.
    DATA: lv_entriesstr1 TYPE string.

    DATA: lt_services_table_format_error TYPE stct_editor_table.
    DATA: lt_services_table_format_ok TYPE stct_editor_table.

    DATA: lt_services_table_format_tmp TYPE stct_editor_table.

    DATA: ls_service_formatted TYPE stct_input_data.

    DATA: lv_count TYPE i.

    DATA: lv_string1 TYPE string,
          lv_string2 TYPE string.

    DATA: task_selected TYPE stc_task_status.

    DATA: outputtxt(256) TYPE c,
          sep(1)         TYPE c VALUE ' '.

    " get selected (01 - selected / 02 - not selected)
    task_selected = if_stctm_task~p_status.


    " read buiness roles
    READ TABLE ir_tasklist->ptx_task INTO ls_task WITH KEY taskname = 'CL_STCT_FCM_SELECT_BUSINESS_R'.

    IF sy-subrc = 0.
      TRY.
          lo_task ?= ls_task-r_task.
          lt_business_roles = lo_task->i_business_roles.

        CATCH cx_sy_move_cast_error INTO lx_cast_exc ##NO_HANDLER.
          " error handling
      ENDTRY.

    ENDIF.

    " read previous entries
    lt_services_table_format_tmp = it_editor_tmp.

    " compare current entries
    " read initial line
    DESCRIBE TABLE it_editor LINES lv_entries.

    IF lv_entries = 0.
      r_maintained = if_stctm_task=>c_bool-false.

      if_stctm_ui_task~p_variant_descr = ''.

      CLEAR: it_editor, it_services.

    ELSE.
      r_maintained = if_stctm_task=>c_bool-true.

      " display parameter description
      IF task_selected = '02' OR r_maintained <> 'X'.

        " clear param description
        if_stctm_ui_task~p_variant_descr = ''.

        CLEAR: it_editor, it_services.

      ELSE.

        " FORMAT SERVICES
        CLEAR it_services.
        CLEAR lt_services_table_format_error.
        CLEAR lt_services_table_format_ok.

        LOOP AT it_editor INTO ls_editor.

          TRANSLATE ls_editor TO UPPER CASE.

          " CHECK ROLES IF AVAILABLE
          SELECT COUNT( * ) FROM agr_define UP TO 1 ROWS WHERE agr_name = ls_editor. "#EC CI_BYPASS

          IF sy-dbcnt > 0.
            APPEND ls_editor TO lt_services_table_format_ok.
          ELSE.
            APPEND ls_editor TO lt_services_table_format_error.
          ENDIF.

        ENDLOOP.

        " PREPARE RESULTS
        " if errors are found
        IF lt_services_table_format_error IS NOT INITIAL.

          " delete duplicates
          DELETE ADJACENT DUPLICATES FROM lt_services_table_format_error.

          MESSAGE e000 WITH 'Format error:'(100) INTO if_stctm_task~pr_log->dummy ##TEXT_UNIQ.
          if_stctm_task~pr_log->add_syst( ).

          "output errors
          LOOP AT lt_services_table_format_error INTO ls_editor .

            " check which line the error is found
            LOOP AT it_editor INTO ls_service_formatted.
              IF ls_service_formatted CS ls_editor.
                DATA(lv_line) = sy-tabix.
              ENDIF.
            ENDLOOP.

            DATA(lv_msg_line) = 'Line'(104) && | { lv_line }| && ':'.

            " Check availibility of role for msg
            SELECT COUNT( * ) FROM agr_define UP TO 1 ROWS WHERE agr_name = ls_editor. "#EC CI_BYPASS

            IF sy-dbcnt = 0.
              ls_editor-line = ls_editor-line && | not available | ##NO_TEXT.
            ENDIF.

            MESSAGE e000 WITH lv_msg_line ls_editor INTO if_stctm_task~pr_log->dummy ##TEXT_UNIQ.
            if_stctm_task~pr_log->add_syst( ).

          ENDLOOP.

          "display in parameter description
          if_stctm_ui_task~p_variant_descr = 'Format error (see log details)'(103) ##TEXT_UNIQ  ##TEXT_DIFF.

        ELSE.

          " delete duplicates
          DELETE ADJACENT DUPLICATES FROM lt_services_table_format_ok.

          LOOP AT lt_services_table_format_ok INTO ls_editor.
            TRANSLATE ls_editor TO UPPER CASE.
            SPLIT ls_editor AT space INTO lv_string1 lv_string2.
            ls_service_formatted-service = lv_string1.
            APPEND ls_service_formatted TO it_services.
          ENDLOOP.

          "prepare param descr output
          DESCRIBE TABLE it_services LINES lv_entries1.

          lv_entriesstr1 = lv_entries1.

          "assemble:
          CONCATENATE 'Defined roles:'(105) lv_entriesstr1 INTO outputtxt SEPARATED BY sep ##TEXT_UNIQ.

          "display in parameter description
          if_stctm_ui_task~p_variant_descr = outputtxt.

        ENDIF.

      ENDIF.

    ENDIF.

*************************************************************

    " format erros found
    IF lt_services_table_format_error IS NOT INITIAL.
      EXIT.
    ENDIF.


    IF it_editor_tmp IS NOT INITIAL.

      " Remove old selection
      LOOP AT lt_business_roles INTO ls_business_roles.

        LOOP AT lt_services_table_format_tmp INTO DATA(ls_services_table_format_tmp).

          IF ls_services_table_format_tmp = ls_business_roles-agr_name.
            ls_business_roles-flag = ' '.
            MODIFY lt_business_roles FROM ls_business_roles.
          ENDIF.

        ENDLOOP.

      ENDLOOP.

      lo_task->i_business_roles = lt_business_roles.
      lo_task->if_stctm_ui_task~maintained( ).

    ENDIF.


    " Set new selection
    LOOP AT lt_business_roles INTO ls_business_roles.

      LOOP AT it_services INTO DATA(ls_services).

        IF ls_services-service = ls_business_roles-agr_name.
          ls_business_roles-flag = 'X'.
          MODIFY lt_business_roles FROM ls_business_roles.
        ENDIF.

      ENDLOOP.

    ENDLOOP.

    lo_task->i_business_roles = lt_business_roles.
    lo_task->if_stctm_ui_task~maintained( ).

    " save current selection
    it_editor_tmp = it_editor.

  ENDMETHOD.