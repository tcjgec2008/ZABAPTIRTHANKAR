  METHOD if_stctm_bg_task~execute.

    DATA ls_variant TYPE t_variant.

    DATA lt_http_whitelist TYPE http_whitelist_tab.
    DATA ls_http_whitelist LIKE LINE OF lt_http_whitelist.
    DATA lt_all_entry_types TYPE STANDARD TABLE OF http_white_list-entry_type.

* Get UI parameter
    LOOP AT pt_variant INTO ls_variant.
      CASE  ls_variant-selname.

        WHEN 'P_HOST'.
          DATA(lv_host) = ls_variant-low.

        WHEN 'P_PORT'.
          DATA(lv_port) = ls_variant-low.

        WHEN 'P_PATH'.
          DATA(lv_path) = ls_variant-low.

      ENDCASE.

    ENDLOOP.

* Execute
    IF i_check EQ 'X'. " check mode

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

    ELSE. " execution mode

      " read new http allowlist configuration
      TRY .
          CALL METHOD cl_http_whitelist_api=>read_setup
            IMPORTING
              ev_syncmandt                = DATA(lv_syncmandt)
              ev_clickjacking_integration = DATA(lv_clickjacking_protection)
              ev_switch_on                = DATA(lv_switch_on).

        CATCH cx_root INTO DATA(lx_root).
          MESSAGE e000 WITH 'Error reading allowlist configuration' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
          RAISE error_occured.
      ENDTRY.

      "  check if whitelist is activated
      IF lv_switch_on = abap_false.
        MESSAGE e000 WITH 'New Allowlist Maintance is not active' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.
      ENDIF.

      " check if whitelist is for all clients or local client
      IF lv_syncmandt = abap_false.
        DATA(lv_mandt) = sy-mandt.
      ELSE.
        lv_mandt = ''.
      ENDIF.

      " check to include clickjacking_protection
      IF lv_clickjacking_protection = abap_true.
        APPEND '01' TO lt_all_entry_types.
        APPEND '02' TO lt_all_entry_types.
        APPEND '03' TO lt_all_entry_types.
      ELSE.
        APPEND '01' TO lt_all_entry_types.
        APPEND '03' TO lt_all_entry_types.
      ENDIF.

      " check and make entries
      LOOP AT lt_all_entry_types INTO DATA(lv_entry_type).

        " create entry for https

        ls_http_whitelist-client = lv_mandt.
        ls_http_whitelist-entry_type = lv_entry_type.
        ls_http_whitelist-namespace = 'C'.
        ls_http_whitelist-scheme = '2'.
        ls_http_whitelist-host = lv_host.
        ls_http_whitelist-port = lv_port.
        ls_http_whitelist-path = lv_path.
        INSERT ls_http_whitelist INTO TABLE lt_http_whitelist.

      ENDLOOP.

      " update
      IF lt_http_whitelist IS NOT INITIAL.

        TRY .
            CALL METHOD cl_http_whitelist_api=>write_whitelist
              EXPORTING
                it_whitelist = lt_http_whitelist.

          CATCH cx_root INTO lx_root.

            MESSAGE e000 WITH 'Error writing allowlist entries' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
            if_stctm_task~pr_log->add_syst( ).
            RAISE error_occured.
        ENDTRY.


        IF lv_syncmandt = abap_true.

          MESSAGE s000 WITH 'Following entries will be' 'added/updated to HTTP Allowlist' '(all clients):' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

        ELSE.

          MESSAGE s000 WITH 'Following entries will be' 'added/updated to HTTP Allowlist client' lv_mandt ':' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).

        ENDIF.

        LOOP AT lt_http_whitelist INTO ls_http_whitelist.
          MESSAGE s000 WITH ls_http_whitelist-entry_type ls_http_whitelist-scheme ls_http_whitelist-host ls_http_whitelist-port   INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
        ENDLOOP.

      ELSE.
        MESSAGE s000 WITH 'No HTTP Allowlist entries needs to be added' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
      ENDIF.

    ENDIF.

  ENDMETHOD.