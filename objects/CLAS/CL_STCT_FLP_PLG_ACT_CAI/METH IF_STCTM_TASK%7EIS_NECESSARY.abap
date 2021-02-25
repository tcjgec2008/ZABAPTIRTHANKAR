  METHOD if_stctm_task~is_necessary.

    DATA: lv_state TYPE ddobjstate.
    DATA: lv_name TYPE ddobjname.

    lv_name = /ui2/flpsetpa.

    " check if table exists
    CALL FUNCTION 'DDIF_STATE_GET'
      EXPORTING
        type          = 'TABL' "table
        name          = lv_name
      IMPORTING
        gotstate      = lv_state
      EXCEPTIONS
        illegal_input = 1
        OTHERS        = 2.

    IF sy-subrc = 0.
      IF lv_state = 'A'.
        r_necessary = if_stctm_task=>c_necessary-optional.
      ELSE.
        r_necessary = if_stctm_task=>c_necessary-impossible.
      ENDIF.
    ENDIF.

  ENDMETHOD.