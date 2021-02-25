  METHOD create_abortion.

    CLEAR rs_chk_result.

    rs_chk_result-check_sub_id = c_inob_dupe_chk_sub_id.
    rs_chk_result-return_code  = c_cons_chk_return_code-abortion.
    rs_chk_result-descriptions = VALUE #( (
         `Inconsistency: Several INOB entries found for Business Object:`
       & ` MANDT=` && is_duplicate-mandt
      && ` KLART='` && is_duplicate-klart && `'`
       & ` OBTAB='` && is_duplicate-obtab && `'`
       & ` OBJEK='` && is_duplicate-objek && `'`
       & ` Please eliminate INOB duplicates. For more information, see SAP Note 2948953!` ) ).

  ENDMETHOD.