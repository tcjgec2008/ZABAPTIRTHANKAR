  METHOD if_stctm_task~is_necessary.

    DATA: lv_new_whitelist TYPE abap_bool.
    DATA: lv_count TYPE i.
    DATA: lv_count_hul TYPE i.

    DATA lr_rt_info TYPE REF TO cl_stctm_tasklist_rt_info.

    DATA ls_task TYPE cl_stctm_tasklist=>ts_task.
    DATA lo_task TYPE REF TO cl_stct_set_sysalias_sap_local.

    DATA ls_task1 TYPE cl_stctm_tasklist=>ts_task.
    DATA lo_task1 TYPE REF TO cl_stct_activate_http_whitelis.
    DATA lr_task_object1 TYPE REF TO if_stctm_task.

    DATA lv_webdispatcher_host_https TYPE rfchost.

    " get runtime info
    lr_rt_info = ir_tasklist->get_runtime_info( ).

    " check new whitelist is enabled
    CALL METHOD cl_http_utility=>if_http_utility~is_new_whitelist_check_active
      RECEIVING
        rv_active = lv_new_whitelist.

    IF lv_new_whitelist = abap_true.

      r_necessary = if_stctm_task=>c_necessary-necessary.

    ELSE.
      "  check for entries in http_whitelist
      SELECT COUNT( * ) FROM http_whitelist CLIENT SPECIFIED INTO lv_count .

      IF lv_count = 0.

        IF lr_rt_info->p_scenario_id CP 'SAP_GW_FIORI_ERP_ONE_CLNT_SETUP'.
          r_necessary = if_stctm_task=>c_necessary-optional.
        ELSE.
          r_necessary = if_stctm_task=>c_necessary-necessary.
        ENDIF.
      ELSE.
        r_necessary = if_stctm_task=>c_necessary-impossible.
      ENDIF.

    ENDIF.

  ENDMETHOD.