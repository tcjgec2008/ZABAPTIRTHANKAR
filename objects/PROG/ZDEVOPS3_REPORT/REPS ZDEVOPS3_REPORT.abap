*&---------------------------------------------------------------------*
*& Report ZDEVOPS3_REPORT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZDEVOPS3_REPORT.
*-------------------------------------------------------------*
*                                                             *
*-------------------------------------------------------------*
* Sub Total Text                                              *
*-------------------------------------------------------------*

*--- Table declaration
TABLES: ekko.


*-- Type pool declaration
TYPE-POOLS: slis.


*--- Selection screen

SELECT-OPTIONS: s_ebeln FOR ekko-ebeln.


*--- Type declaration
TYPES: BEGIN OF lty_ekpo,
       ebeln  TYPE char30,  " Document no.
       ebelp  TYPE ebelp,   " Item no
       matnr  TYPE matnr,   " Material no
       matnr1 TYPE matnr,   " Material no
       werks  TYPE werks_d, " Plant
       werks1 TYPE werks_d, " Plant
       ntgew  TYPE entge,   " Net weight
       gewe   TYPE egewe,   " Unit of weight
       END OF lty_ekpo.



*--- Internal table declaration
DATA: lt_ekpo            TYPE STANDARD TABLE OF lty_ekpo,
      lt_fieldcat        TYPE slis_t_fieldcat_alv,
      lt_alv_top_of_page TYPE slis_t_listheader,
      lt_events          TYPE slis_t_event,
      lt_sort            TYPE slis_t_sortinfo_alv,
      i_event            TYPE slis_t_event.


*--- Work area declaration
DATA: wa_ekko            TYPE lty_ekpo,
      wa_layout          TYPE slis_layout_alv,
      wa_events          TYPE slis_alv_event,
      wa_sort            TYPE slis_sortinfo_alv.



*--- Start-of-selection event
START-OF-SELECTION.

* Select data from ekpo
  SELECT ebeln " Doc no
         ebelp " Item
         matnr " Material
         matnr " Material
         werks " Plant
         werks " Plant
         ntgew " Quantity
         gewei " Unit
         FROM ekpo
         INTO TABLE lt_ekpo
         WHERE ebeln IN s_ebeln
         AND ntgew NE '0.00'
ENDSELECT.
  IF sy-subrc = 0.
    SORT lt_ekpo BY ebeln ebelp matnr .
  ENDIF.

*--- Field Catalog
  PERFORM f_field_catalog.

*--- Layout
  PERFORM f_build_layout.

* Perform to populate the sort table.
  PERFORM f_populate_sort.

* Perform to populate ALV event
  PERFORM f_get_event.

END-OF-SELECTION.

* Perform to display ALV report
  PERFORM f_alv_report_display.


*&---------------------------------------------------------------------*
*&      Form  sub_field_catalog
*&---------------------------------------------------------------------*
*       Build Field Catalog
*----------------------------------------------------------------------*
*       No Parameter
*----------------------------------------------------------------------*
FORM f_field_catalog .

  DATA: lwa_fcat TYPE slis_fieldcat_alv.

*  Build Field Catalog
  lwa_fcat-col_pos        =  1.           "Column
  lwa_fcat-fieldname      =  'EBELN'.     "Field Name
  lwa_fcat-tabname        =  'LT_EKPO'.   "Internal Table Name
  lwa_fcat-seltext_l      =  'Doc. No'.    "Field Text
  APPEND lwa_fcat TO lt_fieldcat.

  lwa_fcat-col_pos        =  2.           "Column
  lwa_fcat-fieldname      =  'EBELP'.     "Field Name
  lwa_fcat-tabname        =  'LT_EKPO'.   "Internal Table Name
  lwa_fcat-seltext_l      =  'Item No'.   "Field Text
  APPEND lwa_fcat TO lt_fieldcat.
  CLEAR:lwa_fcat.

  lwa_fcat-col_pos        =  3.           "Column
  lwa_fcat-fieldname      =  'WERKS1'.     "Field Name
  lwa_fcat-tabname        =  'LT_EKPO'.   "Internal Table Name
  lwa_fcat-seltext_l      =  'Plant'.     "Field Text
  APPEND lwa_fcat TO lt_fieldcat.
  CLEAR:lwa_fcat.

  lwa_fcat-col_pos        =  3.           "Column
  lwa_fcat-fieldname      =  'WERKS'.     "Field Name
  lwa_fcat-tabname        =  'LT_EKPO'.   "Internal Table Name
  lwa_fcat-no_out         =  'X'.
  lwa_fcat-tech           =  'X'.
  lwa_fcat-seltext_l      =  'Plant'.     "Field Text
  APPEND lwa_fcat TO lt_fieldcat.
  CLEAR:lwa_fcat.

  lwa_fcat-col_pos        =  4.           "Column
  lwa_fcat-fieldname      =  'MATNR1'.     "Field Name
  lwa_fcat-tabname        =  'LT_EKPO'.   "Internal Table Name
  lwa_fcat-seltext_l      =  'Material'.  "Field Text
  APPEND lwa_fcat TO lt_fieldcat.
  CLEAR:lwa_fcat.

  lwa_fcat-col_pos        =  4.           "Column
  lwa_fcat-fieldname      =  'MATNR'.     "Field Name
  lwa_fcat-tabname        =  'LT_EKPO'.   "Internal Table Name
  lwa_fcat-no_out         =  'X'.
  lwa_fcat-tech           =  'X'.
  lwa_fcat-seltext_l      =  'Material'.  "Field Text
  APPEND lwa_fcat TO lt_fieldcat.
  CLEAR:lwa_fcat.

  lwa_fcat-col_pos        =  5.           "Column
  lwa_fcat-fieldname      =  'NTGEW'.     "Field Name
  lwa_fcat-tabname        =  'LT_EKPO'.   "Internal Table Name
  lwa_fcat-seltext_l      =  'Quantity'.  "Field Text
  lwa_fcat-do_sum         = 'X'.          "Sum
  APPEND lwa_fcat TO lt_fieldcat.
  CLEAR:lwa_fcat.

  ENDFORM.                    " sub_field_catalog

*&---------------------------------------------------------------------*
*&      Form  f_populate_layout
*&---------------------------------------------------------------------*
*       Populate ALV layout
*----------------------------------------------------------------------*
*       No Parameter
*----------------------------------------------------------------------*
FORM f_build_layout.

  CLEAR wa_layout.
  wa_layout-colwidth_optimize = 'X'." Optimization of Col width

ENDFORM.                    " f_populate_layout

*&---------------------------------------------------------------------*
*&      Form  f_populate_sort
*&---------------------------------------------------------------------*
FORM f_populate_sort .

* Sort on plant
  wa_sort-spos = 1.
  wa_sort-fieldname = 'WERKS'.
  wa_sort-tabname = 'I_EKPO'.
  wa_sort-up = 'X'.
  wa_sort-subtot = 'X'.
  APPEND wa_sort TO lt_sort .
  CLEAR wa_sort.

* Sort on material
  wa_sort-spos = 2.
  wa_sort-fieldname = 'MATNR'.
  wa_sort-tabname = 'I_EKPO'.
  wa_sort-up = 'X'.
  wa_sort-subtot = 'X'.
  APPEND wa_sort TO lt_sort .
  CLEAR wa_sort.

ENDFORM.                    " f_populate_sort

*&---------------------------------------------------------------------*
*&      Form  f_get_event
*&---------------------------------------------------------------------*
FORM f_get_event.

  DATA: lwa_event TYPE slis_alv_event.

  CALL FUNCTION 'REUSE_ALV_EVENTS_GET'
    IMPORTING
      et_events       = lt_events
    EXCEPTIONS
      list_type_wrong = 0
      OTHERS          = 0.

* Subtotal
  READ TABLE lt_events  INTO lwa_event
                    WITH KEY name = slis_ev_subtotal_text.
  IF sy-subrc = 0.
    lwa_event-form = 'SUBTOTAL_TEXT'.
    MODIFY lt_events FROM lwa_event INDEX sy-tabix.
  ENDIF.

ENDFORM.                    " f_get_event


*&---------------------------------------------------------------------*
*&      Form  f_alv_report_display
*&---------------------------------------------------------------------*
FORM f_alv_report_display .

* ALV report
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = sy-repid
      is_layout                = wa_layout
      it_fieldcat              = lt_fieldcat
      it_sort                  = lt_sort
      it_events                = lt_events
    TABLES
      t_outtab                 = lt_ekpo
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.
  IF sy-subrc <> 0.
  ENDIF.

ENDFORM.                    " f_alv_report_display
*&---------------------------------------------------------------------*
*&      Form  subtotal_text
*&---------------------------------------------------------------------*
*       Build subtotal text
*----------------------------------------------------------------------*
FORM subtotal_text CHANGING
               p_total TYPE any
               p_subtot_text TYPE slis_subtot_text.


* Material level sub total
  IF p_subtot_text-criteria = 'MATNR'.
    p_subtot_text-display_text_for_subtotal = 'Material Level Sub-Total'.
  ENDIF.

* Plant level sub total
  IF p_subtot_text-criteria = 'WERKS'.
    p_subtot_text-display_text_for_subtotal = 'Plant Level Sub-Total'.
  ENDIF.


ENDFORM.                    "subtotal_text