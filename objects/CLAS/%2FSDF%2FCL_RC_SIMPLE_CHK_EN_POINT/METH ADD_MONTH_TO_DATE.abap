METHOD add_month_to_date.

  DATA: BEGIN OF dat,
          jjjj(4),
          mm(2),
          tt(2),
        END OF dat,

        BEGIN OF hdat,
          jjjj(4),
          mm(2),
          tt(2),
        END OF hdat,
        newmm    TYPE p,
        diffjjjj TYPE p.

  WRITE:  iv_old_date+0(4) TO dat-jjjj,
          iv_old_date+4(2) TO dat-mm,
          iv_old_date+6(2) TO dat-tt.


*--------------------------------------------------------------------*
* Adjust date on month base; refer to FM RE_ADD_MONTH_TO_DATE

  diffjjjj =   ( dat-mm + iv_month_count - 1 ) DIV 12.
  newmm    =   ( dat-mm + iv_month_count - 1 ) MOD 12 + 1.
  dat-jjjj = dat-jjjj +  diffjjjj.

  IF newmm < 10.
    WRITE '0' TO  dat-mm+0(1).
    WRITE newmm TO  dat-mm+1(1).
  ELSE.
    WRITE newmm TO  dat-mm.
  ENDIF.
  IF dat-tt > '28'.
    hdat-tt = '01'.
    newmm   = ( dat-mm  )  MOD 12 + 1.
    hdat-jjjj = dat-jjjj + ( (  dat-mm ) DIV 12 ).

    IF newmm < 10.
      WRITE '0' TO hdat-mm+0(1).
      WRITE newmm TO hdat-mm+1(1).
    ELSE.
      WRITE newmm TO hdat-mm.
    ENDIF.

    IF dat-tt = '31'.
      rv_new_date = hdat.
      rv_new_date = rv_new_date - 1.
    ELSE.
      IF dat-mm = '02'.
        rv_new_date = hdat.
        rv_new_date = rv_new_date - 1.
      ELSE.
        rv_new_date = dat.
      ENDIF.
    ENDIF.
  ELSE.
    rv_new_date = dat.
  ENDIF.

ENDMETHOD.