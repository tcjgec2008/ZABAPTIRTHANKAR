method _initialize.

  clear:
    partner_data.

  data:
    lv_initial_xubname type bu_xubname,
    lv_initial_n8      type n length 8,
    lv_initial_persnr  type bp_pers_nr.

  field-symbols:
    <partner_data>     type ty_partner_data.

  check i_client is not initial.

*--------------------------------------------------------------------------------
*--- Fetch partner data from BP001 with XUBNAME and/or PERS_NR not initial
*--------------------------------------------------------------------------------
  select a~partner, a~partner, b~partner_guid, ' ', b~type, a~pers_nr, '<initial>', @lv_initial_n8 , a~xubname, '<initial>'
    from bp001 as a
    left outer join but000 as b on a~partner = b~partner using client @i_client
    where a~xubname <> @lv_initial_xubname or a~pers_nr <> @lv_initial_persnr
    into table @partner_data.

*-----------------------------
*--- Fill text fields
*-----------------------------
  loop at partner_data assigning <partner_data>.
    if <partner_data>-pers_nr is not initial.
      <partner_data>-pers_nr_text  = <partner_data>-pers_nr.
      <partner_data>-pers_nr_numc8 = <partner_data>-pers_nr.
    endif.
    if <partner_data>-xubname is not initial.
      <partner_data>-xubname_text = <partner_data>-xubname.
    endif.
    if <partner_data>-guid is not initial.
      <partner_data>-guid_text = <partner_data>-guid.
    endif.
  endloop.


endmethod.