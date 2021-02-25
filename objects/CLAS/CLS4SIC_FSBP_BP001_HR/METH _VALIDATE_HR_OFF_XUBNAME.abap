method _validate_hr_off_xubname.

  data:
    ls_partner      type ty_partner_data,
    ls_user_to_cp   type hrp1001,
    lt_user_to_cp   type table of hrp1001,
    ls_cp_to_bp     type hrp1001,

    lv_error_header type string,
    lv_error        like line of r_error_list.

  clear r_error_list.

  ls_partner = is_partner.
  lv_error_header = _build_error_header( is_partner = is_partner ).


  "-------------------------------------------------------
  "--- Check for User to Central Person
  "-------------------------------------------------------
  loop at it_user_to_cp  into ls_user_to_cp where sobid = ls_partner-xubname.
    append ls_user_to_cp to lt_user_to_cp.
  endloop.

*  --> Is only filled im CRM systems, no general issue when not there
*  if lt_user_to_cp is initial.
*    concatenate lv_error_header
*                'is not assigned to an user in table HRP1001 via XUBNAME'
*           into lv_error respecting blanks.      "#EC NOTEXT
*    append lv_error to r_error_list.
*    return.
*  endif.

  "-------------------------------------------------------
  "--- Check for Central Person to BP
  "-------------------------------------------------------
  loop at lt_user_to_cp into ls_user_to_cp.
    loop at it_cp_to_bp into ls_cp_to_bp where objid = ls_user_to_cp-objid.
      if ls_cp_to_bp-sobid <> ls_partner-partner.
        concatenate lv_error_header
                    'is assigned to a user in HRP1001 via CP_ID = ' ls_user_to_cp-objid(8)
                    ' with PARTNERID = ' ls_user_to_cp-sobid
               into lv_error respecting blanks.      "#EC NOTEXT
        append lv_error to r_error_list.
      endif.
    endloop.

*    --> No issue when there is no user assigned
*    if ls_cp_to_bp is initial.
*      concatenate lv_error_header
*                  'is not assigned to a user in HRP1001 via CP_ID = ' ls_user_to_cp-objid(8)
*             into lv_error respecting blanks.      "#EC NOTEXT
*      append lv_error to r_error_list.
*    endif.
*
*    clear ls_cp_to_bp.
  endloop.

endmethod.