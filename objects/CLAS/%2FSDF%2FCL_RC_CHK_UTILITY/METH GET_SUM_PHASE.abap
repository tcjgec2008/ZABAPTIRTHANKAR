METHOD get_sum_phase.

  DATA lt_uvers             TYPE TABLE OF uvers.

  IF sv_sum_phase IS NOT INITIAL.
    rv_sum_phase = sv_sum_phase.
    RETURN.
  ENDIF.

  rv_sum_phase = c_sum_phase-unknown.
  sv_sum_phase = rv_sum_phase.

  CALL FUNCTION 'UPG_GET_UPGRADE_INFO'
    EXPORTING
      iv_component    = 'SAP_BASIS'
      iv_readmode     = 'ACT'
      iv_comp_select  = space
      iv_avers_select = space
    TABLES
      tt_upginfo      = lt_uvers
    EXCEPTIONS
      OTHERS          = 1.
  CHECK sy-subrc = 0.

  "you need to check for putstatus I or T if you want to check for the #first# SUM-phase.
  "Both values are valid when you run the #first# SUM-phase. It depends on the how often the #first# SUM-phase ran.
  "At the first time, the putstatus is set to I. In case the #first# SUM-phase is executed a second time because
  "errors had been found and corrected, the putstatus has changed to T.
  "You need to check for U if you want to check for the #second# SUM-phase.
  LOOP AT lt_uvers TRANSPORTING NO FIELDS WHERE putstatus = 'T' OR putstatus = 'I'.
    rv_sum_phase = c_sum_phase-first.
    sv_sum_phase = rv_sum_phase.
    RETURN.
  ENDLOOP.

  READ TABLE lt_uvers TRANSPORTING NO FIELDS
    WITH KEY putstatus = 'U'.
  IF sy-subrc = 0.
    rv_sum_phase = c_sum_phase-second.
    sv_sum_phase = rv_sum_phase.
    RETURN.
  ENDIF.

ENDMETHOD.