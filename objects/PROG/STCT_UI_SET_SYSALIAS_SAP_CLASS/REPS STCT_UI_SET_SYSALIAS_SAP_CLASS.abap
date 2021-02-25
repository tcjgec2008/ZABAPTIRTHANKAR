*&---------------------------------------------------------------------*
*& Report STCT_UI_SET_SYSALIAS_SAP_CLASS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT stct_ui_set_sysalias_sap_class.

* HTTPS
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_bl01.

PARAMETERS: p_dest TYPE rfcdest MODIF ID ro, "OBLIGATORY,
            p_desc TYPE rfcdoc_d DEFAULT 'HTTPS Destination for SAP System' MODIF ID ro ##NO_TEXT.

SELECTION-SCREEN BEGIN OF BLOCK b10 WITH FRAME TITLE t_010.
PARAMETERS: p_host  TYPE rfchost,
            p_sysnr TYPE rfcsysid.
SELECTION-SCREEN END OF BLOCK b10.

SELECTION-SCREEN END OF BLOCK b1.


SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE t_bl02.
PARAMETERS p_cusal TYPE c LENGTH 10 DEFAULT 'FIORI_MENU' MODIF ID ro. "/iwfnd/cor_text40 "#EC NOTEXT
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE t_bl03.
PARAMETERS p_mapal TYPE c LENGTH 32 DEFAULT 'FIORI_MENU' MODIF ID ro. "/iwfnd/cor_text40 "#EC NOTEXT
PARAMETERS p_maprfc TYPE c LENGTH 32 MODIF ID ro. "/iwfnd/cor_text40 "#EC NOTEXT
PARAMETERS p_mapcl TYPE c LENGTH 3 MODIF ID ro. "/iwfnd/cor_text40 "#EC NOTEXT
SELECTION-SCREEN END OF BLOCK b3.


INITIALIZATION.

  t_bl01 = 'HTTPS Connection'(010).
  t_bl02 = 'Customer System Alias (/UI2/VC_SYSALIAS)'(020).
  t_bl03 = 'System Alias Mapping (/UI2/V_ALIASMAP)'(030).


AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.

    " set readonly
    IF screen-group1 = 'RO'.
      screen-input = '0'.
      MODIFY SCREEN.
    ENDIF.

  ENDLOOP.