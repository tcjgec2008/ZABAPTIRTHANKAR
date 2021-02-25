method check_bp_category_person.

  data:
    lv_error_header      type string,
    lv_bp_type_text      type c length 12,

    lt_error_list        type salv_wd_t_string,
    lv_error_description like line of lt_error_list.

  field-symbols:
    <partner>   type ty_partner_data.

  clear r_chk_results.

*---------------------------------------------------------------------
*--- Check Business Partner type is Person
*---------------------------------------------------------------------
  loop at partner_data assigning <partner>.

    case <partner>-type.
      when '1'. "Person
        continue.
      when '2'.
        lv_bp_type_text = 'Organization'.                        "#EC NOTEXT
      when '3'.
        lv_bp_type_text = 'Group'.                               "#EC NOTEXT
      when others.
        lv_bp_type_text = '<unknown>'.                           "#EC NOTEXT
    endcase.

    lv_error_header = _build_error_header( is_partner = <partner> ).

    concatenate lv_error_header
                'with category ' lv_bp_type_text(12) ' is not a person'
           into lv_error_description respecting blanks.     "#EC NOTEXT

    append lv_error_description to lt_error_list.
    clear lv_error_description.

    delete partner_data where partner = <partner>-partner.
  endloop.

*---------------------------------------------------------------------
*--- Return result list
*---------------------------------------------------------------------
  r_chk_results = _build_error_list(
                    i_check_sub_id = 'FS-BP / BP001 / 2 / Partner category is not Person' "#EC NOTEXT
                    i_error_list   = lt_error_list ).

endmethod.