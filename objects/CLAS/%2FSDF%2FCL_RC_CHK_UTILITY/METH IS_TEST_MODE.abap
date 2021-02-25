METHOD is_test_mode.
  DATA lv_appli TYPE bcos_appl.

  SELECT SINGLE appli INTO lv_appli
    FROM bcos_cust
    WHERE appli = c_parameter-sys_type_key_local
      AND destinat = c_parameter-sys_type_sap_test.
  IF sy-subrc = 0.
    rv_result = abap_true.
  ELSE.
    rv_result = abap_false.
  ENDIF.
ENDMETHOD.