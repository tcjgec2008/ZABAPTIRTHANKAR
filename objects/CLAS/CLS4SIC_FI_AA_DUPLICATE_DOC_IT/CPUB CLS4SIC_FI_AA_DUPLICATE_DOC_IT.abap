class CLS4SIC_FI_AA_DUPLICATE_DOC_IT definition
  public
  final
  create public .

public section.

  types TY_RETURN_CODE type I .
  types:
    BEGIN OF ty_pre_cons_chk_result_str,
        return_code  TYPE ty_return_code,
        descriptions TYPE salv_wd_t_string, "table of string
        check_sub_id TYPE c LENGTH 80,     "ID for different checks for same SI
      END OF ty_pre_cons_chk_result_str .
  types:
    ty_pre_cons_chk_result_tab TYPE STANDARD TABLE OF ty_pre_cons_chk_result_str WITH DEFAULT KEY .

  class-methods CHECK_CONSISTENCY
    importing
      !IT_PARAMETER type TIHTTPNVP
    exporting
      !ET_CHK_RESULT type TY_PRE_CONS_CHK_RESULT_TAB .
  class-methods CHECK_RELEVANCE
    importing
      !IT_PARAMETER type TIHTTPNVP
    exporting
      !EV_RELEVANCE type CHAR1
      !EV_DESCRIPTION type STRING .
  methods CONSTRUCTOR
    importing
      !IV_CHECK_CLIENT type MANDT .