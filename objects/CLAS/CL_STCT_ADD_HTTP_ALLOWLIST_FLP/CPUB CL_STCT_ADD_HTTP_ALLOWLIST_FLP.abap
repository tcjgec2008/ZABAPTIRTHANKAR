class CL_STCT_ADD_HTTP_ALLOWLIST_FLP definition
  public
  inheriting from CL_STCTM_REPORT_UI
  final
  create public .

public section.

  interfaces IF_STCTM_BG_TASK .

  methods CONSTRUCTOR .

  methods IF_STCTM_TASK~GET_DESCRIPTION
    redefinition .
  methods IF_STCTM_TASK~GET_DOCU_OBJECT
    redefinition .
  methods IF_STCTM_TASK~IS_NECESSARY
    redefinition .
  methods IF_STCTM_UI_TASK~MAINTAINED
    redefinition .