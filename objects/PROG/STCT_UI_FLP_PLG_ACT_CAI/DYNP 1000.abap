PROCESS BEFORE OUTPUT.

MODULE %_INIT_PBO.

MODULE %_PBO_REPORT.

MODULE %_PF_STATUS.

MODULE %_END_OF_PBO.

PROCESS AFTER INPUT.

  MODULE %_BACK AT EXIT-COMMAND.

  MODULE %_INIT_PAI.

CHAIN.
  FIELD P_SYS   .
  FIELD P_CUS   .
    MODULE %_RADIOBUTTON_GROUP_ID1                           .
ENDCHAIN.

FIELD !P_OVER MODULE %_P_OVER .


CHAIN.
  FIELD P_SYS   .
  FIELD P_CUS   .
  FIELD P_OVER .
    MODULE %_BLOCK_1000000.
ENDCHAIN.

CHAIN.
  FIELD P_SYS   .
  FIELD P_CUS   .
  FIELD P_OVER .
  MODULE %_END_OF_SCREEN.
  MODULE %_OK_CODE_1000.
ENDCHAIN.