*******************************************************************
*   THIS FILE IS GENERATED BY THE FUNCTION LIBRARY.               *
*   NEVER CHANGE IT MANUALLY, PLEASE!                             *
*******************************************************************
INCLUDE /SDF/LGEN_FUNCSV07 .

FUNCTION $$UNIT$$ /SDF/GEN_FUNCS_S4_RELEVAN_CHK

    IMPORTING
       VALUE(IV_TEST_API) TYPE !FLAG OPTIONAL
       VALUE(IV_CONV_TARGET_STACK) TYPE !CHAR20
       VALUE(IV_RESULT_EXPIRE_DAY) TYPE !I DEFAULT 10
    EXPORTING
       VALUE(EV_ERR_MESG) TYPE !STRING
       VALUE(EV_RESULT_XSTR) TYPE !XSTRING
       VALUE(EV_CONSIS_XSTR) TYPE !XSTRING .