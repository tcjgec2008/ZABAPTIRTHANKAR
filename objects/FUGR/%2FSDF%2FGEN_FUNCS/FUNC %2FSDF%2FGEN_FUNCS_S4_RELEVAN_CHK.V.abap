*******************************************************************
*   THIS FILE IS GENERATED BY THE FUNCTION LIBRARY               **
*   NEVER CHANGE IT MANUALLY, PLEASE!                            **
*******************************************************************
FORM /SDF/GEN_FUNCS_S4_RELEVAN_CHK %_RFC.
* Parameter declaration
DATA IV_TEST_API TYPE
FLAG
.
DATA IV_CONV_TARGET_STACK TYPE
CHAR20
.
DATA IV_RESULT_EXPIRE_DAY TYPE
I
.
DATA EV_ERR_MESG TYPE
STRING
.
DATA EV_RESULT_XSTR TYPE
XSTRING
.
DATA EV_CONSIS_XSTR TYPE
XSTRING
.
* Assign default values
  IV_RESULT_EXPIRE_DAY = 10 .
* Call remote function
  CALL FUNCTION '/SDF/GEN_FUNCS_S4_RELEVAN_CHK' %_RFC
     EXPORTING
       IV_TEST_API = IV_TEST_API
       IV_CONV_TARGET_STACK = IV_CONV_TARGET_STACK
       IV_RESULT_EXPIRE_DAY = IV_RESULT_EXPIRE_DAY
     IMPORTING
       EV_ERR_MESG = EV_ERR_MESG
       EV_RESULT_XSTR = EV_RESULT_XSTR
       EV_CONSIS_XSTR = EV_CONSIS_XSTR
  .
ENDFORM.