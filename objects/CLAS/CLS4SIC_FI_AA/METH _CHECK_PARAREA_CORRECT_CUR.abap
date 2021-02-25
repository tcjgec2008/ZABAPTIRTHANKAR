METHOD _check_pararea_correct_cur.
*--------------------------------------------------------------------*
* helper method for '_CHECK_MISSING_PARA_AREAS'
* check 3.6: Check if the assigned company code manages all currencies
*            defined in the parallel areas
*--------------------------------------------------------------------*
* PRECONDITION
  " None

* DEFINITIONS
  DATA: lv_msg_text TYPE string.
  FIELD-SYMBOLS: <ls_paraarea> TYPE ty_s_areasettings.

* BODY
  "get parallel area for basis area
  LOOP AT it_areasettings ASSIGNING <ls_paraarea>
                                      WHERE takeover-wrtafb  = is_area-area
                                        AND takeover-parafb  = is_area-area
                                        AND takeover-curtp   IS NOT INITIAL.
    IF <ls_paraarea>-takeover-curtp <> is_x001-curt2 AND
       <ls_paraarea>-takeover-curtp <> is_x001-curt3.
      "parallel area exists, but currency type is different
      " from currency type of company code
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.
        lv_msg_text = 'One or more depreciation areas do not have the correct currency. For more info, choose ''Check Consistency Details''.'.
      ELSE.
        MESSAGE e173(acc_aa) WITH <ls_paraarea>-area iv_comp_code space space
                                                      INTO lv_msg_text.
      ENDIF.
      _add_check_message(
        EXPORTING
          iv_description = lv_msg_text
          iv_check_sub_id = gc_check_sub_id-fiaa_cust_deprarea_currency
      ).
    ENDIF.
  ENDLOOP.

* POSTCONDITION
  " None

ENDMETHOD.