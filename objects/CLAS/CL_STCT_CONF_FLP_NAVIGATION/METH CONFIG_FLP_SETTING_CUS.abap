  METHOD config_flp_setting_cus.


    DATA: ls_flpsetc TYPE t_flpsetc.
    DATA: ls_flpsetpd TYPE t_flpsetpd.

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

    " check if property is avilable
    SELECT SINGLE * FROM (/ui2/flpsetc) INTO @ls_flpsetc WHERE property_id = @i_property_id.

    " is available
    IF ls_flpsetc IS NOT INITIAL.

      "check for property value
      IF ls_flpsetc-value = i_property_value.

        MESSAGE s000 WITH 'FLP Property is already available:' i_property_id '=' i_property_value INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

      ELSE.

        IF i_overwrite = abap_true.

          MESSAGE s000 WITH 'FLP Property is available with diff. value:' i_property_id '=' ls_flpsetc-value INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          MESSAGE s000 WITH 'Setting will be overwritten' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          lv_update = abap_true.

        ELSE.

          MESSAGE w000 WITH 'FLP Property is available with diff. value:' i_property_id '=' ls_flpsetc-value INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
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

      " Create entry
      " get values from property defintions
      SELECT SINGLE * FROM (/ui2/flpsetpd) INTO CORRESPONDING FIELDS OF @ls_flpsetpd WHERE property_id = @i_property_id.

      IF ls_flpsetpd IS INITIAL.

        MESSAGE e000 WITH 'FLP Property' i_property_id 'is not defined' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

        e_error = abap_true.

      ELSE.

        ls_flpsetc-client    = sy-mandt.
        ls_flpsetc-property_id = i_property_id.
        ls_flpsetc-value = i_property_value.

        " create object entry
        wa_e071-trkorr    = i_request_cust.
        wa_e071-pgmid     = 'R3TR'.
        wa_e071-object    = 'CDAT'.
        wa_e071-obj_name  = '/UI2/FLPSETCVC'.
        wa_e071-objfunc     = 'K'.

        APPEND wa_e071  TO it_e071.

        " create key entry for /UI2/C_SYSALIAS
        wa_e071k-trkorr   = i_request_cust.
        wa_e071k-pgmid    = 'R3TR'.
        wa_e071k-object   = 'TABU'.
        wa_e071k-objname = '/UI2/FLPSETC'.
        wa_e071k-tabkey   = sy-mandt && ls_flpsetc-property_id.
        wa_e071k-mastertype = wa_e071-object.
        wa_e071k-mastername = wa_e071-obj_name.
        wa_e071k-viewname = '/UI2/FLPSETCV'.

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

          MESSAGE s000 WITH 'Customizing Request:' i_request_cust INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

          IF lv_update = abap_true.

            " update table
            UPDATE (/ui2/flpsetc) FROM ls_flpsetc.

            MESSAGE s000 WITH 'Updated FLP Property:' ls_flpsetc-property_id '=' ls_flpsetc-value INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).

          ELSE.

            " insert table
            INSERT (/ui2/flpsetc) FROM ls_flpsetc.

            MESSAGE s000 WITH 'Created FLP Property:' ls_flpsetc-property_id '=' ls_flpsetc-value INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).
          ENDIF.

        ENDIF.

      ENDIF.

    ENDIF.

  ENDMETHOD.