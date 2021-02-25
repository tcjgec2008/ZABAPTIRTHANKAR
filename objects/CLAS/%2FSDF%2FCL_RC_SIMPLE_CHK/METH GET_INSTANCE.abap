METHOD get_instance.

  DATA: ls_check         TYPE /sdf/cl_rc_chk_utility=>ty_smdb_check_str,
        ls_check_ty_desc TYPE string.

  CASE is_check-check_type.
    WHEN /sdf/cl_rc_chk_utility=>c_check_type-buz_func.
      ls_check_ty_desc = 'Business Function based check'.   "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_check_type-entry_point.
      ls_check_ty_desc = 'Entry Point based check'.         "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_check_type-idoc.
      ls_check_ty_desc = 'iDoc based check'.                "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_check_type-pre_check_old.
      ls_check_ty_desc = 'Old pre check'.                   "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_check_type-pre_check_new.
      ls_check_ty_desc = 'New pre check'.                   "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_check_type-table.
      ls_check_ty_desc = 'Table based check'.               "#EC NOTEXT
    WHEN /sdf/cl_rc_chk_utility=>c_check_type-manual.
      ls_check_ty_desc = 'Manual check'.                    "#EC NOTEXT
    WHEN OTHERS.
      ls_check_ty_desc = is_check-check_type.               "#EC NOTEXT
  ENDCASE.

  CONCATENATE ls_check_ty_desc '/' is_check-check_identifier INTO mv_mesg_str.
  IF is_check-check_sub_identifier IS NOT INITIAL.
    CONCATENATE mv_mesg_str '/' is_check-check_sub_identifier INTO mv_mesg_str.
  ENDIF.


*--------------------------------------------------------------------*
* Create instance according to the check type

  CASE is_check-check_type.
    WHEN /sdf/cl_rc_chk_utility=>c_check_type-table.
      CREATE OBJECT ro_check TYPE /sdf/cl_rc_simple_chk_db
        EXPORTING
          is_check = is_check.

    WHEN  /sdf/cl_rc_chk_utility=>c_check_type-idoc.
      CREATE OBJECT ro_check TYPE /sdf/cl_rc_simple_chk_idoc
        EXPORTING
          is_check = is_check.

    WHEN  /sdf/cl_rc_chk_utility=>c_check_type-buz_func.

      CREATE OBJECT ro_check TYPE /sdf/cl_rc_simple_chk_buz_func
        EXPORTING
          is_check = is_check.
    WHEN /sdf/cl_rc_chk_utility=>c_check_type-entry_point.
      CREATE OBJECT ro_check TYPE /sdf/cl_rc_simple_chk_en_point
        EXPORTING
          is_check = is_check.

    WHEN OTHERS.
      "Check type &P1& is not supported for &P2&
      mv_mesg_str = /sdf/cl_rc_chk_utility=>get_text_str(
        iv_txt_key = '002'
        iv_para1   = ls_check_ty_desc
        iv_para2   = mv_mesg_str ).
      MESSAGE mv_mesg_str TYPE 'E'.
  ENDCASE.

ENDMETHOD.