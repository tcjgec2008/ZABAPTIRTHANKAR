  METHOD IF_STCTM_TASK~SHOW_MESSAGE_DETAILS.                "#EC NEEDED

    IF i_details = 'X'.
      CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
        EXPORTING
          tcode  = '/IWFND/MAINT_SERVICE'
        EXCEPTIONS
          ok     = 1
          not_ok = 2
          OTHERS = 3.
      IF sy-subrc LE 1.
        CALL TRANSACTION '/IWFND/MAINT_SERVICE'.
      ENDIF.                                                "#EC NEEDED
    ENDIF.

  ENDMETHOD.                    "IF_STCTM_TASK~SHOW_MESSAGE_DETAILS