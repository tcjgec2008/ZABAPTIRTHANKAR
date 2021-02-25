METHOD if_stctm_bg_task~execute.

  DATA ls_variant TYPE t_variant.

  DATA: lv_dest  TYPE rfcdest,
        lv_desc  TYPE rfcdoc_d,
        lv_host  TYPE rfcdisplay-rfchost,
        lv_sysnr TYPE rfcdisplay-rfcsysid,
        lv_path  TYPE string,
        lv_clnt  TYPE rfcclient,
        lv_trrel TYPE rfcslogin,
        lv_cuser TYPE rfcsameusr,
        lv_https TYPE rfclbflag,
        lv_cert  TYPE ssfapplssl.

  DATA: ls_except TYPE bapiret2.

  DATA: lv_cusal TYPE c LENGTH 10.
  DATA: lv_timest TYPE tzntstmps.

  DATA: lv_mapal TYPE c LENGTH 10.
  DATA: lv_maprfc TYPE c LENGTH 26.
  DATA: lv_mapcl TYPE c LENGTH 3.

  DATA: it_e071  TYPE tr_objects ##NEEDED,
        it_e071k TYPE tr_keys,
        wa_e071  TYPE ko200,
        wa_e071k TYPE e071k.

  DATA: lv_tabkey TYPE c LENGTH 120.


*----------------------------------------------------------------
* GET UI PARAMETER
*----------------------------------------------------------------
  LOOP AT pt_variant INTO ls_variant.
    CASE  ls_variant-selname.

      WHEN 'P_DEST'.
        lv_dest = ls_variant-low.
      WHEN 'P_DESC'.
        lv_desc = ls_variant-low.
      WHEN 'P_HOST'.
        lv_host  = ls_variant-low.
      WHEN 'P_SYSNR'.
        lv_sysnr = ls_variant-low.
      WHEN 'P_PATH'.
        lv_path = ls_variant-low.
      WHEN 'P_CUSAL'.
        lv_cusal  = ls_variant-low.
      WHEN 'P_MAPAL'.
        lv_mapal = ls_variant-low.
      WHEN 'P_MAPRFC'.
        lv_maprfc = ls_variant-low.
      WHEN 'P_MAPCL'.
        lv_mapcl = ls_variant-low.

    ENDCASE.
  ENDLOOP.

*----------------------------------------------------------------
* GET REQUEST WORK
*----------------------------------------------------------------

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
        MESSAGE e000 WITH 'Could not get Request from Task CREATE WORKBENCH REQUEST' INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.
    ENDTRY.
  ENDIF.

**----------------------------------------------------------------
** GET RFC FROM PREDCESSOR TASK CL_STCT_CREATE_RFC_GW2SAP_V1
**----------------------------------------------------------------
*
  DATA ls_task TYPE cl_stctm_tasklist=>ts_task.

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

    " check if required predecessor task "Create/Select WorkbenchRequest (SE09)" is in tasklist
    READ TABLE ir_tasklist->ptx_task INTO ls_task WITH KEY taskname = 'CL_STCT_CREATE_REQUEST_WBENCH'.

    IF sy-subrc NE 0.
      MESSAGE e124 WITH 'Create Workbench Request (SE09)' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
      if_stctm_task~pr_log->add_syst( ).
      RAISE error_occured.
    ENDIF.

  ELSE. " execution mode

    DATA lo_dest_factory TYPE REF TO cl_dest_factory.

    CREATE OBJECT lo_dest_factory.
    DATA(lv_rfc_https_exists) = lo_dest_factory->exists( name = lv_dest ).

    IF lv_rfc_https_exists = abap_true. " destination already exists
      MESSAGE s046(s_lmcfg_core_tasks) WITH lv_dest INTO if_stctm_task~pr_log->dummy.
      if_stctm_task~pr_log->add_syst( ).
    ELSE.

      CALL FUNCTION 'RFC_MODIFY_HTTP_DEST_TO_R3'
        EXPORTING
          destination                = lv_dest
          action                     = 'I'
          authority_check            = 'X'
          servicenr                  = lv_sysnr
          server                     = lv_host
          path_prefix                = lv_path
          client                     = sy-mandt
          same_user                  = 'X'
          description                = lv_desc
          sslapplic                  = 'DFAULT'
          logon_method               = 'T'
          ssl                        = 'X'
        EXCEPTIONS
          authority_not_available    = 1
          destination_already_exist  = 2
          destination_not_exist      = 3
          destination_enqueue_reject = 4
          information_failure        = 5
          trfc_entry_invalid         = 6
          internal_failure           = 7
          snc_information_failure    = 8
          snc_internal_failure       = 9
          destination_is_locked      = 10
          invalid_parameter          = 11
          OTHERS                     = 12.

      IF sy-subrc <> 0.
        ls_except-type = 'E'.
        CASE sy-subrc.
          WHEN 1.
            ls_except-message = 'AUTHORITY_NOT_AVAILABLE'.
          WHEN 2.
            ls_except-message = 'DESTINATION_ALREADY_EXIST'.
          WHEN 3.
            ls_except-message = 'DESTINATION_NOT_EXIST'.
          WHEN 4.
            ls_except-message = 'DESTINATION_ENQUEUE_REJECT'.
          WHEN 5.
            ls_except-message = 'INFORMATION_FAILURE'.
          WHEN 6.
            ls_except-message = 'TRFC_ENTRY_INVALID'.
          WHEN 7.
            ls_except-message = 'INTERNAL_FAILURE'.
          WHEN 8.
            ls_except-message = 'SNC_INFORMATION_FAILURE'.
          WHEN 9.
            ls_except-message = 'SNC_INTERNAL_FAILURE'.
          WHEN 10.
            ls_except-message = 'DESTINATION_IS_LOCKED'.
          WHEN 11.
            ls_except-message = 'INVALID_PARAMETER'.
          WHEN OTHERS.
            ls_except-message = 'UNEXPECTED_EXCEPTION_OCCURED'.
        ENDCASE.

        if_stctm_task~pr_log->add_bapiret( ls_except ).
        RAISE error_occured.
      ENDIF.

      MESSAGE s037 WITH lv_dest INTO if_stctm_task~pr_log->dummy.
      if_stctm_task~pr_log->add_syst( ).

    ENDIF.

    " customer system alias /UI2/VC_SYSALIAS -> /UI2/C_SYSALIAS
    DATA: lt_c_sysalias TYPE STANDARD TABLE OF /ui2/c_sysalias.
    DATA: ls_c_sysalias LIKE LINE OF lt_c_sysalias.

    " check if entry exists
    SELECT COUNT( * ) FROM /ui2/c_sysalias UP TO 1 ROWS WHERE sys_alias = lv_cusal. "#EC CI_BYPASS

    IF sy-subrc = 0. "already available
      MESSAGE s357(s_lmcfg_core_tasks) WITH lv_cusal INTO if_stctm_task~pr_log->dummy.
      if_stctm_task~pr_log->add_syst( ).

    ELSE.

      ls_c_sysalias-sys_alias = lv_cusal.
      ls_c_sysalias-changed_by = sy-uname.
      ls_c_sysalias-changed_at = sy-datum && sy-uzeit.

      " create object entry
      wa_e071-trkorr    = lv_request_work.
      wa_e071-pgmid     = 'R3TR'.
      wa_e071-object    = 'VDAT'.
      wa_e071-obj_name  = '/UI2/VC_SYSALIAS'.
      wa_e071-objfunc     = 'K'.

      APPEND wa_e071  TO it_e071.

      " create key entry for /UI2/C_SYSALIAS
      wa_e071k-trkorr   = lv_request_work.
      wa_e071k-pgmid    = 'R3TR'.
      wa_e071k-object   = 'TABU'.
      wa_e071k-objname = '/UI2/C_SYSALIAS'.
      wa_e071k-tabkey   = ls_c_sysalias-sys_alias.
      wa_e071k-mastertype = wa_e071-object.
      wa_e071k-mastername = wa_e071-obj_name.

      APPEND wa_e071k TO it_e071k.

      " check objects
      CALL FUNCTION 'TR_OBJECT_CHECK'
        EXPORTING
          wi_ko200                = wa_e071
          iv_no_show_option       = 'X'
        TABLES
          wt_e071k                = it_e071k
        EXCEPTIONS
          cancel_edit_other_error = 1
          show_only_other_error   = 2
          OTHERS                  = 3.

      IF sy-subrc <> 0.
        MESSAGE e000 WITH 'Object check failed' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.
      ENDIF.

      " insert objects
      CALL FUNCTION 'TR_OBJECT_INSERT'
        EXPORTING
          wi_order                = lv_request_work
          wi_ko200                = wa_e071
          iv_no_show_option       = 'X'
        TABLES
          wt_e071k                = it_e071k
        EXCEPTIONS
          cancel_edit_other_error = 1
          show_only_other_error   = 2
          OTHERS                  = 3.
      IF sy-subrc <> 0.
        MESSAGE e000 WITH 'Object insert failed' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.

      ELSE.

        " insert table
        INSERT /ui2/c_sysalias FROM ls_c_sysalias.

        MESSAGE s356(s_lmcfg_core_tasks) WITH lv_cusal INTO if_stctm_task~pr_log->dummy.
        if_stctm_task~pr_log->add_syst( ).

        MESSAGE i000 WITH 'Object added to Workbench Request' lv_request_work INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

      ENDIF.
    ENDIF.

    " alias map /UI2/V_ALIASMAP -> /UI2/SYSALIASMAP
    " check if entry exists
    DATA: lt_sysaliasmap TYPE STANDARD TABLE OF /ui2/sysaliasmap.
    DATA: ls_sysaliasmap LIKE LINE OF lt_sysaliasmap.

    " check if entry exists
    SELECT COUNT( * ) FROM /ui2/sysaliasmap UP TO 1 ROWS WHERE sysalias_src = lv_mapal. "#EC CI_BYPASS

    IF sy-subrc = 0. "already available
      MESSAGE s359(s_lmcfg_core_tasks) WITH lv_cusal INTO if_stctm_task~pr_log->dummy.
      if_stctm_task~pr_log->add_syst( ).

    ELSE.

      ls_sysaliasmap-client = lv_mapcl.
      ls_sysaliasmap-sysalias_src = lv_mapal.
      ls_sysaliasmap-sysalias_tgt = lv_maprfc.
      ls_sysaliasmap-changed_at = sy-datum && sy-uzeit.

      " create object entry
      wa_e071-trkorr    = lv_request_work.
      wa_e071-pgmid     = 'R3TR'.
      wa_e071-object    = 'VDAT'.
      wa_e071-obj_name  = '/UI2/V_ALIASMAP'.
      wa_e071-objfunc     = 'K'.

      APPEND wa_e071  TO it_e071.

      " create key entry for /UI2/C_SYSALIAS
      wa_e071k-trkorr   = lv_request_work.
      wa_e071k-pgmid    = 'R3TR'.
      wa_e071k-object   = 'TABU'.
      wa_e071k-objname = '/UI2/SYSALIASMAP'.
      wa_e071k-tabkey   = ls_sysaliasmap-sysalias_src.
      wa_e071k-mastertype = wa_e071-object.
      wa_e071k-mastername = wa_e071-obj_name.
      wa_e071k-viewname = '/UI2/V_ALIASMAP'.

      APPEND wa_e071k TO it_e071k.

      " check objects
      CALL FUNCTION 'TR_OBJECT_CHECK'
        EXPORTING
          wi_ko200                = wa_e071
          iv_no_show_option       = 'X'
        TABLES
          wt_e071k                = it_e071k
        EXCEPTIONS
          cancel_edit_other_error = 1
          show_only_other_error   = 2
          OTHERS                  = 3.

      IF sy-subrc <> 0.
        MESSAGE e000 WITH 'Object check failed' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.
      ENDIF.

      " insert objects
      CALL FUNCTION 'TR_OBJECT_INSERT'
        EXPORTING
          wi_order                = lv_request_work
          wi_ko200                = wa_e071
          iv_no_show_option       = 'X'
        TABLES
          wt_e071k                = it_e071k
        EXCEPTIONS
          cancel_edit_other_error = 1
          show_only_other_error   = 2
          OTHERS                  = 3.
      IF sy-subrc <> 0.
        MESSAGE e000 WITH 'Object insert failed' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.
      ELSE.

        " insert table
        INSERT /ui2/sysaliasmap FROM ls_sysaliasmap.

        MESSAGE s358(s_lmcfg_core_tasks) WITH lv_mapal INTO if_stctm_task~pr_log->dummy.
        if_stctm_task~pr_log->add_syst( ).

        MESSAGE i000 WITH 'Object added to Workbench Request' lv_request_work INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

      ENDIF.

    ENDIF.

  ENDIF.

ENDMETHOD.