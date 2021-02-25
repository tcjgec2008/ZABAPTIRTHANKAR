  METHOD check_flp_plugin_sys.

    DATA: ls_flpsetpa TYPE t_flpsetpa.

    " check if property is avilable
    SELECT SINGLE * FROM (/ui2/flpsetpa) INTO @ls_flpsetpa WHERE plugin_id = @i_plugin_id.

    " is available
    IF ls_flpsetpa IS NOT INITIAL.

      "check for state
      IF ls_flpsetpa-act_state <> i_act_state.

        MESSAGE w000 WITH 'FLP Plugin is already available:' ls_flpsetpa-plugin_id INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        IF i_act_state = ''.
          MESSAGE w000 WITH 'Status is different: ACTIVE <>' ls_flpsetpa-act_state INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
        ELSE.
          MESSAGE w000 WITH 'Status is different:' i_act_state '<>' ls_flpsetpa-act_state INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
        ENDIF.

        " exists with different value
        e_rc = 2.

      ELSE.

        " exists
        e_rc = 1.

      ENDIF.

    ELSE.

      " does not exists
      e_rc = 0.

    ENDIF.

  ENDMETHOD.