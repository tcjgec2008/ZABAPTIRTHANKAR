FUNCTION /sdf/gen_funcs_s4_sicmeta.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(IV_URL) TYPE  STRING
*"  EXPORTING
*"     VALUE(EV_CONTENT) TYPE  XSTRING
*"     VALUE(EV_MSG) TYPE  STRING
*"----------------------------------------------------------------------

  /sdf/cl_rc_chk_utility=>smdb_content_fetch_from_sap_ds(
    EXPORTING
      iv_url      = iv_url
    IMPORTING
      ev_content  = ev_content
      ev_msg      = ev_msg
  ).

ENDFUNCTION.