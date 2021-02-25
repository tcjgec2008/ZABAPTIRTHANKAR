METHOD _check_miss_pararea_for_cur.
*--------------------------------------------------------------------*
*-check 3: 3.5 check BUHBKT =2 periodic posting
*---       3.6 check if parallel area for currency missing - only
*               relevant for inactive to sFIN
*---       3.7 Check if the assigned company code/ledger manages all
*                currencies defined in the parallel areas
*---       3.8 Check if the online posting area has the first local
*                currency
*          3.9 check if area which doesn't post, doesn't have
*                 parallel currency area
*              also check if parallel currency area doesn't post
*--------------------------------------------------------------------*
* PRECONDITION
  "None

* DEFINITIONS
  DATA: lt_areasettings TYPE ty_t_areasettings,
        lb_use_ledger   TYPE abap_bool,
        ls_t001         TYPE t001,
        lv_msg_text     TYPE string,
        ls_range_wrong_cust_comp_code LIKE LINE OF mt_range_wrong_cust_comp_code.

  FIELD-SYMBOLS: <ls_area>     TYPE ty_s_areasettings,
                 <ls_paraarea> TYPE ty_s_areasettings. "


* BODY
* Check per chart of depreciation and company code
  REFRESH: lt_areasettings.
  CLEAR: lb_use_ledger.

  _faa_read_area_settings(
    EXPORTING
      iv_comp_code    = is_t093c-bukrs
    IMPORTING
      et_areasettings = lt_areasettings
  ).

*--------------------------------------------------------------------*
*     3.5 Check buhbkt = 2
*--------------------------------------------------------------------*
  LOOP AT lt_areasettings ASSIGNING <ls_area> WHERE definition-buhbkt = gc_buhbkt-per.
    IF sy-subrc = 0.
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.
        lv_msg_text = 'Periodical APC posting is active in one or more depreciation areas, but is no longer supported. For more info, choose ''Check Consistency Details''.'.
      ELSE.
        MESSAGE w212(acc_aa) WITH is_t093c-afapl <ls_area>-area INTO lv_msg_text.
      ENDIF.
      _add_check_message(
      EXPORTING
        iv_description  = lv_msg_text
        iv_return_code  = gc_return_code-warning
        iv_check_sub_id = gc_check_sub_id-fiaa_cust_deprarea
      ).
    ENDIF.
  ENDLOOP.

  IF mb_is_new_fiaa_active = abap_false.
    LOOP AT lt_areasettings TRANSPORTING NO FIELDS
                            WHERE definition-xstore = abap_true
                            AND definition-ldgrp_gl IS NOT INITIAL.
      lb_use_ledger = abap_true.
      EXIT.
    ENDLOOP.

    IF lb_use_ledger = abap_true.
      "get the parallel areas for Ledger solution
      LOOP AT lt_areasettings ASSIGNING <ls_area>
                              WHERE definition-xstore = abap_true
                                AND ( definition-buhbkt = gc_buhbkt-onl
                                OR    definition-buhbkt = gc_buhbkt-dep )
                                AND definition-ldgrp_gl IS NOT INITIAL.
        "check depr. area with buhbkt = 3 only, if there is no other depr. area, that posts into the same ldgrp.
        IF <ls_area>-definition-buhbkt = gc_buhbkt-dep.
          READ TABLE lt_areasettings TRANSPORTING NO FIELDS
                                     WITH KEY definition-buhbkt = gc_buhbkt-onl
                                              definition-ldgrp_gl = <ls_area>-definition-ldgrp_gl.
          IF sy-subrc = 0.
            CONTINUE.
          ENDIF.
        ENDIF.
*--------------------------------------------------------------------*
*          check 3.6 & 3.7
*--------------------------------------------------------------------*
        _check_pararea_curr_congruence(
          EXPORTING
            is_t093c        = is_t093c
            is_area         = <ls_area>
            it_areasettings = lt_areasettings
          EXCEPTIONS
            no_currency_information = 1
         ).
        IF sy-subrc <> 0.
          RETURN. "no currency info available, no further check possible
        ENDIF.
      ENDLOOP. "Ledger Solution areas
    ELSE.
      "get the parallel areas for Account solution
      LOOP AT lt_areasettings ASSIGNING <ls_area>
                              WHERE   definition-xstore = abap_true
                                AND ( definition-buhbkt = gc_buhbkt-onl
                                 OR   definition-buhbkt = gc_buhbkt-per
                                 OR   definition-buhbkt = gc_buhbkt-dir ).
*--------------------------------------------------------------------*
*          check 3.6 & 3.7
*--------------------------------------------------------------------*
        _check_pararea_curr_congruence(
          EXPORTING
            is_t093c                  = is_t093c
            is_area                   = <ls_area>
            it_areasettings           = lt_areasettings
            ib_is_accounting_solution = abap_true
          EXCEPTIONS
            no_currency_information = 1
         ).
        IF sy-subrc <> 0.
          RETURN. "no currency info available, no further check possible
        ENDIF.
      ENDLOOP. "Account Solution areas
    ENDIF.  " ledger or account solution
  ELSEIF mb_is_new_fiaa_active = abap_true.

    " get the parallel areas for Ledger solution
    LOOP AT lt_areasettings ASSIGNING <ls_area>
                            WHERE   definition-xstore = abap_true
                              AND ( definition-buhbkt = gc_buhbkt-onl
                               OR   definition-buhbkt = gc_buhbkt-dep ).
*--------------------------------------------------------------------*
*        check 3.6 check if parallel area fur currency missing
*         Usually if the new FIAA has been activated, no parallel areas shall be missing -> There is check in IMG
*         but just to make sure we check the settings here again.
*        check 3.7 check if the assigned company code manages all currencies defined in the parallel areas
*         although new FIAA is active
*         NO check for account solution because account solution was not supported in EHP7 if new FIAA is active
*         get the parallel areas for Ledger solution
*         LOOP AT all posting area
*--------------------------------------------------------------------*
      _check_pararea_curr_congruence(
          EXPORTING
            is_t093c        = is_t093c
            is_area         = <ls_area>
            it_areasettings = lt_areasettings
          EXCEPTIONS
            no_currency_information = 1
         ).
      IF sy-subrc <> 0.
        RETURN. "no currency info available, no further check possible
      ENDIF.
    ENDLOOP.
  ENDIF.

*--------------------------------------------------------------------*
* check 3.8 - Check if the online posting area has the first local currency
*--------------------------------------------------------------------*
  CLEAR: ls_t001.
  ls_t001-bukrs = is_t093c-bukrs.
  READ TABLE mt_t001 INTO ls_t001 WITH KEY bukrs = is_t093c-bukrs.

  LOOP AT lt_areasettings ASSIGNING <ls_area>
                              WHERE   definition-xstore = abap_true
                                AND ( definition-buhbkt = gc_buhbkt-onl
                                 OR   definition-buhbkt = gc_buhbkt-per
                                 OR   definition-buhbkt = gc_buhbkt-dir ).
    IF <ls_area>-company-waers <> ls_t001-waers.
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.
        lv_msg_text = 'One or more realtime posting depreciation areas do not have the same currency as the company code. For more info, choose ''Check Consistency Details''.'.
      ELSE.
        MESSAGE e148(acc_aa) WITH <ls_area>-area is_t093c-bukrs is_t093c-afapl INTO lv_msg_text.
      ENDIF.
      _add_check_message(
        EXPORTING
          iv_description  = lv_msg_text
          iv_check_sub_id = gc_check_sub_id-fiaa_cust_deprarea_currency
      ).
    ENDIF.
    "all posting area must have the local currency type automatically
    " Therefore the currency type for this area shall not be set
    IF <ls_area>-takeover-curtp IS NOT INITIAL.
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.
        lv_msg_text = 'Currency type of realtime posting depreciation area is not initial. For more info, choose ''Check Consistency Details''.'.
      ELSE.
        MESSAGE e217(acc_aa) WITH <ls_area>-area is_t093c-bukrs is_t093c-afapl
                                  INTO lv_msg_text.
      ENDIF.
      _add_check_message(
        EXPORTING
          iv_description  = lv_msg_text
          iv_check_sub_id = gc_check_sub_id-fiaa_cust_deprarea_currency
      ).
    ENDIF.
  ENDLOOP.

*--------------------------------------------------------------------*
*     check 3.9 - area which doesn't post shall not have parallel currency area
*               - parallel currency area shall not post
*--------------------------------------------------------------------*
  LOOP AT lt_areasettings ASSIGNING <ls_paraarea>
                             WHERE takeover-curtp IS NOT INITIAL.
    IF <ls_paraarea>-definition-buhbkt <> gc_buhbkt-no.
      "parallel area posts into GL --> error
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.
        lv_msg_text = 'One or more parallel currency areas post to G/L; this is not allowed. For more info, choose ''Check Consistency Details''.'.
      ELSE.
        MESSAGE e190(acc_aa) WITH <ls_paraarea>-definition-afapl
                                  <ls_paraarea>-definition-afaber
                                  INTO lv_msg_text.
      ENDIF.
      _add_check_message(
        EXPORTING
          iv_description  = lv_msg_text
          iv_check_sub_id = gc_check_sub_id-fiaa_cust_deprarea_currency
      ).
      "if customizing of parallel depr. area is wrong for company code, the master data/asset clases should not be checked
      IF is_t093c-bukrs NOT IN mt_range_wrong_cust_comp_code
        OR mt_range_wrong_cust_comp_code IS INITIAL.
        ls_range_wrong_cust_comp_code-sign = 'I'.
        ls_range_wrong_cust_comp_code-option = 'EQ'.
        ls_range_wrong_cust_comp_code-low = is_t093c-bukrs.
        APPEND ls_range_wrong_cust_comp_code TO mt_range_wrong_cust_comp_code.
      ENDIF.
    ENDIF.

    "get base area for parallel area to check if it post
    READ TABLE lt_areasettings ASSIGNING <ls_area> WITH KEY definition-afaber = <ls_paraarea>-takeover-wrtafb.
    IF sy-subrc = 0.
      IF <ls_area>-definition-buhbkt = gc_buhbkt-no.
        "area doesn't post --> error
        IF cls4sic_fi_aa=>gb_detailed_check = abap_false.
          lv_msg_text = 'One or more depreciation areas do not post, but they have parallel currencies; this is not allowed. For more info, choose ''Check Consistency Details''.'.
        ELSE.
          MESSAGE e191(acc_aa) WITH <ls_paraarea>-definition-afapl
                                    <ls_paraarea>-definition-afaber
                                    INTO lv_msg_text.
        ENDIF.
        _add_check_message(
          EXPORTING
            iv_description  = lv_msg_text
            iv_check_sub_id = gc_check_sub_id-fiaa_cust_deprarea_currency
        ).
        "if customizing of parallel depr. area is wrong for company code, the master data/asset clases should not be checked
        IF is_t093c-bukrs NOT IN mt_range_wrong_cust_comp_code
          OR mt_range_wrong_cust_comp_code IS INITIAL.
          ls_range_wrong_cust_comp_code-sign = 'I'.
          ls_range_wrong_cust_comp_code-option = 'EQ'.
          ls_range_wrong_cust_comp_code-low = is_t093c-bukrs.
          APPEND ls_range_wrong_cust_comp_code TO mt_range_wrong_cust_comp_code.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

* POSTCONDITION
  "None

ENDMETHOD.