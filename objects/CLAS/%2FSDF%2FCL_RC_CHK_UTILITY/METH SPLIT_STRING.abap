METHOD split_string.

  DATA: lv_length        TYPE i,
        lv_offset        TYPE i,
        lv_length_plus1  TYPE i,
        lv_length_minus1 TYPE i,
        lv_char          TYPE char1.

  CLEAR: ev_msgv, ev_rest.
  CHECK iv_string IS NOT INITIAL.

  lv_length_plus1  = iv_text_length + 1. "iv_text_length
  lv_length_minus1 = iv_text_length - 1.

*--------------------------------------------------------------------*
* Return the string if it's less than target number of characters (e.g. 120)

  IF STRLEN( iv_string ) <= iv_text_length.
    ev_msgv = iv_string.
    RETURN.
  ENDIF.


*--------------------------------------------------------------------*
* Split at position target number + 1 (e.g. 121) if it happens to be a space

  lv_char = iv_string+iv_text_length(1).
  IF lv_char = ' '. " At position 121 is a space.
    ev_msgv = iv_string(iv_text_length).
    ev_rest = iv_string+lv_length_plus1.
    RETURN.
  ENDIF.


*--------------------------------------------------------------------*
* Split at position target number + 1 (e.g. 121) if the string contains no space at all

  IF iv_string NA ' '."Contains Not Any
    ev_msgv = iv_string(iv_text_length).
    ev_rest = iv_string+iv_text_length.
    RETURN.
  ENDIF.


*--------------------------------------------------------------------*
* Split at the last space before character at position target number (e.g. 120)

  lv_length = iv_text_length.
  lv_offset = lv_length_minus1.

  DO iv_text_length TIMES.

    lv_char = iv_string+lv_offset(1).
    IF lv_char <> ' '.

      SUBTRACT 1 FROM lv_length.
      SUBTRACT 1 FROM lv_offset.
      CONTINUE.
    ELSE.
      ev_msgv = iv_string(lv_length).
      ADD 1 TO lv_offset.
      ev_rest = iv_string+lv_offset.
      RETURN.
    ENDIF.

  ENDDO.

ENDMETHOD.