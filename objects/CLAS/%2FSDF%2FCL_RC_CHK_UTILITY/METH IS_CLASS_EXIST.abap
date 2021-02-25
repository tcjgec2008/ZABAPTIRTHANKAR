METHOD is_class_exist.

  DATA: ls_class_key  TYPE seoclskey.

  CHECK iv_class_name IS NOT INITIAL.

  ls_class_key-clsname = iv_class_name.
  CALL FUNCTION 'SEO_CLASS_EXISTENCE_CHECK'
    EXPORTING
      clskey        = ls_class_key
    EXCEPTIONS
      no_text       = 0" No text is allowed
      not_specified = 1
      not_existing  = 2
      is_interface  = 3
      inconsistent  = 4
      OTHERS        = 5.
  IF sy-subrc = 0.
    rv_exist = abap_true.
  ENDIF.

ENDMETHOD.