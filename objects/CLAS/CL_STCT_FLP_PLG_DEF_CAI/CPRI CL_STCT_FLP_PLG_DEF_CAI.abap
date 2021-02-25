private section.

  methods CONFIG_FLP_PLUGIN
    importing
      !I_PLUGIN_ID type CHAR30
      !I_PLUGIN_COMPONENT type CHAR255
      !I_PLUGIN_DESCR type CHAR140
      !I_PLUGIN_URL type CHAR1024
      !I_REQUEST_WORK type CHAR20
      !I_OVERWRITE type ABAP_BOOL
    exporting
      !E_WARNING type ABAP_BOOL
      !E_ERROR type ABAP_BOOL .
  methods CHECK_FLP_PLUGIN
    importing
      !I_PLUGIN_ID type CHAR30
      !I_PLUGIN_DESCR type CHAR140
      !I_PLUGIN_URL type CHAR1024
      !I_PLUGIN_COMPONENT type CHAR255
    exporting
      !E_RC type I .