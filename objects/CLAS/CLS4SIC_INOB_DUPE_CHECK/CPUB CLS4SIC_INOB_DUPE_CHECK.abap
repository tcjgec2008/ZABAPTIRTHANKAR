class CLS4SIC_INOB_DUPE_CHECK definition
  public
  final
  create public .

public section.

  types TY_RETURN_CODE type I .
  types:
    begin of ty_pre_cons_chk_result_str,
      return_code   type ty_return_code,
      descriptions  type salv_wd_t_string,"table of string
      check_sub_id  type c length 80,     "ID for different checks for same SI
    end of ty_pre_cons_chk_result_str .
  types:
    ty_pre_cons_chk_result_tab type standard table of ty_pre_cons_chk_result_str .
  types:
    begin of ty_duplicate_id,
      mandt type mandt,
      klart type klassenart,
      obtab type tabelle,
      objek type cuobn,
    end of ty_duplicate_id .
  types:
    ty_duplicates type standard table of ty_duplicate_id .

  constants:
    begin of c_pre_chk_relevance,
      yes      type char1 value 'Y',   "Relevant    "#NO_TEXT
      no       type char1 value 'N',   "Irrelevant  "#NO_TEXT
      unknown  type char1 value space, "Unknown     "#NO_TEXT
    end of c_pre_chk_relevance .
  constants:
    begin of c_cons_chk_return_code,
        success          type ty_return_code value 0, "Success, everything is good
        warning          type ty_return_code value 4, "Warning, SUM continues, used for important things to tell the customer but no inconsistency
        error_skippable  type ty_return_code value 7, "Error if not exempted, Warning once exempted. Warnings must be confirmed by customer(e.g. data loss) but are no inconsistency
        error            type ty_return_code value 8, "Error: SUM will stop in the second SIC-Check phase, Inconsistency - easy to solve
        abortion         type ty_return_code value 12,"Error: SUM will stop immediately, Inconsistency # complete blocker for conversion or hard to solve
    end of c_cons_chk_return_code .
  constants:
    begin of c_pre_chk_param_key,
      "Values read from Transition DB
      sitem_guid           type string value 'SITEM_GUID',         "/SPN/SMDB_SITEM->GUID
      sitem_id            type string value 'SITEM_ID',           "/SPN/SMDB_SITEM->TEXT_ID
      sitem_title         type string value 'SITEM_TITLE',        "/SPN/SMDB_SITEM->GUID
      sitem_app_area      type string value 'SITEM_APP_AREA',     "/SPN/SMDB_SITEM->TEXT_AREA

      "Values specified through conversion target product version and stack
      target_swc          type string value 'TARGET_SWC',          "Software Component; e.g. S4CORE for S/4HANA 1610
      target_swc_version  type string value 'TARGET_SWC_VERSION',  "Software Component version; e.g. 101 for S/4HANA 1610
      target_support_pack type string value 'TARGET_SUPPORT_PACK', "Support Package level; e.g. 0001 for for S/4HANA 1610 SP01
      detailed_check      type string value 'DETAILED_CHECK',      "Whether to perform detailed check; values 'X' or space
    end of c_pre_chk_param_key .
  constants C_INOB_DUPE_CHK_SUB_ID type STRING value 'CHK_INOB_DUPE' ##NO_TEXT.

  class-methods CLASS_CONSTRUCTOR .
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