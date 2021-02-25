private section.

  types:
    BEGIN OF ty_sum_log_str,
    mesg_text  TYPE  string,
    mesg_type  TYPE  symsgty,
  END OF ty_sum_log_str .
  types:
    ty_sum_log_tab TYPE TABLE OF ty_sum_log_str .

  class-data SV_DWLD_SERV_DEST type RFCDEST .
  class-data ST_NOTE_REQ_LATEST type TY_NOTE_REQ_BUF_TAB .
  class-data C_SUPPORT_DEST type RFCDEST value 'SAP-SUPPORT_PORTAL' ##NO_TEXT.
  class-data MS_LOG_MSG type BAL_S_MSG .
  class-data MS_LOG_WRITE_DB type BALNRI .
  class-data MV_LOG_HANDLE type BALLOGHNDL .
  class-data MV_LOG_LEVEL type CHAR1 .
  class-data MV_LOG_TEXT type STRING .
  class-data MV_SUM_MODE type ABAP_BOOL .
  class-data SO_EXCEPTION type ref to CX_ROOT .
  class-data SO_SUM_LOGGER type ref to OBJECT .
  class-data ST_APP_COMP type TY_SMDB_APP_COMP_TAB .
  class-data ST_CHECK type TY_SMDB_CHECK_TAB .
  class-data ST_CHECK_DB type TY_SMDB_CHECK_DB_TAB .
  class-data ST_CONV_TARGET_STACK type TY_CONV_TARGET_STACK_TAB .
  class-data ST_BW_CONV_TARGET_STACK type TY_CONV_TARGET_STACK_TAB .
  class-data ST_HEADER type TY_NAME_VALUE_PAIR_TAB .
  class-data ST_NOTE type TY_SMDB_NOTE_TAB .
  class-data ST_NOTE_STAT type TY_NOTE_STAT_TAB .
  class-data ST_PIECE_LIST type TY_PIECE_LIST_TAB .
  class-data ST_PPMS_PRODUCT type TY_PPMS_PRODUCT_TAB .
  class-data ST_PPMS_PROD_VERSION type TY_PPMS_PROD_VERSION_TAB .
  class-data ST_PPMS_STACK type TY_PPMS_STACK_TAB .
  class-data ST_RC_NOTE_REQ type TY_RC_NOTE_REQ_TAB .
  class-data ST_SITEM type TY_SMDB_ITEM_TAB .
  class-data ST_SMDB_NOTE_REQ type TY_SMDB_NOTE_REQ_TAB .
  class-data ST_SOURCE_RELEASE type TY_SMDB_SOURCE_TAB .
  class-data ST_SUM_LOG type TY_SUM_LOG_TAB .
  class-data ST_TARGET_RELEASE type TY_SMDB_TARGET_TAB .
  class-data SV_MESSAGE type STRING .
  class-data SV_SMDB_ZIP_XTR type XSTRING .
  class-data SV_SUM_PHASE type CHAR1 .
  class-data SV_TIME_UTC type TIMESTAMP .
  class-data SV_TIME_UTC_STR type STRING .
  class-data ST_UPDATED_NOTE type TY_CWBNTNUMM_TAB .
  class-data ST_USAGE_REPORT type TY_USAGE_TAB .
  class-data ST_USAGE_RFC type TY_USAGE_TAB .
  class-data ST_USAGE_TRANS type TY_USAGE_TAB .
  class-data ST_USAGE_URL type TY_USAGE_TAB .
  class-data SV_MONTH_OF_USG type I .
  class-data ST_DUMMY_HDR_TEXT type SALV_WD_T_STRING .
  class-data ST_LOB type TY_SMDB_LOB_TAB .

  class-methods APP_LOG_ADD_SINGLE_LINE
    importing
      !IV_MESG_TEXT type STRING
      !IV_MESG_TYPE type SYMSGTY
      !IV_MESG_LEVEL type BALLEVEL .
  class-methods APP_LOG_ADD_TO_SUM_LOG_FILE
    importing
      !IV_MESG_TEXT type STRING
      !IV_MESG_TYPE type SYMSGTY .
  class-methods PREPARE_APP_LOG_OBJECT .
  class-methods SMDB_CONTENT_UPLOAD_TIME_GET
    importing
      !IV_FILE_DATA type XSTRING
    returning
      value(RV_TIME_UTC) type TIMESTAMP .
  class-methods SPLIT_STRING
    importing
      value(IV_STRING) type STRING
      !IV_TEXT_LENGTH type I
    exporting
      value(EV_MSGV) type STRING
      value(EV_REST) type STRING .
  class-methods MIGRATE_DATA .