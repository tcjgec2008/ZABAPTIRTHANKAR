METHOD get_led_icon_from_timestamp.

*--------------------------------------------------------------------*
*#  LED ICON:
*  o  Green: the new version download from SAP successfully or upload by manual successfully. The update date is not older than 3 weeks.
*  o  Watch:  the new version download from SAP successfully or upload by manual successfully. The update date is older than 3 weeks.
*  o  Red: No active version in local source.

  DATA: lv_time_utc_expired TYPE timestamp,
        lv_time_utc_current TYPE timestamp,
        lv_expired_seconds  TYPE int4,
        lv_str              TYPE string,
        lv_date             TYPE dats,
        lv_exp_date         TYPE dats.

  IF iv_time IS NOT INITIAL.
    lv_expired_seconds = 21 * 24 * 60 * 60.

    TRY.
        lv_time_utc_expired = cl_abap_tstmp=>add(
         tstmp = iv_time
         secs  = lv_expired_seconds ).
      CATCH cx_parameter_invalid_range cx_parameter_invalid_type.
    ENDTRY.

    IF lv_time_utc_expired IS INITIAL.

      lv_str = iv_time.
      lv_date = lv_str.

      lv_exp_date = lv_date + 21.
      IF lv_exp_date < sy-datum.
        rv_icon = icon_time_ina.
      ELSE.
        rv_icon = icon_led_green.
      ENDIF.

    ELSE.

      GET TIME STAMP FIELD lv_time_utc_current.
      IF lv_time_utc_expired < lv_time_utc_current.
        rv_icon = icon_time_ina.
      ELSE.
        rv_icon = icon_led_green.
      ENDIF.
    ENDIF.

  ELSE.
    rv_icon = icon_led_red.
  ENDIF.

ENDMETHOD.