*******************************************************************
*   THIS FILE IS GENERATED BY THE FUNCTION LIBRARY.               *
*   NEVER CHANGE IT MANUALLY, PLEASE!                             *
*******************************************************************
INCLUDE /SDF/LGEN_FUNCSV05 .
FUNCTION $$UNIT$$ /SDF/GEN_FUNCS_S4_CONS_CHK_SIG

    IMPORTING
       VALUE(IV_TARGET_STACK) TYPE !CHAR20
       VALUE(IV_SITEM_GUID) TYPE !GUID_32
       VALUE(IV_SITEM_ID) TYPE !STRING
       VALUE(IV_CHECK_CLASS) TYPE !STRING
       VALUE(IV_SAP_NOTE) TYPE !CWBNTNUMM
       VALUE(IT_PARAMETER) TYPE !TIHTTPNVP
       VALUE(IV_SUM_MODE) TYPE !FLAG DEFAULT SPACE
    EXPORTING
       VALUE(EV_RESULT_XSTR) TYPE !XSTRING .