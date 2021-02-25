method check_bp001_but000_consistency.

  data:
    lv_initial_guid      type bu_partner_guid,
    lv_error_header      type string,
    lt_error_list        type salv_wd_t_string,
    lv_error_description like line of lt_error_list.

  field-symbols:
    <partner>            type ty_partner_data.

  clear r_chk_results.

*---------------------------------------------------------------------
*--- Check for orphaned BP001 entries.
*---------------------------------------------------------------------
  loop at partner_data assigning <partner> where guid = lv_initial_guid.
    lv_error_header = _build_error_header( is_partner = <partner> ).

    concatenate lv_error_header 'has no entry in header table BUT000'
       into lv_error_description respecting blanks.         "#EC NOTEXT

    append lv_error_description to lt_error_list.
    delete partner_data where partner = <partner>-partner.
  endloop.

*---------------------------------------------------------------------
*--- Return result list
*---------------------------------------------------------------------
  r_chk_results = _build_error_list(
                    i_check_sub_id = 'FS-BP / BP001 / 1 / Missing entries in BUT000' "#EC NOTEXT
                    i_error_list   = lt_error_list ).

endmethod.