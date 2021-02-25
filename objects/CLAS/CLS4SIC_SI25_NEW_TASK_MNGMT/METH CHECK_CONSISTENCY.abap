  METHOD check_consistency.
*   SI check class that tells the customer on the source that the item
*    is relevant and that asks the customer whether he want to do the migration
*    with R_EHFND_WFF_RESTART_PROCESSES manually or automatically.
*   The SI check checks whether the entry in S4SIC_PARAM is there,
*    otherwise it will block the upgrade. (return code = 8).
    TYPES:
    tt_dd03ptab TYPE STANDARD TABLE OF dd03p WITH DEFAULT KEY .

    DATA:
      lv_message     TYPE string,
      ls_dd02v_wa    TYPE dd02v,
      lt_s4sic_param TYPE SORTED TABLE OF ty_gs_s4sic_param WITH UNIQUE KEY name.



    CALL FUNCTION 'DDIF_TABL_GET'
      EXPORTING
        name     = gc_s4sic_param_table_name
        state    = 'A'
      IMPORTING
        dd02v_wa = ls_dd02v_wa.

    IF ls_dd02v_wa IS NOT INITIAL.
      SELECT * FROM (gc_s4sic_param_table_name) INTO TABLE lt_s4sic_param
      WHERE name = gc_tm_check_wff_restart_manual .
      IF  sy-subrc <> 0 .
        add_error_message(
                        IMPORTING
                         et_chk_result = et_chk_result
                      ).
      ELSE. "if value is found - check whether it is consistent value
        LOOP AT lt_s4sic_param REFERENCE INTO DATA(lr_s4sic_param).
          "must be AUTOMATIC or MANUAL
          IF lr_s4sic_param->value <> c_migration_run_mode-manual AND lr_s4sic_param->value <> c_migration_run_mode-automatic.
            add_error_message(
                        IMPORTING
                         et_chk_result = et_chk_result
                      ).
            EXIT.
          ELSE.
            add_success_message(
                                 EXPORTING
                                    iv_param_value =  lr_s4sic_param->value
                                 IMPORTING
                                    et_chk_result  = et_chk_result
                                ).
          ENDIF.


        ENDLOOP.

      ENDIF.
    ENDIF.
  ENDMETHOD.