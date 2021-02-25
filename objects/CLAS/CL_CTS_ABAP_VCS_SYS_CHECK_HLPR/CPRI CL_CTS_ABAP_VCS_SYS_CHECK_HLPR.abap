private section.

  data SYSTEM type ref to IF_CTS_ABAP_VCS_SYSTEM .

  methods CHECK_PERMISSION
    returning
      value(STATUS) type IF_CTS_ABAP_VCS_SYSTEM=>TT_SYSTEM_STATUS .
  methods CHECK_CONFIG
    returning
      value(STATUS) type IF_CTS_ABAP_VCS_SYSTEM=>TT_SYSTEM_STATUS .
  methods CHECK_DIRECTORY
    importing
      !CONFIG_VALUE type SCTS_ABAP_VCS_CONFIG_VALUE
    raising
      CX_CTS_ABAP_VCS_EXCEPTION .
  methods CHECK_REPOSITORIES
    returning
      value(STATUS) type IF_CTS_ABAP_VCS_SYSTEM=>TT_SYSTEM_STATUS .
  methods CHECK_TMS
    returning
      value(STATUS) type IF_CTS_ABAP_VCS_SYSTEM=>TT_SYSTEM_STATUS .
  methods CHECK_KERNEL
    returning
      value(STATUS) type IF_CTS_ABAP_VCS_SYSTEM=>TT_SYSTEM_STATUS .
  methods CHECK_OBSERVER
    returning
      value(STATUS) type IF_CTS_ABAP_VCS_SYSTEM=>TT_SYSTEM_STATUS .
  methods CHECK_CONNECTIVITY
    returning
      value(STATUS) type IF_CTS_ABAP_VCS_SYSTEM=>TT_SYSTEM_STATUS .
  methods CHECK_SICF
    returning
      value(STATUS) type IF_CTS_ABAP_VCS_SYSTEM=>TT_SYSTEM_STATUS .
  methods READ_FILE
    importing
      !CONFIG_VALUE type SCTS_ABAP_VCS_CONFIG_VALUE
    raising
      CX_CTS_ABAP_VCS_EXCEPTION .
  methods SAVE
    importing
      !STATUS type IF_CTS_ABAP_VCS_SYSTEM=>TT_SYSTEM_STATUS .
  methods CHECK
    returning
      value(STATUS) type IF_CTS_ABAP_VCS_SYSTEM=>TT_SYSTEM_STATUS .
  methods READ_FROM_DB
    returning
      value(STATUS) type IF_CTS_ABAP_VCS_SYSTEM=>TT_SYSTEM_STATUS .
  methods HTTP_SEND
    importing
      !URL type STRING
    returning
      value(RESPONSE) type STRING .