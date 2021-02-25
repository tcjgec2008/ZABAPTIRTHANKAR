METHOD constructor.

  DATA:ls_ppms_stack           TYPE /sdf/cl_rc_chk_utility=>ty_ppms_stack_str,
        ls_target_stack        TYPE /sdf/cl_rc_chk_utility=>ty_conv_target_stack_str,
        ls_sitem               TYPE /sdf/cl_rc_chk_utility=>ty_smdb_item_str,
        lt_sitem_master        TYPE /sdf/cl_rc_chk_utility=>ty_smdb_item_tab,
        ls_target_release      TYPE /sdf/cl_rc_chk_utility=>ty_smdb_target_str,
        ls_ppms_prod_ver_from  TYPE /sdf/cl_rc_chk_utility=>ty_ppms_prod_version_str,
        lt_deleted_item        TYPE /sdf/cl_rc_chk_utility=>ty_smdb_item_tab,
        lt_bw_target_stack     TYPE /sdf/cl_rc_chk_utility=>ty_conv_target_stack_tab.

  FIELD-SYMBOLS <fs_sitem_master> TYPE /sdf/cl_rc_chk_utility=>ty_smdb_item_str.

  mv_target_stack = iv_target_stack.

*--------------------------------------------------------------------*
* Get S/4HANA conversion target release

  /sdf/cl_rc_chk_utility=>get_smdb_content(
    IMPORTING
      et_sitem                = mt_sitem
      et_note                 = mt_note
      et_check                = mt_check
      et_conv_target_stack    = mt_conv_target_stack
      et_bw_conv_target_stack = lt_bw_target_stack
      et_target_release       = mt_target_release
      et_source_release       = mt_source_release
      et_app_comp             = mt_app_component
      et_ppms_product         = mt_ppms_product
      et_ppms_prod_version    = mt_ppms_prod_version
      et_ppms_stack           = mt_ppms_stack
    EXCEPTIONS
      smdb_contnet_not_found  = 1
      error                   = 2
      OTHERS                  = 3 ).
  CASE sy-subrc.
    WHEN 0.
    WHEN 1.
      IF /sdf/cl_rc_chk_utility=>sv_is_ds_used = abap_true.
        "Simplification item catalog not found. Check Download Service connection or upload a version manually.
        mv_mesg_str = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '175' ) .
      ELSE.
        "Simplification item catalog not found. Check SAP-SUPPORT_PORTAL connection or upload a version manually.
        mv_mesg_str = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '170' ) .
      ENDIF.
      MESSAGE mv_mesg_str TYPE 'E' RAISING error.
    WHEN OTHERS.
      MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      RAISE error.
  ENDCASE.

  IF mt_sitem IS INITIAL.
    IF /sdf/cl_rc_chk_utility=>sv_is_ds_used = abap_true.
      "Simplification item catalog not found. Check Download Service connection or upload a version manually.
      mv_mesg_str = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '175' ) .
    ELSE.
      "Simplification item catalog not found. Check SAP-SUPPORT_PORTAL connection or upload a version manually.
      mv_mesg_str = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '170' ) .
    ENDIF.
    MESSAGE mv_mesg_str TYPE 'E' RAISING error.
  ENDIF.

  "In Test Mode: Remove master version if copy version exist
  "No test Mode: Remove all of V item
  IF /sdf/cl_rc_chk_utility=>is_test_mode( ) = abap_true.
    lt_sitem_master = mt_sitem.
    DELETE lt_sitem_master WHERE copy_guid IS INITIAL.
    IF lt_sitem_master IS NOT INITIAL.
      LOOP AT lt_sitem_master ASSIGNING <fs_sitem_master> WHERE proc_status = 'R'.
        READ TABLE mt_sitem WITH KEY guid = <fs_sitem_master>-copy_guid proc_status = 'V' TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          DELETE mt_sitem WHERE guid = <fs_sitem_master>-guid.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSE.
    DELETE mt_sitem WHERE proc_status <> 'R'.
  ENDIF.


*--------------------------------------------------------------------*
* Filter out BW/4HANa Simplification Items for S/4HANA

  READ TABLE mt_conv_target_stack INTO ls_target_stack
    WITH KEY stack_number = mv_target_stack.
  IF sy-subrc = 0.
    LOOP AT mt_sitem INTO ls_sitem.

      LOOP AT mt_target_release INTO ls_target_release
        WHERE guid = ls_sitem-guid.
        "Read PPMS meta data for target validality from
        IF ls_target_release-target_rel_valid_from_prd_ver <> '*'.
          READ TABLE mt_ppms_prod_version INTO ls_ppms_prod_ver_from
            WITH KEY prd_version_ppms_id = ls_target_release-target_rel_valid_from_prd_ver.
          "Possible that the S/4HANA item has no valid target release -> be careful and only delete explictly BW4/HANA items
          IF sy-subrc = 0 AND ls_ppms_prod_ver_from-product_ppms_id = '73554900100800000681'."BW4/HANA
            APPEND ls_sitem TO lt_deleted_item.
            DELETE mt_sitem.
            EXIT.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    RETURN.
  ENDIF.


*--------------------------------------------------------------------*
* Filter out S/4HANA Simplification Items for BW/4HANA

  READ TABLE lt_bw_target_stack INTO ls_target_stack
    WITH KEY stack_number = mv_target_stack.
  IF sy-subrc <> 0 OR lt_bw_target_stack IS INITIAL.
    IF /sdf/cl_rc_chk_utility=>sv_is_ds_used = abap_true.
      "BW/4HANA simplification item catalog not found. Check Download Service connection or upload a new version manually.
      mv_mesg_str = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '176' ) .
    ELSE.
      "BW/4HANA simplification item catalog not found. Check SAP-SUPPORT_PORTAL connection or upload a new version manually.
      mv_mesg_str = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '171' ) .
    ENDIF.
    MESSAGE mv_mesg_str TYPE 'E' RAISING error.
  ENDIF.

  mt_conv_target_stack = lt_bw_target_stack.

  LOOP AT mt_sitem INTO ls_sitem.

    LOOP AT mt_target_release INTO ls_target_release
      WHERE guid = ls_sitem-guid.
      "Read PPMS meta data for target validality from
      IF ls_target_release-target_rel_valid_from_prd_ver <> '*'.
        READ TABLE mt_ppms_prod_version INTO ls_ppms_prod_ver_from
          WITH KEY prd_version_ppms_id = ls_target_release-target_rel_valid_from_prd_ver.
        "Possible that the BW/4HANA item has no valid target release -> be careful and only delete explictly S/4HANA items
        IF sy-subrc = 0 AND ls_ppms_prod_ver_from-product_ppms_id <> '73554900100800000681'."BW4/HANA
          APPEND ls_sitem TO lt_deleted_item.
          DELETE mt_sitem.
          EXIT.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDLOOP.

ENDMETHOD.