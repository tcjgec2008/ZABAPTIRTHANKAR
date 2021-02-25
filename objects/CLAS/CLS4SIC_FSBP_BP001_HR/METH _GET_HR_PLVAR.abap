method _get_hr_plvar.

  data:
        ls_t77s0 type t77s0.

  assert i_client is not initial.

**************************************************************
*** Determination logic taken from FM RH_GET_ACTIVE_WF_PLVAR
**************************************************************
  select single * from t77s0 using client @i_client into @ls_t77s0
      where grpid = 'PLOGI' and semid = 'WORKF'.

  if sy-subrc <> 0 or ls_t77s0-gsval is initial.
    clear ls_t77s0.
    select single * from t77s0 using client @i_client into @ls_t77s0
      where grpid = 'PLOGI' and semid = 'PLOGI'.
  endif.

  if ls_t77s0-gsval is initial.
    e_plan_version = '01'.
  else.
    e_plan_version = ls_t77s0-gsval.
  endif.

endmethod.