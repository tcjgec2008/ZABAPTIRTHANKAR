class /SDF/CL_RC_SIMPLE_CHK definition
  public
  abstract
  create public .

public section.
  type-pools ABAP .

  class /SDF/CL_RC_CHK_UTILITY definition load .
  class-methods GET_INSTANCE
    importing
      !IS_CHECK type /SDF/CL_RC_CHK_UTILITY=>TY_SMDB_CHECK_STR
    returning
      value(RO_CHECK) type ref to /SDF/CL_RC_SIMPLE_CHK .
  methods PERFORM_CHECK
    exporting
      value(EV_RESULT_INT) type CHAR30
      value(EV_SUMMARY_INT) type STRING
      value(EV_SQL_STR_INT) type STRING .
  methods CONSTRUCTOR
    importing
      !IS_CHECK type /SDF/CL_RC_CHK_UTILITY=>TY_SMDB_CHECK_STR .