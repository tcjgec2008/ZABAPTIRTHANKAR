  METHOD  check_bp_cv_obsolete_linkages.
* Check whether the entries are migrated to CVI_CUST_LINK/CVI_VEND_LINK from the obsolete tables BD001 and BC001

    TYPES: BEGIN OF ty_kunnr,
             kunnr TYPE kunnr,
           END OF ty_kunnr,
           BEGIN OF ty_lifnr,
             lifnr TYPE lifnr,
           END OF ty_lifnr,
           BEGIN OF ty_customer,
             customer TYPE kunnr,
           END OF ty_customer,
           BEGIN OF ty_vendor,
             vendor TYPE lifnr,
           END OF ty_vendor.

    DATA: ls_check_result      LIKE LINE OF et_check_results,
          lt_kunnr             TYPE STANDARD TABLE OF ty_kunnr,
          lt_lifnr             TYPE STANDARD TABLE OF ty_lifnr,
          lt_customer          TYPE STANDARD TABLE OF ty_customer,
          lt_vendor            TYPE STANDARD TABLE OF ty_vendor,
          lv_error_description TYPE string,
          lv_count_new_links   TYPE int2,
          lv_count_obs_links   TYPE int2.

    CLEAR et_check_results.

*  Check customer assignment table empty or not
    SELECT kunnr FROM bd001 INTO TABLE lt_kunnr.        "#EC CI_NOWHERE
    IF lt_kunnr IS NOT INITIAL.
      SELECT customer FROM cvi_cust_link INTO TABLE lt_customer FOR ALL ENTRIES IN lt_kunnr WHERE customer = lt_kunnr-kunnr. "#EC CI_NO_TRANSFORM
        DESCRIBE TABLE lt_kunnr LINES lv_count_obs_links.
        DESCRIBE TABLE lt_customer LINES lv_count_new_links.
*        If number of entries in tables lt_kunnr and lt_customer are not equal then migration is needed
*        Raise an error message
        IF lv_count_obs_links NE lv_count_new_links.
          lv_error_description = 'Data exists in BP customer assignment (BD001) table. (migration necessary!)'. "#EC NOTEXT
          APPEND lv_error_description TO ls_check_result-descriptions.
          CLEAR: lv_error_description,lv_count_obs_links,lv_count_new_links.
        ENDIF.
    ENDIF.

*  Check vendor assignment table empty or not
    SELECT lifnr FROM bc001 INTO TABLE lt_lifnr.        "#EC CI_NOWHERE
    IF lt_lifnr IS NOT INITIAL.
      SELECT vendor FROM cvi_vend_link INTO TABLE lt_vendor FOR ALL ENTRIES IN lt_lifnr WHERE vendor = lt_lifnr-lifnr. "#EC CI_NO_TRANSFORM
        DESCRIBE TABLE lt_lifnr LINES lv_count_obs_links.
        DESCRIBE TABLE lt_vendor LINES lv_count_new_links.
*        If number of entries in tables lt_lifnr and lt_vendor are not equal then migration is needed
*        Raise an error message
        IF lv_count_obs_links NE lv_count_new_links.
          lv_error_description = 'Data exists in BP vendor assignment (BC001) table. (migration necessary!)'.  "#EC NOTEXT
          APPEND lv_error_description TO ls_check_result-descriptions.
          CLEAR: lv_error_description,lv_count_obs_links,lv_count_new_links.
        ENDIF.
    ENDIF.

*   If data in BD001/BC001 which is not yet migrated to CVI_CUST_LINK/CVI_VEND_LINK
*   Give an error message.
    IF ls_check_result-descriptions IS NOT INITIAL.
      ls_check_result-check_sub_id = 'CHK_BD_BC_001'.
      ls_check_result-return_code =  c_cons_chk_return_code-error.
      APPEND ls_check_result TO et_check_results.
    ENDIF.
  ENDMETHOD.