  METHOD if_stctm_bg_task~execute.

*************** Services ***************

* Services from remote system
    DATA  lo_exploration            TYPE REF TO /iwfnd/cl_med_rem_exploration.

    DATA  lt_return                 TYPE bapirettab.
    DATA  lt_bep_services           TYPE /iwfnd/cl_med_rem_exploration=>ty_t_service_groups.
    DATA lv_bep_not_supported TYPE abap_bool.

    DATA  lx_med_remote             TYPE REF TO /iwfnd/cx_med_remote  ##NEEDED.
    DATA  lx_destin_finder          TYPE REF TO /iwfnd/cx_destin_finder  ##NEEDED.

    DATA  ls_bep_service            TYPE /iwfnd/cl_med_rem_exploration=>ty_s_service_group.
    DATA  ls_return                 TYPE bapiret2.

* Activate service
    DATA lv_processing_mode TYPE c LENGTH 1.

    DATA lv_alias TYPE c LENGTH 16.

    DATA lt_services_data TYPE TABLE OF /iwfnd/i_med_srh.
    DATA ls_services_data LIKE LINE OF lt_services_data.

    DATA lt_split TYPE TABLE OF string.
    DATA lv_count TYPE i.

    DATA lv_ipstr TYPE string.
    DATA lv_opstr TYPE string.

    DATA lo_config_facade  TYPE REF TO /iwfnd/cl_cof_facade.

    DATA lv_service_name TYPE /iwfnd/med_mdl_srg_name.
    DATA lv_service_version TYPE /iwfnd/med_mdl_version.
    DATA lv_service_name_bep TYPE /iwfnd/med_mdl_srg_name.
    DATA lv_service_id TYPE /iwfnd/med_mdl_srg_identifier.
    DATA lv_service_name_tech TYPE /iwfnd/med_mdl_srg_name ##NEEDED.
    DATA lt_sys_aliases TYPE /iwfnd/cl_mgw_inst_man_dba=>ty_gt_system_aliases.
    DATA lv_service_nspace TYPE c LENGTH 10.

    DATA lv_hash_value TYPE xupname.
    DATA lv_hash_value_type TYPE usobtype.

    DATA lx_cof TYPE REF TO /iwfnd/cx_cof ##NEEDED.

* Local
    DATA lv_active TYPE boolean.
    DATA ls_services_activation TYPE stct_service_status.

*************** RESULTS ***************

    TYPES:
      BEGIN OF results,
        status(1)         TYPE c,  "s = ok, w = warning, e = error
        servicename       TYPE string,
        serviceversion(4) TYPE c,
        servicetitle      TYPE string,
        servicestatus     TYPE string,
        aliastitle        TYPE string,
        statusalais(1)    TYPE c,  "s = ok, w = warning, e = error
        alias             TYPE string,
        aliasstatus       TYPE string,
        statusicf(1)      TYPE c,  "s = ok, w = warning, e = error
        icfstitle         TYPE string,
        icfstatus         TYPE string,
      END OF results.


    DATA: lt_results TYPE TABLE OF results,
          ls_results TYPE results.

    DATA lv_msg TYPE c LENGTH 220.
    DATA lv_str1 TYPE string.
    DATA lv_str2 TYPE string.
    DATA lv_str3 TYPE string.

    DATA sep(1)  TYPE c VALUE ' '.

    DATA lv_raise_error TYPE boolean.
    DATA lv_raise_warn TYPE boolean.

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

    " set alias
    lv_alias = i_alias.

    "set processing mode
    IF lv_alias IS INITIAL.
      lv_processing_mode = /iwfnd/if_mgw_core_types=>gcs_process_mode-co_deployed_only.
    ELSE.
      lv_processing_mode = /iwfnd/if_mgw_core_types=>gcs_process_mode-routing_based.
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

      " do not execute, if services are not checked again
      IF i_changed EQ 'X'.
        RAISE error_occured.
      ENDIF.

      IF i_services_activation IS INITIAL.

        MESSAGE e000 WITH 'No OData Services defined'(101) INTO if_stctm_task~pr_log->dummy.
        if_stctm_task~pr_log->add_syst( ).

        RAISE error_occured.
      ENDIF.

    ELSE. " execution mode

      " retrieve technical services for alias
      TRY.
          lo_exploration = /iwfnd/cl_med_rem_exploration=>get_remote_explorer( ).
          lo_exploration->get_bep_service_groups(
            EXPORTING iv_system_alias       = lv_alias
            IMPORTING et_service_groups     = lt_bep_services
                      et_return             = lt_return
                      ev_bep_not_supported  = lv_bep_not_supported ).

        CATCH /iwfnd/cx_med_remote INTO lx_med_remote.

          MESSAGE e000 WITH 'System could not be reached'(102) INTO if_stctm_task~pr_log->dummy.
          if_stctm_task~pr_log->add_syst( ).

          RAISE error_occured.

        CATCH /iwfnd/cx_destin_finder INTO lx_destin_finder .

          MESSAGE e000 WITH 'System Alias not found'(103) INTO if_stctm_task~pr_log->dummy.
          if_stctm_task~pr_log->add_syst( ).

          RAISE error_occured.

      ENDTRY.

      " system is not a backend event publisher
      IF lv_bep_not_supported EQ abap_true.

        MESSAGE e000 WITH 'System is not a Backend Event Publisher'(104) INTO if_stctm_task~pr_log->dummy.
        if_stctm_task~pr_log->add_syst( ).

        RAISE error_occured.

      ENDIF.

      " check for issues
      IF lt_return IS NOT INITIAL.
        SORT lt_return BY type.   "first to find is abbort
        LOOP AT lt_return INTO ls_return WHERE type = 'E' OR type = 'A'.

          "-----Do not use Abbort or Error message type because then the transaction will be left
          MESSAGE e000 WITH ls_return-id ls_return-message INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

        ENDLOOP.
        RAISE error_occured.
      ENDIF.

      "service activation
      TRY .
          lo_config_facade = /iwfnd/cl_cof_facade=>get_instance( ).

        CATCH /iwfnd/cx_med_remote INTO lx_med_remote.

          MESSAGE e000 WITH 'Get instance failed' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          RAISE error_occured.

      ENDTRY.

      CLEAR: lt_results.

      " for each service
      LOOP AT i_services_activation INTO ls_services_activation.

        " set alias
        lv_alias = i_alias.

        " clear
        CLEAR: lv_service_name, lv_service_version, lv_service_name_bep, lv_active, lv_service_id, lv_service_name_tech.
        CLEAR: lt_services_data, ls_services_data.
        CLEAR: lt_split, lv_count.
        CLEAR: ls_results.

        " log
        ls_results-servicetitle = 'Service:'(105).
        ls_results-aliastitle = 'Alias:'(106).
        ls_results-icfstitle = 'ICF Node:'(107).

        " set service name
        lv_service_name = ls_services_activation-service.

        ls_results-servicename = lv_service_name.

        " set service version; if version is initial set to 0001
        IF ls_services_activation-version IS INITIAL.
          lv_service_version = '0001'.
        ELSE.
          lv_service_version = ls_services_activation-version.
        ENDIF.

        " log
        ls_results-serviceversion = lv_service_version.
        SHIFT ls_results-serviceversion  LEFT DELETING LEADING '0'.

        " service was not selected
        IF ls_services_activation-selected = ' '.

          ls_results-status = 's'.
          ls_results-servicestatus = 'deselected'(113).
          ls_results-aliasstatus = '-'.
          ls_results-icfstatus = '-'.

        ELSE.

          " SERVICE ACTIVATION
          lv_service_nspace = '%'.

          "check if namespace as prefix is available (eg. /iwdnf/service_xyz)
          IF lv_service_name CS '/'.

            "1. replace / with space
            TRANSLATE lv_service_name USING '/ '.

            "2. trim start and end
            SHIFT lv_service_name RIGHT DELETING TRAILING space.
            SHIFT lv_service_name LEFT  DELETING LEADING space.

            "3. split and take last string as service_name
            SPLIT lv_service_name AT space INTO TABLE lt_split.

            "->take last row as service name
            DESCRIBE TABLE lt_split LINES lv_count.
            READ TABLE lt_split INDEX lv_count INTO lv_service_name.
            READ TABLE lt_split INDEX lv_count - 1 INTO lv_service_nspace.

            lv_service_nspace = '%' && lv_service_nspace && '%'.

          ENDIF.

          " remove speical charaters
          lv_ipstr = lv_service_name.

          CALL FUNCTION 'SCP_REPLACE_STRANGE_CHARS'
            EXPORTING
              intext            = lv_ipstr
              replacement       = 32  "space
            IMPORTING
              outtext           = lv_opstr
            EXCEPTIONS
              invalid_codepage  = 1
              codepage_mismatch = 2
              internal_error    = 3
              cannot_convert    = 4
              fields_not_type_c = 5
              OTHERS            = 6.

          IF sy-subrc <> 0.
            MESSAGE w000 WITH 'Replace strange characters for' lv_ipstr  INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).
            RAISE warning_occured.

          ELSE.
            CONDENSE lv_opstr NO-GAPS.

          ENDIF.

          lv_service_name = lv_opstr.

          " get servicename from local service table
          SELECT SINGLE * FROM /iwfnd/i_med_srh INTO ls_services_data
                          WHERE service_name = lv_service_name
                          AND namespace LIKE lv_service_nspace
                          AND service_version = lv_service_version ##WARN_OK.

          " if avialable do not create
          IF sy-subrc = 0.
            lv_service_name = ls_services_data-object_name.
            lv_service_id = ls_services_data-srv_identifier.
            lv_active = ls_services_data-is_active.

            CONCATENATE  ls_services_data-namespace ls_services_data-service_name INTO lv_service_name_bep.

            IF lv_task_selected = '02' .

              ls_results-status = 's'.
              ls_results-servicestatus = 'available'(114).

            ELSE.

              IF lv_processing_mode = /iwfnd/if_mgw_core_types=>gcs_process_mode-co_deployed_only.

                IF ls_services_data-process_mode <> 'C'.
                ls_results-status = 'w'.
                ls_results-servicestatus = 'diff. proc. mode'(123).
              ELSE.
                ls_results-status = 's'.
                ls_results-servicestatus = 'available'(114).
              ENDIF.

              ELSE. " routing-based

                IF ls_services_data-process_mode <> ' '.
                ls_results-status = 'w'.
                ls_results-servicestatus = 'diff. proc. mode'(123).

                  " means it is co-deployed, no alias assignment
                  lv_alias = ''.
                  ls_results-statusalais = 'w'.
                  ls_results-aliasstatus = 'not possible'(125).

              ELSE.
                ls_results-status = 's'.
                ls_results-servicestatus = 'available'(114).
              ENDIF.

            ENDIF.

            ENDIF.

            " create service
          ELSE.

            IF lv_task_selected = '02' .

              " skip activation, Odata service
              ls_results-status = 'e'.
              ls_results-servicestatus = 'not available'(110).
              ls_results-aliasstatus = '-'.
              ls_results-icfstatus = '-'.

          ELSE.

            IF lv_active IS INITIAL.

              " get data from retrieved table
              READ TABLE lt_bep_services INTO ls_bep_service WITH KEY external_name = lv_service_name
                                                                      version = lv_service_version.

              " if not availbale in retrieved table, set error
              IF sy-subrc <> 0.

                ls_results-status = 'e'.
                ls_results-servicestatus = 'not found'(108).
                ls_results-aliasstatus = '-'.
                ls_results-icfstatus = '-'.

                " else continue creation
              ELSE.

                " add namespace to name
                CONCATENATE  ls_bep_service-namespace ls_bep_service-external_name INTO lv_service_name_bep.

                " activate service
                TRY.
                    CALL METHOD lo_config_facade->activate_service
                      EXPORTING
                        iv_service_name_bep    = lv_service_name_bep
                        iv_service_version_bep = lv_service_version
                        iv_prefix              = lv_prefix_cust
                          iv_system_alias        = lv_alias
                        iv_package             = lv_devclass
                        iv_transport_dev       = lv_request_work
                        iv_transport_cust      = lv_request_cust
                        iv_shorten_long_names  = abap_true
                        iv_suppress_dialog     = abap_true
                        iv_process_mode        = lv_processing_mode
                      IMPORTING
                        ev_srg_identifier      = lv_service_id    "zservice_0001
                        ev_tech_service_name   = lv_service_name_tech.   "zSERVCIE


                    ls_results-status = 's'.
                    ls_results-servicestatus = 'created'(115).


                  CATCH /iwfnd/cx_cof INTO lx_cof.

                    ls_results-status = 'e'.

                ENDTRY.

                  " re-check
                IF ls_results-status = 'e'.

                    " check for 20 sec if service was created
                    DO 10 TIMES.
                      " get servicename from local service table
                      SELECT SINGLE * FROM /iwfnd/i_med_srh INTO @DATA(ls_services_check)
                                      WHERE service_name = @lv_service_name
                                      AND namespace LIKE @lv_service_nspace
                                      AND service_version = @lv_service_version ##WARN_OK.

                      IF sy-subrc = 0. "ok
                      ls_results-status = 's'.
                      ls_results-servicestatus = 'created'(115).
                        EXIT.
                      ELSE. "not ok
                      ls_results-status = 'e'.
                      ls_results-servicestatus = 'failed'(116).
                      ENDIF.

                      WAIT UP TO 2 SECONDS.

                    ENDDO.

                ENDIF.

              ENDIF.

            ELSE.

              " service available but not active
              ls_results-status = 'w'.
              ls_results-servicestatus = 'available, but not active'(109).
              ls_results-aliasstatus = '-'.
              ls_results-icfstatus = '-'.

            ENDIF.

          ENDIF.

          ENDIF.

          "HASH KEY
          TRY .
              CALL METHOD lo_config_facade->get_hash_value_of_service
                EXPORTING
                  iv_srg_identifier  = lv_service_id
                IMPORTING
                  ev_hash_value      = lv_hash_value
                  ev_hash_value_type = lv_hash_value_type.

            CATCH /iwfnd/cx_cof INTO lx_cof.

          ENDTRY.


          "ALIAS ASSIGNMENT

          IF lv_alias IS NOT INITIAL.

            IF lv_service_id  IS NOT INITIAL.

              "get aliases for service
              TRY.
                  lt_sys_aliases = lo_config_facade->get_sys_aliases_of_srv( lv_service_id ).

                CATCH /iwfnd/cx_cof INTO lx_cof.
                  ls_results-statusalais = 'e'.
                  ls_results-aliasstatus = 'failed'(116).
              ENDTRY.


              "check if alais is already assigned
              READ TABLE lt_sys_aliases WITH KEY system_alias = lv_alias TRANSPORTING NO FIELDS.

              IF sy-subrc = 0.

                " alias is already available
                ls_results-statusalais = 's'.
                ls_results-aliasstatus = 'available'(114).

              ELSE.

                IF lv_task_selected <> '02'.

                  "add alias
                TRY .
                    lo_config_facade->assign_sys_alias_to_srv(
                           EXPORTING
                               iv_transport_cust = lv_request_cust
                             iv_srg_identifier = lv_service_id
                               iv_system_alias   = lv_alias  ).

                    ls_results-statusalais = 's'.
                    ls_results-aliasstatus = 'assigned'(120).

                  CATCH /iwfnd/cx_cof INTO lx_cof.
                    ls_results-statusalais = 'e'.
                    ls_results-aliasstatus = 'failed'(116).
                ENDTRY.

                ENDIF.

              ENDIF.

            ENDIF.

          ELSE.

            IF ls_results-statusalais IS INITIAL.

              ls_results-statusalais = 's'.
            ls_results-aliasstatus = 'assigned'(120).

          ENDIF.

          ENDIF.

          ENDIF.


        "ICF STATUS
          IF lv_service_name_bep IS NOT INITIAL.

            DATA: lv_icf_node_exists TYPE abap_bool.
            DATA: lv_icf_node_is_active TYPE abap_bool.

            " activate ICF Node
            TRY .
                lo_config_facade->activate_icf_node_of_srv( iv_service_name_bep = lv_service_name_bep ).

              CATCH /iwfnd/cx_cof INTO lx_cof.

            ENDTRY.

            CLEAR: lx_cof.

            TRY .

                " check ICF Note
                lo_config_facade->check_icf_node(
                  EXPORTING
                    iv_service_name_bep    = lv_service_name_bep
                  IMPORTING
                    ev_icf_node_exists     = lv_icf_node_exists
                    ev_icf_node_is_active  = lv_icf_node_is_active
                     ).

                IF lv_icf_node_exists = ' '.
                ls_results-statusicf = 'e'.
                  ls_results-icfstatus = 'not available'(110).
                ELSE.

                  IF lv_icf_node_is_active = ' '.
                    ls_results-statusicf = 'w'.
                    ls_results-icfstatus = 'deactivated'(118).
                  ELSE.
                    ls_results-statusicf = 's'.
                    ls_results-icfstatus = 'activated'(119).
                  ENDIF.

                ENDIF.

              CATCH /iwfnd/cx_cof INTO lx_cof.
                ls_results-statusicf = 'e'.
                ls_results-icfstatus = 'failed'(116).
            ENDTRY.

          ENDIF.

        " finalize result
        APPEND ls_results TO lt_results.

      ENDLOOP.

***************** PREPARE LOGRESULTS *****************

      " HEADER - log output services
      IF lv_task_selected = '02'.

        lv_msg = | OData ICF Activation mode only: | ##NO_TEXT.
        if_stctm_task~pr_log->add_text( EXPORTING i_type = 'S' i_text = lv_msg ).

      ELSE.

      " log output transport settings
      IF lv_devclass CS '$'.
        lv_request_work = 'not required' ##NO_TEXT.
        lv_request_cust = 'not required' ##NO_TEXT.
      ENDIF.

      lv_msg = | Prefix: { lv_prefix_cust }; Package: { lv_devclass } | ##NO_TEXT.
      if_stctm_task~pr_log->add_text( EXPORTING i_type = 'S' i_text = lv_msg ).

      lv_msg = | Workbench Request: { lv_request_work }; Customizing Request: { lv_request_cust } | ##NO_TEXT.
      if_stctm_task~pr_log->add_text( EXPORTING i_type = 'S' i_text = lv_msg ).


        IF lv_processing_mode = /iwfnd/if_mgw_core_types=>gcs_process_mode-routing_based.
        " log output alias
        MESSAGE s000 WITH 'Processing mode: Routing based'(121) '/ System Alias:'(117) i_alias INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN.
        if_stctm_task~pr_log->add_syst( ).

      ELSE.
        MESSAGE s000 WITH 'Processing mode: Co-deployed only'(122) INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN.
        if_stctm_task~pr_log->add_syst( ).
        ENDIF.

      ENDIF.

      " DETAILS - log output services
      LOOP AT lt_results INTO ls_results.

        CONCATENATE ls_results-servicetitle ls_results-servicename ls_results-serviceversion ls_results-servicestatus INTO lv_str1 SEPARATED BY sep .

        IF lv_processing_mode = /iwfnd/if_mgw_core_types=>gcs_process_mode-routing_based.
          CONCATENATE '/' ls_results-aliastitle ls_results-aliasstatus INTO lv_str2 SEPARATED BY sep.
        ELSE.
          CONCATENATE '/' ls_results-icfstitle ls_results-icfstatus INTO lv_str3 SEPARATED BY sep.
        ENDIF.

        " SUCCESS
        IF ls_results-status = 's' AND ls_results-statusalais = 's' AND ls_results-statusicf = 's'.

          MESSAGE s000 WITH lv_str1 lv_str2 lv_str3 INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          " WARNING
        ELSEIF ls_results-status = 'w' OR ls_results-statusalais = 'w' AND ls_results-statusicf = 'w'.

          MESSAGE w000 WITH lv_str1 lv_str2 lv_str3 INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
          lv_raise_warn =  abap_true.

          " ERROR
        ELSEIF ls_results-status = 'e' OR ls_results-statusalais = 'e' OR ls_results-statusicf = 'e'.

          " NOT FOUND or API ERROR -> alias status is blank (skip Alias, ICF log output)
          IF ls_results-statusalais IS INITIAL.

            MESSAGE e000 WITH lv_str1  INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).

          ELSE.

            MESSAGE e000 WITH lv_str1 lv_str2 lv_str3 INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).

          ENDIF.

          lv_raise_error =  abap_true.

        ELSE.

          IF ls_results-servicestatus ='deselected'.

            MESSAGE w000 WITH lv_str1 INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).

          ELSE.

            MESSAGE w000 WITH lv_str1 lv_str2 lv_str3 INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).

          ENDIF.

          lv_raise_warn =  abap_true.

        ENDIF.

      ENDLOOP.

      " raise error / warning
      IF lv_raise_error =  abap_true.

        if_stctm_task~pr_log->add_text(
          EXPORTING
            i_type        = 'E'    " Message type
            i_text        = 'For detailed analysis activate failed service manually with transaction /iwfnd/maint_service'
            i_details     = 'X'
        ) ##NO_TEXT.

        MESSAGE e000 WITH 'For support open Fiori Apps Library:'  'https://fioriappslibrary.hana.ondemand.com' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        MESSAGE e000 WITH 'Search for Odata service and'  'check SUPPORT for component' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        RAISE error_occured.
      ELSEIF lv_raise_warn =  abap_true.
        RAISE warning_occured.
      ENDIF.

    ENDIF.

  ENDMETHOD.