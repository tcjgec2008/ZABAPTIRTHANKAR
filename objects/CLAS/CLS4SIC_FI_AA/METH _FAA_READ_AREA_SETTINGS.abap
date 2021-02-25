METHOD _faa_read_area_settings.
*--------------------------------------------------------------------*
*  get information about the depreciation areas of the
*   chart of depreciation that is assigned to a company code
*--------------------------------------------------------------------*
* PRECONDITION
  REFRESH et_areasettings.

* DEFINITIONS
  DATA: ls_t093c                TYPE t093c,
        ls_t093b                TYPE t093b,
        ls_area                 TYPE ty_s_areasettings,
        lt_areasettings         TYPE ty_t_areasettings,
        lb_found_bertyp_postnbv TYPE boole_d,
        lv_area                 TYPE afaber,
        lv_cnt_postnbv_x        TYPE int1,
        lv_cnt_postnbv_space    TYPE int1,
        lv_msg_text             TYPE string.

  FIELD-SYMBOLS: <ls_area>     TYPE t093,
                 <ls_area_to>  TYPE t093a,
                 <ls_area_cc>  TYPE t093b,
                 <ls_area_map> TYPE t093_map_acc,
                 <ls_area_set> TYPE ty_s_areasettings,
                 <ls_area_tmp> TYPE ty_s_areasettings.

  CONSTANTS: lc_bertyp_postnbv  TYPE bertyp VALUE '21'.


* BODY
  READ TABLE mt_t093c INTO ls_t093c WITH KEY bukrs = iv_comp_code.

*   is there at least one area with bertyp = 21 (~ french retirement)?
  LOOP AT mt_t093a TRANSPORTING NO FIELDS
       WHERE afapl = ls_t093c-afapl
         AND bertyp = lc_bertyp_postnbv.
    lb_found_bertyp_postnbv = abap_true.
    EXIT.
  ENDLOOP.

*   Fill output table
  LOOP AT mt_t093 ASSIGNING <ls_area>
                   WHERE afapl = ls_t093c-afapl.
    CLEAR ls_area.
    ls_area-orgunit    = ls_t093c-bukrs.
    ls_area-chart      = ls_t093c-afapl.
    ls_area-area       = <ls_area>-afaber.
    ls_area-definition = <ls_area>.
    IF NOT <ls_area>-xstore IS INITIAL.
      READ TABLE mt_t093a ASSIGNING <ls_area_to>
                          WITH KEY afapl = ls_t093c-afapl
                                   afabe = <ls_area>-afaber.
      ls_area-takeover = <ls_area_to>.
      IF ls_t093c-kzrbwb = abap_true AND
         ( <ls_area_to>-bertyp = lc_bertyp_postnbv
           OR lb_found_bertyp_postnbv = abap_false ).
        ls_area-postnbv = abap_true.
      ENDIF.
      READ TABLE mt_t093b ASSIGNING <ls_area_cc>
                        WITH KEY bukrs = ls_t093c-bukrs
                                 afabe = <ls_area>-afaber
                                 BINARY SEARCH.
      IF sy-subrc = 0.
        ls_area-company = <ls_area_cc>.
      ENDIF.

    ELSE.
      IF ls_t093c-kzrbwb = abap_true AND
         lb_found_bertyp_postnbv = abap_false.
        ls_area-postnbv = abap_true.
      ENDIF.
*     Determine currency for derived area from source areas
      CLEAR ls_t093b.
      LOOP AT mt_t093b ASSIGNING <ls_area_cc>
       WHERE bukrs = ls_t093c-bukrs
       AND ( afabe = <ls_area>-afabe1 OR
             afabe = <ls_area>-afabe2 OR
             afabe = <ls_area>-afabe3 OR
             afabe = <ls_area>-afabe4 ).
*         Check curency customizing (all source areas
*         must be defined in the same way)
        IF ls_t093b-afabe IS NOT INITIAL AND
           ls_t093b-waers <> <ls_area_cc>-waers.
          MESSAGE e028(acc_aa) WITH ls_t093c-afapl <ls_area>-afaber
            INTO lv_msg_text.
          _add_check_message(
             EXPORTING
               iv_description = lv_msg_text
               iv_check_sub_id = gc_check_sub_id-fiaa_cust_deprarea_currency
            ).
          RETURN.
        ENDIF.
        ls_t093b = <ls_area_cc>.
      ENDLOOP.
*       Create virtual table entries for derived area
      IF sy-subrc = 0.
        READ TABLE mt_t093b ASSIGNING <ls_area_cc>
                            WITH KEY bukrs = ls_t093c-bukrs
                                     afabe = <ls_area>-afabe1
                                     BINARY SEARCH.
*         T093B virtual entry
        IF sy-subrc = 0.
          ls_area-company = <ls_area_cc>.
          ls_area-company-afabe = <ls_area>-afaber.
        ENDIF.
        READ TABLE mt_t093a ASSIGNING <ls_area_to>
                            WITH KEY afapl = ls_t093c-afapl
                                     afabe = <ls_area>-afabe1
                            BINARY SEARCH.
*         T093A virtual entry
        IF sy-subrc = 0.
          ls_area-takeover       = <ls_area_to>.
          ls_area-takeover-afabe = <ls_area>-afaber.
        ENDIF.
      ENDIF.
    ENDIF.

    APPEND ls_area TO lt_areasettings.
  ENDLOOP.

  SORT lt_areasettings BY orgunit area.

  LOOP AT lt_areasettings ASSIGNING <ls_area_set>
                          WHERE orgunit = iv_comp_code.
    IF ls_t093c-kzrbwb         = abap_true AND
       lb_found_bertyp_postnbv = abap_true.
*       real parallel areas
      IF <ls_area_set>-definition-buhbkt = gc_buhbkt-no AND
         <ls_area_set>-definition-xstore = abap_true      AND
         <ls_area_set>-takeover-curtp IS NOT INITIAL.
        READ TABLE lt_areasettings ASSIGNING <ls_area_tmp>
                                   WITH KEY orgunit = iv_comp_code
                                            area = <ls_area_set>-takeover-wrtafb.
        IF sy-subrc = 0.
          <ls_area_set>-postnbv = <ls_area_tmp>-postnbv.
        ENDIF.
      ENDIF.
*       virtual areas (including parallel ones)
      IF <ls_area_set>-definition-xstore = abap_false.
        CLEAR: lv_cnt_postnbv_x, lv_cnt_postnbv_space.
        DO 4 TIMES VARYING lv_area
           FROM <ls_area_set>-definition-afabe1
           NEXT <ls_area_set>-definition-afabe2.
          IF lv_area IS INITIAL. EXIT. ENDIF.
          READ TABLE lt_areasettings ASSIGNING <ls_area_tmp>
             WITH KEY orgunit = iv_comp_code
                      area    = lv_area.
          CHECK sy-subrc = 0.
          IF <ls_area_tmp>-postnbv = abap_true.
            ADD 1 TO lv_cnt_postnbv_x.
          ELSE.
            ADD 1 TO lv_cnt_postnbv_space.
          ENDIF.
        ENDDO.
        IF lv_cnt_postnbv_x GT 0 AND lv_cnt_postnbv_space EQ 0.
          <ls_area_set>-postnbv = abap_true.
        ENDIF.
      ENDIF.
    ENDIF.
    APPEND <ls_area_set> TO et_areasettings.
  ENDLOOP.

* Check old advanced mapping customizing and FlexGL settings
* Map old customizing into new structures if possible
  LOOP AT et_areasettings ASSIGNING <ls_area_set>.
*     take over potential mapping changes to static area table
    READ TABLE lt_areasettings ASSIGNING <ls_area_tmp>
                               WITH KEY orgunit = <ls_area_set>-orgunit
                                        area    = <ls_area_set>-area
                                        BINARY SEARCH.
*     Mapping area in chart of depreciation is set but differs from old custo
    IF NOT <ls_area_set>-definition-abwber IS INITIAL AND
       NOT <ls_area_set>-mapping-abwber    IS INITIAL AND
           <ls_area_set>-definition-abwber <> <ls_area_set>-mapping-abwber.
      MESSAGE e043(acc_aa) WITH <ls_area_set>-area <ls_area_set>-chart
                               <ls_area_set>-orgunit INTO lv_msg_text.
      _add_check_message(
          EXPORTING
            iv_description = lv_msg_text
            iv_check_sub_id = gc_check_sub_id-fiaa_cust_deprarea
        ).
      RETURN.
    ENDIF.
    IF <ls_area_set>-definition-abwber IS INITIAL AND
       NOT  <ls_area_set>-mapping-abwber IS INITIAL.
      <ls_area_set>-definition-abwber = <ls_area_set>-mapping-abwber.
      <ls_area_tmp>-definition-abwber = <ls_area_set>-mapping-abwber.
    ENDIF.


*     Derived area posts in real mode but unreal old custo
    IF NOT <ls_area_set>-definition-xafaber IS INITIAL AND
           <ls_area_set>-mapping-xafaber    IS INITIAL AND
           NOT <ls_area_set>-mapping-bukrs  IS INITIAL.
      MESSAGE e043(acc_aa) WITH <ls_area_set>-area <ls_area_set>-chart
                               <ls_area_set>-orgunit INTO lv_msg_text.
      _add_check_message(
          EXPORTING
            iv_description = lv_msg_text
            iv_check_sub_id = gc_check_sub_id-fiaa_cust_deprarea
        ).
      RETURN.
    ENDIF.
    IF <ls_area_set>-definition-xafaber IS INITIAL AND
       NOT <ls_area_set>-mapping-xafaber IS INITIAL.
      <ls_area_set>-definition-xafaber = <ls_area_set>-mapping-xafaber.
      <ls_area_tmp>-definition-xafaber = <ls_area_set>-mapping-xafaber.
    ENDIF.


*     Ledger group assigned but special ledger assigned in old custo
    IF NOT <ls_area_set>-definition-ldgrp_gl IS INITIAL AND
       NOT <ls_area_set>-mapping-acc_principle IS INITIAL.
      MESSAGE e043(acc_aa) WITH <ls_area_set>-area <ls_area_set>-chart
                               <ls_area_set>-orgunit INTO lv_msg_text.
      _add_check_message(
          EXPORTING
            iv_description = lv_msg_text
            iv_check_sub_id = gc_check_sub_id-fiaa_cust_deprarea
        ).
      RETURN.
    ENDIF.


*     Direct posting indicator
    IF NOT <ls_area_set>-mapping-xdirekt IS INITIAL AND
            <ls_area_set>-definition-buhbkt = gc_buhbkt-per.
      <ls_area_set>-definition-buhbkt = gc_buhbkt-dir.
      <ls_area_tmp>-definition-buhbkt = gc_buhbkt-dir.
    ENDIF.
*     Check posting indicator vs. direct posting indicator
    IF NOT <ls_area_set>-mapping-xdirekt IS INITIAL    AND (
      <ls_area_set>-definition-buhbkt = gc_buhbkt-no  OR
      <ls_area_set>-definition-buhbkt = gc_buhbkt-dep ).
      MESSAGE e043(acc_aa) WITH <ls_area_set>-area <ls_area_set>-chart
                               <ls_area_set>-orgunit INTO lv_msg_text.
      _add_check_message(
          EXPORTING
            iv_description = lv_msg_text
            iv_check_sub_id = gc_check_sub_id-fiaa_cust_deprarea
        ).
      RETURN.
    ENDIF.

  ENDLOOP.
* POSTCONDITION
  " None

ENDMETHOD.