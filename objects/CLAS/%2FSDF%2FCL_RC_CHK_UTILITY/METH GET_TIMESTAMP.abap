METHOD get_timestamp.

  DATA: lv_timestamp_c(50) TYPE c.

  CLEAR: ev_timestamp_utc, ev_timestamp_wh_timezone.

  "Get current time stamp and convert:
  GET TIME STAMP FIELD ev_timestamp_utc.

  "Convert UTC to user's specified format (System -> User Profile -> Own Data):
  WRITE ev_timestamp_utc TO lv_timestamp_c TIME ZONE sy-zonlo.

  "Add timezone to time/date string, as per standard in work centers:
  CONCATENATE lv_timestamp_c sy-zonlo INTO ev_timestamp_wh_timezone SEPARATED BY space.

  WRITE ev_timestamp_utc TO lv_timestamp_c TIME ZONE c_time_zone_utc.
  CONCATENATE lv_timestamp_c 'UTC' INTO ev_timestamp_utc_str SEPARATED BY space.

ENDMETHOD.