  METHOD _IS_RELEASE_WITH_TP.
* check whether
* a) the transfer price messages should be shown
* b) the material ledger messages should be shown, since is the same behavior as with transfer price
*
* Important: to check if the release is a classic ERP release, use method _IS_CLASSIC_ERP_RELEASE.
* For Transfer price case at least, this would change the message type to a warning in case it is a
* ERP release.

* Where and how the transfer price message should be shown:
*   Classic ERP    W    ERP Release
*   sFIN 2.0       E    SAP_FIN 720
*   sFIN 3.0       _    SAP_FIN 730 or higher
*   S/4 HANA OP    E    S4CORE  100
*   Infinity       _    S4CORE  101 or higher

    DATA: lt_comptab TYPE TABLE OF cvers_sdu.

    rb_release_with_tp = abap_false.

    CALL METHOD _get_component_release                      "n2881239
      RECEIVING                                             "n2881239
        rt_comptab = lt_comptab.                            "n2881239

    LOOP AT lt_comptab TRANSPORTING NO FIELDS
       WHERE ( component = 'SAP_FIN'  AND release >= '730' )   "sFIN3.0 or higher; note: SAP_FIN exists already in classic ERP with rel 619
       OR    ( component = 'S4CORE'   AND release >= '101' )   "S/4HANA OnPremise higher than 100
       OR    ( component = 'SAPSCORE' AND release >= '105').                      "S/4HANA Cloud
*     This is a S/4 system (except sFIN 2.0 and S/4 HANA OP), which means, the checks are not relevant:
      rb_release_with_tp = abap_true.
      EXIT.
    ENDLOOP.

  ENDMETHOD.