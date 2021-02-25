method _validate_hr_on_xubname.

  data:
    ls_partner        type ty_partner_data,
    ls_persempl_to_cp type hrp1001,
    lt_persempl_to_cp type table of hrp1001,
    ls_cp_to_bp       type hrp1001,
    ls_pa0105         type pa0105,

    lv_numc8          type n length 8,
    lv_error_header   type string,
    lv_error          like line of r_error_list.

  clear r_error_list.
  check is_partner-xubname is not initial.

  ls_partner = is_partner.
  lv_error_header = _build_error_header( is_partner = is_partner ).

  "-------------------------------------------------------
  "--- Check for User assignment in PA0105
  "-------------------------------------------------------
  loop at it_pa0105 into ls_pa0105 where usrid = ls_partner-xubname.
    if ls_pa0105-pernr <> ls_partner-pers_nr_numc8.
      concatenate lv_error_header
                  'is assigned to a user in PA0105 via BP001-XUBNAME = ' ls_partner-xubname(12)
                  ' with PERNR = ' ls_pa0105-pernr
             into lv_error respecting blanks.               "#EC NOTEXT
      append lv_error to r_error_list.
    endif.
  endloop.

  if ls_pa0105 is initial.
    concatenate lv_error_header
                'is not assigned to a user in table PA0105 via BP001-XUBNAME = ' ls_partner-xubname
           into lv_error respecting blanks.                 "#EC NOTEXT
    append lv_error to r_error_list.
  endif.

  if r_error_list is not initial.
    return.
  endif.

  "-------------------------------------------------------
  "--- Check for HR Person/Employee to Central Person
  "-------------------------------------------------------
  loop at it_persempl_to_cp into ls_persempl_to_cp where objid = ls_pa0105-pernr.
    append ls_persempl_to_cp to lt_persempl_to_cp.
  endloop.

  if lt_persempl_to_cp is initial.
    concatenate lv_error_header
                'is not assigned to a Central Person in table HRP1001 via PA0105-PERNR'
           into lv_error respecting blanks.      "#EC NOTEXT
    append lv_error to r_error_list.
  endif.

  "-------------------------------------------------------
  "--- Check for Central Person to BP
  "-------------------------------------------------------
  loop at lt_persempl_to_cp into ls_persempl_to_cp.
    lv_numc8 = ls_persempl_to_cp-sobid.
    loop at it_cp_to_bp  into ls_cp_to_bp where objid = lv_numc8.
      if ls_cp_to_bp-sobid <> ls_partner-partner_sobid.
        concatenate lv_error_header
                    'refers to Business Partner ' ls_cp_to_bp-sobid ' in HRP1001 via CP_ID = ' ls_persempl_to_cp-sobid
               into lv_error respecting blanks.      "#EC NOTEXT
        append lv_error to r_error_list.
      endif.
    endloop.

    if ls_cp_to_bp is initial..
      concatenate lv_error_header
                  'does not refer to a Business Partner in HRP1001 via CP_ID = ' ls_persempl_to_cp-sobid
             into lv_error respecting blanks.      "#EC NOTEXT
      append lv_error to r_error_list.
    endif.

    clear ls_cp_to_bp.

  endloop.
endmethod.