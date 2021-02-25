METHOD _get_count_for_assets.
*--------------------------------------------------------------------*
*  get the amount of assets for
*--------------------------------------------------------------------*
* PRECONDITION
  "None

* DEFINITIONS
  "None

* BODY
  SELECT COUNT(*) FROM anlb AS anlb
            INNER JOIN anla AS anla
                    ON anla~bukrs = anlb~bukrs
                   AND anla~anln1 = anlb~anln1
                   AND anla~anln2 = anlb~anln2
                   AND anla~mandt = anlb~mandt
                  CLIENT SPECIFIED
                 WHERE anlb~mandt = mv_client
                  AND anla~bukrs = iv_comp_code
                  AND  anla~anlkl = iv_asset_class
                  AND  anla~deakt = '00000000'
                  AND  anla~xinvm <> abap_true
                  AND  anlb~afabe =  iv_depr_area.
  rv_count = sy-dbcnt.
* POSTCONDITION
  "None

ENDMETHOD.