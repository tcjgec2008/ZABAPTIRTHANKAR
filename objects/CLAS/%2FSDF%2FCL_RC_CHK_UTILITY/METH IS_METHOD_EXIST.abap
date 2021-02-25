METHOD is_method_exist.

  DATA: lo_descr_ref TYPE REF TO cl_abap_objectdescr,
        lo_method    TYPE abap_methdescr.

  "Make sure the class exists
  rv_exist = is_class_exist( iv_class_name = iv_class_name ).
  CHECK rv_exist = abap_true.


  "Check whether the method exists
  lo_descr_ref ?= cl_abap_typedescr=>describe_by_name( iv_class_name ).
  READ TABLE lo_descr_ref->methods TRANSPORTING NO FIELDS
    WITH KEY name       = iv_method_name
             visibility = 'U'   "Public method
             is_class   = 'X'.  "Stati method
  IF sy-subrc = 0.
    rv_exist = abap_true.
  ELSE.
    rv_exist = abap_false.
  ENDIF.

ENDMETHOD.