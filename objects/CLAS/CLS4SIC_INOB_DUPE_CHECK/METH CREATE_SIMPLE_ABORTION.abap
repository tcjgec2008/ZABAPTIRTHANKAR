  METHOD create_simple_abortion.

    CLEAR rs_chk_result.

    rs_chk_result-check_sub_id = c_inob_dupe_chk_sub_id.
    rs_chk_result-return_code  = c_cons_chk_return_code-abortion.
    rs_chk_result-descriptions = VALUE #( ( `Inconsistency: Several INOB entry found for a Business Object! Please do a run with detailed check turned on.` ) ).

  ENDMETHOD.