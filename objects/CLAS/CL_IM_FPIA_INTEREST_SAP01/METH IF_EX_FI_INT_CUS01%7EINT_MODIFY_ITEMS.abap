method IF_EX_FI_INT_CUS01~INT_MODIFY_ITEMS.
*{   REPLACE        S4UK901423                                        1
*\  RETURN.


IF sy-uname EQ 'GNIGRO' OR sy-uname EQ 'RLEONE'.

     DATA(lt_items) = ct_items[].

     DELETE lt_items
     WHERE augbl IS NOT INITIAL.

      IF lt_items[] IS NOT INITIAL.
       SELECT bukrs,belnr,gjahr,buzei,rebzg,valut
         FROM bseg
         INTO TABLE @DATA(lt_parziali)
         FOR ALL ENTRIES IN @lt_items
         WHERE bukrs EQ @lt_items-bukrs
         AND   belnr EQ @lt_items-belnr.
      ENDIF.

    LOOP AT ct_items
      ASSIGNING FIELD-SYMBOL(<lfs_items>)
      WHERE augbl IS INITIAL.

          READ TABLE lt_parziali
          TRANSPORTING NO FIELDS
          with KEY rebzg = <lfs_items>-belnr.
          IF sy-subrc IS INITIAL.
            <lfs_items>-int_end = <lfs_items>-int_begin.
            <lfs_items>-int_days = 0.
            <lfs_items>-int_amount = 0.
          ELSE.
            <lfs_items>-int_amount = ABS( <lfs_items>-int_amount ).
          ENDIF.
    ENDLOOP.

ENDIF.

*}   REPLACE
*  DATA: ls_log TYPE LINE OF fint_tt_log,
*        ls_item TYPE LINE OF fint_tt_intit_extf,
*        lt_log TYPE fint_tt_log,
*        lt_item TYPE fint_tt_intit_extf.
*
*  IF cl_fpia_ioa_ex_switch_check=>filocfr_sfws_cs_02( )
*    IS NOT INITIAL.
*
*    lt_log[] = ct_log[].
*    lt_item[] = ct_items[].
*    CLEAR: ct_log, ct_items.
*
*    LOOP AT lt_item INTO ls_item.
*      IF NOT ls_item-int_end IS INITIAL.
*        ls_item-int_end = ls_item-augdt.
*      ENDIF.
*      APPEND ls_item TO ct_items.
*    ENDLOOP.
*
*    LOOP AT lt_log INTO ls_log.
*      IF NOT ls_log-int_end IS INITIAL.
*        CLEAR ls_item.
*        READ TABLE ct_items WITH KEY belnr = ls_log-belnr
*                                    gjahr = ls_log-gjahr
*                                     buzei = ls_log-buzei
*                            INTO ls_item.
*        IF sy-subrc = 0.
*          ls_log-int_end = ls_item-augdt.
*        ENDIF.
*      ENDIF.
*      IF ls_log-msgno = '252'.
*      ELSE.
*        IF ls_log-msgno = '321'.
*          CLEAR: ls_item, ls_log-ltext.
*          READ TABLE ct_items WITH KEY belnr = ls_log-belnr
*                                      gjahr = ls_log-gjahr
*                                       buzei = ls_log-buzei
*                              INTO ls_item.
*          MESSAGE ID 'FPIA' TYPE 'I' NUMBER '321'
*                   INTO ls_log-ltext WITH ls_item-int_rate ls_item-int_begin.
*        ENDIF.
*        APPEND ls_log TO ct_log.
*      ENDIF.
*    ENDLOOP.
*  ENDIF.
endmethod.