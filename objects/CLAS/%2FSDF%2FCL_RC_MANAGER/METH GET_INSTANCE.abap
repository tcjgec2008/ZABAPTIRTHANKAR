METHOD get_instance.

  IF iv_target_stack IS INITIAL.
    RAISE target_stack_empty.
  ENDIF.

  CREATE OBJECT ro_rc_manager
    EXPORTING
      iv_target_stack = iv_target_stack
    EXCEPTIONS
      error           = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
    RAISE error.
  ENDIF.

ENDMETHOD.