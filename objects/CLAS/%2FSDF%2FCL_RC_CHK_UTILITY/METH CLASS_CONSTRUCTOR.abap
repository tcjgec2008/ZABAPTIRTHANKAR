METHOD class_constructor.

  DATA:lv_system_type      TYPE rfcdest,
       lv_sy_sid           TYPE sysysid,
       lv_sys_type         TYPE char10,
       lt_tcusapcore       TYPE TABLE OF tcusapcore,
       ls_tcusapcore       TYPE tcusapcore,
       ls_content_data     TYPE srtm_datax.

*--------------------------------------------------------------------*
* Preparation

  SELECT SINGLE destinat FROM bcos_cust INTO lv_system_type
    WHERE appli = c_parameter-sys_type_key_local."'RC_SYS_TYPE'.
  IF sy-subrc = 0.
    sv_system_type = lv_system_type.
  ENDIF.

  sv_content_source = /sdf/cl_rc_chk_utility=>smdb_content_source_get( ).

  IF /sdf/cl_rc_chk_utility=>c_parameter-smdb_source_sap = sv_content_source.
    IF /sdf/cl_rc_chk_utility=>is_sitem_sap_exist( ) = abap_false.
      smdb_content_fetch_from_sap( ).
    ELSE.
      sv_smdb_fetched_from_sap = abap_true.
    ENDIF.
  ENDIF.

  prepare_app_log_object( ).

  get_smdb_content(
    EXCEPTIONS
      OTHERS = 1 ).

  " get DB system type
  CALL FUNCTION 'SCUI_GET_SAPCORE_INFO'
    TABLES
      tt_sapcoretab = lt_tcusapcore
    EXCEPTIONS
      OTHERS        = 0.
  LOOP AT lt_tcusapcore INTO ls_tcusapcore.
    IF ls_tcusapcore-value(21) = 'database system'.
      sv_db_type = ls_tcusapcore-value+21.
      EXIT.
    ENDIF.
  ENDLOOP.

*--------------------------------------------------------------------*
* Check for conditional stop for trouble shooting

  CALL FUNCTION 'FUNCTION_EXISTS'
    EXPORTING
      funcname           = sv_test_function
    EXCEPTIONS
      function_not_exist = 1
      OTHERS             = 2.
  IF sy-subrc = 0.
    sv_conditional_stop = abap_true.

    CALL 'C_SAPGPARAM' ID 'NAME'                          "#EC CI_CCALL
      FIELD 'transport/systemtype'
      ID 'VALUE' FIELD lv_sys_type.
    lv_sy_sid = sy-sysid.
    IF lv_sys_type = /sdf/cl_rc_chk_utility=>c_parameter-sys_type_sap AND lv_sy_sid = 'CVB'.
      sv_test_system = abap_true.
    ENDIF.
  ENDIF.

ENDMETHOD.