  METHOD config_flp_plugin.

    DATA: ls_flpsetp TYPE t_flpsetp.

    DATA: lv_insert TYPE abap_bool.
    DATA: lv_update TYPE abap_bool.

    DATA: it_e071  TYPE tr_objects ##NEEDED,
          it_e071k TYPE tr_keys,
          wa_e071  TYPE ko200,
          wa_e071k TYPE e071k.

    lv_insert = abap_false.
    lv_update = abap_false.
    e_warning = abap_false.
    e_error = abap_false.

    " check if property is available
    SELECT SINGLE * FROM (/ui2/flpsetp) INTO @ls_flpsetp WHERE plugin_id = @i_plugin_id.

    " is available
    IF ls_flpsetp IS NOT INITIAL.

      MESSAGE s000 WITH 'FLP Plugin is already available:' ls_flpsetp-plugin_id INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
      if_stctm_task~pr_log->add_syst( ).

      MESSAGE s000 WITH 'Description:' ls_flpsetp-description INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
      if_stctm_task~pr_log->add_syst( ).

      MESSAGE s000 WITH 'UI5 Component ID:' ls_flpsetp-component INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
      if_stctm_task~pr_log->add_syst( ).

      MESSAGE s000 WITH 'URL:' ls_flpsetp-url INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
      if_stctm_task~pr_log->add_syst( ).

      "check for description
      IF ls_flpsetp-description <> i_plugin_descr.

        IF i_overwrite = abap_true.

          MESSAGE s000 WITH 'Description is available with diff. value:' i_plugin_descr '<>' ls_flpsetp-description INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          MESSAGE s000 WITH 'Setting will be overwritten' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          lv_update = abap_true.

        ELSE.

          MESSAGE w000 WITH 'Description is available with diff. value:' i_plugin_descr '<>' ls_flpsetp-description INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          MESSAGE w000 WITH 'Setting will not be overwritten' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          e_warning = abap_true.

        ENDIF.

      ENDIF.

      "check for component
      IF ls_flpsetp-component <> i_plugin_component.

        IF i_overwrite = abap_true.

          MESSAGE s000 WITH 'UI5 Component ID is available with diff. value:' i_plugin_component '<>' ls_flpsetp-component INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          MESSAGE s000 WITH 'Setting will be overwritten' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          lv_update = abap_true.

        ELSE.

          MESSAGE w000 WITH 'UI5 Component ID is available with diff. value:' i_plugin_component '<>' ls_flpsetp-component INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          MESSAGE w000 WITH 'Setting will not be overwritten' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          e_warning = abap_true.

        ENDIF.

      ENDIF.

      "check for url
      IF ls_flpsetp-url <> i_plugin_url.

        IF i_overwrite = abap_true.

          MESSAGE s000 WITH 'URL is available with diff. value:' i_plugin_url '<>' ls_flpsetp-url INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          MESSAGE s000 WITH 'Setting will be overwritten' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          lv_update = abap_true.

        ELSE.

          MESSAGE w000 WITH 'URL is available with diff. value:' i_plugin_url '<>' ls_flpsetp-url INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          MESSAGE w000 WITH 'Setting will not be overwritten' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          e_warning = abap_true.

        ENDIF.

      ENDIF.

    ELSE.

      lv_insert = abap_true.

    ENDIF.


    IF lv_insert = abap_true OR lv_update = abap_true.

      ls_flpsetp-plugin_id = i_plugin_id.
      ls_flpsetp-component = i_plugin_component.
      ls_flpsetp-description = i_plugin_descr.
      ls_flpsetp-url = i_plugin_url.

      " create object entry
      wa_e071-trkorr    = i_request_work.
      wa_e071-pgmid     = 'R3TR'.
      wa_e071-object    = 'CDAT'.
      wa_e071-obj_name  = '/UI2/FLPSETDEFVC'.
      wa_e071-objfunc   = 'K'.

      APPEND wa_e071  TO it_e071.

      " create key entry for /UI2/FLPSETP
      wa_e071k-trkorr     = i_request_work.
      wa_e071k-pgmid      = 'R3TR'.
      wa_e071k-object     = 'TABU'.
      wa_e071k-objname    = '/UI2/FLPSETP'.
      wa_e071k-tabkey     = ls_flpsetp-plugin_id.
      wa_e071k-mastertype = wa_e071-object.
      wa_e071k-mastername = wa_e071-obj_name.
      wa_e071k-viewname   = '/UI2/FLPSETPV'.

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
        e_error = abap_true.
      ENDIF.

      " insert objects
      CALL FUNCTION 'TR_OBJECT_INSERT'
        EXPORTING
          wi_order                = i_request_work
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
        e_error = abap_true.
      ELSE.

        IF lv_update = abap_true.

          " update table
          UPDATE (/ui2/flpsetp) FROM ls_flpsetp.

          MESSAGE s000 WITH 'Updated FLP Plugin:' ls_flpsetp-plugin_id INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          MESSAGE s000 WITH 'Description:' ls_flpsetp-description INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          MESSAGE s000 WITH 'UI5 Component ID:' ls_flpsetp-component INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          MESSAGE s000 WITH 'URL:' ls_flpsetp-url INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

        ELSE.

          " insert table
          INSERT (/ui2/flpsetp) FROM ls_flpsetp.

          MESSAGE s000 WITH 'Created FLP Plugin:' ls_flpsetp-plugin_id INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          MESSAGE s000 WITH 'Description:' ls_flpsetp-description INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          MESSAGE s000 WITH 'UI5 Component ID:' ls_flpsetp-component INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          MESSAGE s000 WITH 'URL:' ls_flpsetp-url INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

        ENDIF.

        MESSAGE s000 WITH 'Object added to Workbench Request' i_request_work INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

      ENDIF.

    ENDIF.

  ENDMETHOD.