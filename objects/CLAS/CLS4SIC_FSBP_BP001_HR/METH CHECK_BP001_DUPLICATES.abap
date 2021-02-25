method check_bp001_duplicates.

  data:
    lt_error_list        type salv_wd_t_string,
    lv_error_description like line of lt_error_list.

  field-symbols:
    <partner>   type ty_partner_data.

  clear r_chk_results.

*---------------------------------------------------------------------
*--- Check for duplicates in BP001 with same XUBNAME and/or PERS_NR
*---------------------------------------------------------------------
  loop at partner_data assigning <partner>.

    "-----------------------------------------------------------------
    "--- Check for multiple entries in BP001 with same XUBNAME
    "-----------------------------------------------------------------
    if <partner>-xubname is not initial.
      loop at partner_data transporting no fields
        where xubname = <partner>-xubname and partner <> <partner>-partner .

        concatenate 'BP001-XUBNAME = ' <partner>-xubname(12)
                    ' is not exclusively assigned to Business Partner ' <partner>-partner
               into lv_error_description respecting blanks. "#EC NOTEXT

        append lv_error_description to lt_error_list.
        clear lv_error_description.
      endloop.
    endif.

    "-----------------------------------------------------------------
    "--- Check for multiple entries in BP001 with same PERS_NR
    "-----------------------------------------------------------------
    if <partner>-pers_nr is not initial.
      loop at partner_data transporting no fields
        where pers_nr = <partner>-pers_nr and partner <> <partner>-partner.

        concatenate 'BP001-PERS_NR = ' <partner>-pers_nr(15)
                    ' is not exclusively assigned to Business Partner ' <partner>-partner
               into lv_error_description respecting blanks. "#EC NOTEXT

        append lv_error_description to lt_error_list.
        clear lv_error_description.
      endloop.
    endif.
  endloop.

  sort lt_error_list.
  delete adjacent duplicates from lt_error_list.
*---------------------------------------------------------------------
*--- Return result list
*---------------------------------------------------------------------
  r_chk_results = _build_error_list(
                    i_check_sub_id = 'FS-BP / BP001 / 5 / Duplicate XUBNAME/PERS_NR entries in BP001' "#EC NOTEXT
                    i_error_list   = lt_error_list ).

endmethod.