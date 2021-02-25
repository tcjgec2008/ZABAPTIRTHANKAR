method _is_hr_active.

  data:
    lv_is_s4     type boole_d,
    ls_t77s0     type t77s0,
    lv_hr_active type boole_d.

*--------------------------------------------------------------------------------
*--- Determine if S/4 system
*--------------------------------------------------------------------------------
  try.
      call method ('CL_COS_UTILITIES')=>('IS_S4H')
        receiving
          rv_is_s4h = lv_is_s4.
    catch cx_root.
      clear lv_is_s4.
  endtry.

*--------------------------------------------------------------------------------
*--- HR usage checck is different in S/4 and non S/4 systems
*--- Selects are extracted from FM BP_BUPA_CHECK_HR_IS_ACTIVE
*--------------------------------------------------------------------------------
  select single * from t77s0 using client @i_client into @ls_t77s0 where semid = 'HRAC'. "#EC CI_NOORDER

  if ls_t77s0-gsval is initial.
    clear lv_hr_active.
  else.
    clear ls_t77s0.
    if lv_is_s4 = 'X'.
      select single * from t77s0 using client @i_client into @ls_t77s0 where semid = 'PBPON'. "#EC CI_NOORDER
    else.
      select single * from t77s0 using client @i_client into @ls_t77s0 where semid = 'PBPHR'. "#EC CI_NOORDER
    endif.
    if ls_t77s0-gsval = 'ON'.
      lv_hr_active = 'X'.
    endif.
  endif.

*--------------------------------------------------------------------------------
*--- Return result
*--------------------------------------------------------------------------------
  e_hr_active = lv_hr_active.

endmethod.