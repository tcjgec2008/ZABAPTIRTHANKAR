class CL_STCT_SET_SYSALIAS_CLASSICUI definition
  public
  inheriting from CL_STCTM_REPORT_UI
  final
  create public .

public section.

  interfaces IF_STCTM_BG_TASK .

  class-data MV_INITIAL type ABAP_BOOL value ABAP_TRUE ##NO_TEXT.

  methods CONSTRUCTOR .
  methods GET_SYSTEM_HOST_PORT
    exporting
      !EV_HOST_HTTPS type STRING
      !EV_PORT_HTTPS type STRING .

  methods IF_STCTM_TASK~GET_DESCRIPTION
    redefinition .
  methods IF_STCTM_TASK~GET_DOCU_OBJECT
    redefinition .
  methods IF_STCTM_UI_TASK~MAINTAINED
    redefinition .