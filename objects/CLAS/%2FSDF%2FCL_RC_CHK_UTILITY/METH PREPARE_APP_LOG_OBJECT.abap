METHOD prepare_app_log_object.

  DATA: ls_object       TYPE balobj,
        ls_object_txt   TYPE balobjt,
        ls_sub_obj      TYPE balsub,
        lt_sub_obj      TYPE TABLE OF balsub,
        ls_sub_obj_txt  TYPE balsubt,
        lt_sub_obj_txt  TYPE TABLE OF balsubt.

*--------------------------------------------------------------------*
* Automatically create app. log object to avoid manual effort and mistakes

  SELECT SINGLE * FROM balobj INTO ls_object
    WHERE object = c_app_log-object.
  IF sy-subrc <> 0.
    ls_object-object = c_app_log-object.
    MODIFY balobj FROM ls_object.

    ls_object_txt-spras  = c_langu_english.
    ls_object_txt-object = c_app_log-object.
    ls_object_txt-objtxt = get_text_str( iv_txt_key = 'A00' ).
    MODIFY balobjt FROM ls_object_txt.
  ENDIF.


*--------------------------------------------------------------------*
* Add application log sub-object

  SELECT SINGLE * FROM balsub INTO ls_sub_obj "#EC CI_GENBUFF
    WHERE subobject = c_app_log-sub_obj_smdb_source_chng.
  IF sy-subrc <> 0.
    ls_sub_obj-object    = c_app_log-object.
    ls_sub_obj-subobject = c_app_log-sub_obj_cons_check.
    APPEND ls_sub_obj TO lt_sub_obj.
    ls_sub_obj_txt-spras     = c_langu_english.
    ls_sub_obj_txt-object    = c_app_log-object.
    ls_sub_obj_txt-subobject = c_app_log-sub_obj_cons_check.
    ls_sub_obj_txt-subobjtxt = get_text_str( iv_txt_key = 'A01' )."Consistency Check
    APPEND ls_sub_obj_txt TO lt_sub_obj_txt.

    ls_sub_obj-object    = c_app_log-object.
    ls_sub_obj-subobject = c_app_log-sub_obj_cons_check_skip.
    APPEND ls_sub_obj TO lt_sub_obj.
    ls_sub_obj_txt-spras     = c_langu_english.
    ls_sub_obj_txt-object    = c_app_log-object.
    ls_sub_obj_txt-subobject = c_app_log-sub_obj_cons_check_skip.
    ls_sub_obj_txt-subobjtxt = get_text_str( iv_txt_key = 'A05' )."Item Consistency Check Exemption
    APPEND ls_sub_obj_txt TO lt_sub_obj_txt.


    ls_sub_obj-object    = c_app_log-object.
    ls_sub_obj-subobject = c_app_log-sub_obj_relevancy_check.
    APPEND ls_sub_obj TO lt_sub_obj.
    ls_sub_obj_txt-spras     = c_langu_english.
    ls_sub_obj_txt-object    = c_app_log-object.
    ls_sub_obj_txt-subobject = c_app_log-sub_obj_relevancy_check.
    ls_sub_obj_txt-subobjtxt = get_text_str( iv_txt_key = 'A08' )."Item relevance check
    APPEND ls_sub_obj_txt TO lt_sub_obj_txt.


    ls_sub_obj-object    = c_app_log-object.
    ls_sub_obj-subobject = c_app_log-sub_obj_smdb_source_chng.
    APPEND ls_sub_obj TO lt_sub_obj.
    ls_sub_obj_txt-spras     = c_langu_english.
    ls_sub_obj_txt-object    = c_app_log-object.
    ls_sub_obj_txt-subobject = c_app_log-sub_obj_smdb_source_chng.
    ls_sub_obj_txt-subobjtxt = get_text_str( iv_txt_key = 'A09' )."Simplificatin Item Catalog Source Change Log
    APPEND ls_sub_obj_txt TO lt_sub_obj_txt.


    INSERT balsub  FROM TABLE lt_sub_obj ACCEPTING DUPLICATE KEYS.
    INSERT balsubt FROM TABLE lt_sub_obj_txt ACCEPTING DUPLICATE KEYS.
  ENDIF.

ENDMETHOD.