METHOD check_applicable_source_releas.

  DATA: ls_source_release       TYPE /sdf/cl_rc_chk_utility=>ty_smdb_source_str,
        lv_source_from_match    TYPE flag,
        lv_source_to_match      TYPE flag,
        ls_ppms_prod_ver_from   TYPE /sdf/cl_rc_chk_utility=>ty_ppms_prod_version_str,
        ls_ppms_prod_ver_to     TYPE /sdf/cl_rc_chk_utility=>ty_ppms_prod_version_str,
        ls_ppms_prod_ver_source TYPE /sdf/cl_rc_chk_utility=>ty_ppms_prod_version_str,
        ls_cvers                TYPE cvers.

  "Take the item as not match if no source validality defined for the item
  rv_source_match = abap_false.

*  "Skip the source release check in test mode
*  CHECK /sdf/cl_rc_chk_utility=>sv_test_system = abap_false.


*--------------------------------------------------------------------*
* Special handling for sFIN system (SAP_FIN >=700)
* For sFIN system, remove ERP related source release entry then all source
* release possibilities 1, 2, 3 work as desired for both system a & b
*
* For a system to be converted, there are 2 possiblities
*   a. Pure ERP system without sFIN
*   b. sFIN system which technical contains ERP component
* For a SItem source release, there are 3 possiblities
*   1. both ERP and sFIN are maintained
*      works as desired since the SItem is for both system a & b
*   2. only sFIN is maintained
*      works as desired since the SItem is only for system b
*   3. only ERP is maintained -> false-positive for system b
*      need special handling

  IF mt_cvers IS INITIAL.

    SELECT * FROM cvers INTO TABLE mt_cvers.

    READ TABLE mt_cvers INTO ls_cvers
      WITH KEY component = 'SAP_FIN'."sFIN software component
    IF sy-subrc = 0 AND ls_cvers-release >= '700'.
      LOOP AT mt_ppms_prod_version INTO ls_ppms_prod_ver_source
         WHERE sw_comp_tech_name = 'SAP_APPL' "ERP software component
            OR sw_comp_tech_name = 'S4CORE'.  "S/4HANA
        DELETE mt_source_release WHERE source_rel_valid_from_prd_ver = ls_ppms_prod_ver_source-prd_version_ppms_id.
      ENDLOOP.
    ENDIF.

  ENDIF.


*--------------------------------------------------------------------*
* Check whether the item is applicable based on source release
* So far we only validate to product version level since normally source release
* validality information is not maintained to stack level

  LOOP AT mt_source_release INTO ls_source_release
    WHERE guid = iv_sitem_guid.

    "Use the validality calculation if defined
    rv_source_match = abap_false.

    CLEAR: ls_ppms_prod_ver_from, ls_ppms_prod_ver_to.

    "Read PPMS meta data
    IF ls_source_release-source_rel_valid_from_prd_ver <> '*'.
      READ TABLE mt_ppms_prod_version INTO ls_ppms_prod_ver_from
        WITH KEY prd_version_ppms_id = ls_source_release-source_rel_valid_from_prd_ver.
    ENDIF.
    IF ls_source_release-source_rel_valid_to_prd_ver <> '*'.
      READ TABLE mt_ppms_prod_version INTO ls_ppms_prod_ver_to
        WITH KEY prd_version_ppms_id = ls_source_release-source_rel_valid_to_prd_ver.
    ENDIF.

    READ TABLE mt_cvers INTO ls_cvers
      WITH KEY component = ls_ppms_prod_ver_from-sw_comp_tech_name.
    CHECK sy-subrc = 0.

    "Read conversion source PPMS meta data
    READ TABLE mt_ppms_prod_version INTO ls_ppms_prod_ver_source
      WITH KEY sw_comp_tech_name = ls_cvers-component "e.g. SAP_APPL
               sw_comp_release   = ls_cvers-release.  "e.g. 618
    CHECK sy-subrc = 0.

    "No need to check from same PPMS product since it's ganranteed by mataching Software Component
    "Check for validatily from -> match PPMS product version
    IF   ls_source_release-source_rel_valid_from_prd_ver = '*'
      OR ls_source_release-source_rel_valid_from_prd_ver = space
      OR ls_ppms_prod_ver_from-prd_version_sequence <= ls_ppms_prod_ver_source-prd_version_sequence.

      lv_source_from_match = abap_true.

    ENDIF.
    "Check for validatily to -> match PPMS product version
    IF   ls_source_release-source_rel_valid_to_prd_ver = '*'
      OR ls_source_release-source_rel_valid_to_prd_ver = space
      OR ls_ppms_prod_ver_to-prd_version_sequence >= ls_ppms_prod_ver_source-prd_version_sequence.

      lv_source_to_match = abap_true.

    ENDIF.

    IF lv_source_from_match = abap_true AND lv_source_to_match = abap_true.
      rv_source_match = abap_true.
      EXIT.
    ENDIF.

  ENDLOOP.

ENDMETHOD.