  METHOD if_stctm_ui_task~maintained.

* call ui maintain method
    r_maintained = super->if_stctm_ui_task~maintained( ir_tasklist ).

  ENDMETHOD.