METHOD smdb_content_upload.

  DATA:lv_default_file_name     TYPE string VALUE 'SimplificationItemCatalog.zip',
       lt_selected_file         TYPE filetable,
       ls_selected_file         TYPE LINE OF filetable,
       lv_return_code           TYPE i,
       lv_user_action           TYPE i,
       lv_usract                TYPE c LENGTH 10,
       lv_subrc                 TYPE c LENGTH 5,
       lv_file_path             TYPE string,
       lv_file_line             TYPE x LENGTH 1000,
       lt_file_table            LIKE TABLE OF lv_file_line,
       lv_file_data             TYPE xstring,
       lv_db_download_time_new  TYPE timestamp,
       lv_db_download_time_old  TYPE timestamp,
       lv_download_time_new_str TYPE string,
       lv_download_time_old_str TYPE string,
       ls_content_data          TYPE srtm_datax,
       lv_timestamp_c(50)       TYPE c,
       lv_answer                TYPE c LENGTH 1.

  DEFINE exit_upload.
    "Remove content feteched from SAP so that only manual uploaded content is used
    select single * from srtm_datax into ls_content_data
      where trigid     = c_data_key_new-data_trigid
        and trigoffset = c_data_key_new-data_trigoffset
        and subid      = c_data_key_new-subid_smdb_content_upload.
    if sy-subrc = 0.
      delete from srtm_datax
        where trigid     = c_data_key_new-data_trigid
          and trigoffset = c_data_key_new-data_trigoffset
          and subid      = c_data_key_new-subid_smdb_content_latest_sap.
    endif.
    return.
  END-OF-DEFINITION.

  CLEAR rv_err_mesg_str.

*--------------------------------------------------------------------*
* Display a pop-up for user to specify the data file

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      default_filename  = lv_default_file_name
      multiselection    = abap_false
      file_filter       = 'Zip File|*.zip|'                 "#EC NOTEXT
      default_extension = 'ZIP'                             "#EC NOTEXT
    CHANGING
      file_table        = lt_selected_file
      rc                = lv_return_code
      user_action       = lv_user_action
    EXCEPTIONS
      OTHERS            = 1 ).
  IF sy-subrc <> 0.
    "File Open dialog failed; Simplification Item content not uploaded
    rv_err_mesg_str = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '052' ).
    exit_upload.
  ELSE.
    IF lv_user_action = cl_gui_frontend_services=>action_cancel.
      "The action is cancelled
      rv_err_mesg_str = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '032' ).
      exit_upload.
    ENDIF.
  ENDIF.


*--------------------------------------------------------------------*
* Load the content as ZIP

  READ TABLE lt_selected_file INTO ls_selected_file INDEX 1.
  lv_file_path = ls_selected_file-filename.
  cl_gui_frontend_services=>gui_upload(
    EXPORTING
      filename = lv_file_path
      filetype = 'BIN'
    CHANGING
      data_tab = lt_file_table
    EXCEPTIONS
      OTHERS   = 1  ).
  IF sy-subrc <> 0.
    "File Open dialog failed; Simplification Item content not uploaded
    rv_err_mesg_str = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '052' ).
    exit_upload.
  ENDIF.


*--------------------------------------------------------------------*
* Check the content

  LOOP AT lt_file_table INTO lv_file_line.
    CONCATENATE lv_file_data lv_file_line INTO lv_file_data IN BYTE MODE.
  ENDLOOP.
  lv_db_download_time_new = smdb_content_upload_time_get( iv_file_data = lv_file_data ).
  IF lv_db_download_time_new IS INITIAL.
    "Illegal content file; check the file selected
    rv_err_mesg_str = get_text_str( iv_txt_key = '027' ) .
    exit_upload.
  ENDIF.
  WRITE lv_db_download_time_new TO lv_timestamp_c TIME ZONE c_time_zone_utc.
  CONCATENATE lv_timestamp_c 'UTC' INTO lv_download_time_new_str SEPARATED BY space.


  /sdf/cl_rc_chk_utility=>smdb_content_time_get(
    IMPORTING
      ev_time_utc_manual     = lv_db_download_time_old
      ev_time_utc_manual_str = lv_download_time_old_str ).

  IF lv_db_download_time_old IS NOT INITIAL.
*    "Selected Simplification Item content was downloaded at &P1&; continue for uploading?
*    sv_message = /sdf/cl_rc_chk_utility=>get_text_str(
*      iv_txt_key = '053'
*      iv_para1   = lv_download_time_new_str ).
*  ELSE.
    "Selected Simplification Item content was downloaded at &P1&, current Simplification Item content stored in the system was downloaded at &P2&. Continue to overwrite?
    sv_message = /sdf/cl_rc_chk_utility=>get_text_str(
      iv_txt_key = '054'
      iv_para1   = lv_download_time_new_str
      iv_para2   = lv_download_time_old_str ).

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        text_question         = sv_message
        icon_button_1         = 'ICON_OKAY'
        icon_button_2         = 'ICON_CANCEL'
        display_cancel_button = ' '
      IMPORTING
        answer                = lv_answer
      EXCEPTIONS
        text_not_found        = 1
        OTHERS                = 2.
    IF lv_answer <> '1'.
      "The action is cancelled
      rv_err_mesg_str = /sdf/cl_rc_chk_utility=>get_text_str( iv_txt_key = '032' ).
      exit_upload.
    ENDIF.
  ENDIF.


*--------------------------------------------------------------------*
* Store the data into DB
* We do not use the MIME since transport registration is needed

  ls_content_data-trigid     = c_data_key_new-data_trigid.
  ls_content_data-trigoffset = c_data_key_new-data_trigoffset.
  ls_content_data-subid      = c_data_key_new-subid_smdb_content_upload.
  ls_content_data-ddate      = sy-datum.
  ls_content_data-dtime      = sy-uzeit.
  ls_content_data-xtext      = lv_file_data.
  MODIFY srtm_datax FROM ls_content_data.


*--------------------------------------------------------------------*
* Triggering a reload to use the new content

  get_smdb_content(
    EXPORTING
      iv_reload = abap_true
    EXCEPTIONS
      OTHERS    = 0 ).

  exit_upload.

ENDMETHOD.