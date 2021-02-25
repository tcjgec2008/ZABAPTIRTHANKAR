  METHOD IF_STCTM_TASK~SHOW_MESSAGE_DETAILS.

    DATA: lt_role TYPE TABLE OF string.
    DATA: ls_role TYPE string.

    DATA: rspar_tab  TYPE TABLE OF rsparams,
          rspar_line LIKE LINE OF rspar_tab.

    " get data
    SPLIT i_details AT ';' INTO TABLE lt_role.

    LOOP AT lt_role INTO ls_role.

      rspar_line-selname = 'SEL_SHT'.
      rspar_line-sign    = 'I'.
      rspar_line-option  = 'EQ'.
      rspar_line-low     = ls_role.
      APPEND rspar_line TO rspar_tab.

    ENDLOOP.

    " start supc
    SUBMIT sapprofc_new

      WITH prt_gen = ''
      WITH prt_pfl = ''
      WITH prt_ber = ''
      WITH prt_all = 'X'
      WITH prt_akt = ''

      WITH SELECTION-TABLE rspar_tab

    AND RETURN.

  ENDMETHOD.