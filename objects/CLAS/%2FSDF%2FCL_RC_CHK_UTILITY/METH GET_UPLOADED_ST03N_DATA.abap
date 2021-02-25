METHOD get_uploaded_st03n_data.

  CONSTANTS:
    BEGIN OF c_data,
        st03_src_system        TYPE string VALUE 'ST03NSrcSystem',
        st03_src_system_client TYPE string VALUE 'ST03NSrcSystemClient',
        st03_src_utc_timestamp TYPE string VALUE 'ST03NSrcUTCTimestamp',
        st03_src_num_of_month  TYPE string VALUE 'ST03NSrcNumOfMonth',
        st03_file_name         TYPE string VALUE 'st03n_data.xml',
      END OF c_data .
  CONSTANTS:
       lc_time_zone_utc         TYPE  systzonlo  VALUE   'UTC'.

  DATA: lt_header              TYPE ty_name_value_pair_tab,
        ls_header              TYPE ty_name_value_pair_str,
        ls_content_data        TYPE srtm_datax,
        lv_st03n_download_time TYPE timestamp,
        lv_time_now            TYPE timestamp,
        lv_time_difference     TYPE i,
        lv_time_age_second     TYPE i,
        lv_sum_of_st03_entry   TYPE i,
        lv_download_time_str   TYPE string,
        lv_download_system     TYPE string,
        lv_download_client     TYPE string,
        lv_download_sys_log    TYPE string,
        lv_timestamp_c(50)     TYPE c.

  CLEAR: et_usage_report, et_usage_trans, et_usage_rfc, et_usage_url, ev_info_str, ev_month_of_usg.

*--------------------------------------------------------------------*
* Use the buffered data

  et_usage_report = st_usage_report.
  et_usage_trans  = st_usage_trans.
  et_usage_rfc    = st_usage_rfc.
  et_usage_url    = st_usage_url.
  ev_month_of_usg = sv_month_of_usg.
  lv_sum_of_st03_entry = lines( st_usage_report ) + lines( st_usage_trans ) + lines( st_usage_rfc ) + lines( st_usage_url ).
  CHECK lv_sum_of_st03_entry = 0.


*--------------------------------------------------------------------*
* Read the uploaded ST03N data through report TMW_RC_MANAGE_ST03N_DATA
* Refer to SAP Note 2568736

  SELECT SINGLE * FROM srtm_datax INTO ls_content_data
    WHERE trigid     = c_data_key_new-data_trigid
      AND trigoffset = c_data_key_new-data_trigoffset
      AND subid      = c_data_key_new-subid_st03n_data.
  CHECK sy-subrc = 0.

  TRY.
      CALL TRANSFORMATION id SOURCE XML ls_content_data-xtext
        RESULT usage_report = et_usage_report
               usage_trans  = et_usage_trans
               usage_rfc    = et_usage_rfc
               usage_url    = et_usage_url
               header_data  = lt_header.
    CATCH cx_root.
      RETURN.
  ENDTRY.


*--------------------------------------------------------------------*
* Check the data is not obsolete

  READ TABLE lt_header INTO ls_header
    WITH KEY name = c_data-st03_src_utc_timestamp.
  CHECK sy-subrc = 0.
  lv_st03n_download_time = ls_header-value.
  GET TIME STAMP FIELD lv_time_now.
  CALL FUNCTION 'TIMECALC_DIFF'
    EXPORTING
      timestamp1 = lv_st03n_download_time
      timestamp2 = lv_time_now
      timezone   = 'UTC'
    IMPORTING
      difference = lv_time_difference.
  lv_time_age_second = 60 * 60 * 24 * 30.                   " 30 days
  IF lv_time_difference > lv_time_age_second.
    CLEAR: et_usage_report, et_usage_trans, et_usage_rfc, et_usage_url.
    RETURN.
  ENDIF.

  "Buffer the data
  st_usage_report = et_usage_report.
  st_usage_trans  = et_usage_trans.
  st_usage_rfc    = et_usage_rfc.
  st_usage_url    = et_usage_url.

  READ TABLE lt_header INTO ls_header
    WITH KEY name = c_data-st03_src_num_of_month.
  IF sy-subrc = 0.
    ev_month_of_usg = ls_header-value.
    sv_month_of_usg = ev_month_of_usg.
  ENDIF.


*--------------------------------------------------------------------*
* Prepare meta data for the ST03 data

  WRITE lv_st03n_download_time TO lv_timestamp_c TIME ZONE lc_time_zone_utc.
  CONCATENATE lv_timestamp_c 'UTC' INTO lv_download_time_str SEPARATED BY space.

  READ TABLE lt_header INTO ls_header
    WITH KEY name = c_data-st03_src_system.
  lv_download_system = ls_header-value.
  READ TABLE lt_header INTO ls_header
    WITH KEY name = c_data-st03_src_system_client.
  lv_download_client = ls_header-value.
  CONCATENATE lv_download_system '/' lv_download_client INTO lv_download_sys_log.

  "Manually uploaded ST03N data downloaded from &P1& at &P2& is used for relevance check.
  ev_info_str = /sdf/cl_rc_chk_utility=>get_text_str(
    iv_txt_key = '079'
    iv_para1   = lv_download_sys_log
    iv_para2   = lv_download_time_str ).

ENDMETHOD.