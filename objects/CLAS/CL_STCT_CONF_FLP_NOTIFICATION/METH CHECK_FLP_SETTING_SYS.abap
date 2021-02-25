  METHOD CHECK_FLP_SETTING_SYS.

    DATA: ls_flpset TYPE t_flpset.

    " check if property is avilable
    SELECT SINGLE * FROM (/ui2/flpset) INTO @ls_flpset WHERE property_id = @i_property_id.

    " is available
    IF ls_flpset IS NOT INITIAL.

      "check for property value
      IF ls_flpset-value <> i_property_value.

        MESSAGE w000 WITH 'Check setting in' '/UI2/FLP_SYS_CONF:' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        MESSAGE w000 WITH 'FLP Property is available with diff. value:' i_property_id '=' ls_flpset-value INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
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