private section.

  types:
    ty_check_sub_id TYPE c LENGTH 80 .
  types:
    BEGIN OF ty_s_faat_doc_it_analyze,
      icon                 TYPE aa_icon,
      flg_auto_corr        TYPE abap_bool,
      flg_man_corr         TYPE abap_bool,
      flg_corr_done        TYPE abap_bool,
      flg_ident_attibutes  TYPE abap_bool,
      flg_afa_amount       TYPE abap_bool,
      flg_diff_group_asset TYPE abap_bool,
      count_multiple       TYPE int8,
    END OF ty_s_faat_doc_it_analyze .
  types:
    BEGIN OF ty_s_faat_doc_it_err.
      INCLUDE TYPE ty_s_faat_doc_it_analyze.
      INCLUDE TYPE faat_doc_it.
TYPES END OF ty_s_faat_doc_it_err .
  types:
    ty_t_faat_doc_it_err TYPE TABLE OF ty_s_faat_doc_it_err .

  constants:
    BEGIN OF gc_check_sub_id,
      fiaa_no_issues        TYPE ty_check_sub_id VALUE 'FI_AA_NO_ISSUES',
      fiaa_duplicate_doc_it TYPE ty_check_sub_id VALUE 'FI_AA_CHECK_DUPLICATE_DOC_IT',
    END OF gc_check_sub_id .
  constants:
    BEGIN OF gc_return_code,
      success         TYPE ty_return_code VALUE 0,
      warning         TYPE ty_return_code VALUE 4,
      error           TYPE ty_return_code VALUE 8,
      error_skippable TYPE ty_return_code VALUE 7, "Error if not exempted, Warning once exempted. Warnings must be confirmed by customer(e.g. data loss) but are no inconsistency
      abortion        TYPE ty_return_code VALUE 12,
    END   OF gc_return_code .
  constants:
    BEGIN OF gc_pre_chk_param_key,
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
    END OF gc_pre_chk_param_key .
  class-data GB_DETAILED_CHECK type ABAP_BOOL .
  data MT_CHECK_RESULTS type TY_PRE_CONS_CHK_RESULT_TAB .
  data MV_CLIENT type MANDT .

  class-methods _DO_CHECKS
    returning
      value(RT_CHECK_RESULTS) type TY_PRE_CONS_CHK_RESULT_TAB .
  class-methods _GET_CLIENTS_TO_BE_CHECKED
    exporting
      !ET_T000 type T000_TAB .
  methods _ADD_CHECK_MESSAGE
    importing
      !IV_DESCRIPTION type STRING
      !IV_RETURN_CODE type TY_RETURN_CODE default GC_RETURN_CODE-ERROR
      !IV_CHECK_SUB_ID type TY_CHECK_SUB_ID .
  methods _CHECK_FOR_DUPLICATE_IN_DOC_IT .
  methods _DO_CHECKS_IN_CLIENT
    returning
      value(RT_CHECK_RESULTS) type TY_PRE_CONS_CHK_RESULT_TAB .