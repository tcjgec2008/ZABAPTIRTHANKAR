*&---------------------------------------------------------------------*
*& Report STCT_UI_FLP_PLG_ACT_CAI
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT stct_ui_flp_plg_act_cai.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_bl01.


  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS p_sys RADIOBUTTON GROUP id1 DEFAULT 'X' USER-COMMAND act.
    SELECTION-SCREEN COMMENT 20(79) t_sys FOR FIELD p_sys.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS p_cus RADIOBUTTON GROUP id1.
    SELECTION-SCREEN COMMENT 20(39) t_cus FOR FIELD p_cus.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(39) t_over FOR FIELD p_over.
    PARAMETERS: p_over TYPE abap_bool DEFAULT ' ' AS CHECKBOX.
  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.

  t_bl01 = 'Activate FLP Plugin'(001).
  t_sys = 'All clients (/UI2/FLP_SYS_CONF)'(002).
  t_cus = 'Current client (/UI2/FLP_CUS_CONF)'(003).
  t_over = 'Overwrite existing setting'(004).

*----------------------------------------------------
* NO EXECUTION ---> Execution done with Task Manager
*----------------------------------------------------
START-OF-SELECTION.
  WRITE: / 'NOTE: Execution is done with Task Manager (transaction STC01)'(tm1).