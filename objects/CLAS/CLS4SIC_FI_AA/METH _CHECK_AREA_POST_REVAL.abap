METHOD _check_area_post_reval.
*&---------------------------------------------------------------------*
*& In the classic FIAA user may set the indicator T093D-AUFBUC and
*& the revaluation of APC and the accumulated ordinary depreciation of
*& this depreciation area will be posted in the general ledger during the
*& depreciation posting run, in addition to the depreciation.
*& If the indicator was not set, the revaluation and depr. will not be posted;
*& Since sFIN2.0, all values managed by a online posting are will be posted
*& in the GL, therefore the indicator must be set for all posting areas
*& and the account determination must be maintained
*--------------------------------------------------------------------*
* PRECONDITION
  " None

* DEFINITION
  DATA: lt_areasettings TYPE ty_t_areasettings,
        lt_t093d TYPE TABLE OF t093d,
        ls_t093d TYPE t093d,
        lv_msg_text TYPE string,
        lv_return_code TYPE ty_return_code.

  FIELD-SYMBOLS: <ls_area>  TYPE ty_s_areasettings.

* BODY
  REFRESH: lt_areasettings, lt_t093d.

  " get area settings
  _faa_read_area_settings(
    EXPORTING
    iv_comp_code = is_t093c-bukrs
  IMPORTING
    et_areasettings = lt_areasettings
 ).

  SELECT * FROM t093d CLIENT SPECIFIED INTO TABLE lt_t093d
                          WHERE mandt = mv_client
                          AND bukrs = is_t093c-bukrs.
  IF sy-subrc <> 0.
    MESSAGE e652(ac) WITH is_t093c-bukrs INTO lv_msg_text.
    _add_check_message(
         EXPORTING
           iv_description = lv_msg_text
           iv_check_sub_id = gc_check_sub_id-fiaa_cust_deprarea_reval
    ).
  ELSE.
    " check begins
    LOOP AT lt_areasettings ASSIGNING <ls_area> WHERE definition-buhbkt <> gc_buhbkt-no
                                                  AND definition-xstore = abap_true
                                                  AND ( definition-vzindw <> '0'
                                                      OR definition-vzinda <> '0' ).
      " if an area posts into GL and manages revaluation
      " the indicator must be set.
      " user shall check the account determination also
      CLEAR: ls_t093d.
      READ TABLE lt_t093d INTO ls_t093d WITH KEY afaber = <ls_area>-area.
      IF sy-subrc = 0 AND ls_t093d-aufbuc IS INITIAL.
        IF cls4sic_fi_aa=>gb_detailed_check = abap_false.
          lv_msg_text = 'Indicator ''Post Revaluations'' is not set correctly for one or more depreciation areas. For more info, choose ''Check Consistency Details''.'.
        ELSE.
          MESSAGE e193(acc_aa) WITH is_t093c-bukrs <ls_area>-area INTO lv_msg_text. "#EC *
          IF <ls_area>-definition-buhbkt = gc_buhbkt-dep.
            lv_return_code = gc_return_code-warning.
          ELSE.
            lv_return_code = gc_return_code-error.
          ENDIF.
        ENDIF.
        _add_check_message(
           EXPORTING
             iv_description = lv_msg_text
             iv_return_code = lv_return_code
             iv_check_sub_id = gc_check_sub_id-fiaa_cust_deprarea_reval
        ).
        IF cls4sic_fi_aa=>gb_detailed_check = abap_false.RETURN.ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.

* POSTCONDITION
  " None

ENDMETHOD.