method CHECK_CONSISTENCY_HR_ON.

  data:
    lv_user_type         type gsval,
    lv_plavr             type gsval,

    lt_bp_to_cp          type table of hrp1001,
    lt_cp_to_persempl    type table of hrp1001,
    lt_persempl_to_cp    type table of hrp1001,
    lt_cp_to_bp          type table of hrp1001,
    lt_pa0105            type table of pa0105,

    lt_error_list        type salv_wd_t_string,
    lv_error_description like line of lt_error_list.

  field-symbols:
    <partner>     type ty_partner_data.


   clear r_chk_results.
   check i_client is not initial.


*-------------------------------------------------------------------------
*--- Fetch customizing for HR validations
*-------------------------------------------------------------------------
  select single gsval from t77s0 using client @i_client
    into  @lv_user_type   "default is 0001
    where grpid = 'MAIL' and semid = 'SAPSY'.

  lv_plavr = _get_hr_plvar( i_client = i_client ).

*----------------------------------------------------------------------------
*--- Fetch data for HR validations
*-------------------------------------------------------------------------

  "--- Table HRP0101:  BP to Central Person
  select * from hrp1001 using client @i_client into table @lt_bp_to_cp
    where sclas = 'BP' and rsign = 'B' and relat = '207' and plvar = @lv_plavr.

  "--- Table HRP0101: Central Person to HR Person/Employee
  select * from hrp1001 using client @i_client into table @lt_cp_to_persempl
    where otype = 'CP' and rsign = 'B' and relat = '209' and plvar = @lv_plavr.

  "--- Table PA0105: User assignment via HR Person/Employee PERNR
  select * from pa0105 using client @i_client into table @lt_pa0105
    where usrty = @lv_user_type and begda <= @sy-datum and endda >= @sy-datum.

  "--- Table HRP0101: HR Person/Employee to Central Person
  select * from hrp1001 using client @i_client into table @lt_persempl_to_cp
    where otype = 'P' and rsign = 'A' and relat = '209' and plvar = @lv_plavr.

  "--- Table HRP0101: Central Person to BP
  select * from hrp1001 using client @i_client into table @lt_cp_to_bp
    where otype = 'CP' and rsign = 'B' and relat = '207' and plvar = @lv_plavr.

*----------------------------------------------------------------------------
*--- Execute validations
*-------------------------------------------------------------------------

  loop at partner_data assigning <partner>.

    "-------------------------------------------------------------
    "--- Check maximum length of BP001-PERS_NR is 8
    "-------------------------------------------------------------
    lv_error_description = _validate_hr_on_persnr_length( exporting is_partner = <partner> ).
    if lv_error_description is not initial.
      append lv_error_description to lt_error_list.
      continue.
    endif.

    "-------------------------------------------------------------
    "---  Validation from PARTNER to PERS_NR and XUBNAME
    "---  BP -> Central Person -> HR Person/Emplyoee -> User
    "-------------------------------------------------------------
    append lines of _validate_hr_on_partnerid(
                      exporting
                        is_partner        = <partner>
                        it_bp_to_cp       = lt_bp_to_cp
                        it_cp_to_persempl = lt_cp_to_persempl
                        it_pa0105         = lt_pa0105 )
      to lt_error_list.

    "-------------------------------------------------------------
    "---  Validation from PERS_NR to PARTNER and XUBNAME
    "---  1. HR Person/Emplyoee -> User
    "---  2. HR Person/Emplyoee -> Central Person -> BP
    "-------------------------------------------------------------
    if <partner>-pers_nr is not initial.
      append lines of _validate_hr_on_persnr(
                        exporting
                          is_partner        = <partner>
                          it_persempl_to_cp = lt_persempl_to_cp
                          it_cp_to_bp       = lt_cp_to_bp
                          it_pa0105         = lt_pa0105 )
        to lt_error_list.
    endif.

    "-------------------------------------------------------------
    "---  Validation from XUBNAME to PARTNER and PERS_NR
    "---  1. User to HR Person/Emplyoee
    "---  2. HR Person/Emplyoee -> Central Person -> BP
    "-------------------------------------------------------------
    if <partner>-xubname is not initial.
      append lines of _validate_hr_on_xubname(
                        exporting
                          is_partner        = <partner>
                          it_persempl_to_cp = lt_persempl_to_cp
                          it_cp_to_bp       = lt_cp_to_bp
                          it_pa0105         = lt_pa0105 )
        to lt_error_list.
    endif.
  endloop.

*---------------------------------------------------------------------
*--- Build and return result list
*---------------------------------------------------------------------
  r_chk_results = _build_error_list(
                    i_check_sub_id = 'FS-BP / BP001 / 6 / HR active: Inconsistent HR data' "#EC NOTEXT
                    i_error_list   = lt_error_list ).

endmethod.