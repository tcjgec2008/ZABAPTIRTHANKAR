private section.

  class-methods HAS_DUPLICATES
    returning
      value(RV_HAS_DUPLICATES) type BOOLE_D .
  class-methods GET_DUPLICATES
    exporting
      !ET_DUPLICATES type TY_DUPLICATES .
  class-methods CREATE_SIMPLE_ABORTION
    returning
      value(RS_CHK_RESULT) type TY_PRE_CONS_CHK_RESULT_STR .
  class-methods CREATE_ABORTION
    importing
      !IS_DUPLICATE type TY_DUPLICATE_ID
    returning
      value(RS_CHK_RESULT) type TY_PRE_CONS_CHK_RESULT_STR .
  class-methods IS_DETAILED_CHECK
    importing
      !IT_PARAMETER type TIHTTPNVP
    returning
      value(RV_DETAILED_CHECK) type BOOLE_D .