class /SDF/CL_RC_SIMPLE_CHK_DB definition
  public
  inheriting from /SDF/CL_RC_SIMPLE_CHK
  final
  create public .

public section.

  class /SDF/CL_RC_CHK_UTILITY definition load .
  methods CONSTRUCTOR
    importing
      !IS_CHECK type /SDF/CL_RC_CHK_UTILITY=>TY_SMDB_CHECK_STR .

  methods PERFORM_CHECK
    redefinition .