METHOD IF_STCTM_BG_TASK~EXECUTE.

  DATA: ls_icfinstact TYPE icfinstact.
  DATA: lv_dbcnt TYPE sy-dbcnt.
  DATA: ls_url TYPE icfinstact.
  DATA: ls_url1 TYPE icfurlbuf.
  DATA: lv_errtext TYPE string.
  DATA: lt_url TYPE TABLE OF icfinstact.
  DATA: lv_error TYPE abap_bool VALUE abap_false.

* Define Services to be activated

  " check for services in ICFINSTACT
  SELECT * FROM icfinstact INTO ls_icfinstact
          WHERE name = 'SB_APPS'.

    lv_dbcnt = sy-dbcnt.

    IF lv_dbcnt = 1.
      REFRESH lt_url.
      APPEND ls_icfinstact TO lt_url.
    ELSE.
      APPEND ls_icfinstact TO lt_url.
    ENDIF.

  ENDSELECT.

  " if icfinstact is not filled, fill manually
  IF lt_url IS INITIAL.

    " bsp
    CLEAR ls_url.
    MOVE '/sap/bc/bsp/sap/sbrt_appss1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/bsp/sap/sb_apps_assocs1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/bsp/sap/sb_apps_dds1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/bsp/sap/sb_apps_evals1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/bsp/sap/sb_apps_kpis1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/bsp/sap/sb_apps_libs1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/bsp/sap/sb_apps_tiles1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/bsp/sap/sb_apps_wss1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/bsp/sap/ssbtileslibs1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/bsp/sap/ssbtiless1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/bsp/sap/analyticsdts1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    " ui5_ui5
    CLEAR ls_url.
    MOVE '/sap/bc/ui5_ui5/sap/sbrt_appss1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/ui5_ui5/sap/sb_apps_assocs1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/ui5_ui5/sap/sb_apps_dds1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/ui5_ui5/sap/sb_apps_evals1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/ui5_ui5/sap/sb_apps_kpis1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/ui5_ui5/sap/sb_apps_libs1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/ui5_ui5/sap/sb_apps_tiles1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/ui5_ui5/sap/sb_apps_wss1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/ui5_ui5/sap/ssbtileslibs1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/ui5_ui5/sap/ssbtiless1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

    CLEAR ls_url.
    MOVE '/sap/bc/ui5_ui5/sap/analyticsdts1' TO ls_url-path.
    MOVE ' ' TO ls_url-expand.
    APPEND ls_url TO lt_url.

  ENDIF.

  IF i_check = 'X'.

* check authorization
    cl_stct_setup_utilities=>check_authority(
    EXCEPTIONS
      no_authority  = 1
      OTHERS        = 2 ).
    IF sy-subrc <> 0.
      if_stctm_task~pr_log->add_syst( ).
      RAISE error_occured.
    ENDIF.

    CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
      EXPORTING
        tcode  = 'SICF'
      EXCEPTIONS
        ok     = 0
        not_ok = 1
        OTHERS = 2.
    IF sy-subrc NE 0.
      MESSAGE e172(00) WITH 'SICF' INTO if_stctm_task~pr_log->dummy.
      if_stctm_task~pr_log->add_syst( ).
      RAISE error_occured.
    ENDIF.
    AUTHORITY-CHECK OBJECT 'S_ADMI_FCD'
                    ID 'S_ADMI_FCD' FIELD 'NADM'.
    IF sy-subrc NE 0.
      MESSAGE e150(00) WITH 'Network administration'(001) INTO if_stctm_task~pr_log->dummy.
      if_stctm_task~pr_log->add_syst( ).
      RAISE error_occured.
    ENDIF.

    MESSAGE i005 INTO if_stctm_task~pr_log->dummy.
    if_stctm_task~pr_log->add_syst( ).

  ELSE.

****************************************************************************************************
* SICF service activation out of lt_url
****************************************************************************************************

    LOOP AT lt_url INTO ls_url.

      " cast type
      ls_url1 = ls_url-path.

      CALL FUNCTION 'HTTP_ACTIVATE_NODE'
        EXPORTING
*         nodeguid                 = lv_guid
          url                      = ls_url1
*         hostname                 =
          expand                   = ls_url-expand
        EXCEPTIONS
          node_not_existing        = 1
          enqueue_error            = 2
          no_authority             = 3
          url_and_nodeguid_space   = 4
          url_and_nodeguid_fill_in = 5
          OTHERS                   = 6.

      IF sy-subrc = 0.
        TRANSLATE ls_url-path TO LOWER CASE.
        MESSAGE s102 WITH ls_url-path INTO if_stctm_task~pr_log->dummy.
        if_stctm_task~pr_log->add_syst( ).
      ELSEIF sy-subrc = 1.

        "not available, do nothing could be release dependent

      ELSE.
        CASE sy-subrc.
          WHEN '1'.
            lv_errtext = 'Service not available'(002).
          WHEN '2'.
            lv_errtext  = 'Lock error'(003).
          WHEN '3'.
            lv_errtext  = 'No authorization'(004).
          WHEN OTHERS.
            lv_errtext  = 'Other error'(005).
        ENDCASE.

        TRANSLATE ls_url-path TO LOWER CASE.
        MESSAGE e103 WITH ls_url-path lv_errtext INTO if_stctm_task~pr_log->dummy.
        if_stctm_task~pr_log->add_syst( ).
        lv_error = abap_true.
      ENDIF.

    ENDLOOP.

    IF lv_error = abap_true.
      RAISE error_occured.
    ENDIF.

  ENDIF."End of execution

ENDMETHOD.