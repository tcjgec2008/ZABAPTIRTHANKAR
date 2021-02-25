METHOD perform_check.

  DATA: ls_edmsg         TYPE edmsg,
        lt_edidc         TYPE TABLE OF edi_docnum,
        lt_edidc_tmp     TYPE TABLE OF edi_docnum,
        lv_edidc         TYPE edi_docnum,
        lt_edids         TYPE TABLE OF edi_countr,
        lv_idoc_msg_type TYPE edi_mestyp,
        lv_edi_countr    TYPE edi_countr,
        lv_actual_count  TYPE i,
        lv_line_number   TYPE i,
        lv_index         TYPE i VALUE 0,
        lv_divider       TYPE i VALUE 10000,
        lv_at_end        TYPE boolean VALUE abap_false.

*--------------------------------------------------------------------*
* Preparation for simple check
* Also perform the check across-client (add CLIENT SPECIFIED in SQL)
* Refer to comments in /SDF/CL_RC_SIMPLE_CHK_DB->PERFORM_CHECK

  ev_result_int = /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-no.
  CLEAR ev_summary_int.

  lv_idoc_msg_type = ms_check-check_identifier.
  SELECT SINGLE * FROM edmsg CLIENT SPECIFIED INTO ls_edmsg
    WHERE msgtyp = lv_idoc_msg_type.

*--------------------------------------------------------------------*
* Perform IDoc based simple check
* https://wiki.wdf.sap.corp/wiki/pages/viewpage.action?pageId=1819612415#SAPS/4HANATransitionDB/SimplificationList-SimpleCheck
* Do a join on the IDOC status table EDIDS and the IDOC control table EDIDC
* and the message type definition in EDMSG and just check if for the given
* message type (e.g. MATMAS) any status records exists in EDIDS. Which means
* that the customer system did receive or send some messages of that kind.
*
* A refinement of this approach could be not to go for the message type
* but the actual IDOC type. Or not to consider all status messages in EDIDS
* but only only selected ones (e.g. only success at application layer) as defined in TEDS1.

*  mv_dummy_str = ms_check-check_count.
*  CONCATENATE ms_check-check_identifier     '/'
*              mv_check_count_option_str     '/'
*              mv_dummy_str INTO mv_dummy_str.

  IF ls_edmsg IS NOT INITIAL.

    SELECT docnum INTO TABLE lt_edidc
      FROM edidc
      WHERE mestyp = lv_idoc_msg_type
      %_HINTS: DB6    '&SUBSTITUTE VALUES&'               "#EC CI_HINTS
               DB2    '&SUBSTITUTE VALUES&'               "#EC CI_HINTS
               ORACLE '&SUBSTITUTE VALUES&'.              "#EC CI_HINTS

    IF lt_edidc IS NOT INITIAL.

      SORT lt_edidc.
      DELETE ADJACENT DUPLICATES FROM lt_edidc.
      lv_line_number = lines( lt_edidc ).

      "Currently all iDoc based rules uses "More Than" -> use UP TO 1 ROWS for better performance
      lv_edi_countr = ms_check-check_count.

      LOOP AT lt_edidc INTO lv_edidc.

        IF lv_line_number = sy-tabix.
          lv_at_end = abap_true.
        ENDIF.

        lv_index = lv_index + 1.
        APPEND lv_edidc TO lt_edidc_tmp.

        IF lv_index = lv_divider OR lv_at_end = abap_true.

          SELECT countr INTO TABLE lt_edids
            UP TO 1 ROWS
            FROM edids
            FOR ALL ENTRIES IN lt_edidc_tmp
            WHERE docnum = lt_edidc_tmp-table_line
            AND countr > lv_edi_countr
            %_HINTS: DB6    '&SUBSTITUTE VALUES&'         "#EC CI_HINTS
                     DB2    '&SUBSTITUTE VALUES&'         "#EC CI_HINTS
                     ORACLE '&SUBSTITUTE VALUES&'.        "#EC CI_HINTS

          IF lt_edids IS NOT INITIAL.
            EXIT.
          ENDIF.

          CLEAR: lt_edidc_tmp, lv_index.

        ENDIF.

      ENDLOOP.

    ENDIF.

  ENDIF.

  CONCATENATE 'iDoc ''' ms_check-check_identifier ''' based check' "#EC NOTEXT
    INTO mv_dummy_str SEPARATED BY space.

  IF lt_edids IS INITIAL.
    lv_actual_count = 0.
    compare_value(
      EXPORTING
        iv_actual_count   = lv_actual_count
        iv_object_checked = mv_dummy_str
      IMPORTING
        ev_result_int     = ev_result_int
        ev_summary_int    = ev_summary_int ).
  ELSE.
    LOOP AT lt_edids INTO lv_actual_count.
      compare_value(
        EXPORTING
          iv_actual_count   = lv_actual_count
          iv_object_checked = mv_dummy_str
        IMPORTING
          ev_result_int     = ev_result_int
          ev_summary_int    = ev_summary_int ).
      CHECK ev_result_int <> /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.
    ENDLOOP.
  ENDIF.

*  "IDoc &P1&; check not passed
*  IF ev_result_int <> /sdf/cl_rc_chk_utility=>c_si_rele_int_stat-yes.
**    ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '017' iv_para1 = mv_dummy_str ).
**    IF ls_edmsg IS INITIAL.
*    mv_dummy_str = ms_check-check_identifier.
*    "Item is not relevant. IDoc &P1& based check not passed
*    ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '016' iv_para1 = mv_dummy_str ) .
**      RETURN.
**    ENDIF.
*
*  ELSE.
*    "Item is relevant. IDoc &P1& based check passed
*    ev_summary_int = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '043' iv_para1 = mv_dummy_str ).
*  ENDIF.

ENDMETHOD.