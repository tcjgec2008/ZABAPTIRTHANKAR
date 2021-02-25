METHOD _check_leading_ledger.
*--------------------------------------------------------------------*
*   set the leading ledger for the global member variable
*--------------------------------------------------------------------*
* PRECONDITION
  CLEAR mv_lead_ledger.
  CHECK mb_is_new_gl_active = abap_true.

* DEFINITIONS
  DATA lv_msg_text TYPE string.

* BODY
  CALL FUNCTION 'FAGL_GET_LEADING_LEDGER'
    EXPORTING
      i_client      = mv_client
      ix_read_new   = abap_true
    IMPORTING
      e_rldnr       = mv_lead_ledger
    EXCEPTIONS
      not_found     = 1
      more_than_one = 2.
  IF sy-subrc <> 0.
    IF sy-subrc = 1.
      MESSAGE e023(fagl_ledger_cust) INTO lv_msg_text.
      _add_check_message(
         EXPORTING
           iv_description = lv_msg_text
           iv_check_sub_id = gc_check_sub_id-fiaa_cust_ledger
       ).
    ELSEIF sy-subrc = 2.
      MESSAGE e024(fagl_ledger_cust) INTO lv_msg_text.
      _add_check_message(
         EXPORTING
           iv_description = lv_msg_text
           iv_check_sub_id = gc_check_sub_id-fiaa_cust_ledger
       ).
    ENDIF.
  ENDIF.

* POSTCONDITION
  "None

ENDMETHOD.