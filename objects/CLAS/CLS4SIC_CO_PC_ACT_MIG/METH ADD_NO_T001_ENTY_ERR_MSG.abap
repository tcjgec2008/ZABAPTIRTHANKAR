method ADD_NO_T001_ENTY_ERR_MSG.

 DATA:    ls_no_t001_entry_err  TYPE  ty_t001_fields,
          ls_check_result       TYPE ty_pre_cons_check_result,
          lv_table_name         TYPE tabname,
          lv_message            TYPE string,
          lv_is_furth_mess_exist TYPE boole_d.

    ls_check_result-return_code =  cs_return_code-error_skippable.
    ls_check_result-check_sub_id    = 'NO_T001_ENTRY_SKIPPABLE_ERROR'.

    SORT mt_no_t001_entry_err BY mandt bukrs.
    DELETE ADJACENT DUPLICATES FROM mt_no_t001_entry_err COMPARING mandt bukrs.

    LOOP AT mt_no_t001_entry_err INTO ls_no_t001_entry_err.

*Limit number of messages, if detailed check is not selected
      IF sy-tabix > mv_description_size AND
         mv_is_detailed_check = abap_false.

        lv_is_furth_mess_exist = abap_true.
        EXIT.

      ENDIF.

      CONCATENATE 'No T001-entry for MANDT:' ls_no_t001_entry_err-mandt 'BUKRS:' ls_no_t001_entry_err-bukrs 'BWKEY:' ls_no_t001_entry_err-bwkey
      INTO lv_message SEPARATED BY space.                   "#EC NOTEXT

      INSERT lv_message INTO TABLE ls_check_result-descriptions.

    ENDLOOP.

    SORT ls_check_result-descriptions.
    DELETE ADJACENT DUPLICATES FROM ls_check_result-descriptions.

    IF lv_is_furth_mess_exist = abap_true.
      lv_message = mc_further_messages.
      APPEND lv_message TO ls_check_result-descriptions.
    ENDIF.

    IF ls_check_result-descriptions IS NOT INITIAL.
      APPEND ls_check_result TO mt_pre_check_messages.
    ENDIF.

    CLEAR mt_no_t001_entry_err.




endmethod.