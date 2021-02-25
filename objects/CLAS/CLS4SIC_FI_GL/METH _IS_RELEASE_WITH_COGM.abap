  METHOD _IS_RELEASE_WITH_COGM.
*   check whether the parallel COGM messages should be shown
*   COGM is available from S/4HANA OnPrem 1610 SP1.

* Where and how the COGM message should be shown:
*   Classic ERP    W    ERP Release
*   sFIN 2.0       E    SAP_FIN 720
*   sFIN 3.0       E    SAP_FIN 730 or higher
*   S/4 HANA OP    E    S4CORE  100
*   S/4 HANA OP    _    S4CORE  101 or higher

    DATA: lt_comptab TYPE TABLE OF cvers_sdu.

    rb_release_with_cogm = abap_false.

    CALL METHOD _get_component_release                      "n2881239
      RECEIVING                                             "n2881239
        rt_comptab = lt_comptab.                            "n2881239

    LOOP AT lt_comptab TRANSPORTING NO FIELDS
       WHERE ( component = 'S4CORE'   AND release >= '101' )   "S/4HANA OnPremise higher than 101
       OR    ( component = 'SAPSCORE' AND release >= '106').   "S/4HANA Cloud
*     This is a S/4 system which means, the check is not relevant:
      rb_release_with_cogm = abap_true.
      EXIT.
    ENDLOOP.
  ENDMETHOD.