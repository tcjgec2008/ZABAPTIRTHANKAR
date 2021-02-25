METHOD refresh_check_result.

*--------------------------------------------------------------------*
* Consolidate lastest consistency check result

  CLEAR: et_check_result, mt_check_result.
  mt_check_result = it_check_result.

  add_consis_result_to_rel_chk( ).
  et_check_result = mt_check_result.

ENDMETHOD.