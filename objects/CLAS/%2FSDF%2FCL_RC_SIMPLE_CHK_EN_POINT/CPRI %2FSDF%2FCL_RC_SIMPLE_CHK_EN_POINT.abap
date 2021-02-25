private section.

  class-data ST_USAGE_REPORT type /SDF/CL_RC_CHK_UTILITY=>TY_USAGE_TAB .
  class-data ST_USAGE_RFC type /SDF/CL_RC_CHK_UTILITY=>TY_USAGE_TAB .
  class-data ST_USAGE_TRANS type /SDF/CL_RC_CHK_UTILITY=>TY_USAGE_TAB .
  class-data ST_USAGE_URL type /SDF/CL_RC_CHK_UTILITY=>TY_USAGE_TAB .
  class-data SV_USAGE_MESSAGE type STRING .
  class-data SV_NUM_OF_MONTH_GOT type I .
  class-data SV_NUM_OF_USAGE_DATA type I .
  class-data SV_NUM_OF_MONTH_GOT_STR type STRING .
  class-data SV_NUM_OF_USAGE_DATA_STR type STRING .

  class-methods ADD_MONTH_TO_DATE
    importing
      !IV_MONTH_COUNT type DATA default -1
      !IV_OLD_DATE like SY-DATUM
    returning
      value(RV_NEW_DATE) like SY-DATUM .