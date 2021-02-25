METHOD get_smdb_content.

  CLEAR: ev_smdb_zip_xtr, et_header, et_sitem, et_target_release, et_source_release, et_check, et_check_db,
         et_conv_target_stack, et_bw_conv_target_stack, et_note, et_app_comp,
         et_ppms_product, et_ppms_prod_version, et_ppms_stack,
         et_piece_list, ev_time_utc, ev_time_utc_str, et_smdb_note_req, et_rc_note_req.

  IF iv_reload IS NOT INITIAL.
    CLEAR: sv_smdb_zip_xtr.
  ENDIF.

  IF sv_smdb_zip_xtr IS INITIAL.
    smdb_content_load(
     IMPORTING
       ev_smdb_zip_xtr         = sv_smdb_zip_xtr
       et_header               = st_header
       et_sitem                = st_sitem
       et_source_release       = st_source_release
       et_target_release       = st_target_release
       et_check                = st_check
       et_check_db             = st_check_db
       et_conv_target_stack    = st_conv_target_stack
       et_bw_conv_target_stack = st_bw_conv_target_stack
       et_note                 = st_note
       et_app_comp             = st_app_comp
       et_ppms_product         = st_ppms_product
       et_ppms_prod_version    = st_ppms_prod_version
       et_ppms_stack           = st_ppms_stack
       et_piece_list           = st_piece_list
       ev_time_utc             = sv_time_utc
       ev_time_utc_str         = sv_time_utc_str
       et_smdb_note_req        = st_smdb_note_req
       et_rc_note_req          = st_rc_note_req
       et_lob                  = st_lob
     EXCEPTIONS
       error                   = 1
       OTHERS                  = 2 ).
    IF sy-subrc <> 0 OR st_sitem IS INITIAL.
      RAISE smdb_contnet_not_found.
    ENDIF.
  ENDIF.

  ev_smdb_zip_xtr         = sv_smdb_zip_xtr.
  et_header               = st_header.
  et_sitem                = st_sitem.
  et_source_release       = st_source_release.
  et_target_release       = st_target_release.
  et_check                = st_check.
  et_check_db             = st_check_db.
  et_conv_target_stack    = st_conv_target_stack.
  et_bw_conv_target_stack = st_bw_conv_target_stack.
  et_note                 = st_note.
  et_app_comp             = st_app_comp.
  et_ppms_product         = st_ppms_product.
  et_ppms_prod_version    = st_ppms_prod_version.
  et_ppms_stack           = st_ppms_stack.
  et_piece_list           = st_piece_list.
  ev_time_utc             = sv_time_utc.
  ev_time_utc_str         = sv_time_utc_str.
  et_smdb_note_req        = st_smdb_note_req.
  et_rc_note_req          = st_rc_note_req.
  et_lob                  = st_lob.

ENDMETHOD.