  METHOD check_consistency.

    DATA:
      lt_duplicates     TYPE ty_duplicates.

    CLEAR et_chk_result.

    IF is_detailed_check( it_parameter ) = abap_true.
      get_duplicates( IMPORTING et_duplicates = lt_duplicates ).

      IF lines( lt_duplicates ) = 0.
        APPEND gt_chk_result_success TO et_chk_result.
      ELSE.
        LOOP AT lt_duplicates REFERENCE INTO DATA(lr_duplicate).
          APPEND create_abortion( lr_duplicate->* ) TO et_chk_result.
        ENDLOOP.
      ENDIF.
    ELSE.
      IF has_duplicates( ) = abap_true.
        APPEND create_simple_abortion( ) TO et_chk_result.
      ELSE.
        APPEND gt_chk_result_success TO et_chk_result.
      ENDIF.
    ENDIF.

  ENDMETHOD.