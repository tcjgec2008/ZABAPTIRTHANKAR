METHOD app_log_disp_cons_chk.

  DATA: ls_disp_profile    TYPE bal_s_prof,
        lt_log_handle      TYPE bal_t_logh,
        ls_field_cat       TYPE bal_s_fcat,
        lt_field_cat       TYPE TABLE OF bal_s_fcat.

  FIELD-SYMBOLS:
        <fs_field_cat>     TYPE bal_s_fcat.


  CHECK mv_log_handle IS NOT INITIAL.

*--------------------------------------------------------------------*
* Get variant which creates hierarchy according to field DETLEVEL
* Refer to SBAL_DEMO_04_SELF
* Refer to LSBAL_DISPLAY_BASEF10  PROFILE_CONVERT

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
  ls_disp_profile-title = get_text_str( iv_txt_key = 'A03' ).
  "Use vertical layout splitter
  ls_disp_profile-tree_ontop = space.
  "Define up to which level the tree should be expanded
  ls_disp_profile-exp_level = 1.
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

  APPEND mv_log_handle TO lt_log_handle.
  CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
    EXPORTING
      i_s_display_profile = ls_disp_profile
      i_t_log_handle      = lt_log_handle
      i_srt_by_timstmp    = 'X'
    EXCEPTIONS
      OTHERS              = 1.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDMETHOD.