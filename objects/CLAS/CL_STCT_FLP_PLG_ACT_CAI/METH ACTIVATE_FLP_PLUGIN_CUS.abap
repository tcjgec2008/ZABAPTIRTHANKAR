  METHOD activate_flp_plugin_cus.

    DATA: ls_flpsetpac TYPE t_flpsetpac.
    DATA: ls_flpsetp TYPE t_flpsetp.
    DATA: lv_clnt TYPE sy-mandt.

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

    " check if plugin is available
    SELECT SINGLE * FROM (/ui2/flpsetpac) USING CLIENT @lv_clnt INTO CORRESPONDING FIELDS OF @ls_flpsetpac WHERE plugin_id = @i_plugin_id.

    MESSAGE s000 WITH 'Activation for current client' '(/UI2/FLP_CUS_CONF)' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
    if_stctm_task~pr_log->add_syst( ).

    " is available
    IF ls_flpsetpac IS NOT INITIAL.

      "check for property value
      IF ls_flpsetpac-act_state = i_act_state.

        MESSAGE s000 WITH 'FLP Plugin' i_plugin_id 'is already active' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

      ELSE.

        DATA(lv_msg) = |FLP Plugin { i_plugin_id } is available with diff. state:| ##NO_TEXT.

        IF i_overwrite = abap_true.

          IF i_act_state = ''.
            MESSAGE s000 WITH lv_msg 'ACTIVE <>' ls_flpsetpac-act_state INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).
          ELSE.
            MESSAGE s000 WITH lv_msg i_act_state '<>' ls_flpsetpac-act_state INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).
          ENDIF.

          MESSAGE s000 WITH 'Setting will be overwritten' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          lv_update = abap_true.

        ELSE.

          IF i_act_state = ''.
            MESSAGE w000 WITH lv_msg 'ACTIVE <>' ls_flpsetpac-act_state INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).
          ELSE.
            MESSAGE w000 WITH lv_msg i_act_state '<>' ls_flpsetpac-act_state INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).
          ENDIF.

          MESSAGE w000 WITH 'Setting will not be overwritten' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          e_warning = abap_true.

        ENDIF.

      ENDIF.

    ELSE.

      lv_insert = abap_true.

    ENDIF.


    IF lv_insert = abap_true OR lv_update = abap_true.

      " Create entry
      " get plugin from defintions
      SELECT SINGLE * FROM (/ui2/flpsetp) INTO CORRESPONDING FIELDS OF @ls_flpsetp WHERE plugin_id = @i_plugin_id.

      IF ls_flpsetp IS INITIAL.

        MESSAGE e000 WITH 'FLP Plugin' i_plugin_id 'is not defined' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        e_error = abap_true.

      ELSE.

        ls_flpsetpac-client    = sy-mandt.
        ls_flpsetpac-plugin_id = i_plugin_id.
        ls_flpsetpac-act_state = i_act_state.

        " create object entry
        wa_e071-trkorr    = i_request_cust.
        wa_e071-pgmid     = 'R3TR'.
        wa_e071-object    = 'CDAT'.
        wa_e071-obj_name  = '/UI2/FLPSETCVC'.
        wa_e071-objfunc   = 'K'.

        APPEND wa_e071  TO it_e071.

        " create key entry
        wa_e071k-trkorr   = i_request_cust.
        wa_e071k-pgmid    = 'R3TR'.
        wa_e071k-object   = 'TABU'.
        wa_e071k-objname = '/UI2/FLPSETPAC'.
        wa_e071k-tabkey   = sy-mandt && ls_flpsetpac-plugin_id.
        wa_e071k-mastertype = wa_e071-object.
        wa_e071k-mastername = wa_e071-obj_name.
        wa_e071k-viewname = '/UI2/FLPSETPACV'.

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
            wi_order                = i_request_cust
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
            UPDATE (/ui2/flpsetpac) FROM ls_flpsetpac.

            IF i_act_state = ''.
              MESSAGE s000 WITH 'FLP Plugin updated:' ls_flpsetpac-plugin_id '= ACTIVE' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
              if_stctm_task~pr_log->add_syst( ).
            ELSE.
              MESSAGE s000 WITH 'FLP Plugin updated:' ls_flpsetpac-plugin_id '=' ls_flpsetpac-act_state INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
              if_stctm_task~pr_log->add_syst( ).
            ENDIF.

          ELSE.

            " insert table
            INSERT (/ui2/flpsetpac) FROM ls_flpsetpac.

            IF i_act_state = ''.
              MESSAGE s000 WITH 'FLP Plugin set:' ls_flpsetpac-plugin_id '= ACTIVE' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
              if_stctm_task~pr_log->add_syst( ).
            ELSE.
              MESSAGE s000 WITH 'FLP Plugin set:' ls_flpsetpac-plugin_id '=' ls_flpsetpac-act_state INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
              if_stctm_task~pr_log->add_syst( ).
            ENDIF.

          ENDIF.

          MESSAGE s000 WITH 'Object added to Customizing Request' i_request_cust INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

        ENDIF.

      ENDIF.

    ENDIF.

  ENDMETHOD.