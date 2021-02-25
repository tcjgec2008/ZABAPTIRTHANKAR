  METHOD IF_STCTM_UI_TASK~MAINTAINED.

    DATA ls_variant TYPE LINE OF tt_variant.

    DATA: lv_dest         TYPE rfcdest,
          lv_dest_short   TYPE rfcdest,
          lv_sysid        TYPE rfcsysid,
          lv_client       TYPE rfcclient,
          lv_host         TYPE string,
          lv_port         TYPE string,
          lv_port_initial TYPE string,
          lv_path         TYPE string,

          lv_alias        TYPE c LENGTH 40,
          lv_descr        TYPE c LENGTH 40.

    DATA: lv_alias_alternative TYPE c LENGTH 40.

    " set values for task
    lv_dest = 'FIORI_CLASSICUI_HTTPS'.

    me->get_system_host_port(
      IMPORTING
        ev_host_https = lv_host
        ev_port_https = lv_port
    ).

    lv_path = ''.
    lv_alias = 'FIORI_MENU'.
    lv_dest_short = 'FIORI_CLASSICUI'.

*    lv_alias_alternative = 'sid(' && lv_sysid && '.' && lv_client && ')'.

    IF mv_port_initial <> lv_port.
      mv_initial = abap_true.
    ENDIF.

    IF mv_initial = abap_true.

      LOOP AT pt_variant INTO ls_variant.

        IF ls_variant-selname = 'P_DEST'.
          ls_variant-low = lv_dest.
          MODIFY pt_variant FROM ls_variant.
        ENDIF.

        IF ls_variant-selname = 'P_HOST'.
          ls_variant-low = lv_host.
          MODIFY pt_variant FROM ls_variant.
        ENDIF.

        IF ls_variant-selname = 'P_SYSNR'.
          ls_variant-low = lv_port.
          MODIFY pt_variant FROM ls_variant.
        ENDIF.

        IF ls_variant-selname = 'P_PATH'.
          ls_variant-low = lv_path.
          MODIFY pt_variant FROM ls_variant.
        ENDIF.

        IF ls_variant-selname = 'P_CUSAL'.
          ls_variant-low = lv_alias.
          MODIFY pt_variant FROM ls_variant.
        ENDIF.


        IF ls_variant-selname = 'P_MAPAL'.
          ls_variant-low = lv_alias.
          MODIFY pt_variant FROM ls_variant.
        ENDIF.

        IF ls_variant-selname = 'P_MAPRFC'.
          ls_variant-low = lv_dest_short.
          MODIFY pt_variant FROM ls_variant.
        ENDIF.

        IF ls_variant-selname = 'P_MAPCL'.
          ls_variant-low = sy-mandt.
          MODIFY pt_variant FROM ls_variant.
        ENDIF.

      ENDLOOP.

      mv_port_initial = lv_port.
      mv_initial = abap_false.

    ENDIF.


    r_maintained = if_stctm_task=>c_bool-true.

  ENDMETHOD.