class CL_CTS_ABAP_VCS_SYS_CHECK_HLPR definition
  public
  final
  create public .

public section.

  constants CO_TRUE type STRING value 'true' ##NO_TEXT.
  constants CO_FALSE type STRING value 'false' ##NO_TEXT.
  constants CO_SUCCESS type STRING value 'success' ##NO_TEXT.
  constants CO_WARNING type STRING value 'warning' ##NO_TEXT.
  constants CO_ERROR type STRING value 'error' ##NO_TEXT.
  constants CO_CAT_PERMISSION type STRING value 'permission' ##NO_TEXT.
  constants CO_CAT_TMS type STRING value 'tms' ##NO_TEXT.
  constants CO_CAT_GCTS type STRING value 'gcts' ##NO_TEXT.
  constants CO_CAT_KERNEL type STRING value 'kernel' ##NO_TEXT.
  constants CO_CAT_CONFIG type STRING value 'config' ##NO_TEXT.
  constants CO_CAT_REPOSITORY type STRING value 'repository' ##NO_TEXT.
  constants CO_CAT_CONNECTIVITY type STRING value 'connectivity' ##NO_TEXT.
  constants CO_CAT_SICF type STRING value 'sicf' ##NO_TEXT.
  constants CO_KERNEL_JAVA type SCTS_ABAP_VCS_CONFIG_VALUE value 'java' ##NO_TEXT.
  constants CO_KERNEL_CLIENT type SCTS_ABAP_VCS_CONFIG_VALUE value 'client' ##NO_TEXT.
  constants CO_CONFIG_JAVA type SCTS_ABAP_VCS_CONFIG_VALUE value 'java_path' ##NO_TEXT.
  constants CO_CONFIG_PATH type SCTS_ABAP_VCS_CONFIG_VALUE value 'gcts_path' ##NO_TEXT.
  constants CO_CONFIG_PATH_VALUE type SCTS_ABAP_VCS_CONFIG_VALUE value 'gcts' ##NO_TEXT.
  constants CO_CONFIG_CLIENT type SCTS_ABAP_VCS_CONFIG_VALUE value 'client_path' ##NO_TEXT.
  constants CO_TMS_DOMAIN_CTL type SCTS_ABAP_VCS_CONFIG_VALUE value 'domain_ctl' ##NO_TEXT.
  constants CO_GCTS_OBSERVER type SCTS_ABAP_VCS_CONFIG_VALUE value 'observer' ##NO_TEXT.
  constants CO_GCTS_REPOSITORY type SCTS_ABAP_VCS_CONFIG_VALUE value 'repository' ##NO_TEXT.
  constants CO_PERMISSION_TP type SCTS_ABAP_VCS_CONFIG_VALUE value 'tp' ##NO_TEXT.
  constants CO_PERMISSION_GCTS type SCTS_ABAP_VCS_CONFIG_VALUE value 'gcts' ##NO_TEXT.
  constants CO_PERMISSION_DATASET type SCTS_ABAP_VCS_CONFIG_VALUE value 'dataset' ##NO_TEXT.
  constants CO_PERMISSION_CTS type SCTS_ABAP_VCS_CONFIG_VALUE value 'cts' ##NO_TEXT.
  constants CO_PERMISSION_LCMD type SCTS_ABAP_VCS_CONFIG_VALUE value 'lcmd' ##NO_TEXT.
  constants CO_CONNECITIVITY_ABAP_GIT type SCTS_ABAP_VCS_CONFIG_VALUE value 'abap_github' ##NO_TEXT.
  constants CO_CONNECITIVITY_ABAP_SAP type SCTS_ABAP_VCS_CONFIG_VALUE value 'abap_sap' ##NO_TEXT.
  constants CO_CONNECITIVITY_JAVA_GIT type SCTS_ABAP_VCS_CONFIG_VALUE value 'java_github' ##NO_TEXT.
  constants CO_CONNECITIVITY_JAVA_SAP type SCTS_ABAP_VCS_CONFIG_VALUE value 'java_sap' ##NO_TEXT.
  constants CO_SICF_REST type SCTS_ABAP_VCS_CONFIG_VALUE value 'sicf_rest' ##NO_TEXT.
  constants CO_SICF_ODATA type SCTS_ABAP_VCS_CONFIG_VALUE value 'sicf_odata' ##NO_TEXT.
  constants CO_SICF_FIORI type SCTS_ABAP_VCS_CONFIG_VALUE value 'sicf_fiori' ##NO_TEXT.

  methods CONSTRUCTOR
    importing
      !SYSTEM type ref to IF_CTS_ABAP_VCS_SYSTEM .
  methods GET_STATUS
    importing
      !RELOAD type BOOLEAN
    returning
      value(STATUS) type IF_CTS_ABAP_VCS_SYSTEM=>TT_SYSTEM_STATUS .