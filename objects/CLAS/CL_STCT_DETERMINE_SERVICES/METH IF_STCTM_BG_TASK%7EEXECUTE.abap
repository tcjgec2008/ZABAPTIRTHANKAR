  METHOD if_stctm_bg_task~execute.

    DATA: ls_task TYPE cl_stctm_tasklist=>ts_task.
    DATA: lo_task TYPE REF TO cl_stct_select_business_roles.
    DATA: lx_cast_exc TYPE REF TO cx_sy_move_cast_error ##NEEDED.

    DATA lt_business_roles TYPE stct_agr_br_table.
    DATA ls_business_roles TYPE stct_agr_br.

    DATA: lv_agr_name        TYPE          agr_name,
          lt_agr_define      TYPE TABLE OF agr_define,
          lt_agr_menu_groups TYPE          ty_t_agr_menu_groups.

    DATA: lv_log_txt TYPE string.
    DATA: lt_log TYPE TABLE OF string.

    DATA: lt_catalog_id TYPE TABLE OF string.
    DATA: lv_catalog_id TYPE string.
    DATA: lv_tmp TYPE string.
*
    DATA: lt_services_odata TYPE ty_t_service.
    DATA: ls_services_odata TYPE ty_s_service.

    DATA: lt_services_odata_v4 TYPE ty_t_service.
    DATA: lt_services_icf    TYPE TABLE OF string.

    DATA: ls_it_services TYPE stct_input_data.

    DATA: lv_details TYPE string.

**********************************************************************************************

    " get stored data from prerequiste task
    READ TABLE ir_tasklist->ptx_task INTO ls_task WITH KEY taskname = 'CL_STCT_SELECT_BUSINESS_ROLES'.

    IF sy-subrc = 0.
      TRY.
          lo_task ?= ls_task-r_task.
          lt_business_roles = lo_task->i_business_roles.

        CATCH cx_sy_move_cast_error INTO lx_cast_exc ##NO_HANDLER.
          " error handling
      ENDTRY.

    ENDIF.

**********************************************************************************************

    IF i_check = 'X'. "checks

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

    ELSE. "execution

      " Remove not selected roles
      DELETE lt_business_roles WHERE flag <> 'X'.

      IF lt_business_roles IS INITIAL.
        MESSAGE w000 WITH 'No Business Roles available'(101) INTO if_stctm_task~pr_log->dummy.
        if_stctm_task~pr_log->add_syst( ).
        EXIT.
      ENDIF.


*****************************************************************************

      " Log details
      DATA(lv_count) = lines( lt_business_roles ).
      lv_log_txt = |Roles (Total: | && lv_count && |)| ##NO_TEXT.
      APPEND lv_log_txt TO lt_log.

      " Determine servies per role
      LOOP AT lt_business_roles INTO ls_business_roles.

        " Get catalogs
        SELECT * FROM agr_define INTO TABLE lt_agr_define WHERE agr_name = ls_business_roles-agr_name.

        IF lt_agr_define IS NOT INITIAL.

          SELECT h~agr_name   AS agr_name
                 h~object_id  AS object_id
                 h~reporttype AS reporttype
                 h~report     AS report
                 b~url        AS url
            FROM agr_hier AS h INNER JOIN agr_buffi AS b "#EC CI_BUFFJOIN
             ON h~agr_name  = b~agr_name
            AND h~object_id = b~object_id
            INTO CORRESPONDING FIELDS OF TABLE lt_agr_menu_groups
            FOR ALL ENTRIES IN lt_agr_define
            WHERE h~agr_name = lt_agr_define-agr_name
              AND h~reporttype = 'OT'
              AND h~report     = 'CAT_PROVIDER'.

        ENDIF.

        " Prepare table of catalog_ids
        LOOP AT lt_agr_menu_groups INTO DATA(ls_agr_menu_groups).

          SPLIT ls_agr_menu_groups-url AT '?' INTO lv_catalog_id lv_tmp.
          APPEND lv_catalog_id TO lt_catalog_id.

        ENDLOOP.

        " Log details
        lv_log_txt = ls_business_roles-agr_name && '/' && ls_business_roles-agr_description.
        APPEND lv_log_txt TO lt_log.

      ENDLOOP.

      " Remove duplicates fr. catalog_ids
      SORT lt_catalog_id DESCENDING.
      DELETE ADJACENT DUPLICATES FROM lt_catalog_id.

********************************************

      DATA lo_fdm_catalog_api TYPE REF TO /ui2/cl_fdm_catalog_api.
      DATA lo_fdm_service_api TYPE REF TO /ui2/cl_fdm_service_api.
      DATA lo_catalog_items TYPE REF TO /ui2/if_fdm_catalog_items.
      DATA et_icf_service_key TYPE /ui2/if_fdm_service_api=>tth_icf_service_key.
      DATA et_odata_service_key TYPE /ui2/if_fdm_service_api=>tth_odata_service_key.

      " Convert catalog keys
      TRY .

          LOOP AT lt_catalog_id INTO lv_catalog_id.
            DATA(lv_catalog_key) = /ui2/cl_fdm_pb_adapter=>cnv_catpage_id_to_catalog_key( iv_catalogpage_id =  lv_catalog_id ).
            DATA lt_catalog_key TYPE /ui2/if_fdm=>tt_catalog_key.
            APPEND lv_catalog_key TO lt_catalog_key.
          ENDLOOP.

        CATCH /ui2/cx_fdm_pb_adapter INTO DATA(lx_fdm_pb_adapter).
          MESSAGE e000 WITH 'Failed to convert catalog ids' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
      ENDTRY.

      " Init catalog api and get items
      TRY .
          CREATE OBJECT lo_fdm_catalog_api
            EXPORTING
              iv_scope     = 'CUST'
              iv_use_cache = abap_false.

          lo_catalog_items = lo_fdm_catalog_api->/ui2/if_fdm_catalog_api~get_catalog_items( lt_catalog_key ).

        CATCH /ui2/cx_fdm_input_invalid /ui2/cx_fdm_cache_invalid
              /ui2/cx_fdm_not_found /ui2/cx_fdm_unexpected INTO DATA(lx_fdm).
          MESSAGE e000 WITH 'Failed to initialize catalog api and get items' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
      ENDTRY.

      " Get services
      CREATE OBJECT lo_fdm_service_api.

      lo_fdm_service_api->/ui2/if_fdm_service_api~get_item_services( io_catalog_items = lo_catalog_items ).

      DATA(et_item_services) = lo_fdm_service_api->/ui2/if_fdm_service_api~get_item_services( io_catalog_items = lo_catalog_items ).

      LOOP AT et_item_services ASSIGNING FIELD-SYMBOL(<ls_item_services>).

        "get all oData services
        LOOP AT <ls_item_services>-odata_service_keys ASSIGNING FIELD-SYMBOL(<ls_odata_service_key>).
          INSERT <ls_odata_service_key> INTO TABLE et_odata_service_key.
        ENDLOOP.

        "get all ICF services
        LOOP AT <ls_item_services>-icf_service_keys ASSIGNING FIELD-SYMBOL(<ls_icf_service_key>).
          INSERT <ls_icf_service_key> INTO TABLE et_icf_service_key.
        ENDLOOP.

      ENDLOOP.

      " get OData v4 services
      me->get_srv_v4_for_catalog_ids(
        EXPORTING
          it_catalog_id  = lt_catalog_id
        IMPORTING
          et_services_v4 = lt_services_odata_v4
      ).

********************************************

      " Prep OData/ICF services
      CLEAR: it_services, it_services_v4, it_services_icf.

      LOOP AT et_odata_service_key INTO DATA(ls_odata_service_key).
        ls_services_odata-service_name = ls_odata_service_key-ext_service_name.
        ls_services_odata-service_version = ls_odata_service_key-version.
        APPEND ls_services_odata TO lt_services_odata.
      ENDLOOP.

      LOOP AT lt_services_odata INTO ls_services_odata.
        ls_it_services-service = ls_services_odata-service_name.
        ls_it_services-version = ls_services_odata-service_version.
        APPEND ls_it_services TO it_services.
      ENDLOOP.

      " Prep OData services v4
      LOOP AT lt_services_odata_v4 INTO ls_services_odata.
        ls_it_services-service = ls_services_odata-service_name.
        ls_it_services-version = ls_services_odata-service_version.
        APPEND ls_it_services TO it_services_v4.
      ENDLOOP.

      " Prep ICF services
      LOOP AT et_icf_service_key INTO DATA(ls_icf_service_key).
        IF ls_icf_service_key-url NS 'odata4'.
          APPEND ls_icf_service_key-url TO lt_services_icf.
        ENDIF.
      ENDLOOP.

      it_services_icf = lt_services_icf.

********************************************

      " Log details (Catalog IDs)
      lv_count = lines( lt_catalog_key ).
      lv_log_txt = '---------------------------------------------------------------------------'.
      APPEND lv_log_txt TO lt_log.
      lv_log_txt = |Catalogs (Total: | &&  lv_count && |)| ##NO_TEXT.
      APPEND lv_log_txt TO lt_log.
      APPEND LINES OF lt_catalog_key TO lt_log.


      " Log details (OData services)
      lv_count = lines( lt_services_odata ).
      lv_log_txt = '---------------------------------------------------------------------------'.
      APPEND lv_log_txt TO lt_log.
      lv_log_txt = |OData Services (Total: | && lv_count && |)| ##NO_TEXT.
      APPEND lv_log_txt TO lt_log.

      LOOP AT lt_services_odata INTO ls_services_odata.
        lv_log_txt = ls_services_odata-service_name && | | && ls_services_odata-service_version.
        APPEND lv_log_txt TO lt_log.
      ENDLOOP.

      LOOP AT lt_services_odata_v4 INTO ls_services_odata.
        lv_log_txt = ls_services_odata-service_name && | | && ls_services_odata-service_version && | v4 |.
        APPEND lv_log_txt TO lt_log.
      ENDLOOP.

      " Log details(ICF services)
      lv_count = lines( lt_services_icf ).
      lv_log_txt = '---------------------------------------------------------------------------'.
      APPEND lv_log_txt TO lt_log.
      lv_log_txt = |ICF Services (Total: | && lv_count && |)| ##NO_TEXT.
      APPEND lv_log_txt TO lt_log.
      APPEND LINES OF lt_services_icf TO lt_log.

********************************************

      MESSAGE s000 WITH 'OData Services:' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
      if_stctm_task~pr_log->add_syst( ).

      IF lt_services_odata IS INITIAL.

        MESSAGE s000 WITH 'no OData services determined' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

      ELSE.

        LOOP AT lt_services_odata INTO ls_services_odata.
          MESSAGE s000 WITH ls_services_odata-service_name ls_services_odata-service_version INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
        ENDLOOP.

        LOOP AT lt_services_odata_v4 INTO ls_services_odata.
          MESSAGE s000 WITH ls_services_odata-service_name ls_services_odata-service_version 'v4' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
        ENDLOOP.

      ENDIF.

      MESSAGE s101 WITH '------------------------------' '------------------------------' '------------------------------' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
      if_stctm_task~pr_log->add_syst( ).

      MESSAGE s000 WITH 'ICF Services:' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
      if_stctm_task~pr_log->add_syst( ).


      IF lt_services_icf IS INITIAL.

        MESSAGE s000 WITH 'no ICF services determined' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
        if_stctm_task~pr_log->add_syst( ).

      ELSE.

        LOOP AT lt_services_icf INTO DATA(ls_services_icf).
          MESSAGE s000 WITH ls_services_icf INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
          if_stctm_task~pr_log->add_syst( ).
        ENDLOOP.

      ENDIF.

      " Output log details
      LOOP AT lt_log INTO DATA(lv_log).
        lv_details = lv_details && lv_log && ';'.
      ENDLOOP.

      MESSAGE s101 WITH '------------------------------' '------------------------------' '------------------------------' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
      if_stctm_task~pr_log->add_syst( ).

      MESSAGE s000 WITH 'Detailed log (click icon)' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
      if_stctm_task~pr_log->add_syst( lv_details ).

    ENDIF.

  ENDMETHOD.