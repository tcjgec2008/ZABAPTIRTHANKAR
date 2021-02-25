  METHOD IF_STCTM_TASK~SHOW_MESSAGE_DETAILS.

    DATA: lt_log TYPE TABLE OF stct_log.
    DATA: ls_log TYPE string.
    DATA: lt_services_log TYPE TABLE OF stct_input_data.
    DATA: ls_services_log TYPE stct_input_data.

    DATA: ls_layout TYPE slis_layout_alv.
    DATA: lt_fieldcat TYPE slis_t_fieldcat_alv .
    DATA: ls_fieldcat TYPE slis_fieldcat_alv .

    " get data
    SPLIT i_details AT ';' INTO TABLE lt_log.

    LOOP AT lt_log INTO ls_log.
      SPLIT ls_log AT ':' INTO ls_services_log-service ls_services_log-version.
      UNPACK ls_services_log-version TO ls_services_log-version.
      APPEND ls_services_log TO lt_services_log.
    ENDLOOP.

    " prepare output
    ls_layout-colwidth_optimize = 'X'.

    ls_fieldcat-col_pos = 1.
    ls_fieldcat-fieldname = 'SERVICE' .
    ls_fieldcat-seltext_m = 'Service'(012) .
    APPEND ls_fieldcat TO lt_fieldcat .
    CLEAR ls_fieldcat .

    ls_fieldcat-col_pos = 2.
    ls_fieldcat-fieldname = 'VERSION' .
    ls_fieldcat-seltext_m = 'Version'(013) .
    ls_fieldcat-lzero = 'X'.
    APPEND ls_fieldcat TO lt_fieldcat .
    CLEAR ls_fieldcat .

    " output
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_grid_title     = 'Failed services'(010)
        i_structure_name = 'STCT_INPUT_DATA'
        is_layout        = ls_layout
        it_fieldcat      = lt_fieldcat
      TABLES
        t_outtab         = lt_services_log
      EXCEPTIONS
        program_error    = 1
        OTHERS           = 2.

    IF sy-subrc <> 0.
      MESSAGE e000 WITH
      'Detail view cannot be displayed'(011).
      RAISE error_occured.
    ENDIF.

  ENDMETHOD.