METHOD app_log_disp.

  DATA: ls_disp_profile    TYPE bal_s_prof,
        lt_log_handle      TYPE bal_t_logh,
        ls_field_cat       TYPE bal_s_fcat,
        lt_field_cat       TYPE TABLE OF bal_s_fcat,
        lt_log_header      TYPE balhdr_t,
        ls_log_header      TYPE balhdr.

  FIELD-SYMBOLS:
        <fs_field_cat>     TYPE bal_s_fcat.

  CHECK is_log_filter IS NOT INITIAL.

*--------------------------------------------------------------------*
* Searc and load the log handler

  CALL FUNCTION 'BAL_DB_SEARCH'
    EXPORTING
      i_s_log_filter     = is_log_filter
    IMPORTING
      e_t_log_header     = lt_log_header
    EXCEPTIONS
      log_not_found      = 1
      no_filter_criteria = 2
      OTHERS             = 3.
  IF sy-subrc <> 0.
    "No application log is available
    sv_message = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'A09' ).
    MESSAGE sv_message TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'BAL_DB_LOAD'
    EXPORTING
      i_t_log_header     = lt_log_header
    EXCEPTIONS
      no_logs_specified  = 1
      log_not_found      = 2
      log_already_loaded = 3
      OTHERS             = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'W'.
  ENDIF.


*--------------------------------------------------------------------*
* Get variant which creates hierarchy according to field DETLEVEL

  CALL FUNCTION 'BAL_DSP_PROFILE_DETLEVEL_GET'
    IMPORTING
      e_s_display_profile = ls_disp_profile
    EXCEPTIONS
      OTHERS              = 1.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
             WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  ls_disp_profile-use_grid = 'X'.
  "Simplificatin Item Check Application Log
  IF iv_title IS NOT INITIAL.
    ls_disp_profile-title = iv_title.
  ELSE.
    ls_disp_profile-title = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = 'A10' ).
  ENDIF.

  "Use vertical layout splitter
  ls_disp_profile-tree_ontop = space.
  "Define up to which level the tree should be expanded
  "ls_disp_profile-exp_level = 1.
  ls_disp_profile-cwidth_opt = 'X'."Use this to optimize the display of the right part
  "This controls whether all messages are loaded in the right panel
  "Important not to set it to prevent out of memory issue if the log amount is big
  ls_disp_profile-show_all = space.
  ls_disp_profile-disvariant-report = sy-repid.
  ls_disp_profile-disvariant-handle = 'LOG'.
  ls_disp_profile-head_size = 140.
  ls_disp_profile-tree_size = 81."Width of left tree panel

  READ TABLE ls_disp_profile-mess_fcat ASSIGNING <fs_field_cat>
    WITH KEY ref_table = 'BAL_S_SHOW'
             ref_field = 'MSGTY'.
  IF sy-subrc = 0.
    <fs_field_cat>-outputlen = 20.
  ENDIF.
  READ TABLE ls_disp_profile-mess_fcat ASSIGNING <fs_field_cat>
    WITH KEY ref_table = 'BAL_S_SHOW'
             ref_field = 'T_MSG'.
  IF sy-subrc = 0.
    <fs_field_cat>-outputlen = 100.
  ENDIF.


*--------------------------------------------------------------------*
* Display the application log

  LOOP AT lt_log_header INTO ls_log_header.
    INSERT ls_log_header-log_handle INTO TABLE lt_log_handle.
  ENDLOOP.

  CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
    EXPORTING
      i_s_display_profile = ls_disp_profile
      i_t_log_handle      = lt_log_handle
      i_srt_by_timstmp    = 'X'
    EXCEPTIONS
      OTHERS              = 1.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'W'.
  ENDIF.

ENDMETHOD.