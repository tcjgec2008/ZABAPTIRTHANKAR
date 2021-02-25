  METHOD _check_for_duplicate_in_doc_it.
    "--------------------------------------------------------------------"
    " Search for duplicate entries in DB within a single client
    "--------------------------------------------------------------------"
    " PRECONDITION
    " none

    " DEFINITIONS
    DATA:
      lt_faat_doc_it_err TYPE          ty_t_faat_doc_it_err,
      lt_range_client    TYPE RANGE OF sy-mandt,
      lv_msg_sub_text    TYPE          string,
      lv_msg_text        TYPE          string.

    " BODY
    CLEAR lt_faat_doc_it_err.
    "--------------------------------------
    " DB select:
    " Check for duplicate entries in DB table FAAT_DOC_IT
    "--------------------------------------
    SELECT
      mandt,
      bukrs,
      anln1,
      anln2,
      gjahr,
      awtyp,
      awref,
      aworg,
      awsys,
      subta,
      afabe,
      slalittype,
      drcrk,
      COUNT(*) AS count_multiple
    FROM faat_doc_it  USING CLIENT @mv_client
    GROUP BY
      mandt,
      bukrs,
      anln1,
      anln2,
      gjahr,
      awtyp,
      awref,
      aworg,
      awsys,
      subta,
      afabe,
      slalittype,
      drcrk
    HAVING COUNT(*) > 1
    ORDER BY count_multiple DESCENDING
    INTO CORRESPONDING FIELDS OF TABLE @lt_faat_doc_it_err
    UP TO 1 ROWS.                                              "#EC CI_NOWHERE

    " In case of duplicates: add findings to check sub ID of Simplification Item
    IF sy-subrc EQ 0 AND
       NOT lt_faat_doc_it_err IS INITIAL.

      CLEAR: lv_msg_sub_text, lv_msg_text.
      lv_msg_sub_text = 'Duplicate entries found in table FAAT_DOC_IT'.
      MESSAGE w900(ac) with lv_msg_sub_text INTO lv_msg_text.
      _add_check_message(
        EXPORTING
          iv_description  = lv_msg_text
          iv_return_code  = gc_return_code-abortion
          iv_check_sub_id = gc_check_sub_id-fiaa_duplicate_doc_it ).

      CLEAR: lv_msg_sub_text, lv_msg_text.
      lv_msg_sub_text = 'See note: 2948964'.
      MESSAGE w900(ac) with lv_msg_sub_text INTO lv_msg_text.
      _add_check_message(
        EXPORTING
          iv_description  = lv_msg_text
          iv_return_code  = gc_return_code-abortion
          iv_check_sub_id = gc_check_sub_id-fiaa_duplicate_doc_it ).

      CLEAR: lv_msg_sub_text, lv_msg_text.
      lv_msg_sub_text = 'Please correct this using following report:'.
      MESSAGE w900(ac) with lv_msg_sub_text INTO lv_msg_text.
      _add_check_message(
        EXPORTING
          iv_description  = lv_msg_text
          iv_return_code  = gc_return_code-abortion
          iv_check_sub_id = gc_check_sub_id-fiaa_duplicate_doc_it ).

      CLEAR: lv_msg_sub_text, lv_msg_text.
      lv_msg_sub_text = 'FAA_DELETE_DUPLICATE_DOC_IT'.
      MESSAGE w900(ac) with lv_msg_sub_text INTO lv_msg_text.
      _add_check_message(
        EXPORTING
          iv_description  = lv_msg_text
          iv_return_code  = gc_return_code-abortion
          iv_check_sub_id = gc_check_sub_id-fiaa_duplicate_doc_it ).

      CLEAR: lv_msg_sub_text, lv_msg_text.
      lv_msg_sub_text = 'The report consolidates duplicate entries'.
      MESSAGE w900(ac) with lv_msg_sub_text INTO lv_msg_text.
      _add_check_message(
        EXPORTING
          iv_description  = lv_msg_text
          iv_return_code  = gc_return_code-abortion
          iv_check_sub_id = gc_check_sub_id-fiaa_duplicate_doc_it ).

      CLEAR: lv_msg_sub_text, lv_msg_text.
      lv_msg_sub_text = 'Balances are kept stable at asset level'.
      MESSAGE w900(ac) with lv_msg_sub_text INTO lv_msg_text.
      _add_check_message(
        EXPORTING
          iv_description  = lv_msg_text
          iv_return_code  = gc_return_code-abortion
          iv_check_sub_id = gc_check_sub_id-fiaa_duplicate_doc_it ).

    ENDIF.

    " POSTCONDITION
    " none

  ENDMETHOD.