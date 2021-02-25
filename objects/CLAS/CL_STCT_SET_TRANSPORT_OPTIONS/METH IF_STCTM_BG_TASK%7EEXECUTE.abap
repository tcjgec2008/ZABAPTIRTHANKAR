METHOD if_stctm_bg_task~execute.

  DATA ls_variant TYPE t_variant.

  DATA lv_auth_object(10) TYPE c.
  DATA lv_activity(2)     TYPE c.

  DATA: lv_prefix TYPE string.
  DATA: lv_pack TYPE devclass.

  DATA: lv_layer TYPE tcetral-translayer.
  DATA: lv_translayer TYPE bapiscts02.
  DATA: lv_descr TYPE text60.
  DATA: lv_choice_selected TYPE abap_bool.
  DATA: lv_request_selected TYPE char20.
  DATA: lv_allow_changes TYPE abap_bool.

  DATA: lv_descr_c TYPE text60.
  DATA: lv_choice_selected_c TYPE abap_bool.
  DATA: lv_request_selected_c TYPE char20.
  DATA: lv_allow_changes_c TYPE abap_bool.


  DATA: lt_t000 TYPE STANDARD TABLE OF t000,
        ls_t000 LIKE LINE OF lt_t000.

  DATA: lv_request TYPE char20.
  DATA: ls_message TYPE bapiret2.

  DATA lt_authorlist TYPE TABLE OF bapiscts12.
  DATA lt_tasklist TYPE TABLE OF bapiscts07.
  DATA ls_tasklist LIKE LINE OF lt_tasklist.

  DATA: lv_task TYPE char20.

  DATA: lv_count TYPE i.
  DATA: lv_bapi_msg TYPE bapi_msg.


*----------------------------------------------------------------
* GET UI PARAMETER
*----------------------------------------------------------------
  LOOP AT pt_variant INTO ls_variant.
    CASE  ls_variant-selname.

      WHEN 'P_PREFIX'.
        lv_prefix = ls_variant-low.
      WHEN 'P_PACK'.
        lv_pack = ls_variant-low.


      WHEN 'P_DESCR'.
        lv_descr  = ls_variant-low.

      WHEN 'P_OPT2'.
        lv_choice_selected   = ls_variant-low.

      WHEN 'P_CHCK'.
        lv_allow_changes = ls_variant-low.

      WHEN 'P_TR'.
        lv_request_selected  = ls_variant-low.


      WHEN 'P_DESCRC'.
        lv_descr_c  = ls_variant-low.

      WHEN 'P_OPT2C'.
        lv_choice_selected_c   = ls_variant-low.

      WHEN 'P_TRC'.
        lv_request_selected_c  = ls_variant-low.

      WHEN 'P_CHCKC'.
        lv_allow_changes_c = ls_variant-low.

    ENDCASE.
  ENDLOOP.
*

  " CHECK
  IF i_check EQ 'X' .
    " check authorization tm
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

    " check authorization table maintenance
    lv_auth_object = 'S_TABU_DIS'.

    lv_activity = '02'.
    AUTHORITY-CHECK OBJECT lv_auth_object
             ID 'ACTVT' FIELD lv_activity.
    IF sy-subrc <> 0.
      MESSAGE e187(s_lmcfg_core_tasks) WITH lv_activity lv_auth_object INTO if_stctm_task~pr_log->dummy.
      if_stctm_task~pr_log->add_syst( ).
      RAISE error_occured.
    ENDIF.

    lv_activity = '03'.
    AUTHORITY-CHECK OBJECT lv_auth_object
             ID 'ACTVT' FIELD lv_activity.
    IF sy-subrc <> 0.
      MESSAGE e187(s_lmcfg_core_tasks) WITH lv_activity lv_auth_object INTO if_stctm_task~pr_log->dummy.
      if_stctm_task~pr_log->add_syst( ).
      RAISE error_occured.
    ENDIF.

    "  check settings for cross client changes
    IF lv_pack NS '$'.

      SELECT * FROM t000 BYPASSING BUFFER INTO CORRESPONDING FIELDS OF TABLE lt_t000 WHERE mandt = sy-mandt.

      LOOP AT lt_t000 INTO ls_t000.
        CASE ls_t000-ccnocliind.
          WHEN 1.
            MESSAGE s155 INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).
          WHEN 2.
            IF lv_allow_changes <> abap_true.
              MESSAGE w125 INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
              if_stctm_task~pr_log->add_syst( ).
              RAISE warning_occured.
            ENDIF.
          WHEN 3.
            IF lv_allow_changes <> abap_true.
              MESSAGE w125 INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
              if_stctm_task~pr_log->add_syst( ).
              RAISE warning_occured.
            ENDIF.
          WHEN OTHERS.
            MESSAGE s155 INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).
        ENDCASE.
      ENDLOOP.

      " check settings automatic recording
      CLEAR: lt_t000, ls_t000.

      SELECT * FROM t000 BYPASSING BUFFER INTO CORRESPONDING FIELDS OF TABLE lt_t000 WHERE mandt = sy-mandt .

      LOOP AT lt_t000 INTO ls_t000.
        CASE ls_t000-cccoractiv.
          WHEN 2.
            IF lv_allow_changes_c <> abap_true.
              MESSAGE w150 INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
              if_stctm_task~pr_log->add_syst( ).
              RAISE warning_occured.
            ENDIF.
          WHEN OTHERS.
            MESSAGE s154 INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).
        ENDCASE.
      ENDLOOP.
    ENDIF.

    " EXECUTION
  ELSE.

    p_prefix = lv_prefix.
    p_package = lv_pack.

    MESSAGE s000 WITH 'Prefix:' lv_prefix '; Package:' lv_pack INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
    if_stctm_task~pr_log->add_syst( ).

    IF lv_pack NS '$'.

      " SCC4: set "Changes to the Repository and cross-client Customizing allowed"
      CLEAR: lt_t000, ls_t000.
      IF lv_allow_changes EQ abap_true.

        SELECT SINGLE * FROM t000 INTO ls_t000 WHERE mandt = sy-mandt. "#EC CI_BYPASS

        IF ls_t000 IS NOT INITIAL.
          ls_t000-ccnocliind = ' '.
          MODIFY t000 FROM ls_t000.
          MESSAGE s220(s_lmcfg_core_tasks) INTO if_stctm_task~pr_log->dummy.
          if_stctm_task~pr_log->add_syst( ).
        ENDIF.
      ENDIF.

      " SCC4: set "automatic recording of changes"
      CLEAR: lt_t000, ls_t000.
      IF lv_allow_changes_c EQ abap_true.

        SELECT SINGLE * FROM t000 INTO ls_t000 WHERE mandt = sy-mandt. "#EC CI_BYPASS

        IF ls_t000 IS NOT INITIAL.
          ls_t000-cccoractiv = '1'.
          MODIFY t000 FROM ls_t000.
          MESSAGE s221(s_lmcfg_core_tasks) INTO if_stctm_task~pr_log->dummy.
          if_stctm_task~pr_log->add_syst( ).
        ENDIF.
      ENDIF.


      " set / create wb request
      CLEAR: lv_request, ls_message, lt_authorlist, lt_tasklist, ls_tasklist, lv_task, lv_count, lv_bapi_msg.
      IF lv_choice_selected EQ abap_true.

        " request selected
        lv_request = lv_request_selected .
        p_request_workbench = lv_request. " write request to attribute
        p_selected_workbench = abap_true.

        MESSAGE s151 WITH lv_request INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

      ELSE.

        APPEND sy-uname  TO lt_authorlist.

        p_request_workbench = ''.

        " get layer
        CALL FUNCTION 'TR_GET_TRANSPORT_TARGET'
          EXPORTING
            iv_development_class       = lv_pack
          IMPORTING
            ev_layer                   = lv_layer
          EXCEPTIONS
            wrong_call                 = 1
            invalid_input              = 2
            cts_initialization_failure = 3
            OTHERS                     = 4.
        IF sy-subrc <> 0.
          MESSAGE e000 WITH 'Could not get layer' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
        ENDIF.

        lv_translayer-layer = lv_layer.

        CALL FUNCTION 'BAPI_CTREQUEST_CREATE'
          EXPORTING
            request_type = 'K'  " k - workbench request
            author       = sy-uname
            text         = lv_descr
            translayer   = lv_translayer
          IMPORTING
            requestid    = lv_request
            return       = ls_message
          TABLES
            authorlist   = lt_authorlist
            task_list    = lt_tasklist.

        lv_bapi_msg = ls_message. "cast message for log

        " check if at least 1 task for sy-user is created
        DESCRIBE TABLE lt_tasklist LINES lv_count.

        CASE lv_count.
          WHEN 1.
            p_request_workbench = lv_request. " write request to attribute
            LOOP AT lt_tasklist INTO ls_tasklist.
              lv_task = ls_tasklist-taskid.
            ENDLOOP.
            MESSAGE s152 WITH lv_request lv_task  sy-uname INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).
          WHEN OTHERS.
            if_stctm_task~pr_log->add_text( lv_bapi_msg ).
            MESSAGE e153 INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).
            RAISE error_occured.
        ENDCASE.

      ENDIF.

      " set / create cust request
      CLEAR: lv_request, ls_message, lt_authorlist, lt_tasklist, ls_tasklist, lv_task, lv_count, lv_bapi_msg.
      IF lv_choice_selected_c EQ abap_true.

        " request selected
        lv_request = lv_request_selected_c .
        p_request_customizing = lv_request. " write request to attribute
        p_selected_customizing = abap_true.

        MESSAGE s151 WITH lv_request INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

      ELSE.

        " request create
        APPEND sy-uname  TO lt_authorlist.

        p_request_customizing = ''.

        " get layer
        CALL FUNCTION 'TR_GET_TRANSPORT_TARGET'
          EXPORTING
            iv_development_class       = lv_pack
          IMPORTING
            ev_layer                   = lv_layer
          EXCEPTIONS
            wrong_call                 = 1
            invalid_input              = 2
            cts_initialization_failure = 3
            OTHERS                     = 4.
        IF sy-subrc <> 0.
          MESSAGE e000 WITH 'Could not get layer' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
        ENDIF.

        lv_translayer-layer = lv_layer.

        CALL FUNCTION 'BAPI_CTREQUEST_CREATE'
          EXPORTING
            request_type = 'W'  "w - customizing request
            author       = sy-uname
            text         = lv_descr
            translayer   = lv_translayer
          IMPORTING
            requestid    = lv_request
            return       = ls_message
          TABLES
            authorlist   = lt_authorlist
            task_list    = lt_tasklist.

        lv_bapi_msg = ls_message. "cast message for log

        " check if at least 1 task for sy-user is created
        DESCRIBE TABLE lt_tasklist LINES lv_count.

        CASE lv_count.
          WHEN 1.
            p_request_customizing = lv_request. " write request to attribute
            LOOP AT lt_tasklist INTO ls_tasklist.
              lv_task = ls_tasklist-taskid.
            ENDLOOP.
            MESSAGE s152 WITH lv_request lv_task  sy-uname INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).
          WHEN OTHERS.
            if_stctm_task~pr_log->add_text( lv_bapi_msg ).
            MESSAGE e153 INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).
            RAISE error_occured.
        ENDCASE.
      ENDIF.
    ENDIF.
  ENDIF.

ENDMETHOD.