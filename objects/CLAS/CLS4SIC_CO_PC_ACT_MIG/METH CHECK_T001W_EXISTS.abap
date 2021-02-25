method CHECK_T001W_EXISTS.


  DATA:     ls_t001k TYPE ty_t001k_fields,
            lt_t001w  TYPE tt_t001w,
            ls_t001w  TYPE ty_t001w_fields.


  CHECK IT_T001K IS NOT INITIAL.    " only proceed if there are entries!

  SELECT  mandt bwkey
     FROM t001w CLIENT SPECIFIED
     INTO CORRESPONDING FIELDS OF TABLE lt_t001w
      FOR ALL ENTRIES IN it_t001k
           WHERE mandt = it_t001k-mandt AND
                 bwkey = it_t001k-bwkey.

  sort lt_t001w by mandt bwkey.

  LOOP AT IT_T001K INTO LS_T001K  .

    READ TABLE LT_T001W TRANSPORTING NO FIELDS WITH KEY
            MANDT = LS_T001K-MANDT
            BWKEY = LS_T001K-BWKEY BINARY SEARCH.

    IF SY-SUBRC <> 0 .
      append ls_t001k to mt_no_t001w_entry_err.
    ENDIF.

  ENDLOOP.
endmethod.