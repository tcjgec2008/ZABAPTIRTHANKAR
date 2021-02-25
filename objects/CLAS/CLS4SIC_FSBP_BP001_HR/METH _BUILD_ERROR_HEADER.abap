method _build_error_header.

  check is_partner is not initial.

    "concatenate 'Business Partner ' is_partner-partner(10) ' with BUT000-PARTNER_GUID = ' is_partner-guid_text(32)
    concatenate 'Business Partner ' is_partner-partner(10)
                ', BP001-XUBNAME = ' is_partner-xubname_text(12)
                ', BP001-PERS_NR = ' is_partner-pers_nr_text(15) ' '
           into r_error_header respecting blanks.

endmethod.