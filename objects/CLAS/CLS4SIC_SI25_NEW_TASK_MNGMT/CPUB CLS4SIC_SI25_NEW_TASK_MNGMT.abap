class CLS4SIC_SI25_NEW_TASK_MNGMT definition
  public
  final
  create protected .

public section.

  types TY_RETURN_CODE type I .
  types:
    BEGIN OF ty_pre_cons_chk_result_str,
        return_code  TYPE ty_return_code,
        descriptions TYPE salv_wd_t_string, "table of string
        check_sub_id TYPE c LENGTH 80,     "ID for different checks for same SI
      END OF ty_pre_cons_chk_result_str .
  types:
    ty_pre_cons_chk_result_tab TYPE STANDARD TABLE OF ty_pre_cons_chk_result_str .
  types:
    ty_t685a_tab TYPE TABLE OF t685a .
  types:
    ty_cpec_applsetting_tab TYPE TABLE OF cpec_applsetting .
  types:
    BEGIN OF ty_gs_s4sic_param,
        name  TYPE char64,
        value TYPE char64,
      END OF ty_gs_s4sic_param .

  constants GC_S4SIC_PARAM_TABLE_NAME type TABNAME value 'S4SIC_PARAM' ##NO_TEXT.
  constants GC_S4SIC_PARAM_COL_NAME type TABNAME value 'NAME' ##NO_TEXT.
  constants GC_TM_CHECK_WFF_RESTART_MANUAL type CHAR64 value 'S4SIC_TASK_MGMT_CHECK_WFF_RESTART_MANUAL' ##NO_TEXT.
  constants:
    BEGIN OF c_pre_chk_relevance,
        yes     TYPE char1 VALUE 'Y',   "Relevant    "#NO_TEXT
        no      TYPE char1 VALUE 'N',   "Irrelevant  "#NO_TEXT
        unknown TYPE char1 VALUE space, "Unknown     "#NO_TEXT
      END OF c_pre_chk_relevance .
  constants:
    BEGIN OF c_cons_chk_return_code,
        success         TYPE ty_return_code VALUE 0, "Success, everything is good
        warning         TYPE ty_return_code VALUE 4, "Warning, SUM continues, used for important things to tell the customer but no inconsistency
        error_skippable TYPE ty_return_code VALUE 7, "Error if not exempted, Warning once exempted. Warnings must be confirmed by customer(e.g. data loss) but are no inconsistency
        error           TYPE ty_return_code VALUE 8, "Error: SUM will stop in the second SIC-Check phase, Inconsistency - easy to solve
        abortion        TYPE ty_return_code VALUE 12, "Error: SUM will stop immediately, Inconsistency # complete blocker for conversion or hard to solve
      END OF c_cons_chk_return_code .
  constants:
    BEGIN OF c_pre_chk_param_key,
        "Values read from Transition DB
        sitem_guid          TYPE string VALUE 'SITEM_GUID',         "/SPN/SMDB_SITEM->GUID
        sitem_id            TYPE string VALUE 'SITEM_ID',           "/SPN/SMDB_SITEM->TEXT_ID
        sitem_title         TYPE string VALUE 'SITEM_TITLE',        "/SPN/SMDB_SITEM->GUID
        sitem_app_area      TYPE string VALUE 'SITEM_APP_AREA',     "/SPN/SMDB_SITEM->TEXT_AREA

        "Values specified through conversion target product version and stack
        target_swc          TYPE string VALUE 'TARGET_SWC',          "Software Component; e.g. S4CORE for S/4HANA 1610
        target_swc_version  TYPE string VALUE 'TARGET_SWC_VERSION',  "Software Component version; e.g. 101 for S/4HANA 1610
        target_support_pack TYPE string VALUE 'TARGET_SUPPORT_PACK', "Support Package level; e.g. 0001 for for S/4HANA 1610 SP01
        detailed_check      TYPE string VALUE 'DETAILED_CHECK',      "Whether to perform detailed check; values 'X' or space
      END OF c_pre_chk_param_key .
  constants:
    BEGIN OF c_migration_run_mode,
        manual    TYPE char1 VALUE 'M',   "Manual run mode    "#NO_TEXT
        automatic TYPE char1 VALUE 'A',   "Automatic run mode  "#NO_TEXT
      END OF c_migration_run_mode .

  class-methods CHECK_CONSISTENCY
    importing
      !IT_PARAMETER type TIHTTPNVP
    exporting
      !ET_CHK_RESULT type TY_PRE_CONS_CHK_RESULT_TAB .
  class-methods GET_PARAMETER_VALUES
    importing
      !IT_PARAMETER type TIHTTPNVP
    exporting
      !EV_SITEM_GUID type STRING
      !EV_SWC type STRING
      !EV_SWC_VERSION type STRING
      !EV_SWC_SP_LVL type STRING
      !EV_DETAILED_CHECK type ABAP_BOOL .