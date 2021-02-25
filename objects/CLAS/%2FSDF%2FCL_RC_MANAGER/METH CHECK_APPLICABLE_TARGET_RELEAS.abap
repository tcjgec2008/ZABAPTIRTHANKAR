METHOD check_applicable_target_releas.

  DATA: ls_target_release       TYPE /sdf/cl_rc_chk_utility=>ty_smdb_target_str,
        lv_target_from_match    TYPE flag,
        lv_target_to_match      TYPE flag,
        lv_tooltip              TYPE char40,
        ls_ppms_prod_ver_from   TYPE /sdf/cl_rc_chk_utility=>ty_ppms_prod_version_str,
        ls_ppms_prod_ver_to     TYPE /sdf/cl_rc_chk_utility=>ty_ppms_prod_version_str,
        ls_ppms_stack_from      TYPE /sdf/cl_rc_chk_utility=>ty_ppms_stack_str,
        ls_ppms_stack_to        TYPE /sdf/cl_rc_chk_utility=>ty_ppms_stack_str,
        ls_ppms_prod_ver_target TYPE /sdf/cl_rc_chk_utility=>ty_ppms_prod_version_str,
        ls_ppms_stack_target    TYPE /sdf/cl_rc_chk_utility=>ty_ppms_stack_str.

  CLEAR: ev_target_match, es_match_target_rel.

*--------------------------------------------------------------------*
* Check whether the item is applicable based on target release

  "Read conversion target PPMS meta data
  READ TABLE mt_ppms_prod_version INTO ls_ppms_prod_ver_target
    WITH KEY prd_version_ppms_id = mv_target_prod_ver.
  READ TABLE mt_ppms_stack INTO ls_ppms_stack_target
    WITH KEY stack_ppms_id = mv_target_stack.

  "Take the item as match if no target validality defined for the item
  ev_target_match = abap_true.

  LOOP AT mt_target_release INTO ls_target_release
    WHERE guid = iv_sitem_guid.

    "Use the validality calculation if defined
    ev_target_match = abap_false.

    CLEAR: ls_ppms_prod_ver_from, ls_ppms_prod_ver_to, ls_ppms_stack_from, ls_ppms_stack_to.

    "Read PPMS meta data
    IF ls_target_release-target_rel_valid_from_prd_ver <> '*'.
      READ TABLE mt_ppms_prod_version INTO ls_ppms_prod_ver_from
        WITH KEY prd_version_ppms_id = ls_target_release-target_rel_valid_from_prd_ver.
    ENDIF.
    IF ls_target_release-target_rel_valid_to_prd_ver <> '*'.
      READ TABLE mt_ppms_prod_version INTO ls_ppms_prod_ver_to
        WITH KEY prd_version_ppms_id = ls_target_release-target_rel_valid_to_prd_ver.
    ENDIF.
    IF ls_target_release-target_rel_valid_from_stack <> '*'.
      READ TABLE mt_ppms_stack INTO ls_ppms_stack_from
        WITH KEY stack_ppms_id = ls_target_release-target_rel_valid_from_stack.
    ENDIF.
    IF ls_target_release-target_rel_valid_to_stack <> '*'.
      READ TABLE mt_ppms_stack INTO ls_ppms_stack_to
        WITH KEY stack_ppms_id = ls_target_release-target_rel_valid_to_stack.
    ENDIF.

    "Same PPMS product
    IF ls_ppms_prod_ver_from-product_ppms_id = ls_ppms_prod_ver_target-product_ppms_id.

      "Check for validity from
      "Match PPMS product version
      IF   ls_target_release-target_rel_valid_from_prd_ver = '*'
        OR ls_target_release-target_rel_valid_from_prd_ver = space
        OR ls_ppms_prod_ver_from-prd_version_sequence < ls_ppms_prod_ver_target-prd_version_sequence.

        "No need to compare stack if the product version already matches
        lv_target_from_match = abap_true.

      ELSEIF ls_ppms_prod_ver_from-prd_version_sequence = ls_ppms_prod_ver_target-prd_version_sequence.
        "Match PPMS stack
        IF   ls_target_release-target_rel_valid_from_stack = '*'
          OR ls_target_release-target_rel_valid_from_stack = space
          OR ls_ppms_stack_from-stack_sequence <= ls_ppms_stack_target-stack_sequence.
          lv_target_from_match = abap_true.
        ENDIF.
      ENDIF.

      "Check for validatily to
      "Match PPMS product version
      IF   ls_target_release-target_rel_valid_to_prd_ver = '*'
        OR ls_target_release-target_rel_valid_to_prd_ver = space
        OR ls_ppms_prod_ver_to-prd_version_sequence > ls_ppms_prod_ver_target-prd_version_sequence.

        "No need to compare stack if the product version already matches
        lv_target_to_match = abap_true.

      ELSEIF ls_ppms_prod_ver_to-prd_version_sequence = ls_ppms_prod_ver_target-prd_version_sequence.
        "Match PPMS stack
        IF   ls_target_release-target_rel_valid_to_stack = '*'
          OR ls_target_release-target_rel_valid_to_stack = space
          OR ls_ppms_stack_to-stack_sequence >= ls_ppms_stack_target-stack_sequence.
          lv_target_to_match = abap_true.
        ENDIF.
      ENDIF.

    ENDIF.

    IF lv_target_from_match = abap_true AND lv_target_to_match = abap_true.
      ev_target_match = abap_true.
      "We suppose there is only one target release maintained for the target conversion version;
      "otherwise it does not make sense. The target release will be used to calculate category.
      es_match_target_rel = ls_target_release.
      EXIT.
    ENDIF.

  ENDLOOP.

ENDMETHOD.