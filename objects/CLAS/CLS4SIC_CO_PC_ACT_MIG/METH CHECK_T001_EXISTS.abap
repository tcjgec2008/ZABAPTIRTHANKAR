METHOD check_t001_exists.


  DATA: ls_t001k TYPE ty_t001k_fields,
        lt_t001  TYPE tt_t001,
        ls_t001  TYPE ty_t001_fields,
        ls_no_t001_entry_err TYPE ty_t001_fields.


  CHECK it_t001k IS NOT INITIAL.    " only proceed if there are entries!

  SELECT  mandt bukrs
     FROM t001 CLIENT SPECIFIED
     INTO CORRESPONDING FIELDS OF TABLE lt_t001
      FOR ALL ENTRIES IN it_t001k
           WHERE mandt = it_t001k-mandt AND
                 bukrs = it_t001k-bukrs
    ORDER BY PRIMARY KEY .

  LOOP AT it_t001k INTO ls_t001k  .

    READ TABLE lt_t001 TRANSPORTING NO FIELDS WITH KEY
            mandt = ls_t001k-mandt
            bukrs = ls_t001k-bukrs BINARY SEARCH.

    IF sy-subrc <> 0 .
      MOVE-CORRESPONDING ls_t001k TO ls_no_t001_entry_err.
      APPEND ls_no_t001_entry_err TO mt_no_t001_entry_err.
    ENDIF.

  ENDLOOP.

ENDMETHOD.