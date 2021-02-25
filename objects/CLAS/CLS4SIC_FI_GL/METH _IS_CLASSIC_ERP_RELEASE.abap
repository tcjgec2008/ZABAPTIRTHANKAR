METHOD _IS_CLASSIC_ERP_RELEASE.
* check whether
* a) the current system is a classic ERP system/release or whether
* b) the system is already a sFIN or S/4HANA (OnPrem or Cloud) release

  DATA:
    lt_comptab TYPE TABLE OF cvers_sdu,
    ls_comptab LIKE LINE OF lt_comptab.

* default: this system a classic ERP system (not yet upgraded to S/4):
  gb_is_classic_erp = abap_true.

  CALL METHOD _get_component_release                        "n2881239
    RECEIVING                                               "n2881239
      rt_comptab = lt_comptab.                              "n2881239

  LOOP AT lt_comptab INTO ls_comptab
     WHERE ( component = 'SAP_FIN' AND release >= '720' )   "sFIN2.0 or higher; note: SAP_FIN exists already in classic ERP with rel 619
     OR    ( component = 'S4CORE'   )                       "S/4HANA OnPremise
     OR    ( component = 'SAPSCORE' ).                      "S/4HANA Cloud
*   this is an S/4 or SFIN system:
    IF ls_comptab-component = 'S4CORE'.
      gv_source_software = 'S4_OP'.
    ELSEIF ls_comptab-component = 'SAPSCORE' .
      gv_source_software = 'S4_CE'.
    ELSE.
      gv_source_software = 'SFIN'.
    ENDIF.

    gv_source_release = ls_comptab-release.
    gv_source_sp = ls_comptab-extrelease.

    gb_is_classic_erp = abap_false.
    EXIT.
  ENDLOOP.

  IF gb_is_classic_erp = abap_true.
    READ TABLE lt_comptab INTO ls_comptab WITH KEY component = 'SAP_APPL'.
    IF sy-subrc = 0.
      gv_source_software = 'ERP'.
      gv_source_release = ls_comptab-release.
      gv_source_sp = ls_comptab-extrelease.
    ENDIF.
  ENDIF.

ENDMETHOD.