private section.

  class-methods ADD_ERROR_MESSAGE
    exporting
      !ET_CHK_RESULT type CLS4SIC_SI25_NEW_TASK_MNGMT=>TY_PRE_CONS_CHK_RESULT_TAB .
  class-methods ADD_SUCCESS_MESSAGE
    importing
      !IV_PARAM_VALUE type CHAR64
    exporting
      !ET_CHK_RESULT type CLS4SIC_SI25_NEW_TASK_MNGMT=>TY_PRE_CONS_CHK_RESULT_TAB .