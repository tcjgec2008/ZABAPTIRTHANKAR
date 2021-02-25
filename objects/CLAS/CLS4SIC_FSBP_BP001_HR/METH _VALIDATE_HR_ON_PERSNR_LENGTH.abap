method _validate_hr_on_persnr_length.

  data:
    ls_partner          type ty_partner_data,
    lv_bp001_persnr_len type i,
    lv_text             type c length 2,
    lv_error_header     type string.

  clear e_error_description.
  check is_partner-pers_nr is not initial.

  ls_partner = is_partner.
  lv_error_header = _build_error_header( is_partner = is_partner ).

  "--------------------------------------------------------------------------
  "--- BP001-PERS_NR must be numeric for HR compatibility
  "--------------------------------------------------------------------------
  if ls_partner-pers_nr cn '0123456789 '.
    concatenate lv_error_header
                ' the PERS_NR = ' ls_partner-pers_nr ' is not numeric -> HR only supports numerics'
           into e_error_description respecting blanks.      "#EC NOTEXT
    return.
  endif.

 "--------------------------------------------------------------------------
  "--- Validation maximum length 8 of BP001-PERS_NR for HR compatibility
  "--------------------------------------------------------------------------
  lv_bp001_persnr_len = strlen( ls_partner-pers_nr ).

  if lv_bp001_persnr_len > 8.
    lv_text = lv_bp001_persnr_len.
    concatenate lv_error_header
                ' with PERS_NR length = ' lv_text(2) ' -> HR only supports length 8 at maximum'
           into e_error_description respecting blanks.      "#EC NOTEXT
    return.
  endif.
endmethod.