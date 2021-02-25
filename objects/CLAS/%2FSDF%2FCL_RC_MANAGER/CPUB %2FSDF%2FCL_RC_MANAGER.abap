class /SDF/CL_RC_MANAGER definition
  public
  create private .

public section.
  type-pools ABAP .

  class /SDF/CL_RC_CHK_UTILITY definition load .
  class-methods GET_INSTANCE
    importing
      !IV_TARGET_STACK type /SDF/CL_RC_CHK_UTILITY=>TY_BORMNR
    returning
      value(RO_RC_MANAGER) type ref to /SDF/CL_RC_MANAGER
    exceptions
      ERROR
      TARGET_STACK_EMPTY .
  methods GET_SITEM_4_MATCH_PRODUCT
    exporting
      value(ET_SITEM) type /SDF/CL_RC_CHK_UTILITY=>TY_SMDB_ITEM_TAB .
  methods CHECK_CLASS_BASED_RELEVANCE
    importing
      !IS_CHECK type /SDF/CL_RC_CHK_UTILITY=>TY_SMDB_CHECK_STR
    exporting
      !EV_RELEVANCE type CHAR1
      !EV_DESCRIPTION type STRING .
  methods PERFORM_CONSISTENCY_CHECK
    importing
      !IV_SUM_MODE type FLAG optional
      !IT_ALL_SITEM type /SDF/CL_RC_CHK_UTILITY=>TY_CHECK_RESULT_TAB
      !IT_CHECK_SITEM type /SDF/CL_RC_CHK_UTILITY=>TY_CHECK_RESULT_TAB
      !IV_DETAILED_CHK type FLAG optional
    exporting
      !ET_CHECK_RESULT type /SDF/CL_RC_CHK_UTILITY=>TY_CHECK_RESULT_TAB .
  methods REFRESH_CHECK_RESULT
    importing
      !IT_CHECK_RESULT type /SDF/CL_RC_CHK_UTILITY=>TY_CHECK_RESULT_TAB
    exporting
      !ET_CHECK_RESULT type /SDF/CL_RC_CHK_UTILITY=>TY_CHECK_RESULT_TAB .
  methods PERFORM_RELEVANCE_CHECK
    importing
      !IT_CHECK_SITEM type /SDF/CL_RC_CHK_UTILITY=>TY_SMDB_ITEM_TAB optional
    exporting
      !ET_RESULT type /SDF/CL_RC_CHK_UTILITY=>TY_CHECK_RESULT_TAB
      !ES_HEADER_INFO type /SDF/CL_RC_CHK_UTILITY=>TY_RELEV_CHK_HEADER_STR .