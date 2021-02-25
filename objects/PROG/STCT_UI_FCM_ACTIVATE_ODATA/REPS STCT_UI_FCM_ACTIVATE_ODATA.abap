*&---------------------------------------------------------------------*
*& Report STCT_UI_FCM_ACTIVATE_ODATA
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT stct_ui_fcm_activate_odata NO STANDARD PAGE HEADING LINE-SIZE 200.

SELECTION-SCREEN BEGIN OF BLOCK b0 WITH FRAME TITLE t_bl00.
  SELECTION-SCREEN COMMENT /1(79) t_nfo1.
  SELECTION-SCREEN COMMENT /1(79) t_nfo2.
SELECTION-SCREEN END OF BLOCK b0.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t_bl01.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS p_opt2 RADIOBUTTON GROUP id1 USER-COMMAND act.
    SELECTION-SCREEN COMMENT 20(79) t_opt2 FOR FIELD p_opt2 MODIF ID b. "#EC NOTEXT
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS p_opt1 RADIOBUTTON GROUP id1 DEFAULT 'X'.
    SELECTION-SCREEN COMMENT 20(79) t_opt1 FOR FIELD p_opt1 MODIF ID a.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(39) t_seldes FOR FIELD p_seldes.
    PARAMETERS p_seldes TYPE /iwfnd/defi_system_alias DEFAULT 'LOCAL_TGW'.
  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  t_bl00 = 'Info'(010).
  t_nfo1 = 'OData services will be activated by default in co-deployed mode.'(011).
  t_nfo2 = 'Use below setting for the exceptional handling of the ''TASKPROCESSING'' service.'(012).

  t_bl01 = 'Select SAP System Alias for ''TASKPROCESSING'''(001).
  t_seldes = 'SAP System Alias'(003).
  t_opt1 = 'Routing-based'(004).
  t_opt2 = 'Co-deployed only'(005).

AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.
    IF screen-name = 'P_OPT2'.
      screen-input = '0'.
      MODIFY SCREEN.
    ENDIF.

    IF screen-name = 'P_OPT1'.
      screen-input = '0'.
      MODIFY SCREEN.
    ENDIF.

  ENDLOOP.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_seldes.

  TYPES:
    BEGIN OF ls_sys_aliases_simple,
      alias TYPE /iwfnd/defi_system_alias,
      host  TYPE /iwfnd/mgw_inma_host_name,
    END OF ls_sys_aliases_simple.

  DATA: lt_sys_aliases_simple TYPE TABLE OF ls_sys_aliases_simple WITH DEFAULT KEY,
        ls_sys_aliases_simple TYPE ls_sys_aliases_simple.

  DATA: it_return LIKE ddshretval OCCURS 0 WITH HEADER LINE.

  DATA: lt_sys_aliases TYPE TABLE OF /iwfnd/c_dfsyal.
  DATA: ls_sys_aliases LIKE LINE OF lt_sys_aliases.

  " get aliases
  SELECT * FROM /iwfnd/c_dfsyal INTO ls_sys_aliases .
    APPEND ls_sys_aliases TO lt_sys_aliases.
  ENDSELECT.

  " prepare f4
  LOOP AT lt_sys_aliases INTO ls_sys_aliases.
    ls_sys_aliases_simple-alias = ls_sys_aliases-system_alias.
    ls_sys_aliases_simple-host = ls_sys_aliases-rfc_dest.
    APPEND ls_sys_aliases_simple TO lt_sys_aliases_simple.
  ENDLOOP.

  " call f4
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'ALIAS'
      value_org       = 'S'
    TABLES
      value_tab       = lt_sys_aliases_simple
      return_tab      = it_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc EQ 0.
    p_seldes = it_return-fieldval.
  ENDIF.


*----------------------------------------------------------------
* Process Key events: enter, save, go back
*----------------------------------------------------------------

AT SELECTION-SCREEN.

  LOOP AT SCREEN.

* process key events
    CASE sy-ucomm.

* press enter -> check rfc
      WHEN ' '.
        IF p_opt1 = 'X'.
          PERFORM checkrfcforalias.
        ENDIF.

* save variant -> check rfc
      WHEN 'SAVE'.
        IF p_opt1 = 'X'.
          PERFORM checkrfcforalias.
        ENDIF.

* go back -> check rfc
      WHEN 'VBAC'.

        IF p_opt1 = 'X'.
          PERFORM checkrfcforalias.
        ENDIF.

    ENDCASE.

  ENDLOOP.

FORM checkrfcforalias.

  DATA: lt_sys_aliases TYPE TABLE OF /iwfnd/c_dfsyal.
  DATA: ls_sys_aliases LIKE LINE OF lt_sys_aliases.

  DATA: lo_dest_factory TYPE REF TO cl_dest_factory.
  DATA: lx_dest_api TYPE REF TO cx_dest_api.

  DATA: lv_rfcdest TYPE rfcdest.

  DATA: lv_flag_trustedsystem TYPE rfcdisplay-rfcslogin.
  DATA: lv_flag_sameuser TYPE rfcdisplay-rfcsameusr.

  " handover parameter to form variable

  IF p_seldes IS INITIAL.
    MESSAGE e000(s_lmcfg_core_tasks) WITH 'SAP System Alias is mandatory' ##NO_TEXT.
    RETURN.
  ELSE.

    " check alias is available
    SELECT SINGLE * FROM /iwfnd/c_dfsyal INTO ls_sys_aliases WHERE system_alias = p_seldes .

    IF ls_sys_aliases IS INITIAL.

      MESSAGE e000(s_lmcfg_core_tasks) WITH 'SAP System Alias not found' ##NO_TEXT.
      RETURN.

    ENDIF.

  ENDIF.

ENDFORM.


*----------------------------------------------------
* NO EXECUTION ---> Execution done with Task Manager
*----------------------------------------------------
START-OF-SELECTION.
  WRITE: / 'NOTE: Execution is done with Task Manager (transaction STC01)'(tm1).