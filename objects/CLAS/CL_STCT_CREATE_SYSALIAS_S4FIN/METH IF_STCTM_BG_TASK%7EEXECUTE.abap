METHOD if_stctm_bg_task~execute.

  DATA: lv_rfcdest TYPE rfcdest. "/iwfnd/defi_system_alias.
  DATA: ls_c_dfsyal TYPE /iwfnd/c_dfsyal.

  DATA: lv_alias TYPE c LENGTH 16. "/iwfnd/defi_system_alias.

  DATA: lv_alias_custom_selected TYPE abap_bool.
  DATA: lv_alias_custom TYPE c LENGTH 16. "/iwfnd/defi_system_alias.

  DATA  ls_set_local_system_alias TYPE /iwfnd/cl_destin_finder_dba_wr=>ty_gs_dfsyal.
  DATA  lr_dest_finder TYPE REF TO /iwfnd/cl_destin_finder_dba_wr.

  DATA: lv_descr TYPE c LENGTH 40. "/iwfnd/cor_text40.
  DATA: lv_svers TYPE c LENGTH 16. "/iwfnd/inma_software_version.
  DATA: lv_wsprovider TYPE c LENGTH 120. " /iwfnd/defi_provider_system.
  DATA: lv_local_iwf TYPE boole.
  DATA: lv_is_for_bep TYPE boole.

  DATA lv_overwrite TYPE abap_bool VALUE abap_false.

  DATA ls_error TYPE scx_t100key.
  DATA lx_errorcx_destin_finder TYPE REF TO /iwfnd/cx_destin_finder.
  DATA lx_errorcx_cof TYPE REF TO /iwfnd/cx_cof.

  DATA lv_errortext TYPE bapi_msg ##NEEDED.
  DATA lv_text TYPE bapi_msg ##NEEDED.

*----------------------------------------------------------------
* GET REQUEST
*----------------------------------------------------------------

  DATA ls_task_creq TYPE cl_stctm_tasklist=>ts_task.
  DATA lo_task_creq TYPE REF TO cl_stct_create_request_cust.
  DATA lx_cast_exc_creq TYPE REF TO cx_sy_move_cast_error ##NEEDED.

  DATA lv_request_cust TYPE char20.
  DATA lv_client_changes_allowed TYPE abap_bool.

  " get stored data from prerequiste task 'CREATE CUSTOMIZING REQUEST'
  READ TABLE ir_tasklist->ptx_task INTO ls_task_creq WITH KEY taskname = 'CL_STCT_CREATE_REQUEST_CUST'.

  IF sy-subrc = 0.
    TRY.
        lo_task_creq ?= ls_task_creq-r_task.
        lv_request_cust = lo_task_creq->p_request_customizing.
        lv_client_changes_allowed = lo_task_creq->p_client_changes_allowed.

      CATCH cx_sy_move_cast_error INTO lx_cast_exc_creq.
        MESSAGE e000 WITH 'Could not get Request from Task CREATE CUSTOMIZING REQUEST' INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.
    ENDTRY.
  ENDIF.

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

    " check if required predecessor task "Create/Select Customizing Request (SE09)" is in tasklist
    READ TABLE ir_tasklist->ptx_task INTO ls_task_creq WITH KEY taskname = 'CL_STCT_CREATE_REQUEST_CUST'.

    IF sy-subrc NE 0.

      MESSAGE e124 WITH 'Create Customizing Request (SE09)' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
      if_stctm_task~pr_log->add_syst( ).
      RAISE error_occured.

    ENDIF.

  ELSE. " execution mode

    lv_alias = 'S4FIN'.
    lv_descr = 'System Alias f. Design Studio (Fin)' ##NO_TEXT.
    lv_rfcdest = 'NONE'.
    lv_svers = 'DEFAULT'.
    lv_wsprovider = ''.
    lv_local_iwf = abap_true.

    " check if alias alraedy exists
    SELECT SINGLE * FROM /iwfnd/c_dfsyal INTO ls_c_dfsyal WHERE system_alias = lv_alias.

    IF sy-subrc = 0 .
      MESSAGE s130 WITH lv_alias INTO if_stctm_task~pr_log->dummy.
      if_stctm_task~pr_log->add_syst( ).

    ELSE.

      " check lv_request_cust is not emtpy
      IF lv_request_cust IS INITIAL.

        MESSAGE e000 WITH 'No Customizing Request available' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.

      ENDIF.

      IF lv_rfcdest NE ''. " rfc destination found

        " create system alias
        ls_set_local_system_alias   = VALUE #( system_alias     = lv_alias
                                               is_local_iwf     = lv_local_iwf
                                               is_for_bep       = lv_is_for_bep
                                               software_version = lv_svers
                                               rfc_dest         = lv_rfcdest
                                               ws_provider_syst = lv_wsprovider
                                               description      = lv_descr ) ##NO_TEXT.

        TRY.
            lr_dest_finder = /iwfnd/cl_destin_finder_dba_wr=>get_destin_finder_dba_wr( ). " find rfc
            lr_dest_finder->create_dfsyal( is_dfsyal = ls_set_local_system_alias
                                           iv_transport = lv_request_cust ). " create alias

            MESSAGE s129 WITH lv_alias INTO if_stctm_task~pr_log->dummy.
            if_stctm_task~pr_log->add_syst( ).

            MESSAGE s000 WITH 'Object added to Customizing Request' lv_request_cust INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).

          CATCH /iwfnd/cx_cof INTO lx_errorcx_cof .

            lv_errortext = lx_errorcx_cof->get_text( ).

            if_stctm_task~pr_log->add_text( lv_errortext ).
            RAISE error_occured.

          CATCH /iwfnd/cx_destin_finder INTO lx_errorcx_destin_finder .

            " get message no
            ls_error = lx_errorcx_destin_finder->if_t100_message~t100key.

            IF ls_error-msgno EQ '009'. " alias already exists

              MESSAGE s130 WITH lv_alias INTO if_stctm_task~pr_log->dummy.
              if_stctm_task~pr_log->add_syst( ).

            ELSE.

              lv_errortext = lx_errorcx_destin_finder->get_text( ).

              REPLACE '&1' IN lv_errortext WITH lv_alias.

              if_stctm_task~pr_log->add_text( lv_errortext ).
              RAISE error_occured.

            ENDIF.

        ENDTRY.

      ELSE. " rfc destination not found

        MESSAGE e000 WITH 'Input Parameter RFC Destination not available' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.

      ENDIF.

    ENDIF.

**********************************************************************************************************

    lv_alias = 'S4SD'.
    lv_descr = 'System Alias f. Design Studio (Sales)' ##NO_TEXT.
    lv_rfcdest = 'NONE'.
    lv_svers = 'DEFAULT'.
    lv_wsprovider = ''.
    lv_local_iwf = abap_true.

    " check if alias alraedy exists
    SELECT SINGLE * FROM /iwfnd/c_dfsyal INTO ls_c_dfsyal WHERE system_alias = lv_alias.

    IF sy-subrc = 0 .
      MESSAGE s130 WITH lv_alias INTO if_stctm_task~pr_log->dummy.
      if_stctm_task~pr_log->add_syst( ).

    ELSE.

      " check lv_request_cust is not emtpy
      IF lv_request_cust IS INITIAL.

        MESSAGE e000 WITH 'No Customizing Request available' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.

      ENDIF.

      IF lv_rfcdest NE ''. " rfc destination found

        " create system alias
        ls_set_local_system_alias   = VALUE #( system_alias     = lv_alias
                                               is_local_iwf     = lv_local_iwf
                                               is_for_bep       = lv_is_for_bep
                                               software_version = lv_svers
                                               rfc_dest         = lv_rfcdest
                                               ws_provider_syst = lv_wsprovider
                                               description      = lv_descr ) ##NO_TEXT.

        TRY.
            lr_dest_finder = /iwfnd/cl_destin_finder_dba_wr=>get_destin_finder_dba_wr( ). " find rfc
            lr_dest_finder->create_dfsyal( is_dfsyal = ls_set_local_system_alias
                                           iv_transport = lv_request_cust ). " create alias

            MESSAGE s129 WITH lv_alias INTO if_stctm_task~pr_log->dummy.
            if_stctm_task~pr_log->add_syst( ).

            MESSAGE s000 WITH 'Object added to Customizing Request' lv_request_cust INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).

          CATCH /iwfnd/cx_cof INTO lx_errorcx_cof .

            lv_errortext = lx_errorcx_cof->get_text( ).

            if_stctm_task~pr_log->add_text( lv_errortext ).
            RAISE error_occured.

          CATCH /iwfnd/cx_destin_finder INTO lx_errorcx_destin_finder .

            " get message no
            ls_error = lx_errorcx_destin_finder->if_t100_message~t100key.

            IF ls_error-msgno EQ '009'. " alias already exists

              MESSAGE s130 WITH lv_alias INTO if_stctm_task~pr_log->dummy.
              if_stctm_task~pr_log->add_syst( ).

            ELSE.

              lv_errortext = lx_errorcx_destin_finder->get_text( ).

              REPLACE '&1' IN lv_errortext WITH lv_alias.

              if_stctm_task~pr_log->add_text( lv_errortext ).
              RAISE error_occured.

            ENDIF.

        ENDTRY.

      ELSE. " rfc destination not found

        MESSAGE e000 WITH 'Input Parameter RFC Destination not available' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.

      ENDIF.

    ENDIF.

  ENDIF.

ENDMETHOD.