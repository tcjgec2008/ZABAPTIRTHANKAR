method _validate_hr_on_partnerid.

  data:
    ls_partner        type ty_partner_data,
    lt_bp_to_cp       type table of hrp1001,
    ls_bp_to_cp       type hrp1001,
    ls_cp_to_persempl type hrp1001,
    lt_cp_to_persempl type table of hrp1001,
    ls_pa0105         type pa0105,

    lv_numc8          type n length 8,
    lv_error_header   type string,
    lv_error          like line of r_error_list.

  clear r_error_list.

  ls_partner = is_partner.
  lv_error_header = _build_error_header( is_partner = is_partner ).


  "-------------------------------------------------------
  "--- Check for BP to Central Person
  "-------------------------------------------------------
  loop at it_bp_to_cp into ls_bp_to_cp where sobid = ls_partner-partner_sobid.
    append ls_bp_to_cp to lt_bp_to_cp.
  endloop.

  if lt_bp_to_cp is initial.
    concatenate lv_error_header
                'is not assigned to a Central Person in table HRP1001 via PARTNER_ID'
           into lv_error respecting blanks.      "#EC NOTEXT
    append lv_error to r_error_list.
    return.
  endif.

  "-------------------------------------------------------
  "--- Check for Central Person to HR Person/Employee
  "-------------------------------------------------------
  loop at lt_bp_to_cp into ls_bp_to_cp.
    loop at it_cp_to_persempl into ls_cp_to_persempl where objid = ls_bp_to_cp-objid.
      if ls_cp_to_persempl-sobid <> ls_partner-pers_nr_numc8.
        concatenate lv_error_header
                    'is assigned to an HR Person/Employee in HRP1001 via CP_ID = ' ls_bp_to_cp-objid(8)
                    ' with PERNR = ' ls_cp_to_persempl-sobid(15)
               into lv_error respecting blanks.      "#EC NOTEXT
        append lv_error to r_error_list.
      endif.
      append ls_cp_to_persempl to lt_cp_to_persempl.
    endloop.

    if ls_cp_to_persempl is initial.
      concatenate lv_error_header
                  'is not assigned to an HR Person/Employee in HRP1001 via CP_ID = ' ls_bp_to_cp-objid(8)
             into lv_error respecting blanks.      "#EC NOTEXT
      append lv_error to r_error_list.
    endif.

    clear ls_cp_to_persempl.
  endloop.

  "-------------------------------------------------------
  "--- Check for User assignment in PA0105
  "-------------------------------------------------------
  loop at lt_cp_to_persempl into ls_cp_to_persempl.
    lv_numc8  = ls_cp_to_persempl-sobid.
    loop at it_pa0105 into ls_pa0105 where pernr = lv_numc8.
      if ls_pa0105-usrid <> ls_partner-xubname.
        concatenate lv_error_header
                    'is assigned to an user in PA0105 via PERNR = ' ls_cp_to_persempl-sobid(8)
                    ' with USRID = ' ls_pa0105-usrid(30)
               into lv_error respecting blanks.      "#EC NOTEXT
        append lv_error to r_error_list.
      endif.
    endloop.

    if ls_pa0105 is initial.
      concatenate lv_error_header
                  'is not assigned to an user in table PA0105 via PERNR = ' ls_cp_to_persempl-sobid(8)
             into lv_error respecting blanks.      "#EC NOTEXT
      append lv_error to r_error_list.
    endif.

    clear ls_pa0105.
  endloop.
endmethod.