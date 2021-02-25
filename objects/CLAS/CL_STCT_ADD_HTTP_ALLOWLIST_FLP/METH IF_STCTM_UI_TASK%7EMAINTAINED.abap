  METHOD if_stctm_ui_task~maintained.

    DATA ls_variant TYPE LINE OF tt_variant.

    DATA ls_task TYPE cl_stctm_tasklist=>ts_task.
    DATA lo_task TYPE REF TO cl_stct_set_sysalias_sap_local.

    DATA: lpt_variant TYPE tt_variant.
    DATA: lls_variant TYPE LINE OF tt_variant.

    DATA lr_maintained TYPE sap_bool.

    DATA: sep(1)         TYPE c VALUE ' ',
          txt1(100)      TYPE c,
          outputtxt(256) TYPE c.

    DATA: task_selected TYPE stc_task_status.

* call ui maintain method
    r_maintained = super->if_stctm_ui_task~maintained( ir_tasklist ).

* check if task is selected (01 - selected / 02 - not selected)
    task_selected = if_stctm_task~p_status.

* get data from prerequiste task 'CL_STCT_SET_SYSALIAS_SAP_LOCAL'
    READ TABLE ir_tasklist->ptx_task INTO ls_task WITH KEY taskname = 'CL_STCT_SET_SYSALIAS_SAP_LOCAL'.
    IF sy-subrc = 0.
      TRY.
          lo_task ?= ls_task-r_task.
          DATA(lv_host) = lo_task->mv_webdispatcher_host_https.
          DATA(lv_port) = lo_task->mv_webdispatcher_port_https.

        CATCH cx_sy_move_cast_error INTO DATA(lx_cast_exc) ##NO_HANDLER.
      ENDTRY.
    ENDIF.

    LOOP AT pt_variant INTO ls_variant.

      IF ls_variant-selname = 'P_HOST'.
        ls_variant-low = lv_host.
        MODIFY pt_variant FROM ls_variant.
      ENDIF.

      IF ls_variant-selname = 'P_PORT'.
        ls_variant-low = lv_port.
        MODIFY pt_variant FROM ls_variant.
      ENDIF.

    ENDLOOP.

  r_maintained = if_stctm_task=>c_bool-true.

ENDMETHOD.