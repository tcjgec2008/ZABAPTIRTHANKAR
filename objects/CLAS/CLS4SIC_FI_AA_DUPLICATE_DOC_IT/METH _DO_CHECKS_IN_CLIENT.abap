  METHOD _do_checks_in_client.
*--------------------------------------------------------------------*
    " Trigger checks within a single client
*--------------------------------------------------------------------*
* PRECONDITION
    CLEAR rt_check_results.

    " DEFINITIONS
    "None

    " BODY

    "---check 1: Check for duplicate entries in FAAT_DOC_IT
    _check_for_duplicate_in_doc_it( ).

* POSTCONDITION
    rt_check_results = mt_check_results.

  ENDMETHOD.