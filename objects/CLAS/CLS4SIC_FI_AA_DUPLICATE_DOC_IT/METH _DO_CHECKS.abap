  METHOD _do_checks.
*--------------------------------------------------------------------*
* Trigger checks separately per clients
*--------------------------------------------------------------------*
* PRECONDITION
    REFRESH rt_check_results.

* DEFINITIONS
    DATA:
      lt_t000                 TYPE t000_tab,
      lo_pre_check            TYPE REF TO cls4sic_fi_aa_duplicate_doc_it,
      lt_check_results_client TYPE ty_pre_cons_chk_result_tab.

   FIELD-SYMBOLS:
      <ls_t000> LIKE LINE OF lt_t000.

* BODY
    _get_clients_to_be_checked(
      IMPORTING
        et_t000 = lt_t000
    ).

* Do checks for all needed clients
    LOOP AT lt_t000 ASSIGNING <ls_t000>.
      CREATE OBJECT lo_pre_check
        EXPORTING
          iv_check_client = <ls_t000>-mandt.
      lt_check_results_client = lo_pre_check->_do_checks_in_client( ).
      APPEND LINES OF lt_check_results_client TO rt_check_results.
    ENDLOOP.

* POSTCONDITION
    "None

  ENDMETHOD.