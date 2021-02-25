  METHOD get_system_host_port.

    DATA: lt_list TYPE TABLE OF msxxlist_v6,
          ls_list TYPE msxxlist_v6.

    DATA: lt_servlist TYPE TABLE OF icm_sinfo2,
          ls_servlist TYPE icm_sinfo2.

********************************************************
* get HTTPS host/port

    " get server list
    CALL FUNCTION 'TH_SERVER_LIST'
      TABLES
        list           = lt_list
      EXCEPTIONS
        no_server_list = 1
        OTHERS         = 2.

    IF sy-subrc <> 0.

      MESSAGE e001 WITH 'TH_SERVER_LIST' sy-subrc INTO if_stctm_task~pr_log->dummy.
      if_stctm_task~pr_log->add_syst( ).

    ELSE.

      " if icm is active, get data
      CALL FUNCTION 'ICM_ACTIVE'
        EXCEPTIONS
          icm_not_active = 1
          OTHERS         = 2.

      IF sy-subrc <> 0.

        MESSAGE e001 WITH 'ICM_ACTIVE' sy-subrc INTO if_stctm_task~pr_log->dummy.
        if_stctm_task~pr_log->add_syst( ).

      ELSE.

        LOOP AT lt_list INTO ls_list.

          CALL FUNCTION 'ICM_GET_INFO2' DESTINATION ls_list-name
            TABLES
              servlist           = lt_servlist
            EXCEPTIONS
              icm_error          = 1
              icm_timeout        = 2
              icm_not_authorized = 3
              OTHERS             = 4.

          IF sy-subrc <> 0.

            MESSAGE e001 WITH 'ICM_GET_INFO2' sy-subrc INTO if_stctm_task~pr_log->dummy.
            if_stctm_task~pr_log->add_syst( ).

          ELSE.

            " get https and port
            LOOP AT lt_servlist INTO ls_servlist.

              DATA(lv_host_https) = ls_servlist-hostname.

              IF ls_servlist-protocol = 2.

                IF ls_servlist-service <> 0.
                  DATA(lv_port_https) = ls_servlist-service.
                ENDIF.

              ENDIF.

            ENDLOOP.

          ENDIF.

        ENDLOOP.

        ev_host_https = lv_host_https.
        ev_port_https = lv_port_https.

      ENDIF.

    ENDIF.

  ENDMETHOD.