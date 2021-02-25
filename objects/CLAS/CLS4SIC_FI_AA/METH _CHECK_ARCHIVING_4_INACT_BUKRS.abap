METHOD _CHECK_ARCHIVING_4_INACT_BUKRS.
*--------------------------------------------------------------------*
* check if deactive company code data are archived completely
*--------------------------------------------------------------------*
* PRECONDITION
  "None

* DEFINITIONS
  DATA: lt_archived_deact_comp_code TYPE STANDARD TABLE OF t093r,
        lt_deact_comp_code          TYPE STANDARD TABLE OF bukrs,
        lv_msg_text                 TYPE string,
        ls_anea TYPE anea,
        ls_anek TYPE anek,
        ls_anep TYPE anep,
        ls_anlp TYPE anlp.
  FIELD-SYMBOLS: <ls_archived_deact_comp_code> TYPE t093r,
                 <ls_deact_comp_code>          TYPE bukrs.

* BODY
  SELECT bukrs FROM t093c CLIENT SPECIFIED
                INTO TABLE lt_deact_comp_code
                WHERE mandt  = mv_client
                  AND xanueb = gc_status_comp_code-deactivated. "#EC CI_BYPASS.
  IF sy-subrc <> 0.
    "no deactivated company codes exisiting
    RETURN.
  ENDIF.

  "Get last archiving run for each of the obsolete company codes
  "-> BEWARE: maybe there has never been any archiving!!!
  SELECT
      t093c~bukrs
      t093r~gjwer
      t093r~gjbuc
    FROM t093c            AS t093c
    LEFT OUTER JOIN t093r AS t093r
      ON t093c~bukrs = t093r~bukrs
     AND t093c~mandt = t093r~mandt
    CLIENT SPECIFIED
    INTO CORRESPONDING FIELDS OF TABLE lt_archived_deact_comp_code
   WHERE t093c~mandt = mv_client
     AND t093c~xanueb = gc_status_comp_code-deactivated
   ORDER BY t093c~bukrs.                               "#EC CI_BUFFJOIN

  "check if there are deactivated comp codes that are not archived
  LOOP AT lt_deact_comp_code ASSIGNING <ls_deact_comp_code>.
    READ TABLE lt_archived_deact_comp_code TRANSPORTING NO FIELDS
                                           WITH KEY bukrs = <ls_deact_comp_code>.
    IF sy-subrc <> 0.
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.
        lv_msg_text = 'One or more deactivated company codes exist. For more info, choose ''Check Consistency Details''.'.
      ELSE.
        CONCATENATE 'Company Code' <ls_archived_deact_comp_code>-bukrs  'is deactivated and only subsequent reporting is allowed.' INTO lv_msg_text.
      ENDIF.
      _add_check_message(
        iv_description = lv_msg_text
        iv_return_code = gc_check_return_code-error_skippable
        iv_check_sub_id = gc_check_sub_id-fiaa_archiving
        ).
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.EXIT.ENDIF.
    ENDIF.
  ENDLOOP.

  "check if we find any transactional data after last archiving -> not completly archived
  " With ACDOCA some tables are replaced by compatability views
  " DDL Sources use @ClientHandling.algorithm: #SESSION_VARIABLE, which does
  " not allow the usage of CLIENT SPECIFIED anymore -> usage of USING CLIENT necessary
  LOOP AT lt_archived_deact_comp_code ASSIGNING <ls_archived_deact_comp_code>.
    "Check ANEK
      SELECT SINGLE *
      FROM anek
      USING CLIENT @mv_client
      INTO @ls_anek
      WHERE bukrs = @<ls_archived_deact_comp_code>-bukrs
        AND gjahr > @<ls_archived_deact_comp_code>-gjwer.
    IF sy-subrc = 0.
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.
        lv_msg_text = 'Data of deactivated company code is not completely archived. For more info, choose ''Check Consistency Details''.'.
      ELSE.
        MESSAGE e213(acc_aa) WITH <ls_archived_deact_comp_code>-bukrs INTO lv_msg_text.
      ENDIF.
      _add_check_message(
        iv_description = lv_msg_text
        iv_return_code = gc_check_return_code-error_skippable
        iv_check_sub_id = gc_check_sub_id-fiaa_archiving
        ).
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.RETURN.ENDIF.
      CONTINUE.
    ENDIF.

    "Check ANEP
    SELECT SINGLE *
      FROM anep
     USING CLIENT @mv_client
     INTO @ls_anep
     WHERE bukrs = @<ls_archived_deact_comp_code>-bukrs
       AND gjahr > @<ls_archived_deact_comp_code>-gjwer.
    IF sy-subrc = 0.
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.
        lv_msg_text = 'Data of deactivated company code is not archived. For more info, choose ''Check Consistency Details''.'.
      ELSE.
        MESSAGE e213(acc_aa) WITH <ls_archived_deact_comp_code>-bukrs INTO lv_msg_text.
      ENDIF.
      _add_check_message(
        iv_description = lv_msg_text
        iv_return_code = gc_check_return_code-error_skippable
        iv_check_sub_id = gc_check_sub_id-fiaa_archiving
        ).
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.RETURN.ENDIF.
      CONTINUE.
    ENDIF.

    "Check ANEA
    SELECT SINGLE *
      FROM anea
     USING CLIENT @mv_client
     INTO @ls_anea
     WHERE bukrs = @<ls_archived_deact_comp_code>-bukrs
       AND gjahr > @<ls_archived_deact_comp_code>-gjwer.
    IF sy-subrc = 0.
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.
        lv_msg_text = 'Data of deactivated company code is not archived. For more info, choose ''Check Consistency Details''.'.
      ELSE.
        MESSAGE e213(acc_aa) WITH <ls_archived_deact_comp_code>-bukrs INTO lv_msg_text.
      ENDIF.
      _add_check_message(
        iv_description = lv_msg_text
        iv_return_code = gc_check_return_code-error_skippable
        iv_check_sub_id = gc_check_sub_id-fiaa_archiving
        ).
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.RETURN.ENDIF.
      CONTINUE.
    ENDIF.

    "Check ANLP
    SELECT SINGLE *
      FROM anlp
     USING CLIENT @mv_client
     INTO @ls_anlp
     WHERE bukrs = @<ls_archived_deact_comp_code>-bukrs
       AND gjahr > @<ls_archived_deact_comp_code>-gjwer.
    IF sy-subrc = 0.
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.
        lv_msg_text = 'Data of deactivated company code is not archived. For more info, choose ''Check Consistency Details''.'.
      ELSE.
        MESSAGE e213(acc_aa) WITH <ls_archived_deact_comp_code>-bukrs INTO lv_msg_text.
      ENDIF.
      _add_check_message(
        iv_description = lv_msg_text
        iv_return_code = gc_check_return_code-error_skippable
        iv_check_sub_id = gc_check_sub_id-fiaa_archiving
        ).
      IF cls4sic_fi_aa=>gb_detailed_check = abap_false.RETURN.ENDIF.
      CONTINUE.
    ENDIF.
  ENDLOOP.

* POSTCONDITION
  "None

ENDMETHOD.