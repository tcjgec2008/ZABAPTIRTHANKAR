METHOD check_is_test_mode.

  DATA: lv_user TYPE syuname.

*--------------------------------------------------------------------*
* Get test mode flag

*  lv_user = sy-uname.
*  CHECK lv_user(1) = 'Y'.

  CALL FUNCTION 'FUNCTION_EXISTS'
    EXPORTING
      funcname           = c_test_function
    EXCEPTIONS
      function_not_exist = 1
      OTHERS             = 2.
  IF sy-subrc = 0.
    rv_test_mode = abap_true.
  ENDIF.

ENDMETHOD.