  METHOD if_stctm_ui_task~maintained.

    DATA ls_variant TYPE LINE OF tt_variant.

    DATA: sep(1)         TYPE c VALUE ' ',
          txt1(256)      TYPE c,
          txt2(256)      TYPE c,
          outputtxt(256) TYPE c.

    DATA: task_selected TYPE stc_task_status.

* call ui maintain method
    r_maintained = super->if_stctm_ui_task~maintained( ir_tasklist ).

* check if task is selected (01 - selected / 02 - not selected)
    task_selected = if_stctm_task~p_status.

* display parameter description
    IF task_selected = '02' OR r_maintained <> 'X'.

      " clear param description
      if_stctm_ui_task~p_variant_descr = 'OData ICF Activation mode only'(102).

    ELSE.

      " get prefix
      READ TABLE pt_variant INTO ls_variant WITH KEY selname = 'P_PREFIX'  ##WARN_OK.

      IF ls_variant-low IS NOT INITIAL.
        txt1 = ls_variant-low.
      ENDIF.

      " get package
      READ TABLE pt_variant INTO ls_variant WITH KEY selname = 'P_PACK'.

      IF ls_variant-low IS NOT INITIAL.
        txt2 = ls_variant-low .
      ENDIF.

      "assemble message
      CONCATENATE 'Prefix:'(100) txt1 '/' 'Package:'(101) txt2 INTO outputtxt SEPARATED BY sep.

      "output in parameter description
      if_stctm_ui_task~p_variant_descr = outputtxt.

    ENDIF.

  ENDMETHOD.