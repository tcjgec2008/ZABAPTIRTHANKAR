*******************************************************************
*   THIS FILE IS GENERATED BY THE FUNCTION LIBRARY               **
*   NEVER CHANGE IT MANUALLY, PLEASE!                            **
*******************************************************************
FORM /SDF/GEN_FUNCS_S4_REL_CHK_JOB %_RFC.
* Parameter declaration
DATA IV_TARGET_STACK TYPE
CHAR20
.
DATA IV_NO_CONS_CHECK TYPE
FLAG
.
* Assign default values
* Call remote function
  CALL FUNCTION '/SDF/GEN_FUNCS_S4_REL_CHK_JOB' %_RFC
     EXPORTING
       IV_TARGET_STACK = IV_TARGET_STACK
       IV_NO_CONS_CHECK = IV_NO_CONS_CHECK
  .
ENDFORM.