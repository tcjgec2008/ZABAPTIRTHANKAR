FUNCTION-POOL stct_core_tasks_gw.           "MESSAGE-ID ..

* INCLUDE LSTCT_CORE_TASKS_GWD...            " Local class definition

**********************************************************************

DATA  g_ok_code LIKE sy-ucomm.       " return code from screen


DATA: d100_disp_only   TYPE boolean.
DATA: d100_initial TYPE boolean.
DATA: d100_lt_service  TYPE stct_input_data_table.
DATA: d100_ls_service  TYPE stct_input_data.

DATA: d100_it_editor TYPE stct_editor_table.

CONSTANTS: line_length TYPE i VALUE 256.


DATA:
*   reference to wrapper class of control
  g_editor               TYPE REF TO cl_gui_textedit,
*   reference to custom container: necessary to bind TextEdit Control
  g_editor_container     TYPE REF TO cl_gui_custom_container,
  g_repid                LIKE sy-repid,
  g_relink               TYPE c,               " to manage relinking
  g_mytable(line_length) TYPE c OCCURS 0,
  g_mycontainer(30)      TYPE c,      " string for the containers
  g_container_linked     TYPE i.                            "#EC NEEDED
" container to which control is linked
DATA: gs_mytable LIKE LINE OF g_mytable.
* necessary to flush the automation queue
CLASS cl_gui_cfw DEFINITION LOAD.

DATA: gd_mode TYPE i  VALUE cl_gui_textedit=>false.

**********************************************************************

TYPES: BEGIN OF t_output,
         selected    TYPE flag,
         service     TYPE /iwfnd/med_mdl_srg_name,
         version     TYPE /iwfnd/med_mdl_version,
         field_style TYPE lvc_t_styl, "FOR DISABLE
       END OF t_output.

DATA d200_disp_only TYPE boolean.
DATA d200_header TYPE text60.

DATA d200_service_table TYPE stct_service_status_table.

DATA d200_services TYPE stct_service_status.
DATA d200_services_status TYPE stct_service_status.

DATA d200_sys TYPE string.

DATA d200_save TYPE boolean.

CLASS grid_appl DEFINITION DEFERRED.

* custom control and grid_application object
DATA: my_container   TYPE REF TO cl_gui_custom_container,
      my_application TYPE REF TO grid_appl.


DATA: gt_outtab TYPE STANDARD TABLE OF t_output INITIAL SIZE 0,
      wa_output TYPE                   t_output.  "table for ALV



DATA: d200_service_table_input TYPE STANDARD TABLE OF t_output INITIAL SIZE 0.
DATA: d200_service_table_saved TYPE STANDARD TABLE OF t_output INITIAL SIZE 0.

DATA: lv_exit TYPE boolean.

**********************************************************************

*---------------------------------------------------------------------*
*       CLASS grid_appl DEFINITION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS grid_appl DEFINITION.

  PUBLIC SECTION.
    DATA: my_grid TYPE REF TO cl_gui_alv_grid.

    METHODS: constructor,
      display_table.

ENDCLASS.                    "grid_appl


*&---------------------------------------------------------------------*
*&       Class (Implementation)  grid_appl
*&---------------------------------------------------------------------*
*        Text
*----------------------------------------------------------------------*
CLASS grid_appl IMPLEMENTATION.

  METHOD constructor.

* instantiate the grid
    CREATE OBJECT my_grid EXPORTING i_parent = my_container.
    CALL METHOD display_table.

  ENDMETHOD.                    "constructor

*---------------------------------------------------------------------*
*       METHOD display_table                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
  METHOD display_table.

* data for grid
    DATA: gs_layout   TYPE lvc_s_layo,
          gt_fieldcat TYPE lvc_t_fcat,
          gs_fieldcat TYPE lvc_s_fcat.

* prepare fieldcatalogue
    gs_fieldcat-fieldname   = 'SELECTED'.
    gs_fieldcat-scrtext_m   = 'Activate'(130).
    gs_fieldcat-col_pos     = 0.
    gs_fieldcat-outputlen   = 10.
    gs_fieldcat-checkbox = 'X'."print as checkbox
    gs_fieldcat-edit = 'X'. "make field open for input
    APPEND gs_fieldcat TO gt_fieldcat.
    CLEAR  gs_fieldcat.

    gs_fieldcat-fieldname   = 'SERVICE'.
    gs_fieldcat-scrtext_m   = 'ODate Service'(131).
    gs_fieldcat-outputlen   = 40.
    gs_fieldcat-col_pos     = 1.
    APPEND gs_fieldcat TO gt_fieldcat.
    CLEAR  gs_fieldcat.

    gs_fieldcat-fieldname   = 'VERSION'.
    gs_fieldcat-scrtext_m   = 'Version'(132).
    gs_fieldcat-just = 'L'.

    gs_fieldcat-col_pos     = 2.
    gs_fieldcat-outputlen   = 10.
    APPEND gs_fieldcat TO gt_fieldcat.
    CLEAR  gs_fieldcat.

* Set layout field for field attributes(i.e. input/output)
    gs_layout-stylefname = 'FIELD_STYLE'.
    gs_layout-zebra             = 'X'.
    gs_layout-no_toolbar        = 'X'.

    DATA ls_stylerow TYPE lvc_s_styl .
    DATA lt_styletab TYPE lvc_t_styl .

* set table for first display
    CALL METHOD my_grid->set_table_for_first_display
      EXPORTING
        is_layout       = gs_layout
      CHANGING
        it_outtab       = gt_outtab
        it_fieldcatalog = gt_fieldcat.

  ENDMETHOD.                    "new_table

ENDCLASS.


**********************************************************************

TYPES: BEGIN OF t_output300,
         selected    TYPE flag,
         role        TYPE agr_name,
         description TYPE agr_title,
         field_style TYPE lvc_t_styl, "FOR DISABLE
       END OF t_output300.

DATA d300_disp_only TYPE boolean.
DATA d300_header TYPE text60.

DATA d300_roles_table TYPE stct_agr_br_table.

DATA d300_roles TYPE stct_agr_br.

DATA d300_save TYPE boolean.
*
CLASS grid_appl300 DEFINITION DEFERRED.

* custom control and grid_application object
DATA: my_container300   TYPE REF TO cl_gui_custom_container,
      my_application300 TYPE REF TO grid_appl300.

DATA: event_receiver300 TYPE REF TO grid_appl300.

DATA: gt_outtab300 TYPE STANDARD TABLE OF t_output300 INITIAL SIZE 0,
      wa_output300 TYPE                   t_output300.  "table for ALV


DATA: d300_roles_input TYPE STANDARD TABLE OF t_output300 INITIAL SIZE 0.
DATA: d300_roles_saved TYPE STANDARD TABLE OF t_output300 INITIAL SIZE 0.

DATA: lv_filter TYPE string.


**********************************************************************

*---------------------------------------------------------------------*
*       CLASS grid_appl300 DEFINITION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS grid_appl300 DEFINITION.

  PUBLIC SECTION.
    DATA: my_grid300 TYPE REF TO cl_gui_alv_grid.

    METHODS: constructor,
      display_table300,
      handle_double_click300
        FOR EVENT double_click OF cl_gui_alv_grid
        IMPORTING e_row e_column.

ENDCLASS.                    "grid_appl


*&---------------------------------------------------------------------*
*&       Class (Implementation)  grid_appl300
*&---------------------------------------------------------------------*
*        Text
*----------------------------------------------------------------------*
CLASS grid_appl300 IMPLEMENTATION.

  METHOD constructor.

* instantiate the grid
    CREATE OBJECT my_grid300 EXPORTING i_parent = my_container300.
    CALL METHOD display_table300.

  ENDMETHOD.                    "constructor

*---------------------------------------------------------------------*
*       METHOD display_table300                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
  METHOD display_table300.

* data for grid
    DATA: gs_layout   TYPE lvc_s_layo,
          gt_fieldcat TYPE lvc_t_fcat,
          gs_fieldcat TYPE lvc_s_fcat.

* prepare fieldcatalogue
    gs_fieldcat-fieldname   = 'SELECTED'.
    gs_fieldcat-scrtext_m   = 'Select'(301).
    gs_fieldcat-col_pos     = 0.
    gs_fieldcat-outputlen   = 10.
    gs_fieldcat-checkbox = 'X'."print as checkbox
    gs_fieldcat-edit = 'X'. "make field open for input
    APPEND gs_fieldcat TO gt_fieldcat.
    CLEAR  gs_fieldcat.

    gs_fieldcat-fieldname   = 'ROLE'.
    gs_fieldcat-scrtext_m   = 'Role'(302).
    gs_fieldcat-outputlen   = 30.
    gs_fieldcat-col_pos     = 1.
    APPEND gs_fieldcat TO gt_fieldcat.
    CLEAR  gs_fieldcat.

    gs_fieldcat-fieldname   = 'DESCRIPTION'.
    gs_fieldcat-scrtext_m   = 'Description'(303).
    gs_fieldcat-just = 'L'.

    gs_fieldcat-col_pos     = 2.
    gs_fieldcat-outputlen   = 80.
    APPEND gs_fieldcat TO gt_fieldcat.
    CLEAR  gs_fieldcat.

* Set layout field for field attributes(i.e. input/output)
    gs_layout-stylefname = 'FIELD_STYLE'.
    gs_layout-zebra             = 'X'.
    gs_layout-no_toolbar        = 'X'.

    DATA ls_stylerow TYPE lvc_s_styl .
    DATA lt_styletab TYPE lvc_t_styl .

* set table for first display
    CALL METHOD my_grid300->set_table_for_first_display
      EXPORTING
        is_layout       = gs_layout
      CHANGING
        it_outtab       = gt_outtab300
        it_fieldcatalog = gt_fieldcat.

  ENDMETHOD.                    "new_table

  METHOD handle_double_click300.

    DATA: gt_sort TYPE lvc_t_sort.
    DATA: gs_sort TYPE lvc_s_sort.

    "Get current sort for
    my_application300->my_grid300->get_sort_criteria(
      IMPORTING
        et_sort = gt_sort              " Sort Criteria
    ).

    READ TABLE gt_sort INTO gs_sort INDEX 1.

    IF gs_sort IS INITIAL.
      gs_sort-fieldname = e_column.
      gs_sort-down = 'X'.
      gs_sort-up = ''.
    ELSE.

      CASE gs_sort-down.
        WHEN 'X'.
          gs_sort-fieldname = e_column.
          gs_sort-down = ''.
          gs_sort-up = 'X'.
        WHEN ''.
          gs_sort-fieldname = e_column.
          gs_sort-down = 'X'.
          gs_sort-up = ''.
      ENDCASE.
    ENDIF.

    CLEAR gt_sort.
    APPEND gs_sort TO gt_sort.

    my_application300->my_grid300->set_sort_criteria(
      EXPORTING
        it_sort                   =   gt_sort               " Sort Criteria
        ).

    "Refresh ALV
    CALL METHOD my_application300->my_grid300->refresh_table_display.

  ENDMETHOD.

ENDCLASS.






*&---------------------------------------------------------------------*
*&      Module  START  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE start_0100 OUTPUT.

  SET PF-STATUS '0100'.
  SET TITLEBAR '0100' WITH 'Define OData Services'(134).

  IF g_editor IS INITIAL.

*   create control container
    CREATE OBJECT g_editor_container
      EXPORTING
        container_name              = 'TEXTEDITOR1'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5.
    IF sy-subrc NE 0.
*      add your handling
    ENDIF.
    g_mycontainer = 'TEXTEDITOR1'.

*   create calls constructor, which initializes, creats and links
*   TextEdit Control
    CREATE OBJECT g_editor
      EXPORTING
        parent                     = g_editor_container
        wordwrap_mode              =
*             cl_gui_textedit=>wordwrap_off
                                     cl_gui_textedit=>wordwrap_at_fixed_position
*             cl_gui_textedit=>WORDWRAP_AT_WINDOWBORDER
        wordwrap_position          = line_length
        wordwrap_to_linebreak_mode = cl_gui_textedit=>true.

*   to handle different containers
*    g_container_linked = 1.

    REFRESH g_mytable.  " to initialize table upon OK_CODE 'BACK' at PAI

    CALL METHOD g_editor->set_text_as_r3table
      EXPORTING
        table           = d100_it_editor
      EXCEPTIONS
        error_dp        = 1
        error_dp_create = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    CALL METHOD cl_gui_cfw=>flush
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc NE 0.
    ENDIF.


  ENDIF.

  " set display mode
  IF d100_disp_only = abap_true.

    gd_mode = cl_gui_textedit=>true.

    CALL METHOD g_editor->set_readonly_mode
      EXPORTING
        readonly_mode          = gd_mode
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2
        OTHERS                 = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    CALL METHOD cl_gui_cfw=>flush
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc NE 0.
    ENDIF.

  ELSE.

    gd_mode = cl_gui_textedit=>false.

    CALL METHOD g_editor->set_readonly_mode
      EXPORTING
        readonly_mode          = gd_mode
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2
        OTHERS                 = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    CALL METHOD cl_gui_cfw=>flush
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc NE 0.
    ENDIF.

  ENDIF.


ENDMODULE.                             " START  OUTPUT

**&---------------------------------------------------------------------*
**&      Module  EXIT  INPUT
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
MODULE exit_0100 INPUT.

  CASE g_ok_code.
    WHEN 'CONTINUE'.
*   retrieve table from control
      CALL METHOD g_editor->get_text_as_r3table
        IMPORTING
          table = g_mytable.

      PERFORM exit_program.
      LEAVE TO SCREEN 0.

    WHEN 'CANCEL'.
      PERFORM exit_program.
      LEAVE TO SCREEN 0.

    WHEN 'INFO'.
      CALL FUNCTION 'DOCU_CALL'
        EXPORTING
          displ      = 'X'
          displ_mode = '1'
          id         = 'TX'
          langu      = sy-langu
          object     = 'STCT_INPUT_ODATA_SERVICES'
        EXCEPTIONS
          wrong_name = 1
          OTHERS     = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

  ENDCASE.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module START_0110 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE start_0110 OUTPUT.
  SET PF-STATUS '0110'.
  SET TITLEBAR '0110' WITH 'Define Business Roles'(135).

  IF g_editor IS INITIAL.

*   create control container
    CREATE OBJECT g_editor_container
      EXPORTING
        container_name              = 'TEXTEDITOR1'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5.
    IF sy-subrc NE 0.
*      add your handling
    ENDIF.
    g_mycontainer = 'TEXTEDITOR1'.

*   create calls constructor, which initializes, creats and links
*   TextEdit Control
    CREATE OBJECT g_editor
      EXPORTING
        parent                     = g_editor_container
        wordwrap_mode              =
*             cl_gui_textedit=>wordwrap_off
                                     cl_gui_textedit=>wordwrap_at_fixed_position
*             cl_gui_textedit=>WORDWRAP_AT_WINDOWBORDER
        wordwrap_position          = line_length
        wordwrap_to_linebreak_mode = cl_gui_textedit=>true.

*   to handle different containers
*    g_container_linked = 1.

    REFRESH g_mytable.  " to initialize table upon OK_CODE 'BACK' at PAI

    CALL METHOD g_editor->set_text_as_r3table
      EXPORTING
        table           = d100_it_editor
      EXCEPTIONS
        error_dp        = 1
        error_dp_create = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    CALL METHOD cl_gui_cfw=>flush
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc NE 0.
    ENDIF.


  ENDIF.

  " set display mode
  IF d100_disp_only = abap_true.

    gd_mode = cl_gui_textedit=>true.

    CALL METHOD g_editor->set_readonly_mode
      EXPORTING
        readonly_mode          = gd_mode
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2
        OTHERS                 = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    CALL METHOD cl_gui_cfw=>flush
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc NE 0.
    ENDIF.

  ELSE.

    gd_mode = cl_gui_textedit=>false.

    CALL METHOD g_editor->set_readonly_mode
      EXPORTING
        readonly_mode          = gd_mode
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2
        OTHERS                 = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    CALL METHOD cl_gui_cfw=>flush
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc NE 0.
    ENDIF.

  ENDIF.
ENDMODULE.                             " START  OUTPUT

**&---------------------------------------------------------------------*
**&      Module  EXIT  INPUT
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
MODULE exit_0110 INPUT.

  CASE g_ok_code.
    WHEN 'CONTINUE'.
*   retrieve table from control
      CALL METHOD g_editor->get_text_as_r3table
        IMPORTING
          table = g_mytable.

      PERFORM exit_program.
      LEAVE TO SCREEN 0.

    WHEN 'CANCEL'.
      PERFORM exit_program.
      LEAVE TO SCREEN 0.

    WHEN 'INFO'.
      CALL FUNCTION 'DOCU_CALL'
        EXPORTING
          displ      = 'X'
          displ_mode = '2'
          id         = 'TX'
          langu      = sy-langu
          object     = 'STCT_INPUT_BUSINESS_ROLES'
        EXCEPTIONS
          wrong_name = 1
          OTHERS     = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

  ENDCASE.

ENDMODULE.


************************************************************************
*  F O R M S
************************************************************************

*&---------------------------------------------------------------------*
*&      Form  EXIT_PROGRAM
*&---------------------------------------------------------------------*
FORM exit_program.
* Destroy Control.
  IF NOT g_editor IS INITIAL.
    CALL METHOD g_editor->free
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc NE 0.
*     add your handling
    ENDIF.
*   free ABAP object also
    FREE g_editor.
  ENDIF.

* destroy container
  IF NOT g_editor_container IS INITIAL.
    CALL METHOD g_editor_container->free
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc NE 0.
*     add your handling
    ENDIF.
*   free ABAP object also
    FREE g_editor_container.
  ENDIF.

* finally flush
  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      OTHERS = 1.
  IF sy-subrc NE 0.
*   add your handling
  ENDIF.

ENDFORM.                               " EXIT_PROGRAM


*&---------------------------------------------------------------------*
*&      Form  EXIT_PROGRAM_200
*&---------------------------------------------------------------------*
FORM exit_program_200.
* Destroy Control.
  IF my_application IS NOT INITIAL AND
     my_application->my_grid IS NOT INITIAL.
    CALL METHOD my_application->my_grid->free
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc NE 0.
*     add your handling
    ENDIF.
*   free ABAP object also
    FREE my_application->my_grid.
  ENDIF.

  CLEAR my_application.

* destroy container
  IF NOT my_container IS INITIAL.
    CALL METHOD my_container->free
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc NE 0.
*     add your handling
    ENDIF.
*   free ABAP object also
    FREE my_container.
  ENDIF.

* finally flush
  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      OTHERS = 1.
  IF sy-subrc NE 0.
*   add your handling
  ENDIF.

ENDFORM.                               " EXIT_PROGRAM


**&---------------------------------------------------------------------*
**&      Module  EXIT  INPUT
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
MODULE exit_0200 INPUT.


  CASE g_ok_code.

    WHEN 'SAVE'.
      PERFORM update_selection CHANGING gt_outtab[].
      PERFORM save_table.

    WHEN 'BACK'.
      lv_exit = abap_false.

      PERFORM check_for_changes CHANGING lv_exit.

      IF lv_exit = abap_true.
        PERFORM exit_program_200.
        LEAVE TO SCREEN 0.
      ENDIF.

    WHEN 'EXIT'.
      lv_exit = abap_false.

      PERFORM check_for_changes CHANGING lv_exit.

      IF lv_exit = abap_true.
        PERFORM exit_program_200.
        LEAVE TO SCREEN 0.
      ENDIF.

    WHEN 'ESC'.
      lv_exit = abap_false.

      PERFORM check_for_changes CHANGING lv_exit.

      IF lv_exit = abap_true.
        PERFORM exit_program_200.
        LEAVE TO SCREEN 0.
      ENDIF.

    WHEN 'SELECT'.
      PERFORM select_all_entries CHANGING gt_outtab[].

    WHEN 'DESELECT'.
      PERFORM deselect_all_entries CHANGING gt_outtab[].

    WHEN 'INFO'.
      CALL FUNCTION 'DOCU_CALL'
        EXPORTING
          displ      = 'X'
          displ_mode = '2'
          id         = 'TX'
          langu      = sy-langu
          object     = 'STCT_ACTIVATE_ODATA_SERVICE'
        EXCEPTIONS
          wrong_name = 1
          OTHERS     = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

  ENDCASE.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Form  update_entries
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_OUTTAB  text
*----------------------------------------------------------------------*
FORM update_selection CHANGING pt_outtab TYPE STANDARD TABLE.
  DATA: ls_outtab TYPE t_output.
  DATA: l_valid TYPE c.

  CALL METHOD my_application->my_grid->check_changed_data
    IMPORTING
      e_valid = l_valid.

  IF l_valid EQ 'X'.

    LOOP AT pt_outtab INTO ls_outtab.
      MODIFY pt_outtab FROM ls_outtab.
    ENDLOOP.
  ENDIF.
ENDFORM.                               " update_entries


*&---------------------------------------------------------------------*
*&      Form  SAVE_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_table .

  CLEAR d200_service_table.

  LOOP AT gt_outtab INTO wa_output.

    d200_services_status-selected =  wa_output-selected.
    d200_services_status-service =  wa_output-service.
    d200_services_status-version =  wa_output-version.

    APPEND d200_services_status TO d200_service_table.

  ENDLOOP.

  d200_service_table_input = gt_outtab.

  MESSAGE 'Selection saved'(120) TYPE 'S'.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  select_all_entries
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_OUTTAB  text
*----------------------------------------------------------------------*
FORM select_all_entries CHANGING pt_outtab TYPE STANDARD TABLE.
  DATA: ls_outtab TYPE t_output.
  DATA: l_valid TYPE c.

  CALL METHOD my_application->my_grid->check_changed_data
    IMPORTING
      e_valid = l_valid.

  IF l_valid EQ 'X'.

    LOOP AT pt_outtab INTO ls_outtab.

      IF ls_outtab-selected EQ ' '.
        ls_outtab-selected = 'X'.
      ENDIF.

      MODIFY pt_outtab FROM ls_outtab.

    ENDLOOP.

    CALL METHOD my_application->my_grid->refresh_table_display.

  ENDIF.

ENDFORM.                               " select_all_entries


*&---------------------------------------------------------------------*
*&      Form  deselect_all_entries
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_OUTTAB[]  text
*----------------------------------------------------------------------*
FORM deselect_all_entries CHANGING pt_outtab TYPE STANDARD TABLE.
  DATA: ls_outtab TYPE t_output.
  DATA: l_valid TYPE c.

  CALL METHOD my_application->my_grid->check_changed_data
    IMPORTING
      e_valid = l_valid.

  IF l_valid EQ 'X'.

    LOOP AT pt_outtab INTO ls_outtab.

      IF NOT ls_outtab-selected EQ ' '.
        ls_outtab-selected = ' '.
      ENDIF.

      MODIFY pt_outtab FROM ls_outtab.
    ENDLOOP.

    CALL METHOD my_application->my_grid->refresh_table_display.

  ENDIF.

ENDFORM.                               " deselect_all_entries


*&---------------------------------------------------------------------*
*&      Form  CHECK_FOR_CHANGES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  <--  exit        text
*----------------------------------------------------------------------*
FORM check_for_changes CHANGING exit.

  DATA: answer(1).

  PERFORM update_selection CHANGING gt_outtab[].

  " check if data was chnaged, if yes show popup to save
  IF d200_service_table_input NE gt_outtab.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar       = 'Selection has been changed'(110)
        text_question  = 'Save selection?'(133)
        text_button_1  = 'Yes'(111)
        text_button_2  = 'No'(112)
      IMPORTING
        answer         = answer
      EXCEPTIONS
        text_not_found = 1
        OTHERS         = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.

      CASE answer.
        WHEN '1'.
          PERFORM save_table.
          exit = abap_true.

        WHEN '2'.
          exit = abap_true.

        WHEN OTHERS.
          exit = abap_false.
          MESSAGE 'Action cancelled'(121) TYPE 'E'.
          EXIT.
      ENDCASE.

    ENDIF.

  ENDIF.

  exit = abap_true.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  EXIT_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_0300 INPUT.

  CASE g_ok_code.

    WHEN 'SAVE'.
      PERFORM update_selection300 CHANGING gt_outtab300[].
      PERFORM save_table300.

    WHEN 'BACK'.
      lv_exit = abap_false.

      PERFORM check_for_changes300 CHANGING lv_exit.

      IF lv_exit = abap_true.
        PERFORM exit_program_300.
        LEAVE TO SCREEN 0.
      ENDIF.

    WHEN 'EXIT'.
      lv_exit = abap_false.

      PERFORM check_for_changes300 CHANGING lv_exit.

      IF lv_exit = abap_true.
        PERFORM exit_program_300.
        LEAVE TO SCREEN 0.
      ENDIF.

    WHEN 'ESC'.
      lv_exit = abap_false.

      PERFORM check_for_changes300 CHANGING lv_exit.

      IF lv_exit = abap_true.
        PERFORM exit_program_300.
        LEAVE TO SCREEN 0.
      ENDIF.

    WHEN 'FILTER'.
      PERFORM filter USING abap_false.

    WHEN 'FILTER_U'.
      PERFORM filter USING abap_true.

    WHEN 'SORT_SELECTED'.
      PERFORM sort_selected300 CHANGING gt_outtab300[].

    WHEN 'SELECT_BR_ROLES'.
      PERFORM select_br_roles300 CHANGING gt_outtab300[].

    WHEN 'OK'.
      PERFORM filter USING abap_false.

    WHEN 'SELECT'.
      PERFORM select_all_entries300 CHANGING gt_outtab300[].

    WHEN 'DESELECT'.
      PERFORM deselect_all_entries300 CHANGING gt_outtab300[].

    WHEN 'INFO'.
      CALL FUNCTION 'DOCU_CALL'
        EXPORTING
          displ      = 'X'
          displ_mode = '3'
          id         = 'TX'
          langu      = sy-langu
          object     = 'STCT_SELECT_BUSINESS_R_DYNPR'
        EXCEPTIONS
          wrong_name = 1
          OTHERS     = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

  ENDCASE.

ENDMODULE.


FORM filter USING lv_clear TYPE abap_bool.

  DATA: gt_filter TYPE lvc_t_filt.
  DATA: gs_filter TYPE lvc_s_filt.

  CLEAR: gt_filter.

  PERFORM update_selection300 CHANGING gt_outtab300[].

  IF lv_clear = abap_true.
    lv_filter = ''.
  ENDIF.

  IF lv_filter IS NOT INITIAL.

    gs_filter-fieldname = 'ROLE'. "Field Name
    gs_filter-sign = 'I'.
    gs_filter-option = 'CP'.
    gs_filter-low = lv_filter. "Filter Value
    APPEND gs_filter TO gt_filter.

  ENDIF.

  my_application300->my_grid300->set_filter_criteria(
    EXPORTING
      it_filter                 =       gt_filter           " Filter Conditions
  ).

ENDFORM.


FORM sort_selected300 CHANGING pt_outtab TYPE STANDARD TABLE.

  " Sort for selected roles
  PERFORM update_selection300 CHANGING gt_outtab300[].

  DATA: gt_sort TYPE lvc_t_sort.
  DATA: gs_sort TYPE lvc_s_sort.

  CLEAR: gt_sort.

  gs_sort-fieldname = 'SELECTED'.
  gs_sort-down = 'X'.

  APPEND gs_sort TO gt_sort.

  my_application300->my_grid300->set_sort_criteria(
    EXPORTING
      it_sort                   =   gt_sort               " Sort Criteria
      ).

ENDFORM.

FORM select_br_roles300 CHANGING pt_outtab TYPE STANDARD TABLE.

  DATA: ls_outtab TYPE t_output300.

  PERFORM update_selection300 CHANGING gt_outtab300[].

  " Select recommended roles
  LOOP AT pt_outtab INTO ls_outtab.

    IF ls_outtab-role = 'SAP_BR_ADMINISTRATOR'.
      ls_outtab-selected = 'X'.
    ENDIF.

    IF ls_outtab-role = 'SAP_BR_ANALYTICS_SPECIALIST'.
      ls_outtab-selected = 'X'.
    ENDIF.

    IF ls_outtab-role = 'SAP_BR_BUSINESS_PROCESS_SPEC'.
      ls_outtab-selected = 'X'.
    ENDIF.

    IF ls_outtab-role = 'SAP_BR_BPC_EXPERT'.
      ls_outtab-selected = 'X'.
    ENDIF.

    MODIFY pt_outtab FROM ls_outtab.

  ENDLOOP.

  " Sort for selected roles
  PERFORM update_selection300 CHANGING gt_outtab300[].

  DATA: gt_sort TYPE lvc_t_sort.
  DATA: gs_sort TYPE lvc_s_sort.

  CLEAR: gt_sort.

  gs_sort-fieldname = 'SELECTED'.
  gs_sort-down = 'X'.

  APPEND gs_sort TO gt_sort.

  my_application300->my_grid300->set_sort_criteria(
    EXPORTING
      it_sort                   =   gt_sort               " Sort Criteria
      ).

ENDFORM.



*&---------------------------------------------------------------------*
*&      Form  update_entries
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_OUTTAB  text
*----------------------------------------------------------------------*
FORM update_selection300 CHANGING pt_outtab TYPE STANDARD TABLE.
  DATA: ls_outtab TYPE t_output300.
  DATA: l_valid TYPE c.

  CALL METHOD my_application300->my_grid300->check_changed_data
    IMPORTING
      e_valid = l_valid.

  IF l_valid EQ 'X'.

    LOOP AT pt_outtab INTO ls_outtab.
      MODIFY pt_outtab FROM ls_outtab.
    ENDLOOP.
  ENDIF.
ENDFORM.                               " update_entries


*&---------------------------------------------------------------------*
*&      Form  SAVE_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_table300.

  CLEAR d300_roles_table.

  LOOP AT gt_outtab300 INTO wa_output300.

    d300_roles-flag =  wa_output300-selected.
    d300_roles-agr_name =  wa_output300-role.
    d300_roles-agr_description =  wa_output300-description.

    APPEND d300_roles TO d300_roles_table.

  ENDLOOP.

  d300_roles_input = gt_outtab300.

  MESSAGE 'Selection saved'(120) TYPE 'S'.
ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  select_all_entries
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_OUTTAB  text
*----------------------------------------------------------------------*
FORM select_all_entries300 CHANGING pt_outtab TYPE STANDARD TABLE.

  DATA: ls_outtab TYPE t_output300.
  DATA: l_valid TYPE c.

  " Copy original table
  DATA(lit_buffer) = gt_outtab300[].

  my_application300->my_grid300->get_filtered_entries(
    IMPORTING
      et_filtered_entries =  DATA(lit_index)             " Hashed Table of Filtered Entries
  ).

  SORT lit_index DESCENDING.

  LOOP AT lit_index ASSIGNING FIELD-SYMBOL(<index>).
    DELETE lit_buffer INDEX <index>.
  ENDLOOP.

  CALL METHOD my_application300->my_grid300->check_changed_data
    IMPORTING
      e_valid = l_valid.

  IF l_valid EQ 'X'.

    LOOP AT lit_buffer INTO DATA(lis_buffer).

      LOOP AT pt_outtab INTO ls_outtab.

        IF ls_outtab-role = lis_buffer-role.

          ls_outtab-selected = 'X'.

          MODIFY pt_outtab FROM ls_outtab.

        ENDIF.

      ENDLOOP.

    ENDLOOP.

    CALL METHOD my_application300->my_grid300->refresh_table_display.

  ENDIF.

ENDFORM.                               " select_all_entries


*&---------------------------------------------------------------------*
*&      Form  deselect_all_entries
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_OUTTAB[]  text
*----------------------------------------------------------------------*
FORM deselect_all_entries300 CHANGING pt_outtab TYPE STANDARD TABLE.

  DATA: ls_outtab TYPE t_output300.
  DATA: l_valid TYPE c.

  " Copy original table
  DATA(lit_buffer) = gt_outtab300[].

  my_application300->my_grid300->get_filtered_entries(
    IMPORTING
      et_filtered_entries =  DATA(lit_index)             " Hashed Table of Filtered Entries
  ).

  SORT lit_index DESCENDING.

  LOOP AT lit_index ASSIGNING FIELD-SYMBOL(<index>).
    DELETE lit_buffer INDEX <index>.
  ENDLOOP.


  CALL METHOD my_application300->my_grid300->check_changed_data
    IMPORTING
      e_valid = l_valid.

  IF l_valid EQ 'X'.

    LOOP AT lit_buffer INTO DATA(lis_buffer).

      LOOP AT pt_outtab INTO ls_outtab.

        IF ls_outtab-role = lis_buffer-role.

          ls_outtab-selected = ' '.

          MODIFY pt_outtab FROM ls_outtab.

        ENDIF.

      ENDLOOP.

    ENDLOOP.

    CALL METHOD my_application300->my_grid300->refresh_table_display.

  ENDIF.

ENDFORM.                               " deselect_all_entries


*&---------------------------------------------------------------------*
*&      Form  CHECK_FOR_CHANGES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  <--  exit        text
*----------------------------------------------------------------------*
FORM check_for_changes300 CHANGING exit.

  DATA: answer(1).

  PERFORM update_selection300 CHANGING gt_outtab300[].

  " check if data was chnaged, if yes show popup to save
  IF d300_roles_input NE gt_outtab300.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar       = 'Selection has been changed'(110)
        text_question  = 'Save selection?'(133)
        text_button_1  = 'Yes'(111)
        text_button_2  = 'No'(112)
      IMPORTING
        answer         = answer
      EXCEPTIONS
        text_not_found = 1
        OTHERS         = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.

      CASE answer.
        WHEN '1'.
          PERFORM save_table300.
          exit = abap_true.

        WHEN '2'.
          exit = abap_true.

        WHEN OTHERS.
          exit = abap_false.
          MESSAGE 'Action cancelled'(121) TYPE 'E'.
          EXIT.
      ENDCASE.

    ENDIF.

  ENDIF.

  exit = abap_true.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  EXIT_PROGRAM_200
*&---------------------------------------------------------------------*
FORM exit_program_300.
* Destroy Control.
  IF my_application300 IS NOT INITIAL AND
     my_application300->my_grid300 IS NOT INITIAL.
    CALL METHOD my_application300->my_grid300->free
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc NE 0.
*     add your handling
    ENDIF.
*   free ABAP object also
    FREE my_application300->my_grid300.
  ENDIF.

  CLEAR my_application300.

* destroy container
  IF NOT my_container300 IS INITIAL.
    CALL METHOD my_container300->free
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc NE 0.
*     add your handling
    ENDIF.
*   free ABAP object also
    FREE my_container300.
  ENDIF.

* finally flush
  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      OTHERS = 1.
  IF sy-subrc NE 0.
*   add your handling
  ENDIF.

ENDFORM.                               " EXIT_PROGRAM