  METHOD check_flp_plugin.

    DATA: ls_flpsetp TYPE t_flpsetp.

    " check if plugin is available
    SELECT SINGLE * FROM (/ui2/flpsetp) INTO @ls_flpsetp WHERE plugin_id = @i_plugin_id.

    " is available
    IF ls_flpsetp IS NOT INITIAL.

      "check for descr
      IF ls_flpsetp-description <> i_plugin_descr.

        MESSAGE w000 WITH 'FLP Plugin is already available:' ls_flpsetp-description INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        MESSAGE w000 WITH 'Description is available with diff. value:' i_plugin_descr '<>' ls_flpsetp-description INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        " exists with different value
        e_rc = 2.

        "check for component
      ELSEIF ls_flpsetp-component <> i_plugin_component.

        MESSAGE w000 WITH 'FLP Plugin is already available:' ls_flpsetp-plugin_id INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        MESSAGE w000 WITH 'UI5 Component ID is available with diff. value:' i_plugin_component '<>' ls_flpsetp-component INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        " exists with different value
        e_rc = 2.

        "check for url
      ELSEIF ls_flpsetp-url <> i_plugin_url.

        MESSAGE w000 WITH 'FLP Plugin is already available:' ls_flpsetp-plugin_id INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        MESSAGE w000 WITH 'URL is available with diff. value:' i_plugin_url '<>' ls_flpsetp-url INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

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