protected section.

  class-data MV_MESG_STR type STRING .
  data MS_CHECK type /SDF/CL_RC_CHK_UTILITY=>TY_SMDB_CHECK_STR .
  class-data MV_DUMMY_STR type STRING .
  data MV_CHECK_MESG_STR type STRING .
  data MV_CHECK_COUNT_OPTION_STR type STRING .

  methods COMPARE_VALUE
    importing
      !IV_ACTUAL_COUNT type I
      !IV_OBJECT_CHECKED type STRING
    exporting
      !EV_RESULT_INT type CHAR30
      !EV_SUMMARY_INT type STRING .
  methods GET_TABLE_SELECT_UP_TO_ROWS
    returning
      value(RV_UP_TO_ROWS) type I .