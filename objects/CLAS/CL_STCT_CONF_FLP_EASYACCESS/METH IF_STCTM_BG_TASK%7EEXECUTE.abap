METHOD if_stctm_bg_task~execute.

  DATA ls_variant TYPE t_variant.
  DATA lv_sys TYPE abap_bool.
  DATA lv_cus TYPE abap_bool.
  DATA lv_overwrite TYPE abap_bool.

  DATA lv_property_id TYPE c LENGTH 40.
  DATA lv_property_value TYPE c LENGTH 1024.

  DATA lv_rc_ret TYPE i.
  DATA lv_rc TYPE i.

  DATA lv_warn_ret TYPE abap_bool VALUE abap_false.
  DATA lv_error_ret TYPE abap_bool VALUE abap_false.

  DATA lv_warn TYPE abap_bool VALUE abap_false.
  DATA lv_error TYPE abap_bool VALUE abap_false.

*****************************************

  " get workbench request
  DATA ls_task_wreq TYPE cl_stctm_tasklist=>ts_task.
  DATA lo_task_wreq TYPE REF TO cl_stct_create_request_wbench.
  DATA lx_cast_exc_wreq TYPE REF TO cx_sy_move_cast_error ##NEEDED.

  DATA lv_request_work TYPE char20.

  " get stored data from prerequiste task 'CREATE WORKBENCH REQUEST'
  READ TABLE ir_tasklist->ptx_task INTO ls_task_wreq WITH KEY taskname = 'CL_STCT_CREATE_REQUEST_WBENCH'.

  IF sy-subrc = 0.
    TRY.
        lo_task_wreq ?= ls_task_wreq-r_task.
        lv_request_work = lo_task_wreq->p_request_workbench.

      CATCH cx_sy_move_cast_error INTO lx_cast_exc_wreq.
        MESSAGE e000 WITH 'Could not get Request from Task CL_STCT_CREATE_REQUEST_WBENCH' INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.
    ENDTRY.
  ENDIF.

  " get customizing request
  DATA ls_task_creq TYPE cl_stctm_tasklist=>ts_task.
  DATA lo_task_creq TYPE REF TO cl_stct_create_request_cust.
  DATA lx_cast_exc_creq TYPE REF TO cx_sy_move_cast_error ##NEEDED.

  DATA lv_request_cust TYPE char20.

  " get stored data from prerequiste task 'CREATE WORKBENCH REQUEST'
  READ TABLE ir_tasklist->ptx_task INTO ls_task_creq WITH KEY taskname = 'CL_STCT_CREATE_REQUEST_CUST'.

  IF sy-subrc = 0.
    TRY.
        lo_task_creq ?= ls_task_creq-r_task.
        lv_request_cust = lo_task_creq->p_request_customizing.

      CATCH cx_sy_move_cast_error INTO lx_cast_exc_wreq.
        MESSAGE e000 WITH 'Could not get Request from Task CL_STCT_CREATE_REQUEST_CUST' INTO if_stctm_task~pr_log->dummy ##MG_ARG_LEN ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.
    ENDTRY.
  ENDIF.

*****************************************

  " get UI parameter

  LOOP AT pt_variant INTO ls_variant.
    CASE  ls_variant-selname.
      WHEN 'P_SYS'.
        lv_sys = ls_variant-low.
      WHEN 'P_CUS'.
        lv_cus = ls_variant-low.
      WHEN 'P_OVER'.
        lv_overwrite  = ls_variant-low.
    ENDCASE.
  ENDLOOP.

*****************************************

  IF i_check = 'X'.

    " authority check
    cl_stct_setup_utilities=>check_authority(
       EXCEPTIONS
         no_authority  = 1
         OTHERS        = 2 ).
    IF sy-subrc <> 0.
      if_stctm_task~pr_log->add_syst( ).
      RAISE error_occured.
    ELSE.
      MESSAGE s005 INTO if_stctm_task~pr_log->dummy.
      if_stctm_task~pr_log->add_syst( ).
    ENDIF.

    " check flp setting all in current client /UI2/FLP_CUS_CONF
    IF lv_cus = abap_true.
      IF lv_overwrite = abap_false.

      " check APPFINDER_EASYACCESSMENU_SAPMENU
      lv_property_id = 'APPFINDER_EASYACCESSMENU_SAPMENU'.
      lv_property_value = 'true'.

        me->check_flp_setting_cus(
        EXPORTING
          i_property_id    = lv_property_id                " FLP Property ID
          i_property_value = lv_property_value             " FLP Property Value
        IMPORTING
          e_rc        =  lv_rc_ret
      ).

      IF lv_rc_ret = 2.
        lv_warn = abap_true.
      ENDIF.

      " check APPFINDER_EASYACCESSMENU_USERMENU
      lv_property_id = 'APPFINDER_EASYACCESSMENU_USERMENU'.
      lv_property_value = 'true'.

        me->check_flp_setting_cus(
        EXPORTING
          i_property_id    = lv_property_id                " FLP Property ID
          i_property_value = lv_property_value             " FLP Property Value
        IMPORTING
          e_rc        =  lv_rc_ret
      ).

      IF lv_rc_ret = 2.
        lv_warn = abap_true.
      ENDIF.

      IF lv_warn = abap_true.
          MESSAGE w000 WITH 'Confirm overwrite by checking the option' 'in the Parameter UI' 'or continue by clicking' '''Execute (F8)''' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
          RAISE warning_occured.
        ENDIF.
      ENDIF.
    ENDIF.

    " check flp setting all in clients /UI2/FLP_SYS_CONF
    IF lv_sys = abap_true.
      IF lv_overwrite = abap_false.

        " check APPFINDER_EASYACCESSMENU_SAPMENU
        lv_property_id = 'APPFINDER_EASYACCESSMENU_SAPMENU'.
        lv_property_value = 'true'.

        me->check_flp_setting_sys(
          EXPORTING
            i_property_id    = lv_property_id                " FLP Property ID
            i_property_value = lv_property_value             " FLP Property Value
          IMPORTING
            e_rc        =  lv_rc_ret
        ).

        IF lv_rc_ret = 2.
          lv_warn = abap_true.
        ENDIF.

        " check APPFINDER_EASYACCESSMENU_USERMENU
        lv_property_id = 'APPFINDER_EASYACCESSMENU_USERMENU'.
        lv_property_value = 'true'.

        me->check_flp_setting_sys(
          EXPORTING
            i_property_id    = lv_property_id                " FLP Property ID
            i_property_value = lv_property_value             " FLP Property Value
          IMPORTING
            e_rc        =  lv_rc_ret
        ).

        IF lv_rc_ret = 2.
          lv_warn = abap_true.
        ENDIF.

        IF lv_warn = abap_true.
          MESSAGE w000 WITH 'Confirm overwrite by checking the option' 'in the Parameter UI' 'or continue by clicking' '''Execute (F8)''' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
          RAISE warning_occured.
        ENDIF.
      ENDIF.

    ENDIF.

  ELSE. "start execution

    " configure flp current client /UI2/FLP_CUS_CONF
    IF lv_cus = abap_true.

      " check lv_request_cust is not emtpy
      IF lv_request_cust IS INITIAL.
        MESSAGE e000 WITH 'No Customizing Request available' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).
        RAISE error_occured.
      ENDIF.

      MESSAGE s000 WITH 'Configure FLP setting' '(/UI2/FLP_CUS_CONF):' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
      if_stctm_task~pr_log->add_syst( ).

      " conf APPFINDER_EASYACCESSMENU_SAPMENU
      lv_property_id = 'APPFINDER_EASYACCESSMENU_SAPMENU'.
      lv_property_value = 'true'.

      me->config_flp_setting_cus(
        EXPORTING
          i_property_id    =  lv_property_id                " FLP Property ID
          i_property_value =  lv_property_value             " FLP Property Value
          i_request_cust   =  lv_request_cust               " Customizing Request
          i_overwrite      =  lv_overwrite                  " Overwrite
        IMPORTING
          e_warning        =  lv_warn_ret
          e_error          =  lv_error_ret
      ).

      IF lv_warn_ret = abap_true.
        lv_warn = abap_true.
      ENDIF.

      IF lv_error_ret = abap_true.
        lv_error = abap_true.
      ENDIF.

      " conf APPFINDER_EASYACCESSMENU_USERMENU
      lv_property_id = 'APPFINDER_EASYACCESSMENU_USERMENU'.
      lv_property_value = 'true'.

      me->config_flp_setting_cus(
        EXPORTING
          i_property_id    =  lv_property_id                " FLP Property ID
          i_property_value =  lv_property_value             " FLP Property Value
          i_request_cust   =  lv_request_cust               " Customizing Request
          i_overwrite      =  lv_overwrite                  " Overwrite
        IMPORTING
          e_warning        =  lv_warn_ret
          e_error          =  lv_error_ret
      ).

      IF lv_warn_ret = abap_true.
        lv_warn = abap_true.
      ENDIF.

      IF lv_error_ret = abap_true.
        lv_error = abap_true.
      ENDIF.

    ENDIF.

    " configure flp setting in all clients /UI2/FLP_SYS_CONF
    IF lv_sys = abap_true.

      " check lv_request_work is not emtpy
    IF lv_request_work IS INITIAL.
      MESSAGE e000 WITH 'No Workbench Request available' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
      if_stctm_task~pr_log->add_syst( ).
      RAISE error_occured.
    ENDIF.

      MESSAGE s000 WITH 'Configure FLP setting' '(/UI2/FLP_SYS_CONF):' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
      if_stctm_task~pr_log->add_syst( ).

      " conf APPFINDER_EASYACCESSMENU_SAPMENU
    lv_property_id = 'APPFINDER_EASYACCESSMENU_SAPMENU'.
    lv_property_value = 'true'.

      me->config_flp_setting_sys(
      EXPORTING
        i_property_id    =  lv_property_id                " FLP Property ID
        i_property_value =  lv_property_value             " FLP Property Value
        i_request_work   =  lv_request_work               " Workbench Request
        i_overwrite      =  lv_overwrite                  " Overwrite
      IMPORTING
        e_warning        =  lv_warn_ret
        e_error          =  lv_error_ret
    ).

    IF lv_warn_ret = abap_true.
      lv_warn = abap_true.
    ENDIF.

    IF lv_error_ret = abap_true.
      lv_error = abap_true.
    ENDIF.

      " conf APPFINDER_EASYACCESSMENU_USERMENU
    lv_property_id = 'APPFINDER_EASYACCESSMENU_USERMENU'.
    lv_property_value = 'true'.

      me->config_flp_setting_sys(
      EXPORTING
        i_property_id    =  lv_property_id                " FLP Property ID
        i_property_value =  lv_property_value             " FLP Property Value
        i_request_work   =  lv_request_work               " Workbench Request
        i_overwrite      =  lv_overwrite                  " Overwrite
      IMPORTING
        e_warning        =  lv_warn_ret
        e_error          =  lv_error_ret
    ).

    IF lv_warn_ret = abap_true.
      lv_warn = abap_true.
    ENDIF.

    IF lv_error_ret = abap_true.
      lv_error = abap_true.
      ENDIF.

    ENDIF.

    " set overall task status
    IF lv_error = abap_true.
      RAISE error_occured.
    ENDIF.

    IF lv_warn = abap_true.
      RAISE warning_occured.
    ENDIF.

  ENDIF."End of execution

ENDMETHOD.