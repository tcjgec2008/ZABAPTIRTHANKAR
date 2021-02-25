*&---------------------------------------------------------------------*
*& Report STCT_UI_ADD_HTTP_ALLOWLIST_NEW
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT stct_ui_add_http_allowlist_flp.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_bl01.

  PARAMETERS p_host TYPE rfcdisplay-rfchost MODIF ID r01.   "#EC NOTEXT
  PARAMETERS p_port TYPE rfcdisplay-rfcsysid MODIF ID r01.  "#EC NOTEXT
  PARAMETERS p_path TYPE c LENGTH 210 DEFAULT '*' MODIF ID r01. "#EC NOTEXT

SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.

  t_bl01 = 'Fiori URL for HTTP Allowlist:'(010).

AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.

    " set readonly
    IF screen-group1 = 'R01'.
      screen-input = '0'.
    ENDIF.

    MODIFY SCREEN.

  ENDLOOP.