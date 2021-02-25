METHOD _CHECK_PERIOD_SCALING.
*--------------------------------------------------------------------*
* check the period scaling compatible with definition of depr. key;
* in the depreciation key, the calculation of depreciation to the
* exact day is allowed;
* if this option is activated, the period scaling has to be 365
*--------------------------------------------------------------------*
* PRECONDITION
  " None

* DEFINITIONS
  CONSTANTS: lc_message_limit TYPE i VALUE 100.
  DATA: lt_t090na           TYPE STANDARD TABLE OF t090na,
        lr_t090na           TYPE RANGE OF afasl,
        lr_t090na_line      LIKE LINE OF lr_t090na,
        ls_asset            TYPE ty_s_asset_key,
        lt_assets           TYPE ty_t_asset_key,
        lv_msg_text         TYPE string,
        lv_asset_text       TYPE string,
        lv_remaining_assets TYPE string,
        lv_table_lines      TYPE i.
  FIELD-SYMBOLS: <ls_t093c>  TYPE t093c,
                 <ls_t090na> TYPE t090na.


* BODY
  LOOP AT mt_t093c ASSIGNING <ls_t093c>. "check all active company code
    " Check if there are depreciation key with daily depr.
    SELECT afapl afasl xdaily FROM t090na
                    CLIENT SPECIFIED
                    INTO CORRESPONDING FIELDS OF TABLE lt_t090na
                    WHERE mandt = mv_client
                      AND afapl = <ls_t093c>-afapl
                      AND xdaily = abap_true.

    CHECK lt_t090na IS NOT INITIAL. "Daily depr exists
    "Build up range of afasl
    CLEAR: lr_t090na.
    LOOP AT lt_t090na ASSIGNING <ls_t090na>.
      " Build up range of rldnr
      lr_t090na_line-sign = 'I'.
      lr_t090na_line-option = 'EQ'.
      lr_t090na_line-low = <ls_t090na>-afasl.
      APPEND lr_t090na_line TO lr_t090na.
    ENDLOOP.

    "Check if there are active assets, that have have an depr. key with daily depr.,
    " but their period scaling is not equal 365 (and not 0 or not specified)
    SELECT SINGLE *
      FROM anlb AS anlb
    INNER JOIN anla AS anla
      ON  anla~bukrs = anlb~bukrs
      AND anla~anln1 = anlb~anln1
      AND anla~anln2 = anlb~anln2
      AND anla~mandt = anlb~mandt
     CLIENT SPECIFIED
     INTO CORRESPONDING FIELDS OF ls_asset
     WHERE anlb~mandt = mv_client
       AND anlb~bukrs = <ls_t093c>-bukrs
       AND anlb~afasl IN lr_t090na
       AND anla~deakt = '00000000'
       AND NOT ( anlb~perfy = '365'
                OR anlb~perfy = ''
                OR anlb~perfy = '0' ).
    IF sy-subrc = 0. "Find something -> error
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.
        lv_msg_text = 'There are inconsistencies with depr. key for daily depr. and asset period scaling. For more info, choose ''Check Consistency Details''.'.
        _add_check_message(
        EXPORTING
          iv_description = lv_msg_text
          iv_check_sub_id = gc_check_sub_id-fiaa_cust_depr_key ).
        RETURN.
      ELSE.
        SELECT anlb~bukrs
               anlb~anln1
               anlb~anln2
          FROM      anlb AS anlb
         INNER JOIN anla AS anla
            ON      anla~bukrs = anlb~bukrs
           AND      anla~anln1 = anlb~anln1
           AND      anla~anln2 = anlb~anln2
           AND      anla~mandt = anlb~mandt
        CLIENT SPECIFIED
          INTO TABLE lt_assets
         WHERE anlb~mandt = mv_client
           AND anlb~bukrs = <ls_t093c>-bukrs
           AND anlb~afasl IN lr_t090na
           AND anla~deakt = '00000000'
           AND NOT ( anlb~perfy = '365'
                  OR anlb~perfy = ''
                  OR anlb~perfy = '0' ).

        LOOP AT lt_assets INTO ls_asset.
          CONCATENATE ls_asset-anln1 '-' ls_asset-anln2 INTO lv_asset_text.
          MESSAGE e215(acc_aa) WITH <ls_t093c>-bukrs lv_asset_text INTO lv_msg_text.
          _add_check_message(
            EXPORTING
              iv_description = lv_msg_text
              iv_check_sub_id = gc_check_sub_id-fiaa_cust_depr_key ).
          IF sy-index >= lc_message_limit.
            DESCRIBE TABLE lt_assets LINES lv_table_lines.
            lv_remaining_assets = lv_table_lines - sy-index.
            CONCATENATE 'Number of calculation periods differing from deprec. key. CC' <ls_t093c>-bukrs
                         lv_remaining_assets 'more Assets' INTO lv_msg_text SEPARATED BY space.
      _add_check_message(
        EXPORTING
          iv_description = lv_msg_text
                iv_check_sub_id = gc_check_sub_id-fiaa_cust_depr_key ).
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ELSE.
      "check also the time-dependent depreciation terms
      SELECT SINGLE *
        FROM anlbza AS anlbza
      INNER JOIN  anlb   AS anlb
        ON        anlbza~bukrs = anlb~bukrs
        AND       anlbza~anln1 = anlb~anln1
        AND       anlbza~anln2 = anlb~anln2
        AND       anlbza~afabe = anlb~afabe
        AND       anlbza~mandt = anlb~mandt
      INNER JOIN  anla   AS anla
        ON        anla~bukrs = anlb~bukrs
        AND       anla~anln1 = anlb~anln1
        AND       anla~anln2 = anlb~anln2
        AND       anla~mandt = anlb~mandt
      CLIENT SPECIFIED
      INTO CORRESPONDING FIELDS OF ls_asset
      WHERE anlbza~mandt = mv_client
        AND anlbza~bukrs  = <ls_t093c>-bukrs
        AND anla~deakt    = '00000000'
        AND anlbza~bdatu  <= '99991231'
        AND anlbza~afasl  IN lr_t090na
        AND NOT (   anlb~perfy  = '365'
                 OR  anlb~perfy = ''
                 OR  anlb~perfy = '0' ).

      IF sy-subrc = 0.
        IF cls4sic_fi_aa=>gb_detailed_check = abap_false.
          lv_msg_text = 'There are inconsistencies with depr. key for daily depr. and asset period scaling. For more info, choose ''Check Consistency Details''.'.
          _add_check_message(
            EXPORTING
              iv_description = lv_msg_text
              iv_check_sub_id = gc_check_sub_id-fiaa_cust_depr_key ).
          RETURN.
        ELSE.
          SELECT anlbza~bukrs
                 anlbza~anln1
                 anlbza~anln2
            FROM anlbza AS anlbza
          INNER JOIN  anlb   AS anlb
            ON        anlbza~bukrs = anlb~bukrs
            AND       anlbza~anln1 = anlb~anln1
            AND       anlbza~anln2 = anlb~anln2
            AND       anlbza~afabe = anlb~afabe
            AND       anlbza~mandt = anlb~mandt
          INNER JOIN  anla   AS anla
            ON        anla~bukrs = anlb~bukrs
            AND       anla~anln1 = anlb~anln1
            AND       anla~anln2 = anlb~anln2
            AND       anla~mandt = anlb~mandt
          CLIENT SPECIFIED
          INTO TABLE lt_assets
          WHERE anlbza~mandt = mv_client
            AND anlbza~bukrs  = <ls_t093c>-bukrs
            AND anla~deakt    = '00000000'
            AND anlbza~bdatu  <= '99991231'
            AND anlbza~afasl  IN lr_t090na
            AND NOT (   anlb~perfy  = '365'
                     OR  anlb~perfy = ''
                     OR  anlb~perfy = '0' ).

          LOOP AT lt_assets INTO ls_asset.
            CONCATENATE ls_asset-anln1 '-' ls_asset-anln2 INTO lv_asset_text.
            MESSAGE e215(acc_aa) WITH <ls_t093c>-bukrs lv_asset_text INTO lv_msg_text.
            _add_check_message(
              EXPORTING
                iv_description = lv_msg_text
                iv_check_sub_id = gc_check_sub_id-fiaa_cust_depr_key ).
            IF sy-index >= lc_message_limit.
              DESCRIBE TABLE lt_assets LINES lv_table_lines.
              lv_remaining_assets = lv_table_lines - sy-index.
              CONCATENATE 'Number of calculation periods differing from deprec. key. CC' <ls_t093c>-bukrs
                           lv_remaining_assets 'more Assets' INTO lv_msg_text SEPARATED BY space.
        _add_check_message(
          EXPORTING
            iv_description = lv_msg_text
                  iv_check_sub_id = gc_check_sub_id-fiaa_cust_depr_key ).
              EXIT.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDIF. "wrong data found in anlbza
    ENDIF. "wrong data found in anlb
  ENDLOOP.

* POSTCONDITION
" None

ENDMETHOD.