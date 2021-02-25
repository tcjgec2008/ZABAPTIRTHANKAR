METHOD cleanup_string.

  DATA: lv_string TYPE string.

  lv_string = iv_field_value.

  "Remove leading ' and "
  SHIFT lv_string LEFT DELETING LEADING ''''.
  SHIFT lv_string LEFT DELETING LEADING '"'.
  SHIFT lv_string LEFT DELETING LEADING ''''.
  SHIFT lv_string LEFT DELETING LEADING '"'.

  "Remove ending ' and "
  SHIFT lv_string RIGHT DELETING TRAILING ''''.
  SHIFT lv_string RIGHT DELETING TRAILING '"'.
  SHIFT lv_string RIGHT DELETING TRAILING ''''.
  SHIFT lv_string RIGHT DELETING TRAILING '"'.

  "Remove leading and ending space
  SHIFT lv_string LEFT DELETING LEADING space.
  SHIFT lv_string RIGHT DELETING TRAILING space.

  rv_field_value = lv_string.

ENDMETHOD.