class /SDF/CL_RC_S4SIC_SAMPLE definition
  public
  final
  create public .

public section.

  types TY_RETURN_CODE type I .

  constants:
    BEGIN OF c_pre_chk_relevance,
            yes      TYPE char1 VALUE 'Y',   "Relevant    "#NO_TEXT
            no       TYPE char1 VALUE 'N',   "Irrelevant  "#NO_TEXT
            unknown  TYPE char1 VALUE space, "Unknown     "#NO_TEXT
            error    TYPE char1 VALUE 'E',   "Error       "#NO_TEXT
          END OF c_pre_chk_relevance .
  constants:
    BEGIN OF c_cons_chk_return_code,
              success          TYPE ty_return_code VALUE 0, "Success, everything is good
              warning          TYPE ty_return_code VALUE 4, "Warning, SUM continues, used for important things to tell the customer but no inconsistency
              error_skippable  TYPE ty_return_code VALUE 7, "Error if not exempted, Warning once exempted. Warnings must be confirmed by the customer(e.g. data loss) but are no inconsistency
              error            TYPE ty_return_code VALUE 8, "Error: SUM will stop in the second SIC-Check phase, Inconsistency - easy to solve
              abortion         TYPE ty_return_code VALUE 12,"Error: SUM will stop immediately, Inconsistency # complete blocker for conversion or hard to solve
              END OF c_cons_chk_return_code .
  constants:
    BEGIN OF c_pre_chk_param_key,
            "Values read from Transition DB
            sitem_guid          TYPE string VALUE 'SITEM_GUID',         "/SPN/SMDB_SITEM->GUID
            sitem_id            TYPE string VALUE 'SITEM_ID',           "/SPN/SMDB_SITEM->TEXT_ID
            sitem_title         TYPE string VALUE 'SITEM_TITLE',        "/SPN/SMDB_SITEM->GUID
            sitem_app_area      TYPE string VALUE 'SITEM_APP_AREA',     "/SPN/SMDB_SITEM->TEXT_AREA
            "sitem_check_id     TYPE string VALUE 'SITEM_CHECK_ID',     "/SPN/SMDB_CHK->CHECK_IDENTIFIER
            "sitem_check_subid  TYPE string VALUE 'SITEM_CHECK_SUBID',  "/SPN/SMDB_CHK->CHECK_SUB_IDENTIFIER
            "software_component TYPE string VALUE 'SOFTWARE_COMPONENT', "Installed SW can be read from table CVERS
            "Values specified through conversion target product version and stack
            "PPMS ID not provided to eliminate necessity to handle PPMS information
            "Target target Software Component (e.g. S4CORE 101 SP01) based on mapping defined in Transition DB
            "target_prd_version  TYPE string VALUE 'TARGET_PRD_VERSION',  "Product Version (PPMS ID); e.g. 73555000100900000627 for S/4HANA 1610
            "target_stack        TYPE string VALUE 'TARGET_STACK',        "SP stack (PPMS ID); e.g. 73554900103300002258 for S/4HANA 1610 SP01
            target_swc          TYPE string VALUE 'TARGET_SWC',          "Software Component; e.g. S4CORE for S/4HANA 1610
            target_swc_version  TYPE string VALUE 'TARGET_SWC_VERSION',  "Software Component version; e.g. 101 for S/4HANA 1610
            target_support_pack TYPE string VALUE 'TARGET_SUPPORT_PACK', "Support Package level; e.g. 0001 for for S/4HANA 1610 SP01
            detailed_check      TYPE string VALUE 'DETAILED_CHECK',      "Whether to perform detailed check; values 'X' or space
          END OF c_pre_chk_param_key .
  constants:
    BEGIN OF c_ppms,
              "Product Version
              s4hana_prd_ver_1511    TYPE char20 VALUE '73554900100900000398', "SAP S/4HANA, on-premise 1511
              s4hana_prd_ver_1610    TYPE char20 VALUE '73555000100900000627', "SAP S/4HANA, on-premise 1610
              s4hana_prd_ver_1709    TYPE char20 VALUE '73555000100900001152', "SAP S/4HANA, on-premise 1709
              "Stack
              s4hana_stack_1511_sp00 TYPE char20 VALUE '73554900103300000642', "SAP S/4HANA 1511 - Initial Shipment Stack
              s4hana_stack_1511_sp01 TYPE char20 VALUE '73555000103300001066', "SAP S/4HANA 1511 - FP stack 01
              s4hana_stack_1511_sp02 TYPE char20 VALUE '73555000103300001483', "SAP S/4HANA 1511 - FP stack 02
              s4hana_stack_1511_sp03 TYPE char20 VALUE '73555000103300001803', "SAP S/4HANA 1511 - SP stack 03
              s4hana_stack_1511_sp04 TYPE char20 VALUE '73555000103300002199', "SAP S/4HANA 1511 - SP stack 04
              s4hana_stack_1610_sp00 TYPE char20 VALUE '73555000103300001270', "SAP S/4HANA 1610 - Initial Shipment Stack
              s4hana_stack_1610_sp01 TYPE char20 VALUE '73554900103300002258', "SAP S/4HANA 1610 - Feature Package Stack 01
              s4hana_stack_1610_sp02 TYPE char20 VALUE '73555000103300001952', "SAP S/4HANA 1610 - Feature Package Stack 02
              s4hana_stack_1610_sp03 TYPE char20 VALUE '73555000103300001953', "SAP S/4HANA 1610 - Support Package Stack 03
              s4hana_stack_1709_sp00 TYPE char20 VALUE '73554900103300002096', "SAP S/4HANA 1610 - Initial Shipment Stack
          END OF c_ppms .

  class /SDF/CL_RC_CHK_UTILITY definition load .
  class-methods CHECK_CONSISTENCY
    importing
      !IT_PARAMETER type TIHTTPNVP
    exporting
      !ET_CHK_RESULT type /SDF/CL_RC_CHK_UTILITY=>TY_PRE_CONS_CHK_RESULT_TAB .
  class-methods CHECK_RELEVANCE
    importing
      !IT_PARAMETER type TIHTTPNVP
    exporting
      !EV_RELEVANCE type CHAR1
      !EV_DESCRIPTION type STRING .