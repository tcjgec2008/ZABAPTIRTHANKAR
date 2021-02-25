method _validate_hr_off_partnerid.

  data:
    ls_partner      type ty_partner_data,
    ls_bp_to_cp     type hrp1001,
    lt_bp_to_cp     type table of hrp1001,
    ls_cp_to_user   type hrp1001,

    lv_error_header type string,
    lv_error        like line of r_error_list.

  clear r_error_list.

  ls_partner = is_partner.
  lv_error_header = _build_error_header( is_partner = is_partner ).

  "-------------------------------------------------------
  "--- Check for BP to Central Person
  "-------------------------------------------------------
  loop at it_bp_to_cp into ls_bp_to_cp where sobid = ls_partner-partner_sobid.
    append ls_bp_to_cp to lt_bp_to_cp.
  endloop.

*  --> Is only filled im CRM systems, no general issue when not there
*  if lt_bp_to_cp is initial.
*    concatenate lv_error_header
*                'is not assigned to a Central Person in table HRP1001 via PARTNER_ID'
*           into lv_error respecting blanks.      "#EC NOTEXT
*    append lv_error to r_error_list.
*  endif.

  "-------------------------------------------------------
  "--- Check for Central Person to User
  "-------------------------------------------------------
  loop at lt_bp_to_cp into ls_bp_to_cp.
    loop at it_cp_to_user into ls_cp_to_user where objid = ls_bp_to_cp-objid.
      if ls_cp_to_user-sobid <> ls_partner-xubname.
        concatenate lv_error_header
                    'is assigned to a user in HRP1001 via CP_ID = ' ls_bp_to_cp-objid(8)
                    ' with USRID = ' ls_cp_to_user-sobid(15)
               into lv_error respecting blanks.      "#EC NOTEXT
        append lv_error to r_error_list.
        endif.
    endloop.

*    --> No issue when there is no user assigned
*    if ls_cp_to_user is initial.
*      concatenate lv_error_header
*                  'is not assigned to a user in HRP1001 via CP_ID = ' ls_bp_to_cp-objid(8)
*             into lv_error respecting blanks.      "#EC NOTEXT
*      append lv_error to r_error_list.
*    endif.
*
*    clear ls_cp_to_user.
  endloop.

endmethod.