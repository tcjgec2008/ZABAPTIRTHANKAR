METHOD check_relevance.

*  DATA: lt_table_name    TYPE TABLE OF tabname,
*        lv_table_name    TYPE tabname,
*        lv_subrc         LIKE sy-subrc,
*        lv_entry_count   TYPE i.
*
***********************************************************************
** Sample code according to https://wiki.wdf.sap.corp/wiki/x/lPo0bw
** 1. Don't use this method if Simple Check is enough; refer to
**  https://wiki.wdf.sap.corp/wiki/x/-xR1b#SAPS/4HANATransitionDB/SimplificationList-SimpleCheck
** 2. Delete this method if you don't need it
***********************************************************************
*
*  CLEAR: ev_relevance, ev_description.
*
**--------------------------------------------------------------------*
** Load the DB based check rule definition
** If the table does not exist in the system, then the item is not relevant.
*
*  APPEND 'KOMK'  TO lt_table_name.
*  APPEND 'KOMP'  TO lt_table_name.
*  APPEND 'KONP'  TO lt_table_name.
*
*  LOOP AT lt_table_name INTO lv_table_name.
*
*    CALL FUNCTION 'DB_EXISTS_TABLE'
*      EXPORTING
*        tabname = lv_table_name
*      IMPORTING
*        subrc   = lv_subrc.
*    IF lv_subrc = 0.
*
*      CLEAR lv_entry_count.
*      SELECT COUNT( * ) INTO lv_entry_count
*             FROM (lv_table_name) CLIENT SPECIFIED.
*      IF lv_entry_count > 0.
*        ev_relevance = c_pre_chk_relevance-yes.
*        ev_description = 'Item is relevant since non-empty database table &P1& exists in the system'."#EC NOTEXT
*        REPLACE ALL OCCURRENCES OF '&P1&' IN ev_description WITH lv_table_name.
*        RETURN.
*      ENDIF.
*
*    ENDIF.
*  ENDLOOP.
*
*  ev_relevance = c_pre_chk_relevance-no.
*  ev_description = 'Item is not relevant since no target database table entries exists in the system'."#EC NOTEXT
*  REPLACE ALL OCCURRENCES OF '&P1&' IN ev_description WITH lv_table_name.

ENDMETHOD.