  METHOD class_constructor.

    gt_chk_result_success = VALUE #(
      check_sub_id = c_inob_dupe_chk_sub_id
      return_code  = c_cons_chk_return_code-success
      descriptions = VALUE #( ( `No INOB duplicates (inconsistency) found.` ) ) ).

  ENDMETHOD.