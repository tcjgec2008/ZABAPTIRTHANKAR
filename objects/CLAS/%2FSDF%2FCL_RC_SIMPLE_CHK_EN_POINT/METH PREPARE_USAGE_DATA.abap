METHOD prepare_usage_data.

  DATA: lv_1st_day_of_month     TYPE sydatum,
        lt_user_tcode           TYPE TABLE OF swncaggusertcode,
        lt_rfc_server           TYPE TABLE OF swncaggrfcsrvr,
        lt_web_server           TYPE TABLE OF swncaggwebclnt,
        ls_usage                TYPE /sdf/cl_rc_chk_utility=>ty_usage_str,
        lv_count                TYPE i,
        lt_entry_report         TYPE /sdf/cl_rc_chk_utility=>ty_entry_hash_tab,
        lt_entry_rfc            TYPE /sdf/cl_rc_chk_utility=>ty_entry_hash_tab,
        lt_entry_trans          TYPE /sdf/cl_rc_chk_utility=>ty_entry_hash_tab,
        lt_entry_url            TYPE /sdf/cl_rc_chk_utility=>ty_entry_hash_tab,
        ls_entry                TYPE /sdf/cl_rc_chk_utility=>ty_entry_str,
        lt_usage_report         TYPE /sdf/cl_rc_chk_utility=>ty_usage_hash_tab,
        lt_usage_rfc            TYPE /sdf/cl_rc_chk_utility=>ty_usage_hash_tab,
        lt_usage_trans          TYPE /sdf/cl_rc_chk_utility=>ty_usage_hash_tab,
        lt_usage_url            TYPE /sdf/cl_rc_chk_utility=>ty_usage_hash_tab.

  FIELD-SYMBOLS:
        <fs_user_tcode>         TYPE swncaggusertcode,
        <fs_rfc_server>         TYPE swncaggrfcsrvr,
        <fs_web_server>         TYPE swncaggwebclnt.

  DEFINE clear_illegal_chars.
    condense ls_entry-object_name.
    translate ls_entry-object_name to upper case.

    "Replace potentially invalid characters and keep only a sufficient positive set
    "refer to 413791 2017
    replace all occurrences
      of regex '[^a-zA-Z0-9 #$;:._<>=,+*\-\\\/"%()\[\]\{\}?!''''`]'"#EC NOTEXT
      in ls_entry-object_name with '#'.
  END-OF-DEFINITION.

*--------------------------------------------------------------------*
* Read the uploaded ST03N data through report TMW_RC_MANAGE_ST03N_DATA

  /sdf/cl_rc_chk_utility=>get_uploaded_st03n_data(
    IMPORTING
      et_usage_report = st_usage_report
      et_usage_trans  = st_usage_trans
      et_usage_rfc    = st_usage_rfc
      et_usage_url    = st_usage_url
      ev_month_of_usg = sv_num_of_month_got ).
  sv_num_of_usage_data = LINES( st_usage_report ) + LINES( st_usage_trans ) + LINES( st_usage_rfc ) + LINES( st_usage_url ).
  CHECK sv_num_of_usage_data = 0.


*--------------------------------------------------------------------*
* Read ST03 for usage data
* All FMs finally uses SWNC_COLLECTOR_GET_AGGREGATES which is also used here
*
* FM /SDF/SAPWL_T_UCOUNT_AGGREGATE does not return the number of executions
* per transaction, but the number of distinct users who have executed a transaction
* in a given time period. This FM is also not able to read real-time ST03 data. It rather
* uses statistics calculated by the TOTAL workload collector, which in turn uses
* the instance daily aggregates of complete days. So we should no use it.
*
* FM SAPWL_TCODE_AGGREGATION can be used to know the number of executions for a given transaction,
* This FM supports different levels of aggregation (user, tcode, application, subapplication)
* and allows to specify any time period (day, week, month). Important to note is that this FM is
* instance specific, so you need to provide the instance name as input parameter.

  "Get first day of current month
  CONCATENATE sy-datum(6) '01' INTO lv_1st_day_of_month.
  CLEAR sv_num_of_month_got.

  "In ST03 normally data is kept only for several months; try to read data upto 12 months
  DO 12 TIMES.

    CLEAR: lt_user_tcode, lt_rfc_server, lt_web_server.
    CALL FUNCTION 'SWNC_COLLECTOR_GET_AGGREGATES'
      EXPORTING
        component     = 'TOTAL' "To get statistics for all instances
        periodtype    = 'M'
        periodstrt    = lv_1st_day_of_month
      TABLES
        usertcode     = lt_user_tcode
        rfcsrvr       = lt_rfc_server "count server (received) call
        webs          = lt_web_server "count server (received) call
      EXCEPTIONS
        no_data_found = 1        "summary_only = 'X' "Not specify so result can always be returned regardless of the BASIS version
        OTHERS        = 2.
    IF sy-subrc = 0.
      "Continue to try previous month. Possible that no data for current month but data exist for previous monthes->66707 2017
      ADD 1 TO sv_num_of_month_got.
      "Read the transaction and report usage data
      LOOP AT lt_user_tcode ASSIGNING <fs_user_tcode>.
        CLEAR ls_entry.
        ls_entry-object_name    = <fs_user_tcode>-entry_id(40). " entry_id(40) report name, entry_id+40(32)  batch job name
        ls_entry-account        = <fs_user_tcode>-account.
        clear_illegal_chars.  "#EC NOTEXT
        CASE <fs_user_tcode>-entry_id+72(1).
          WHEN 'R'."Report
            ls_entry-object_type = /sdf/cl_rc_chk_utility=>c_entry_point_type-report.
            INSERT ls_entry INTO TABLE lt_entry_report.
            IF sy-subrc = 0.
              CLEAR ls_usage.
              ls_usage-object_name    = ls_entry-object_name.
              ls_usage-object_type    = ls_entry-object_type.
              ls_usage-usage_counter  = 1.                    " usage_counter counts users
              COLLECT ls_usage INTO lt_usage_report.
            ENDIF.
          WHEN 'T'."Transaction
            ls_entry-object_type = /sdf/cl_rc_chk_utility=>c_entry_point_type-transaction.
            INSERT ls_entry INTO TABLE lt_entry_trans.
            IF sy-subrc = 0.
              CLEAR ls_usage.
              ls_usage-object_name    = ls_entry-object_name.
              ls_usage-object_type    = ls_entry-object_type.
              ls_usage-usage_counter  = 1.
              COLLECT ls_usage INTO lt_usage_trans.
            ENDIF.
        ENDCASE.
      ENDLOOP.
      CLEAR lt_user_tcode.

      "Read the RFC usage data
      "Count server (received) call
      LOOP AT lt_rfc_server ASSIGNING <fs_rfc_server>.
        CLEAR ls_entry.
        ls_entry-object_name    = <fs_rfc_server>-func_name.
        ls_entry-account        = <fs_rfc_server>-account.
        clear_illegal_chars.  "#EC NOTEXT
        ls_entry-object_type = /sdf/cl_rc_chk_utility=>c_entry_point_type-rfc.
        INSERT ls_entry INTO TABLE lt_entry_rfc.
        IF sy-subrc = 0.
          CLEAR ls_usage.
          ls_usage-object_name    = ls_entry-object_name.
          ls_usage-object_type    = ls_entry-object_type.
          ls_usage-usage_counter  = 1.
          COLLECT ls_usage INTO lt_usage_rfc.
        ENDIF.
      ENDLOOP.
      CLEAR lt_rfc_server.

      "Read the URL usage data
      "Count server (received) call
      LOOP AT lt_web_server ASSIGNING <fs_web_server>.
        CLEAR ls_entry.
        ls_entry-object_name    = <fs_web_server>-path.
        ls_entry-account        = <fs_web_server>-account.
        clear_illegal_chars.  "#EC NOTEXT
        ls_entry-object_type = /sdf/cl_rc_chk_utility=>c_entry_point_type-url.
        INSERT ls_entry INTO TABLE lt_entry_url.
        IF sy-subrc = 0.
          CLEAR ls_usage.
          ls_usage-object_name    = ls_entry-object_name.
          ls_usage-object_type    = ls_entry-object_type.
          ls_usage-usage_counter  = 1.
          COLLECT ls_usage INTO lt_usage_url.
        ENDIF.
      ENDLOOP.
      CLEAR lt_web_server.

      "Prevent running out of memory
      "Exit if we have enough data (1.5 million & 3 month) to prevent running out of memory.
      lv_count = lines( lt_entry_report ).
      IF lv_count > 1500000 AND sv_num_of_month_got >= 3.
        EXIT.
      ENDIF.
      lv_count = lines( lt_entry_trans ).
      IF lv_count > 1500000 AND sv_num_of_month_got >= 3.
        EXIT.
      ENDIF.
      lv_count = lines( lt_entry_rfc ).
      IF lv_count > 1500000 AND sv_num_of_month_got >= 3.
        EXIT.
      ENDIF.
      lv_count = lines( lt_entry_url ).
      IF lv_count > 1500000 AND sv_num_of_month_got >= 3.
        EXIT.
      ENDIF.
    ENDIF.

    "Get first day of previous month
    lv_1st_day_of_month = add_month_to_date(
      iv_month_count = -1
      iv_old_date    = lv_1st_day_of_month ).
  ENDDO.

  MOVE lt_usage_report TO st_usage_report.
  MOVE lt_usage_trans TO st_usage_trans.
  MOVE lt_usage_rfc TO st_usage_rfc.
  MOVE lt_usage_url TO st_usage_url.

  sv_num_of_usage_data = LINES( st_usage_report ) + LINES( st_usage_trans ) + LINES( st_usage_rfc ) + LINES( st_usage_url ).
  sv_num_of_month_got_str = sv_num_of_month_got.
  sv_num_of_usage_data_str = sv_num_of_usage_data.

ENDMETHOD.