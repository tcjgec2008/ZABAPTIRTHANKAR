METHOD perform_check.

  DATA: lv_entry_point_ty_str TYPE string,
        lv_actual_count       TYPE i,
        lt_usage              TYPE /sdf/cl_rc_chk_utility=>ty_usage_tab,
        lv_chk_identi_str     TYPE string,
        ls_usage              TYPE /sdf/cl_rc_chk_utility=>ty_usage_str.

*--------------------------------------------------------------------*
* Preparation for Entry Point based simple check

  TRANSLATE ms_check-check_identifier TO UPPER CASE."Make it case insensitive

  ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.
  CLEAR: ev_summary_int.

  lv_entry_point_ty_str = ms_check-check_sub_identifier.
  CASE ms_check-check_sub_identifier.
    WHEN /sdf/cl_rc_chk_utility=>c_entry_point_type-transaction.
      lv_entry_point_ty_str = 'Transaction'.                "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_entry_point_type-report.
      lv_entry_point_ty_str = 'Report'.                     "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_entry_point_type-rfc.
      lv_entry_point_ty_str = 'Remote Function Call'.       "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_entry_point_type-url.
      lv_entry_point_ty_str = 'URL'.                        "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_entry_point_type-job.
      lv_entry_point_ty_str = 'Batch Job'.                  "#EC NOTEXT
  ENDCASE.

  CONCATENATE lv_entry_point_ty_str '''' ms_check-check_identifier ''''
               INTO mv_dummy_str SEPARATED BY space.


*--------------------------------------------------------------------*
* Perform Entry Point based simple check
* ABAP call monitor (SCMON) not used:1) only available >= NW 7.4 2)turned on manually

  CASE ms_check-check_sub_identifier.
    WHEN /sdf/cl_rc_chk_utility=>c_entry_point_type-transaction.
      lt_usage = st_usage_trans.
    WHEN /sdf/cl_rc_chk_utility=>c_entry_point_type-report.
      lt_usage = st_usage_report.
    WHEN /sdf/cl_rc_chk_utility=>c_entry_point_type-rfc.
      lt_usage = st_usage_rfc.
    WHEN /sdf/cl_rc_chk_utility=>c_entry_point_type-url.
      lt_usage = st_usage_url.
    WHEN OTHERS.
      ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-rule_issue.
      "Entry point check type &P1& is not supported: &P2&
      ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '020'
        iv_para1   = lv_entry_point_ty_str
        iv_para2   = mv_dummy_str ) .
      RETURN.
  ENDCASE.

*--------------------------------------------------------------------*
* Check usage data
* The Readiness Check user guide recommends to have ST03N data of at least 4-6 weeks
* 2019-03-15 change the rule as below:
  " If the customer has > 0 ST03N entries
  "   Do the entry point check
  "	  If the entry point check did return true
  "     Show the S-Item as relevant
  "	  Else
  "     If there is less than 2 months of data OR less then <number records needed> records in ST03N
  "       Tell the customer that he does not have sufficient ST03N data (needs to be checked manually)
  "     Else
  "       Show the S-Item as not relevant
  "   Else
  "	    Tell the customer that he does not have sufficient ST03N data (needs to be checked manually)

  DATA lv_number_month_needed TYPE i VALUE 2.

  IF sv_num_of_usage_data = 0.

    ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-miss_usg_data.
    "Relevance cannot be determined. Entry point &P1& based check not executed: not enough ST03N data (&P2& months)
    ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '040'
      iv_para1   = mv_dummy_str
      iv_para2   = sv_num_of_month_got_str ).
    /sdf/cl_rc_chk_utility=>sv_no_enough_st03_data = abap_true.
    RETURN.

  ENDIF.

  "Sum up the usage data distributed in different time period
  IF ms_check-check_sub_identifier = /sdf/cl_rc_chk_utility=>c_entry_point_type-url.

    "Tolerance for URL: check if the identifier is #contained# in the path string.
    "SI SI25: Logistics_PLM_DI -> Entry Point: URL  - /plmu/WDA_RTG_RCA_ADAPT_OVP
    "Result in ST03N :{A_RTG_RCA_ADAPT_OVP T} PATH: /sap/bc/webdynpro/plmu/wda_rtg_rca_adapt_ovp
    lv_chk_identi_str = ms_check-check_identifier.
    TRANSLATE lv_chk_identi_str TO UPPER CASE.
    LOOP AT lt_usage INTO ls_usage.
      TRANSLATE ls_usage-object_name TO UPPER CASE.
      FIND FIRST OCCURRENCE OF lv_chk_identi_str IN ls_usage-object_name.
      IF sy-subrc = 0.
        lv_actual_count = lv_actual_count + ls_usage-usage_counter.
      ENDIF.
    ENDLOOP.
  ELSE.
    LOOP AT lt_usage INTO ls_usage
      WHERE object_name = ms_check-check_identifier.
      lv_actual_count = lv_actual_count + ls_usage-usage_counter.
    ENDLOOP.
  ENDIF.

  compare_value(
    EXPORTING
      iv_actual_count   = lv_actual_count
      iv_object_checked = mv_dummy_str
    IMPORTING
      ev_result_int     = ev_result_int
      ev_summary_int    = ev_summary_int
  ).

  IF /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes <> ev_result_int.

    IF sv_num_of_month_got < lv_number_month_needed.
      ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-miss_usg_data.
      "Relevance cannot be determined. Entry point &P1& based check not executed: not enough ST03N data (&P2& months)
      ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '040'
        iv_para1   = mv_dummy_str
        iv_para2   = sv_num_of_month_got_str ).
      /sdf/cl_rc_chk_utility=>sv_no_enough_st03_data = abap_true.
    ELSE.
      ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.
    ENDIF.

  ENDIF.

ENDMETHOD.