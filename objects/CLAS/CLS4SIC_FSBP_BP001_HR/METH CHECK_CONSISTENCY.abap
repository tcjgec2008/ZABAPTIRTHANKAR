method check_consistency.

  data:
    lt_clients    type table of t000,
    lt_chk_result type ty_pre_cons_chk_result_tab.

  field-symbols:
    <client>     type t000.

  clear et_chk_result.

*-------------------------------------------------------------------------
*--- Fetch clients
*-------------------------------------------------------------------------
  select * from t000 into table @lt_clients
    where mandt <> '000' and mandt <> '066'.

*-------------------------------------------------------------------------
*--- Execute consistency checks ín each client
*-------------------------------------------------------------------------
  loop at lt_clients assigning <client>.

    clear lt_chk_result.

    "--------------------------------------------------------------------
    "--- Initialize class attributes storing client Business Partner data
    "--------------------------------------------------------------------
    _initialize( i_client = <client>-mandt ).
    check partner_data is not initial.

    "--------------------------------------------------------------------
    "--- Execute consistency checks
    "--------------------------------------------------------------------
    append lines of check_bp001_but000_consistency( )
      to lt_chk_result.
    append lines of check_bp_category_person( )
      to lt_chk_result.
    append lines of check_role_category_bup003( i_client = <client>-mandt )
      to lt_chk_result.
    append lines of check_usr21_guid( i_client = <client>-mandt )
      to lt_chk_result.
    append lines of check_bp001_duplicates( )
      to lt_chk_result.


    if _is_hr_active( i_client = <client>-mandt ) = 'X'.
      append lines of check_consistency_hr_on( i_client = <client>-mandt )
        to lt_chk_result.
    else.
      append lines of check_consistency_hr_off( i_client = <client>-mandt )
        to lt_chk_result.
    endif.

    "--------------------------------------------------------------------
    "--- Add system and client information and append result list
    "--------------------------------------------------------------------
    _build_result_table(
      exporting
        i_client             = <client>-mandt
        it_runtime_parameter = it_parameter
      changing
        c_chk_result_tab     = lt_chk_result ).

    append lines of lt_chk_result to et_chk_result.

  endloop.
endmethod.