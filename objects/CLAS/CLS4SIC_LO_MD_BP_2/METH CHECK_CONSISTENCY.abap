    METHOD check_consistency.
    DATA: ls_chk_result  TYPE ty_pre_cons_chk_result_str,
            lv_description   TYPE string,
            lt_check_results TYPE ty_pre_cons_chk_result_tab.

      CLEAR et_chk_result.
* Add initial status line
    ls_chk_result-check_sub_id = 'CHECK_START'.
    ls_chk_result-return_code = c_cons_chk_return_code-success.
    lv_description = 'Start execution of Class'. "#EC NOTEXT
      APPEND lv_description TO ls_chk_result-descriptions.
      APPEND ls_chk_result TO et_chk_result.

**********************************************************************************************
***********************************Start of Checks *******************************************

* Check whether the entries are migrated to CVI_CUST_LINK/CVI_VEND_LINK from the obsolete tables BD001 and BC001
      CALL METHOD cls4sic_lo_md_bp_2=>check_bp_cv_obsolete_linkages
        IMPORTING
          et_check_results = lt_check_results.

    IF lt_check_results IS NOT INITIAL.
      APPEND LINES OF lt_check_results TO et_chk_result.
    ENDIF.

  endmethod.