  METHOD if_stctm_bg_task~execute.

    DATA ls_variant TYPE t_variant.
    DATA lv_overwrite TYPE abap_bool.

    DATA lv_plugin_id TYPE c LENGTH 30.
    DATA lv_plugin_descr TYPE c LENGTH 140.
    DATA lv_plugin_component TYPE c LENGTH 255.
    DATA lv_plugin_url TYPE c LENGTH 1024.

    DATA lv_rc_ret TYPE i.
    DATA lv_rc TYPE i.

    DATA lv_warn_ret TYPE abap_bool VALUE abap_false.
    DATA lv_error_ret TYPE abap_bool VALUE abap_false.

    DATA lv_warn TYPE abap_bool VALUE abap_false.
    DATA lv_error TYPE abap_bool VALUE abap_false.

*****************************************

    " get workbench request
    DATA ls_task_wreq TYPE cl_stctm_tasklist=>ts_task.
    DATA lo_task_wreq TYPE REF TO cl_stct_create_request_wbench.
    DATA lx_cast_exc_wreq TYPE REF TO cx_sy_move_cast_error ##NEEDED.

    DATA lv_request_work TYPE char20.

    " get stored data from prerequiste task 'CREATE WORKBENCH REQUEST'
    READ TABLE ir_tasklist->ptx_task INTO ls_task_wreq WITH KEY taskname = 'CL_STCT_CREATE_REQUEST_WBENCH'.

    IF sy-subrc = 0.
      TRY.
          lo_task_wreq ?= ls_task_wreq-r_task.
          lv_request_work = lo_task_wreq->p_request_workbench.

        CATCH cx_sy_move_cast_error INTO lx_cast_exc_wreq.
          MESSAGE e000 WITH 'Could not get Request from Task CL_STCT_CREATE_REQUEST_WBENCH' INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
          RAISE error_occured.
      ENDTRY.
    ENDIF.

    " get UI parameter
    LOOP AT pt_variant INTO ls_variant.
      CASE  ls_variant-selname.
        WHEN 'P_PLID'.
          lv_plugin_id = ls_variant-low.
        WHEN 'P_COMP'.
          lv_plugin_component = ls_variant-low.
        WHEN 'P_DESCR'.
          lv_plugin_descr = ls_variant-low.
        WHEN 'P_URL'.
          lv_plugin_url = ls_variant-low.
        WHEN 'P_OVER'.
          lv_overwrite = ls_variant-low.
      ENDCASE.
    ENDLOOP.

    IF i_check = 'X'.

      " authority check
      cl_stct_setup_utilities=>check_authority(
         EXCEPTIONS
           no_authority  = 1
           OTHERS        = 2 ).
      IF sy-subrc <> 0.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.
      ELSE.
        MESSAGE s005 INTO if_stctm_task~pr_log->dummy.
        if_stctm_task~pr_log->add_syst( ).
      ENDIF.

      IF lv_overwrite = abap_false.

        " check plugin
        me->check_flp_plugin(
          EXPORTING
            i_plugin_id        = lv_plugin_id
            i_plugin_component = lv_plugin_component
            i_plugin_descr     = lv_plugin_descr
            i_plugin_url       = lv_plugin_url
          IMPORTING
            e_rc               =  lv_rc_ret
        ).

        IF lv_rc_ret = 2.
          lv_warn = abap_true.
        ENDIF.

        IF lv_warn = abap_true.

          MESSAGE w000 WITH 'Confirm overwrite by checking the option' 'in the Parameter UI' 'or continue by clicking' '''Execute (F8)''' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          RAISE warning_occured.
        ENDIF.

      ENDIF.

    ELSE. "start execution

      " check lv_request_cust is not emtpy
      IF lv_request_work IS INITIAL.
        MESSAGE e000 WITH 'No Workbench Request available' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.
      ENDIF.

      me->config_flp_plugin(
        EXPORTING
          i_plugin_id        = lv_plugin_id
          i_plugin_component = lv_plugin_component
          i_plugin_descr     = lv_plugin_descr
          i_plugin_url       = lv_plugin_url
          i_request_work     = lv_request_work
          i_overwrite        = lv_overwrite                  " Overwrite
        IMPORTING
          e_warning          =  lv_warn_ret
          e_error            =  lv_error_ret
      ).

      IF lv_warn_ret = abap_true.
        lv_warn = abap_true.
      ENDIF.

      IF lv_error_ret = abap_true.
        lv_error = abap_true.
      ENDIF.

      " set overall task status
      IF lv_error = abap_true.
        RAISE error_occured.
      ENDIF.

      IF lv_warn = abap_true.
        RAISE warning_occured.
      ENDIF.

    ENDIF."End of execution

  ENDMETHOD.