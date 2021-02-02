*&---------------------------------------------------------------------*
*& Report ZDEVOPS4_REPO
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZDEVOPS4_REPO.


*Write: 'Hello Azure and S4A'.
DATA: gd_fcurr TYPE tcurr-fcurr,
      gd_tcurr TYPE tcurr-tcurr,
      gd_date  TYPE sy-datum,
      gd_value TYPE i.
gd_fcurr = 'EUR'.
gd_tcurr = 'GBP'.
gd_date  = sy-datum.
gd_value = 10.

PERFORM currency_conversion USING gd_fcurr
                                  gd_tcurr
                                  gd_date
                         CHANGING gd_value.
* Convert value to Currency value
*&---------------------------------------------------------------------*
*&      Form  currency_conversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GD_FCURR  text
*      -->P_GD_TCURR  text
*      -->P_GD_DATE   text
*      <--P_GD_VALUE  text
*----------------------------------------------------------------------*
FORM currency_conversion  USING    p_fcurr
                                   p_tcurr
                                   p_date
                          CHANGING p_value.
  DATA: t_er        TYPE tcurr-ukurs,
        t_ff        TYPE tcurr-ffact,
        t_lf        TYPE tcurr-tfact,
        t_vfd       TYPE datum,
        ld_erate(12)   TYPE c.
  CALL FUNCTION 'READ_EXCHANGE_RATE'
    EXPORTING
*       CLIENT                  = SY-MANDT
      date                    = p_date
      foreign_currency        = p_fcurr
      local_currency          = p_tcurr
      TYPE_OF_RATE            = 'M'
*       EXACT_DATE              = ' '
   IMPORTING
      exchange_rate           = t_er
      foreign_factor          = t_ff
      local_factor            = t_lf
      valid_from_date         = t_vfd
*       DERIVED_RATE_TYPE       =
*       FIXED_RATE              =
*       OLDEST_RATE_FROM        =
   EXCEPTIONS
     no_rate_found           = 1
     no_factors_found        = 2
     no_spread_found         = 3
     derived_2_times         = 4
     overflow                = 5
     zero_rate               = 6
     OTHERS                  = 7
            .
  IF sy-subrc EQ 0.
    ld_erate = t_er / ( t_ff / t_lf ).
    p_value = p_value * ld_erate.
  ENDIF.
ENDFORM.                    " currency_conversion