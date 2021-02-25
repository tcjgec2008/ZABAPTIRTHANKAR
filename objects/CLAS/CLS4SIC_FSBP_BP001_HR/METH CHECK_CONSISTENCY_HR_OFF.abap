method check_consistency_hr_off.

  data:
    lv_plavr      type gsval,

    lt_bp_to_cp   type table of hrp1001,
    lt_cp_to_user type table of hrp1001,
    lt_cp_to_bp   type table of hrp1001,
    lt_user_to_cp type table of hrp1001,

    lt_error_list type salv_wd_t_string.

  field-symbols:
    <partner>       type ty_partner_data.

  clear r_chk_results.
  check i_client is not initial.


*-------------------------------------------------------------------------
*--- Fetch customizing for HR validations
*-------------------------------------------------------------------------
  lv_plavr = _get_hr_plvar( i_client = i_client ).

*----------------------------------------------------------------------------
*--- Fetch data for HR validations
*-------------------------------------------------------------------------

  "--- Table HRP0101:  BP to Central Person
  select * from hrp1001 using client @i_client into table @lt_bp_to_cp
    where sclas = 'BP' and rsign = 'B' and relat = '207' and plvar = @lv_plavr.

  "--- Table HRP0101:  Central Person to User
  select * from hrp1001 using client @i_client into table @lt_cp_to_user
    where otype = 'CP' and rsign = 'B' and relat = '208' and plvar = @lv_plavr.

  "--- Table HRP0101:  User to Central Person
  select * from hrp1001 using client @i_client into table @lt_user_to_cp
    where sclas = 'US' and rsign = 'B' and relat = '208' and plvar = @lv_plavr.

  "--- Table HRP0101: Central Person to BP
  select * from hrp1001 using client @i_client into table @lt_cp_to_bp
    where otype = 'CP' and rsign = 'B' and relat = '207' and plvar = @lv_plavr.


*----------------------------------------------------------------------------
*--- Execute validations
*-------------------------------------------------------------------------

  loop at partner_data assigning <partner>.

    "-------------------------------------------------------------
    "---  Validation from PARTNER to XUBNAME
    "---  BP -> Central Person -> User
    "-------------------------------------------------------------
    append lines of _validate_hr_off_partnerid(
                      exporting
                        is_partner    = <partner>
                        it_bp_to_cp   = lt_bp_to_cp
                        it_cp_to_user = lt_cp_to_user )
      to lt_error_list.

    "-------------------------------------------------------------
    "---  Validation from XUBNAME to PARTNER
    "---  User -> Central Person -> Partner
    "-------------------------------------------------------------
    append lines of _validate_hr_off_xubname(
                      exporting
                        is_partner     = <partner>
                        it_user_to_cp  = lt_user_to_cp
                        it_cp_to_bp    = lt_cp_to_bp )
      to lt_error_list.

  endloop.

*---------------------------------------------------------------------
*--- Build and return result list
*---------------------------------------------------------------------
  r_chk_results = _build_error_list(
                    i_check_sub_id = 'FS-BP / BP001 / 6 / HR inactive: Inconsistent HR Central Person data' "#EC NOTEXT
                    i_error_list   = lt_error_list ).

endmethod.