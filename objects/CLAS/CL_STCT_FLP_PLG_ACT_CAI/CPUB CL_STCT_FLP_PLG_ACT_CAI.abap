class CL_STCT_FLP_PLG_ACT_CAI definition
  public
  inheriting from CL_STCTM_REPORT_UI
  final
  create public .

public section.

  interfaces IF_STCTM_BG_TASK .

  types:
    BEGIN OF t_flpsetpa,
        plugin_id TYPE c LENGTH 30,
        act_state TYPE c LENGTH 8,
      END OF t_flpsetpa .
  types:
    BEGIN OF t_flpsetpac,
        client    TYPE mandt,
        plugin_id TYPE c LENGTH 30,
        act_state TYPE c LENGTH 8,
      END OF t_flpsetpac .
  types:
    BEGIN OF t_flpsetp,
        plugin_id   TYPE c LENGTH 30,
        component   TYPE c LENGTH 255,
        description TYPE c LENGTH 140,
        url         TYPE c LENGTH 1024,
      END OF t_flpsetp .

  constants /UI2/FLPSETPA type DDTABNAME value '/UI2/FLPSETPA' ##NO_TEXT.
  constants /UI2/FLPSETPAC type DDTABNAME value '/UI2/FLPSETPAC' ##NO_TEXT.
  constants /UI2/FLPSETP type DDTABNAME value '/UI2/FLPSETP' ##NO_TEXT.

  methods CONSTRUCTOR .

  methods IF_STCTM_TASK~GET_DESCRIPTION
    redefinition .
  methods IF_STCTM_TASK~GET_DOCU_OBJECT
    redefinition .
  methods IF_STCTM_TASK~IS_NECESSARY
    redefinition .
  methods IF_STCTM_UI_TASK~MAINTAINED
    redefinition .