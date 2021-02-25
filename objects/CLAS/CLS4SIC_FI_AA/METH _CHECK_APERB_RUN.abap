METHOD _check_aperb_run.
*--------------------------------------------------------------------*
*  check if the last RAPERB2000 finished successfully and
*     if there are no documents leftover that are still planned
*     to be posted (periodically)
*--------------------------------------------------------------------*
* PRECONDITION
  " None

* DEFINITIONS
  DATA:
    lv_run_status TYPE aperb_stat,
    lv_msg_text TYPE string.
  CONSTANTS:
    lc_successfuly_posted TYPE aperb_stat VALUE 'P'.

* BODY
* Check protocol if the last run has been finishes with success
  SELECT SINGLE status
    FROM aperb_prot
    CLIENT SPECIFIED
    INTO lv_run_status
   WHERE mandt  = mv_client
     AND bukrs  = iv_comp_code
     AND status <> lc_successfuly_posted.
  IF sy-subrc = 0.
    IF cls4sic_fi_aa=>gb_detailed_check = abap_true.
      lv_msg_text = 'Cocd &: Not all documents were updated in last run.'.
      REPLACE '&' IN lv_msg_text WITH iv_comp_code.
      _add_check_message(
         EXPORTING
           iv_description = lv_msg_text
           iv_check_sub_id = gc_check_sub_id-fiaa_periodic_posting
      ).
    ENDIF.
    RAISE error_last_run.
  ENDIF.


**The last run was successful.
* Then check if there are documents which have to be posted periodically
  _check_open_periodic_postings(
    EXPORTING
      iv_comp_code = iv_comp_code
      iv_depr_chart = iv_depr_chart
    EXCEPTIONS
      not_all_documents_posted = 1
  ).
  IF sy-subrc = 1.
    IF cls4sic_fi_aa=>gb_detailed_check = abap_true.
      MESSAGE e206(acc_aa) WITH iv_comp_code INTO lv_msg_text.
      _add_check_message(
           EXPORTING
             iv_description = lv_msg_text
             iv_check_sub_id = gc_check_sub_id-fiaa_periodic_posting
      ).
    ENDIF.
    RAISE error_doc_to_be_post.
  ENDIF.

* POSTCONDITION
  " None

ENDMETHOD.