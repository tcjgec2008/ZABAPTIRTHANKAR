  METHOD if_stctm_bg_task~execute.

    DATA  lo_exploration TYPE REF TO /iwfnd/cl_med_rem_exploration.
    DATA  lx_med_remote TYPE REF TO /iwfnd/cx_med_remote  ##NEEDED.
    DATA  lx_destin_finder TYPE REF TO /iwfnd/cx_destin_finder  ##NEEDED.
    DATA  lt_bep_services TYPE /iwfnd/cl_med_rem_exploration=>ty_t_service_groups.
    DATA  ls_bep_service TYPE /iwfnd/cl_med_rem_exploration=>ty_s_service_group.
    DATA  lv_bep_not_supported TYPE abap_bool.
    DATA  lt_return TYPE bapirettab.
    DATA  lv_icfactivationonly TYPE abap_bool VALUE abap_false.

    DATA lv_servicename TYPE c LENGTH 35.
    DATA lv_serviceversion TYPE n LENGTH 4.
    DATA lv_alias TYPE c LENGTH 16.
    DATA lv_process_mode TYPE c LENGTH 1.
    DATA lv_rc TYPE i.
    DATA lv_error TYPE abap_bool.
    DATA lv_warn TYPE abap_bool.

    DATA: lv_fm_exist TYPE i VALUE 0.
    DATA lt_gw_services TYPE  /iwbep/t_model_group.
    DATA ls_gw_services TYPE LINE OF /iwbep/t_model_group.
    DATA lt_bapiret TYPE TABLE OF bapiret2.
    DATA lv_funcname TYPE rs38l_fnam.

*****************************************

    "get prefix, devclass and requests from task 'CL_STCT_SET_TRANSPORT_OPTIONS'

    DATA ls_task_set_trans TYPE cl_stctm_tasklist=>ts_task.
    DATA lo_task_set_trans TYPE REF TO cl_stct_set_transport_options.
    DATA lx_cast_exc_set_trans TYPE REF TO cx_sy_move_cast_error ##NEEDED.

    DATA lv_devclass TYPE devclass.
    DATA lv_prefix_cust TYPE string.
    DATA lv_request_work TYPE char20.
    DATA lv_request_cust TYPE char20.
    DATA lv_task_selected TYPE stc_task_status.

    READ TABLE ir_tasklist->ptx_task INTO ls_task_set_trans WITH KEY taskname = 'CL_STCT_SET_TRANSPORT_OPTIONS'.

    IF sy-subrc = 0.
      TRY.
          lo_task_set_trans ?= ls_task_set_trans-r_task.

          lv_task_selected = lo_task_set_trans->if_stctm_task~p_status.
          lv_prefix_cust = lo_task_set_trans->p_prefix.
          lv_devclass = lo_task_set_trans->p_package.
          lv_request_work = lo_task_set_trans->p_request_workbench.
          lv_request_cust = lo_task_set_trans->p_request_customizing.

        CATCH cx_sy_move_cast_error INTO lx_cast_exc_set_trans.
          MESSAGE e000 WITH 'Could not retrieve data from Task Set transport settings' INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
          RAISE error_occured.
      ENDTRY.
    ENDIF.

    IF i_check EQ 'X'.

      " authority check
      cl_stct_setup_utilities=>check_authority(
         EXCEPTIONS
           no_authority  = 1
           OTHERS        = 2 ).
      IF sy-subrc <> 0.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.
      ENDIF.

      " authenfication
      CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
        EXPORTING
          tcode  = '/IWFND/MAINT_SERVICE'
        EXCEPTIONS
          ok     = 0
          not_ok = 1
          OTHERS = 2.

      IF sy-subrc NE 0.
        MESSAGE e172(00) WITH '/IWFND/MAINT_SERVICE' INTO if_stctm_task~pr_log->dummy.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.
      ENDIF.

      AUTHORITY-CHECK OBJECT 'S_ADMI_FCD'
                      ID 'S_ADMI_FCD' FIELD 'NADM'.

      IF sy-subrc NE 0.
        MESSAGE e150(00) WITH 'Network administration'(002) INTO if_stctm_task~pr_log->dummy.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.
      ENDIF.

      MESSAGE s005 INTO if_stctm_task~pr_log->dummy.
      if_stctm_task~pr_log->add_syst( ).

    ELSE.

      "set flags
      lv_error = abap_false.
      lv_warn = abap_false.

      " log output transport settings
      DATA: lv_msg TYPE c LENGTH 220.

      IF lv_task_selected = '02'.

        lv_icfactivationonly = abap_true.

        lv_msg = | OData ICF Activation mode only: | ##NO_TEXT.
        if_stctm_task~pr_log->add_text( EXPORTING i_type = 'S' i_text = lv_msg ).

      ELSE.

      lv_msg = | Prefix: { lv_prefix_cust }; Package: { lv_devclass } | ##NO_TEXT.
      if_stctm_task~pr_log->add_text( EXPORTING i_type = 'S' i_text = lv_msg ).

      IF lv_devclass CS '$'.

        lv_request_work = ''.
        lv_request_cust = ''.

        lv_msg = | Workbench Request: not required; Customizing Request: not required | ##NO_TEXT.
        if_stctm_task~pr_log->add_text( EXPORTING i_type = 'S' i_text = lv_msg )..
      ELSE.
        lv_msg = | Workbench Request: { lv_request_work }; Customizing Request: { lv_request_cust } | ##NO_TEXT.
        if_stctm_task~pr_log->add_text( EXPORTING i_type = 'S' i_text = lv_msg ).
      ENDIF.

      ENDIF.

      " activate foundation services co-deployed
      lv_alias = ''.
      lv_process_mode = 'C'.

      ls_gw_services-technical_name = 'ESH_SEARCH_SRV'.
      ls_gw_services-version = '001'.
      APPEND ls_gw_services TO lt_gw_services.

      ls_gw_services-technical_name = 'RSAO_ODATA_SRV'.
      ls_gw_services-version = '001'.
      APPEND ls_gw_services TO lt_gw_services.

      ls_gw_services-technical_name = '/SSB/SMART_BUSINESS_RUNTIME_SRV'.
      ls_gw_services-version = '001'.
      APPEND ls_gw_services TO lt_gw_services.

      ls_gw_services-technical_name = '/SSB/SMART_BUSINESS_DESIGNTIME_SRV'.
      ls_gw_services-version = '001'.
      APPEND ls_gw_services TO lt_gw_services.

      IF lv_task_selected <> '02'.
        " log output
        MESSAGE s000 WITH 'Processing mode: Co-deployed only'(122) INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN.
        if_stctm_task~pr_log->add_syst( ).
      ENDIF.

      LOOP AT lt_gw_services INTO ls_gw_services.

        " set params
        lv_servicename = ls_gw_services-technical_name.
        lv_serviceversion = ls_gw_services-version .

        " activate service
        lv_rc = activate_service(  iv_servicename    = lv_servicename
                                   iv_serviceversion = lv_serviceversion
                                   iv_alias          = lv_alias
                                   iv_prefix_cust    = lv_prefix_cust
                                   iv_devclass       = lv_devclass
                                   iv_request_work   = lv_request_work
                                   iv_request_cust   = lv_request_cust
                                   iv_process_mode      = lv_process_mode
                                   iv_icfactivationonly = lv_icfactivationonly ).

        CASE lv_rc.
          WHEN 0.
            " ok
          WHEN 1.
            " error
            lv_error = abap_true.
          WHEN 2.
            " warn
            lv_warn = abap_true.
          WHEN OTHERS.
            lv_error = abap_true.
        ENDCASE.

        CLEAR lv_rc.

      ENDLOOP.


      " activate foundation services routing based for alias 'FIORI_MENU'
      CLEAR lt_gw_services.

      lv_alias = 'FIORI_MENU'.
      lv_process_mode = ''.

      ls_gw_services-technical_name = '/UI2/EASY_ACCESS_MENU'.
      ls_gw_services-version = '001'.
      APPEND ls_gw_services TO lt_gw_services.

      ls_gw_services-technical_name = '/UI2/USER_MENU'.
      ls_gw_services-version = '001'.
      APPEND ls_gw_services TO lt_gw_services.

      IF lv_task_selected <> '02'.
        " log output alias
        MESSAGE s000 WITH 'Processing mode: Routing based'(121) '/ System Alias:'(117) lv_alias INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN.
        if_stctm_task~pr_log->add_syst( ).
      ENDIF.

      LOOP AT lt_gw_services INTO ls_gw_services.

        " set params
        lv_servicename = ls_gw_services-technical_name.
        lv_serviceversion = ls_gw_services-version .

        " activate service
        lv_rc = activate_service(  iv_servicename    = lv_servicename
                                   iv_serviceversion = lv_serviceversion
                                   iv_alias          = lv_alias
                                   iv_prefix_cust    = lv_prefix_cust
                                   iv_devclass       = lv_devclass
                                   iv_request_work   = lv_request_work
                                   iv_request_cust   = lv_request_cust
                                   iv_process_mode      = lv_process_mode
                                   iv_icfactivationonly = lv_icfactivationonly ).

        CASE lv_rc.
          WHEN 0.
            " ok
          WHEN 1.
            " error
            lv_error = abap_true.
          WHEN 2.
            " warn
            lv_warn = abap_true.
          WHEN OTHERS.
            lv_error = abap_true.
        ENDCASE.

        CLEAR lv_rc.

      ENDLOOP.

      " set status of task
      IF lv_error = abap_true.

        MESSAGE e101 WITH '------------------------------' '------------------------------' '------------------------------' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        if_stctm_task~pr_log->add_text(
          EXPORTING
            i_type        = 'E'    " Message type
            i_text        = 'For detailed analysis activate failed service manually with transaction /iwfnd/maint_service'
            i_details     = 'X'        ) ##NO_TEXT.

        RAISE error_occured.
      ENDIF.

      IF lv_warn = abap_true.
        RAISE warning_occured.
      ENDIF.

    ENDIF.

  ENDMETHOD.                    "IF_STCTM_BG_TASK~EXECUTE