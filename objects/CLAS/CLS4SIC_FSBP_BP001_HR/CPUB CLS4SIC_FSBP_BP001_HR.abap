class CLS4SIC_FSBP_BP001_HR definition
  public
  create public .

public section.

  types TY_RETURN_CODE type I .
  types:
    begin of ty_pre_cons_chk_result_str,
        return_code  type ty_return_code,
        descriptions type salv_wd_t_string, "table of string
        check_sub_id type c length 80,     "ID for different checks for same SI
      end of ty_pre_cons_chk_result_str .
  types:
    ty_pre_cons_chk_result_tab type standard table of ty_pre_cons_chk_result_str.

  types:
    ty_pre_cons_chk_result_tab_int type standard table of ty_pre_cons_chk_result_str with non-unique key return_code .

  constants:
    begin of c_pre_chk_relevance,
        yes     type char1 value 'Y',   "Relevant    "#NO_TEXT
        no      type char1 value 'N',   "Irrelevant  "#NO_TEXT
        unknown type char1 value space, "Unknown     "#NO_TEXT
      end of c_pre_chk_relevance .
  constants:
    begin of c_cons_chk_return_code,
        success         type ty_return_code value 0, "Success, everything is good
        warning         type ty_return_code value 4, "Warning, SUM continues, used for important things to tell the customer but no inconsistency
        error_skippable type ty_return_code value 7, "Error if not exempted, Warning once exempted. Warnings must be confirmed by customer(e.g. data loss) but are no inconsistency
        error           type ty_return_code value 8, "Error: SUM will stop in the second SIC-Check phase, Inconsistency - easy to solve
        abortion        type ty_return_code value 12, "Error: SUM will stop immediately, Inconsistency # complete blocker for conversion or hard to solve
      end of c_cons_chk_return_code .

  class-methods CHECK_RELEVANCE
    importing
      !IT_PARAMETER type TIHTTPNVP
    exporting
      !EV_RELEVANCE type CHAR1
      !EV_DESCRIPTION type STRING .
  class-methods CHECK_CONSISTENCY
    importing
      !IT_PARAMETER type TIHTTPNVP
    exporting
      !ET_CHK_RESULT type TY_PRE_CONS_CHK_RESULT_TAB .