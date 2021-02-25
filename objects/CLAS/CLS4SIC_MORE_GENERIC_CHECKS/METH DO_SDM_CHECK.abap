  METHOD do_sdm_check.
    FIELD-SYMBOLS: <lt_ranges1>   TYPE ANY TABLE.
    DATA: ls_chk_result   TYPE ty_pre_cons_chk_result_str,
          ls_chk_result_f TYPE ty_pre_cons_chk_result_str, "for finished migrations
          ls_chk_result_e TYPE ty_pre_cons_chk_result_str, "for cancelled migrations
          lv_status       TYPE c,
          lv_len          TYPE i,
          lv_len_where    TYPE i,
          lv_offset       TYPE i,
          lv_description  TYPE LINE OF ty_pre_cons_chk_result_str-descriptions.
    DATA: lt_t000   TYPE TABLE OF sy-mandt,
          wa_client TYPE sy-mandt.
*Data necessary for selecting relevant SDM's:
    DATA: lwa_sdm_registration TYPE sdm_registration,
          lt_sdm_registration  TYPE TABLE OF sdm_registration,
          lwa_sdm_proc_status  TYPE sdm_proc_status.
    DATA: go_sdm_handler    TYPE REF TO cl_sdm_package_migration,
          lv_value_done     TYPE sdm_status_value_done,
          lt_filter         TYPE cl_shdb_pfw_selset=>tt_selset,
          lv_tabname        TYPE tabname,
          lv_statusfld      TYPE fieldname,
          lt_range_obj      TYPE RANGE OF char50,
          ls_condition      TYPE cl_shdb_pfw_selset=>ts_selset,
          ls_done_condition TYPE cl_shdb_pfw_seltab=>ts_named_seltab,
          lo_selset         TYPE REF TO cl_shdb_pfw_selset,
          lv_where_str      TYPE string.
    DATA: wa_qualified_mig TYPE LINE OF sdm_registration_tab.
    DATA: lv_ach TYPE df14l-ps_posid. "Application component.
    DATA lv_detailed_check TYPE string.
    DATA: lwa_parameter TYPE LINE OF tihttpnvp.
* ###########################################################################################################################
* Start check for parameter SBCSETS_ACTIVATE_IN_CLIENTS in SFWPARAM

* Read detailed Check flag
    READ TABLE it_parameter WITH KEY name = c_pre_chk_param_key-detailed_check INTO lwa_parameter.
    lv_detailed_check = lwa_parameter-value. CLEAR lwa_parameter.

    CLEAR ls_chk_result.
    ls_chk_result-check_sub_id = 'DO_SDMI_CHECK'.

    DATA et_issue_finished TYPE clms_t_hc_issue.
    DATA hc_ut_obj TYPE REF TO cl_sdmi_hc.

    SELECT mandt FROM t000 INTO TABLE lt_t000.
* Get all online qualified_migration_tab
    TRY.
        CALL METHOD cl_sdm_utils=>get_qualified_migrations
          EXPORTING
            iv_sum_execution = ''
          RECEIVING
            rt_migration     = DATA(qualified_migration_tab).
      CATCH cx_root.
        RETURN.
    ENDTRY.

    LOOP AT qualified_migration_tab INTO wa_qualified_mig.
      lv_len = strlen( wa_qualified_mig-migration_class ) .
      LOOP AT lt_t000 INTO wa_client.
        CLEAR lv_status.
        SELECT SINGLE migration_status FROM sdm_proc_status USING CLIENT @wa_client INTO @lv_status
              WHERE migration_class = @wa_qualified_mig-migration_class
                AND sum_phase = ' '.
*              AND migration_status = 'F' "finished.
*               OR migration_status = 'N'. "not relevant
        IF lv_detailed_check = 'X'.
          TRY.
              CALL METHOD cl_sdm_utils=>num_not_done_entries
                EXPORTING
                  iv_client     = wa_client
                  iv_class_name = wa_qualified_mig-migration_class
                RECEIVING
                  rv_num        = DATA(num_tbd)
                EXCEPTIONS
                  OTHERS        = 8.
            CATCH cx_root.
              CONCATENATE 'The SDMI ' wa_qualified_mig-migration_class(lv_len) ' cannot be checked for not-done entries ' wa_client INTO lv_description RESPECTING BLANKS.
              APPEND lv_description TO ls_chk_result-descriptions.
              ls_chk_result-return_code = c_cons_chk_return_code-warning.
*          APPEND ls_chk_result TO ct_chk_result.
*        CONTINUE.
          ENDTRY.
        ENDIF.

        IF num_tbd > 0 AND lv_status = 'F'.
          ls_chk_result-return_code = c_cons_chk_return_code-warning.
          lv_description = num_tbd && ' entries are found that are still/again valid for migration.'.
          CONCATENATE 'The SDMI (Silent Data Migration) ' wa_qualified_mig-migration_class(lv_len) ' finished in client ' wa_client ' but ' lv_description INTO lv_description RESPECTING BLANKS.
*          APPEND lv_description TO ls_chk_result_f-descriptions.
          APPEND lv_description TO ls_chk_result_f-descriptions.

*          APPEND ls_chk_result TO ct_chk_result.
        ELSEIF lv_status = 'C' OR lv_status = 'E'. "Cancelled or Error
          ls_chk_result-return_code = c_cons_chk_return_code-warning.
          CONCATENATE 'The SDMI (Silent Data Migration) ' wa_qualified_mig-migration_class(lv_len) ' is cancelled/erroneous in client ' wa_client '.' INTO lv_description RESPECTING BLANKS.
          APPEND lv_description TO ls_chk_result_e-descriptions.
          IF lv_detailed_check = 'X'.
            lv_description = num_tbd && ' relevant entries still to be migrated.'.
            CONCATENATE 'There are ' lv_description  INTO lv_description RESPECTING BLANKS.
            APPEND lv_description TO ls_chk_result_e-descriptions.
          ENDIF.
*          APPEND ls_chk_result TO ct_chk_result.
        ENDIF.
      ENDLOOP.

      IF ls_chk_result_f-descriptions IS NOT INITIAL.
        APPEND 'Explanation: It is expected that the SDMI migrates the data only once, because the application should write the data already in the new format.' TO ls_chk_result_f-descriptions.
        APPEND 'If relevant data is found for finished SDMIs, then the question is where this data is coming from.' TO ls_chk_result_f-descriptions.
        APPEND 'Please check whether the data is coming from Z-Coding and correct the source and the data.' TO ls_chk_result_f-descriptions.
        APPEND 'New data should not apply to the below selection criteria, cause then it is considered as "old" data that still needs to be migrated.' TO ls_chk_result_f-descriptions.
        APPEND LINES OF ls_chk_result_f-descriptions TO ls_chk_result-descriptions.
        CLEAR ls_chk_result_f.
      ENDIF.
      IF ls_chk_result_e-descriptions IS NOT INITIAL.
        APPEND 'Explanation: Cancelled/erroneous SDMIs can be restarted in transaction SDM_MON current client view with the button "Restart cancelled migration".' TO ls_chk_result_e-descriptions.
        CONCATENATE 'Please check the application log first for error identification and solution. (Object: SDMI_MIGRATION; External ID: ' wa_qualified_mig-migration_class(lv_len) '*' INTO lv_description RESPECTING BLANKS.
        APPEND lv_description TO ls_chk_result_e-descriptions.
        APPEND LINES OF ls_chk_result_e-descriptions TO ls_chk_result-descriptions.
        CLEAR ls_chk_result_e.
      ENDIF.
      IF ls_chk_result-descriptions IS NOT INITIAL.
        SELECT SINGLE c~ps_posid FROM tadir AS a
          INNER JOIN tdevc AS b ON a~devclass = b~devclass "#EC CI_BUFFJOIN
          INNER JOIN df14l AS c ON c~fctr_id = b~component
          INTO  @lv_ach WHERE a~pgmid = 'R3TR' AND a~object = 'CLAS' AND a~obj_name = @wa_qualified_mig-migration_class.
        lv_len = strlen( lv_ach ) .
        CONCATENATE 'For questions please open a message to the component of the SDMI class ' lv_ach(lv_len) '.' INTO lv_description RESPECTING BLANKS.
        APPEND lv_description TO ls_chk_result-descriptions.
* get select statement
        TRY.
            CREATE OBJECT go_sdm_handler TYPE (wa_qualified_mig-migration_class).
            lv_tabname    = go_sdm_handler->if_sdm_migration~get_table_name( ).
            lt_filter     = go_sdm_handler->if_sdm_migration~get_filter_conditions( ).
            lv_statusfld  = go_sdm_handler->if_sdm_migration~get_status_field( ).
            lv_value_done = go_sdm_handler->if_sdm_migration~get_status_value_done( ).
            IF <lt_ranges1> IS ASSIGNED.
              CLEAR <lt_ranges1>.
            ENDIF.
            CREATE DATA ls_done_condition-dref LIKE lt_range_obj.
            ASSIGN ls_done_condition-dref->* TO <lt_ranges1>.
            ls_done_condition-name = lv_statusfld.
            lt_range_obj =  VALUE #( ( sign = 'I' option = 'LT' low = lv_value_done ) ).
            <lt_ranges1> = lt_range_obj.

*Extend Filter with status_value_done at the right place
            IF lt_filter IS NOT INITIAL.
              ls_condition = lt_filter[ 1 ].
              IF ls_condition-dref2 IS NOT BOUND.
                ls_condition-op = 'AND'.
                ls_condition-name2 = ls_done_condition-name.
                ls_condition-dref2 = ls_done_condition-dref.
                lt_filter = VALUE cl_shdb_pfw_selset=>tt_selset( ( ls_condition ) ).
                lo_selset = NEW cl_shdb_pfw_selset( it_selset = lt_filter ).
              ELSE.
                lo_selset = NEW cl_shdb_pfw_selset( lt_filter ).
                lo_selset->add_on_top( ls_done_condition ).
              ENDIF.
            ELSE. "keine Condition...
              ls_condition-name1 =  ls_done_condition-name.
              ls_condition-dref1 =  ls_done_condition-dref.
              lt_filter = VALUE cl_shdb_pfw_selset=>tt_selset( ( ls_condition ) ).
              lo_selset = NEW cl_shdb_pfw_selset( it_selset = lt_filter ).
            ENDIF.
            lv_where_str = lo_selset->get_where_clause( ).
            lv_len = strlen( lv_tabname ) .
            APPEND 'The following select statement can be used to see the relevant data for migration: (check in correct client)' TO ls_chk_result-descriptions.
            lv_len_where = strlen( lv_where_str ).
            IF lv_len_where > 160.
              lv_offset = 160.
            ELSE.
              lv_offset = lv_len_where.
            ENDIF.
            CONCATENATE 'SELECT * FROM ' lv_tabname(lv_len) ' WHERE ' lv_where_str(lv_offset) INTO lv_description RESPECTING BLANKS.
            APPEND lv_description TO ls_chk_result-descriptions.
            IF lv_len_where > 160.
              lv_len_where -= 160.
              IF lv_len_where > 195.
                lv_offset = 195.
              ELSE.
                lv_offset = lv_len_where.
              ENDIF.
              lv_description = lv_where_str+160(lv_len_where).
              APPEND lv_description TO ls_chk_result-descriptions.
            ENDIF.
            IF lv_len_where > 195.
              lv_description = lv_where_str+355.
              APPEND lv_description TO ls_chk_result-descriptions.
            ENDIF.
          CATCH cx_root.
*      WRITE: / '@5C@Issue instanciateing the SDM class', iv_sdm_name.
*            EXIT.
        ENDTRY.
*end get select statement


        APPEND ls_chk_result TO ct_chk_result.
        CLEAR ls_chk_result-descriptions.
      ENDIF.
    ENDLOOP.

* IF not detailed check -> give a message to run with detailed_check option..
    IF lv_detailed_check = ' '.
      ls_chk_result-check_sub_id = 'DO_SDMI_CHECK-Detailed-option'.
      ls_chk_result-return_code = c_cons_chk_return_code-warning.
      APPEND 'This check was executed in normal mode due to performance reasons. ' TO ls_chk_result-descriptions.
      APPEND 'If the consistency check is run with detailed option, then it will also check whether all finished SDMIs do not have any data left, that still needs to be migrated.' TO ls_chk_result-descriptions.
      APPEND 'To do this: mark S-Item in the list and click on "Check Consistency Details"' TO ls_chk_result-descriptions.
      APPEND 'All SDMIs can be seen in transaction SDM_MON.' TO ls_chk_result-descriptions.
      APPEND 'Please ignore this message in case detailed check was consulted already .' TO ls_chk_result-descriptions.
      APPEND ls_chk_result TO ct_chk_result.
    ELSEIF ct_chk_result IS INITIAL.
* Maybe no SDMI job is runnnig at all ...
      lv_len = lines( qualified_migration_tab ).
      IF lv_len > 0.
        SELECT COUNT( * ) FROM sdm_proc_status USING ALL CLIENTS  WHERE migration_status IS NOT INITIAL INTO @lv_len.
        IF lv_len = 0.
          ls_chk_result-check_sub_id = 'DO_SDMI_CHECK-is_job_running?'.
          ls_chk_result-return_code = c_cons_chk_return_code-warning.
          APPEND 'There are relevant SDMI´s but no status is currently filled. Please check whether the SDMI job SAP_SDM_EXECUTOR_ONLINE_MIGR from TA S_JOB_REPO' TO ls_chk_result-descriptions.
          APPEND 'is running. See transaction SDM_MON for more details and SAP note 2907976.' TO ls_chk_result-descriptions.
          APPEND ls_chk_result TO ct_chk_result.
        ENDIF.
      ENDIF.
      ls_chk_result-check_sub_id = 'DO_SDMI_CHECK-Detailed-option'.
      ls_chk_result-return_code = c_cons_chk_return_code-success.
      APPEND 'There were no findings during SDMI detailed check.' TO ls_chk_result-descriptions.
    ENDIF.
  ENDMETHOD.