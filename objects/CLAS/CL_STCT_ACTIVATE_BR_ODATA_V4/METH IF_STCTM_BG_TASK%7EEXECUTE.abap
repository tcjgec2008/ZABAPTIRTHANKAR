  METHOD if_stctm_bg_task~execute.

    DATA lv_suppress_dialog TYPE abap_bool VALUE abap_true.
    DATA lv_system_alias TYPE /iwfnd/if_v4_routing_types=>ty_e_system_alias.
    DATA lv_group_id TYPE /iwfnd/v4_med_group_id.
    DATA lt_group_info TYPE /iwfnd/if_v4_publishing_types=>ty_t_bep_group_info.
    DATA lv_published TYPE abap_bool.

*************** RESULTS ***************

    TYPES:
      BEGIN OF results,
        servicetitle      TYPE string,
        servicename       TYPE string,
        serviceversion(4) TYPE c,
        servicestatus     TYPE string,
        status(1)         TYPE c,  "s = ok, w = warning, e = error
      END OF results.

    DATA: lt_results TYPE TABLE OF results,
          ls_results TYPE results.

    DATA lv_str1 TYPE string.
    DATA sep(1)  TYPE c VALUE ' '.

    DATA lv_raise_error TYPE boolean VALUE abap_false.
    DATA lv_raise_warn TYPE boolean VALUE abap_false.

*****************************************

    DATA ls_task TYPE cl_stctm_tasklist=>ts_task.
    DATA lo_task TYPE REF TO cl_stct_determine_services.

    DATA lx_cast_exc TYPE REF TO cx_sy_move_cast_error ##NEEDED.

    DATA lt_services TYPE stct_services_odata_table.
    DATA lt_services_activation TYPE stct_service_status_table.

    " get stored data from prerequiste task 'Determine OData/ICF Services for Roles'
    READ TABLE ir_tasklist->ptx_task INTO ls_task WITH KEY taskname = 'CL_STCT_DETERMINE_SERVICES'.

    IF sy-subrc = 0.
      TRY.
          lo_task ?= ls_task-r_task.
          lt_services = lo_task->it_services_v4.

        CATCH cx_sy_move_cast_error INTO lx_cast_exc ##NO_HANDLER.
          " error handling
      ENDTRY.

    ENDIF.

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

*****************************************

    IF i_check EQ 'X' . "check mode

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

    ELSE. " execution mode

      lv_system_alias = 'LOCAL'.

      IF lt_services IS INITIAL.

        MESSAGE s000 WITH 'No OData Services v4 defined' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        EXIT.

      ELSE.

        " check if client is customizing, if yes allow popups for Customizing Request
        SELECT SINGLE cccategory FROM t000 INTO @DATA(lv_category) WHERE mandt = @sy-mandt.

        IF lv_category <> 'C'.
          lv_suppress_dialog = abap_false.
        ENDIF.

        LOOP AT lt_services INTO DATA(ls_services).

          CLEAR ls_results.

          " log
          ls_results-servicetitle = 'Service Group:' ##NO_TEXT.
          ls_results-servicename = ls_services-service.
          ls_results-serviceversion = ls_services-version.

          lv_group_id = ls_services-service.

          " check if already published
          TRY.
              CALL METHOD /iwfnd/cl_v4_cof_facade=>is_group_published
                EXPORTING
                  iv_group_id     = lv_group_id
                RECEIVING
                  rv_is_published = lv_published.

            CATCH /iwfnd/cx_gateway INTO DATA(lx_gateway).
              IF lx_gateway IS NOT INITIAL.
                ls_results-servicestatus = lx_gateway->get_exception_text( ) .
                ls_results-status = 'e'.
                lv_raise_error = abap_true.
              ENDIF.

          ENDTRY.

          "Only execute when not in ICF Activation mode only
          IF lv_published = abap_false AND lv_task_selected <> '02'.

            " get services group
            TRY.
                CALL METHOD /iwfnd/cl_v4_cof_facade=>find_groups_from_backend
                  EXPORTING
                    iv_system_alias   = lv_system_alias
                    iv_group_id       = lv_group_id
                  IMPORTING
                    et_bep_group_info = lt_group_info.

              CATCH /iwfnd/cx_gateway INTO lx_gateway.
                IF lx_gateway IS NOT INITIAL.
                  ls_results-servicestatus = lx_gateway->get_exception_text( ) .
                  ls_results-status = 'e'.
                  lv_raise_error = abap_true.
                ENDIF.

            ENDTRY.

            " check services group exists
            READ TABLE lt_group_info INTO DATA(ls_group_info) WITH KEY  group_id = lv_group_id.

            IF sy-subrc <> 0.

              " not available
              ls_results-servicestatus = 'not found' ##NO_TEXT.
              ls_results-status = 'e'.
              lv_raise_error = abap_true.

            ELSE.

              " publish service group
              TRY.
                  CALL METHOD /iwfnd/cl_v4_cof_facade=>publish_group
                    EXPORTING
                      iv_group_id        = lv_group_id
                      iv_system_alias    = lv_system_alias
                      iv_suppress_dialog = lv_suppress_dialog
                    CHANGING
                      cv_transport       = lv_request_cust.

                CATCH /iwfnd/cx_gateway INTO lx_gateway.
                  IF lx_gateway IS NOT INITIAL.
                    ls_results-servicestatus = lx_gateway->get_exception_text( ) .
                    ls_results-status = 'e'.
                    lv_raise_error = abap_true.
                  ENDIF.
              ENDTRY.

              ls_results-servicestatus = 'activated'.
              ls_results-status = 's'.

            ENDIF.

          ELSE.

            "already published
            ls_results-servicestatus = 'available'.
            ls_results-status = 's'.

          ENDIF.

          APPEND ls_results TO lt_results.

        ENDLOOP.

      ENDIF.

      " activate ICF node /sap/opu/odata4
      CLEAR: ls_results.

      TRY.

          ls_results-servicetitle = 'ICF Node:' ##NO_TEXT.
          ls_results-servicename = '/sap/opu/odata4' ##NO_TEXT.

          CALL METHOD /iwfnd/cl_v4_cof_facade=>activate_icf_node.
        CATCH /iwfnd/cx_gateway INTO lx_gateway.
          IF lx_gateway IS NOT INITIAL.
            ls_results-servicestatus = lx_gateway->get_exception_text( ) .
            ls_results-status = 'e'.
            lv_raise_error = abap_true.
          ENDIF.

      ENDTRY.

      ls_results-servicestatus = 'activated' ##NO_TEXT.
      ls_results-status = 's'.

      APPEND ls_results TO lt_results.

****************** PREPARE LOGRESULTS *****************

      IF lv_task_selected = '02'.
        MESSAGE s000 WITH 'ICF Activation mode only:' INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
      ENDIF.

      " DETAILS - log output services
      LOOP AT lt_results INTO ls_results.

        CONCATENATE ls_results-servicetitle ls_results-servicename ls_results-serviceversion INTO lv_str1 SEPARATED BY sep .

        " SUCCESS
        IF ls_results-status = 's'.

          MESSAGE s000 WITH lv_str1 ls_results-servicestatus INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          " WARNING
        ELSEIF ls_results-status = 'w'.

          MESSAGE w000 WITH lv_str1 ls_results-servicestatus INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
          lv_raise_warn =  abap_true.

          " ERROR
        ELSEIF ls_results-status = 'e'.
          MESSAGE e000 WITH lv_str1 ls_results-servicestatus INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
          lv_raise_error =  abap_true.
        ENDIF.

      ENDLOOP.

      " raise error / warning
      IF lv_raise_error =  abap_true.

        MESSAGE e101 WITH '------------------------------' '------------------------------' '------------------------------' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        MESSAGE e000 WITH 'For detailed analysis activate failed service'  'manually with transaction' '/IWFND/V4_ADMIN' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        MESSAGE e101 WITH '------------------------------' '------------------------------' '------------------------------' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        MESSAGE e000 WITH 'After errors have been resolved,' 'make sure to rerun this tasklist' 'with the same config' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        RAISE error_occured.

      ELSEIF lv_raise_warn =  abap_true.
        RAISE warning_occured.
      ENDIF.

    ENDIF.

  ENDMETHOD.