private section.

  methods PREPARE_CHECK_4_EMPTY
    importing
      !IV_WHERE_CLAUSE type /SDF/CL_RC_CHK_UTILITY=>TY_WHERE_CLAUSE_LINE
    returning
      value(RV_WHERE_CLAUSE) type /SDF/CL_RC_CHK_UTILITY=>TY_WHERE_CLAUSE_LINE .
  methods CLEANUP_STRING
    importing
      !IV_FIELD_VALUE type CHAR100
    returning
      value(RV_FIELD_VALUE) type /SDF/CL_RC_CHK_UTILITY=>TY_WHERE_CLAUSE_LINE .