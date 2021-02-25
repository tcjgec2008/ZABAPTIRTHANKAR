*&---------------------------------------------------------------------*
*& Report STCT_UI_FLP_PLG_DEF_CAI
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT STCT_UI_FLP_PLG_DEF_CAI.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_bl01.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(39) t_plid FOR FIELD p_plid.
PARAMETERS: p_plid TYPE c LENGTH 30 DEFAULT 'CAI_PLUGIN' MODIF ID ro ##NO_TEXT.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(39) t_descr FOR FIELD p_descr.
PARAMETERS: p_descr TYPE c LENGTH 140 LOWER CASE DEFAULT 'Plugin for Conversational AI' MODIF ID ro ##NO_TEXT.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(39) t_comp FOR FIELD p_comp.
PARAMETERS: p_comp TYPE c LENGTH 255 LOWER CASE DEFAULT 'sap.cai.webclient' MODIF ID ro ##NO_TEXT.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(39) t_url FOR FIELD p_url.
PARAMETERS: p_url TYPE c LENGTH 255 LOWER CASE OBLIGATORY.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE t_bl02.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(39) t_over FOR FIELD p_over.
PARAMETERS: p_over TYPE abap_bool DEFAULT ' ' AS CHECKBOX.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b2.

INITIALIZATION.

  t_bl01 = 'Define FLP Plugin'(001).

  t_plid = 'FLP Plugin ID'(002).
  t_comp = 'UI5 Component ID'(003).
  t_descr = 'Description'(004).
  t_url = 'URL'(005).

  t_bl02 = 'Set Parameter'(010).
  t_over = 'Overwrite existing setting'(011).

AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.

    " set readonly
    IF screen-group1 = 'RO'.
      screen-input = '0'.
      MODIFY SCREEN.
    ENDIF.

  ENDLOOP.

*----------------------------------------------------
* NO EXECUTION ---> Execution done with Task Manager
*----------------------------------------------------
START-OF-SELECTION.
  WRITE: / 'NOTE: Execution is done with Task Manager (transaction STC01)'(tm1).