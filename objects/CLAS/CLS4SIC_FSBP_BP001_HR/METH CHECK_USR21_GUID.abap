method check_usr21_guid.

  data:
    lv_initial_bname     type xubname,
    lt_usr21             type table of usr21,
    ls_usr21             type usr21,
    lv_hr_guid_string    type c length 32,

    lt_error_list        type salv_wd_t_string,
    lv_error_description like line of lt_error_list.

  field-symbols:
    <partner>     type ty_partner_data.

  clear r_chk_results.
  check i_client is not initial.

*-------------------------------------------------------------------------------------
*--- Fetch all entries from USR21 for found BP001-XUBNAME and IDADTYPEs 00,02,04
*-------------------------------------------------------------------------------------
  if partner_data is not initial.
    select * from usr21 as a  using client @i_client
      for all entries in @partner_data
        where a~bname <> @lv_initial_bname
          and a~bname  = @partner_data-xubname
      into table @lt_usr21.

    sort lt_usr21 by bname.
  endif.

*-------------------------------------------------------------------------------------
*--- Check for GUID consistency between USR21-BPPERSON and BUT000-PARTNER-GUID
*-------------------------------------------------------------------------------------
  loop at partner_data assigning <partner> where xubname is not initial.
    clear: ls_usr21, lv_error_description.

    loop at lt_usr21 into ls_usr21 where bname = <partner>-xubname.
      case ls_usr21-idadtype.
        when '00'.
          "--------------------------------------------------------------------------------------------------------
          "--- For USR21-IDADTYPE = 00 ("User's Old Type 3 Address"), USR21-BPPERSON must be initial (no GUID)
          "--------------------------------------------------------------------------------------------------------
          if ls_usr21-bpperson is not initial.
            lv_hr_guid_string = ls_usr21-bpperson.
            concatenate 'Business Partner ' <partner>-partner(10) ' with BP001-XUBAME = ' <partner>-xubname(12)
                        ' is assigned to an entry with old type 3 address in USR21 (IDADTYPE = 00) via USR21-BNAME'
                        ' and USR21-BPPERSON is not initial (' lv_hr_guid_string(32) ')'
                   into lv_error_description respecting blanks. "#EC NOTEXT
            append lv_error_description to lt_error_list.
          endif.

        when '01'.
          "--------------------------------------------------------------------------------------------------------
          "--- USR21-IDADTYPE must not be 01 ("Technical User")
          "--------------------------------------------------------------------------------------------------------
          concatenate 'Business Partner ' <partner>-partner(10) ' with BP001-XUBAME = ' <partner>-xubname(12)
                      ' is assigned to a technical user in table USR21 (IDADTYPE = 01) via USR21-BNAME'
                 into lv_error_description respecting blanks. "#EC NOTEXT
          append lv_error_description to lt_error_list.

        when '03'.
          "--------------------------------------------------------------------------------------------------------
          "--- USR21-IDADTYPE must not be 03 ("Identity with BP Person, BP Organization and Type 3 Address")
          "--------------------------------------------------------------------------------------------------------
          concatenate 'Business Partner ' <partner>-partner(10) ' with BP001-XUBAME = ' <partner>-xubname(12)
                      ' is assigned to an entry in USR21 with IDADTYPE = 03 via USR21-BNAME'
                 into lv_error_description respecting blanks. "#EC NOTEXT
          append lv_error_description to lt_error_list.

        when '02' or '04'.
          "--------------------------------------------------------------------------------------------------------
          "--- GUID in USR21-BPPERSON must not be initial
          "--------------------------------------------------------------------------------------------------------
          if ls_usr21-bpperson is initial.
            concatenate 'Business Partner ' <partner>-partner(10) ' with BP001-XUBAME = ' <partner>-xubname(12)
                        ' is assigned to a USR21 entry with IDADTYPE = ' ls_usr21-idadtype(2) ' via USR21-BNAME'
                        ' but USR21-BPPERSON is initial'
                    into lv_error_description respecting blanks. "#EC NOTEXT
            append lv_error_description to lt_error_list.

            "--------------------------------------------------------------------------------------------------------
            "--- GUID in USR21-BPPERSON must be equal to BUT000-PARTNER_GUID
            "--------------------------------------------------------------------------------------------------------
          elseif ls_usr21-bpperson <> <partner>-guid.
            lv_hr_guid_string = ls_usr21-bpperson.
            concatenate 'Business Partner ' <partner>-partner(10) ' with BP001-XUBAME = ' <partner>-xubname(12)
                        ' is assigned to a USR21 entry with IDADTYPE = ' ls_usr21-idadtype(2) ' via USR21-BNAME'
                        ' but USR21-BPPERSON (' lv_hr_guid_string ') is not equal to BUT000-PARTNER_GUID (' <partner>-guid_text(32) ')'
                    into lv_error_description respecting blanks. "#EC NOTEXT
            append lv_error_description to lt_error_list.
          endif.

        when others.
          assert 1 = 2.
      endcase.
    endloop.
  endloop.

*-------------------------------------------------------------------------------------
*--- Return result list
*-------------------------------------------------------------------------------------
  r_chk_results = _build_error_list(
                    i_check_sub_id = 'FS-BP / BP001 / 4 / GUID inconsistencies between USR21 and BUT000' "#EC NOTEXT
                    i_error_list   = lt_error_list ).

endmethod.