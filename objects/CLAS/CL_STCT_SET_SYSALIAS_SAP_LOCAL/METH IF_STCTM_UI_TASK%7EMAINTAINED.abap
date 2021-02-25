  METHOD if_stctm_ui_task~maintained.

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

    DATA lv_alias_alternative TYPE c LENGTH 40.

*    lv_alias_alternative = 'sid(' && lv_sysid && '.' && lv_client && ')'.

*    r_maintained = super->if_stctm_ui_task~maintained( ir_tasklist ).

    " check if host has changed
    READ TABLE pt_variant INTO ls_variant WITH KEY selname = 'P_HOST'.
    IF lv_host <> ls_variant-low.
      mv_webdispatcher_host_https = ls_variant-low.
      mv_initial = abap_false.
    ENDIF.

    " check if port has changed
    READ TABLE pt_variant INTO ls_variant WITH KEY selname = 'P_SYSNR'.
    IF lv_port <> ls_variant-low.
      mv_webdispatcher_port_https = ls_variant-low.
      mv_initial = abap_false.
    ENDIF.

    " check if path has changed
    READ TABLE pt_variant INTO ls_variant WITH KEY selname = 'P_PATH'.
    IF lv_path <> ls_variant-low.
      mv_initial = abap_false.
    ENDIF.

    IF mv_initial = abap_true.

    " set values for task
    lv_dest = 'FIORI_FLP_HTTPS'.
    lv_host = cl_stct_set_profile_https=>mv_host_https.
    lv_port = cl_stct_set_profile_https=>mv_port_https.
    lv_path = '/sap/bc/ui2/flp'.
    lv_alias = 'FIORI'.
    lv_dest_short = 'FIORI_FLP'.

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

      " set external values
      mv_webdispatcher_host_https = lv_host.
      mv_webdispatcher_port_https = lv_port.

      mv_initial = abap_false.

    ENDIF.

    r_maintained = if_stctm_task=>c_bool-true.

  ENDMETHOD.