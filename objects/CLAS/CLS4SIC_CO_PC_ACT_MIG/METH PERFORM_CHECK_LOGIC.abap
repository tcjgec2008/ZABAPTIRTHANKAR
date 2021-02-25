  METHOD perform_check_logic.

    DATA: c1                    TYPE cursor,
          c2                    TYPE cursor,
          lt_t001k              TYPE STANDARD TABLE OF  ty_t001k_fields,
          ls_t001k              TYPE  ty_t001k_fields,
          ls_xbew_table         TYPE ty_table,
          lt_xbew               TYPE STANDARD TABLE OF ty_xbew_fields,
          ls_xbew               TYPE ty_xbew_fields,
          lt_xbewh              TYPE STANDARD TABLE OF ty_xbew_fields,
          ls_xbewh              TYPE ty_xbew_fields,
          lt_mara               TYPE STANDARD TABLE OF ty_mandt_matnr_mtart,
          ls_mara               TYPE ty_mandt_matnr_mtart,
          lt_ckmlhd             TYPE STANDARD TABLE OF ty_mandt_kalnr,
          lt_distinct_mtart     TYPE STANDARD TABLE OF ty_mandt_matnr_mtart,
          lt_t134m              TYPE STANDARD TABLE OF ty_mandt_mtart_wertu,
          lv_ml_is_active       TYPE boole_d,
          lv_act_cost_is_active TYPE boole_d,
          lv_ckmlhd_is_missing  TYPE boole_d,
          lv_check_hist_table   TYPE boole_d,
          lv_xbew_sql_where     TYPE string,
          lv_xbewh_sql_where    TYPE string,
          lv_xbew_sql_fields    TYPE string,
          lv_xbewh_sql_fields   TYPE string,
          lv_ktopl              TYPE t001-ktopl,
          lt_t030               TYPE tt_t030,
          ls_marv               TYPE ty_marv_fields,
          lt_ckmlpp             TYPE tt_ckmlpp,
          lt_ckmlcr             TYPE tt_ckmlcr,
          lt_ckmlct_prev_bwkey  TYPE tt_curtp,
          lt_ckmlct_curr_bwkey  TYPE tt_curtp,
          ls_t001k_ml_act_prev  TYPE ty_mandt_bwkey_bukrs,
        lx_error          TYPE REF TO cx_root,
        lt_t001               TYPE  tt_t001,
        lt_t001w              TYPE  tt_t001w.
    TRY.

*Retrieve valuation areas
        OPEN CURSOR WITH HOLD c1 FOR SELECT mandt bwkey bukrs bwmod
          FROM t001k CLIENT SPECIFIED
          ORDER BY mandt bukrs.      "#EC CI_BYPASS. "#EC CI_BUFFCLIENT

        DO.
          FETCH NEXT CURSOR c1 INTO TABLE lt_t001k PACKAGE SIZE mv_package_size.
          IF sy-subrc <> 0.
            EXIT. " no more entries to process
          ELSE.
*Check, if corresponding T001 entry exists, if assignment exists to valuation area in T001K
           check_t001_exists( EXPORTING it_t001k = lt_t001k ).

*Check, if corresponding T001w entry exists for each entry in T001K
           check_t001w_exists( EXPORTING it_t001k = lt_t001k ).


*Execute for each valuation areas
            LOOP AT lt_t001k INTO ls_t001k.

              lv_ktopl = get_t001_ktopl( is_t001k = ls_t001k ).


              lv_ml_is_active = is_ml_active( iv_mandt = ls_t001k-mandt
                                              iv_bwkey = ls_t001k-bwkey ).

              lv_act_cost_is_active = is_actual_costing_active( iv_mandt = ls_t001k-mandt
                                                                iv_bwkey = ls_t001k-bwkey ).


*If ML is active, compare CURTPs from CKMLCT table ... Needs to be consistent for same BUKRS
              IF lv_ml_is_active = abap_true.

                get_ckmlct_entries( EXPORTING iv_mandt = ls_t001k-mandt
                                              iv_bwkey = ls_t001k-bwkey
                                    IMPORTING et_ckmlct = lt_ckmlct_curr_bwkey ).

*Only perform check, if BUKRS is same in current and previous loop
                IF ls_t001k_ml_act_prev-mandt = ls_t001k-mandt AND
                   ls_t001k_ml_act_prev-bukrs = ls_t001k-bukrs.

                  check_ckmlct_entries( EXPORTING it_ckmlct_curr_bwkey = lt_ckmlct_curr_bwkey
                                                  it_ckmlct_prev_bwkey = lt_ckmlct_prev_bwkey
                                                  iv_mandt             = ls_t001k-mandt
                                                  iv_bukrs             = ls_t001k-bukrs
                                                  iv_bwkey_prev        = ls_t001k_ml_act_prev-bwkey
                                                  iv_bwkey_curr        = ls_t001k-bwkey ).

                ENDIF.

*Assign current data to previous structures for next loop iteration
                lt_ckmlct_prev_bwkey = lt_ckmlct_curr_bwkey.
                ls_t001k_ml_act_prev-mandt = ls_t001k-mandt.
                ls_t001k_ml_act_prev-bukrs = ls_t001k-bukrs.
                ls_t001k_ml_act_prev-bwkey = ls_t001k-bwkey.
              ENDIF.

*Processing for MBEW, EBEW, QBEW and OBEW table
              LOOP AT mt_xbew_tables INTO ls_xbew_table.

*Retrieve Dynamic SQL statements (fields and WHERE condition)
                lv_xbew_sql_where = get_xbew_where_cond( iv_table_name = ls_xbew_table-table_name
                                                         is_t001k = ls_t001k ).


                lv_xbew_sql_fields = get_xbew_fields( iv_table_name = ls_xbew_table-table_name
                                                      iv_only_key_fields = abap_false ).


                OPEN CURSOR WITH HOLD c2 FOR SELECT (lv_xbew_sql_fields)
                  FROM (ls_xbew_table-table_name) CLIENT SPECIFIED
                  WHERE (lv_xbew_sql_where).

                DO.
                  FETCH NEXT CURSOR c2 INTO CORRESPONDING FIELDS OF TABLE lt_xbew PACKAGE SIZE mv_package_size.
                  IF sy-subrc <> 0.
                    EXIT. " no more entries to process
                  ELSE.
                    ASSERT lt_xbew IS NOT INITIAL. " should never happen with the EXIT check before, but just to be sure to have no empty FOR ALL ENTRIES table!


*Fetch data, needed for later analysis
                    IF ls_marv-mandt <> ls_t001k-mandt OR
                       ls_marv-bukrs <> ls_t001k-bukrs.
                      get_marv_entry( EXPORTING is_t001k = ls_t001k
                                      IMPORTING es_marv = ls_marv ).
                    ENDIF.


                    get_account_determinat_entries( EXPORTING is_t001k = ls_t001k
                                                                iv_ktopl = lv_ktopl
                                                                it_xbew = lt_xbew
                                                      IMPORTING et_t030 = lt_t030 ).

                    get_ckmlhd_entries( EXPORTING iv_ml_is_active = lv_ml_is_active
                                                  it_xbew = lt_xbew
                                        IMPORTING et_ckmlhd = lt_ckmlhd ).


                    get_mara_entries( EXPORTING it_xbew = lt_xbew
                                      IMPORTING et_mara = lt_mara
                                                et_distinct_mtart = lt_distinct_mtart ).


                    get_t134m_entries( EXPORTING it_distinct_mtart = lt_distinct_mtart
                                                 iv_bwkey = ls_t001k-bwkey
                                       IMPORTING et_t134m = lt_t134m ).


*If ML is active before S/4HANA --> Retrieve data for consistency check between CKMLPP/CKMLCR and xBEWH
                    IF lv_ml_is_active = abap_true.

                      get_xbewh_pp_cr_entries( EXPORTING is_marv = ls_marv
                                                           iv_hist_table_name = ls_xbew_table-history_table_name
                                                           it_xbew = lt_xbew
                                                           iv_act_cost_is_active = lv_act_cost_is_active
                                                 IMPORTING et_xbewh = lt_xbewh
                                                           et_ckmlpp = lt_ckmlpp
                                                           et_ckmlcr = lt_ckmlcr ).
                    ENDIF.

                    LOOP AT lt_xbew INTO ls_xbew.

*Save, which table is currently processed
                      ls_xbew-xbew_table_name = ls_xbew_table-table_name.


*Check, if transactional fields (LBKUM, SALK3 or VKSAL) are filled
                      check_xbew_trans_fields_filled( CHANGING cs_xbew = ls_xbew ).


*Check, if CKMLHD record is missing ... Only relevant, if ML is active before S/4HANA
                      lv_ckmlhd_is_missing = check_ckmlhd_is_missing( iv_ml_is_active = lv_ml_is_active
                                                                      it_ckmlhd = lt_ckmlhd
                                                                      is_xbew = ls_xbew ).

*Check, if period in xBEW (fields: LFMON or LFGJA) is initial
                      check_xbew_init_period( EXPORTING is_xbew = ls_xbew
                                              CHANGING cv_check_hist_table = lv_check_hist_table ).

*Check, if corresponding MARA entry exists
                      check_mara_exists( EXPORTING iv_ckmlhd_is_missing = lv_ckmlhd_is_missing
                                                   it_mara = lt_mara
                                                   is_xbew = ls_xbew
                                         IMPORTING es_mara = ls_mara
                                         CHANGING cv_check_hist_table = lv_check_hist_table ).


*Check, if corresponding T134M entry exists or T134M-WERTU = 'X' (if LBKUM, SALK3 or VKSAL is set)
                      check_t134m_exists_wertu( EXPORTING iv_ckmlhd_is_missing = lv_ckmlhd_is_missing
                                                          is_mara = ls_mara
                                                          it_t134m = lt_t134m
                                                          is_xbew = ls_xbew
                                                CHANGING  cv_check_hist_table = lv_check_hist_table  ).

*Check, if account assignment is missing
                      check_xbew_account_assign_miss( EXPORTING is_xbew = ls_xbew
                                                                it_t030 = lt_t030
                                                      CHANGING cv_check_hist_table = lv_check_hist_table ).


*Check, if xBEW(H) and CKMLPP/CKMLCR is consistent (fields: LBKUM and SALK3) --> Done for current and previous MARV-period
                      IF lv_ml_is_active = abap_true AND
                         lv_ckmlhd_is_missing = abap_false.
                        check_xbew_h_pp_cr_consistency( is_xbew = ls_xbew
                                                        is_marv = ls_marv
                                                        it_xbewh = lt_xbewh
                                                        it_ckmlpp = lt_ckmlpp
                                                        it_ckmlcr = lt_ckmlcr
                                                        iv_xbew_table_name = ls_xbew_table-table_name
                                                        iv_hist_table_name = ls_xbew_table-history_table_name ).
                      ENDIF.

*Record is not needed anymore,
                      IF lv_check_hist_table = abap_false.

                        DELETE lt_xbew.

                      ENDIF.

                      CLEAR : lv_check_hist_table,
                              ls_mara,
                              lv_ckmlhd_is_missing.
                    ENDLOOP.

                    CLEAR: lt_xbewh,
                           lt_ckmlpp,
                           lt_ckmlcr.


                    IF lt_xbew IS NOT INITIAL.
*Check if there are records in history tables with LBKUM <> 0 or SALK3 <> 0 or VKSAL <> 0

                      get_xbewh_entries_trans_fields( EXPORTING is_xbew_table = ls_xbew_table
                                                                it_xbew = lt_xbew
                                                      IMPORTING et_xbewh = lt_xbewh ).


*Check xBEWH entries, since history records exist with filled LBKUM, SALK3 OR VKSAL
                      LOOP AT lt_xbewh INTO ls_xbewh.

                        ls_xbewh-hist_table_name = ls_xbew_table-history_table_name.


                        check_xbewh_no_mara( is_xbewh = ls_xbewh ).


                        check_xbewh_no_t134m( is_xbewh = ls_xbewh ).


                        check_xbewh_no_wertu( is_xbewh = ls_xbewh ).


                        check_xbewh_no_ckmlhd_wert_set( is_xbewh = ls_xbewh ).


                        check_xbewh_init_per( is_xbewh = ls_xbewh ).


                        check_xbewh_acc_assig_mis_init( is_xbewh = ls_xbewh ).

                      ENDLOOP.

                    ENDIF.

                  ENDIF.

                  CLEAR: lt_xbew,
                         lt_ckmlhd,
                         ls_xbew,
           "            ls_marv,
                         lt_t030,
                         mt_xbew_no_wertu_warn,
                         mt_xbew_init_per_warn,
                         mt_xbew_no_mara_warn,
                         mt_xbew_no_ckmlhd_no_mara_war,
                         mt_xbew_no_ckmlhd_no_t134m_war,
                         mt_xbew_no_ckmlhd_no_wertu_war,
                         mt_xbew_no_ckmlhd_wertu_set_wa,
                       mt_xbew_acc_assign_miss_warn.

                ENDDO.

                CLOSE CURSOR c2.

              ENDLOOP.

              CLEAR: lv_ktopl,
                     lv_ml_is_active,
                     lv_act_cost_is_active.

            ENDLOOP.

          ENDIF.

        ENDDO.

        CLOSE CURSOR c1.

*Check, if xBEW duplicate records exist
        check_xbew_duplicate_kaln1( ).

*Check, if Base Unit of Measure is inconsistent between CKMLPP and MLCD
        check_uom_ckmlpp_mlcd( ).

*Check, if Actual Costing run is still running
        check_act_cost_run_unfinished( ).

*Check, if Actual Costing cost component structure has been changed
        check_act_cost_ccs_changed( ).

*Check, if there are CKMLHD entries without xBEW entry
        check_ckmlhd_no_xbew( ).

*Check, if more than one CKMLHD entry exists for xBEW semantical keys (MATNR, BWKEY, BWTAR, SOBKZ etc.)
        check_ckmlhd_duplicate( ).

*Collect all pre-check-messages
        collect_pre_check_messages( ).

      CATCH cx_root INTO lx_error.

        collect_pre_check_messages( ).

        process_exception(
          EXPORTING
            ix_exception         = lx_error
              iv_check_sub_id      = 'EXCEPTION'
            CHANGING
              ct_check_result = mt_pre_check_messages ).
    ENDTRY.

  ENDMETHOD.