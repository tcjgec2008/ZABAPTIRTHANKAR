PROCESS BEFORE OUTPUT.

MODULE %_INIT_PBO.

MODULE %_PBO_REPORT.

MODULE %_PF_STATUS.

MODULE %_END_OF_PBO.

PROCESS AFTER INPUT.

  MODULE %_BACK AT EXIT-COMMAND.

  MODULE %_INIT_PAI.


CHAIN.
  FIELD P_OPT2  .
  FIELD P_OPT1  .
    MODULE %_RADIOBUTTON_GROUP_ID1                           .
ENDCHAIN.

FIELD !P_SELDES MODULE %_P_SELDES .


CHAIN.
  FIELD P_OPT2  .
  FIELD P_OPT1  .
  FIELD P_SELDES .
    MODULE %_BLOCK_1000004.
ENDCHAIN.

CHAIN.
  FIELD P_OPT2  .
  FIELD P_OPT1  .
  FIELD P_SELDES .
  MODULE %_END_OF_SCREEN.
  MODULE %_OK_CODE_1000.
ENDCHAIN.

PROCESS ON VALUE-REQUEST.
  FIELD P_SELDES MODULE %_P_SELDES_VAL .