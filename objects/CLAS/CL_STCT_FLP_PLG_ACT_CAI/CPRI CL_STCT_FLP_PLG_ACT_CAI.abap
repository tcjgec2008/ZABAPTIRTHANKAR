private section.

  methods ACTIVATE_FLP_PLUGIN_SYS
    importing
      !I_PLUGIN_ID type CHAR30
      !I_ACT_STATE type CHAR8
      !I_REQUEST_WORK type CHAR20
      !I_OVERWRITE type ABAP_BOOL
    exporting
      !E_WARNING type ABAP_BOOL
      !E_ERROR type ABAP_BOOL .
  methods CHECK_FLP_PLUGIN_SYS
    importing
      !I_PLUGIN_ID type CHAR30
      !I_ACT_STATE type CHAR8
    exporting
      !E_RC type I .
  methods ACTIVATE_FLP_PLUGIN_CUS
    importing
      !I_PLUGIN_ID type CHAR30
      !I_ACT_STATE type CHAR8
      !I_REQUEST_CUST type CHAR20
      !I_OVERWRITE type ABAP_BOOL
    exporting
      !E_WARNING type ABAP_BOOL
      !E_ERROR type ABAP_BOOL .
  methods CHECK_FLP_PLUGIN_CUS
    importing
      !I_PLUGIN_ID type CHAR30
      !I_ACT_STATE type CHAR8
    exporting
      !E_RC type I .