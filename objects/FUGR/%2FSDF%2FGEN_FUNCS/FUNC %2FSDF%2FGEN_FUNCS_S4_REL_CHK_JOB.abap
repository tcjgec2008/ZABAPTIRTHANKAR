FUNCTION /sdf/gen_funcs_s4_rel_chk_job.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_TARGET_STACK) TYPE  CHAR20
*"     VALUE(IV_NO_CONS_CHECK) TYPE  FLAG OPTIONAL
*"----------------------------------------------------------------------

**********************************************************************
* API for report AGSRC_START_ANALYSIS run in remote SolMan system
* API for report TMW_RC_DOWNLOAD_ANALYSIS_DATA run locally
**********************************************************************
  DATA: lv_mesg_str      TYPE string,
        lv_jobcount      TYPE btcjobcnt,
        lv_job_name      TYPE btcjob VALUE 'RC_NEW_CHECK_IN_JOB'.

*--------------------------------------------------------------------*
* Schedule data collector in batch mode

  "Open job-planning without dialog
  CALL FUNCTION 'SET_PRINT_PARAMETERS'
    EXPORTING
      immediately = ''.
  CALL FUNCTION 'JOB_OPEN'
    EXPORTING
      jobname  = lv_job_name
    IMPORTING
      jobcount = lv_jobcount
    EXCEPTIONS
      OTHERS   = 1.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'W' NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    RETURN.
  ENDIF.

  "Submit the report as a job
  SUBMIT /sdf/rc_start_check
    WITH p_prd_st = iv_target_stack
    WITH p_ck_job = 'X'
    WITH p_no_con = iv_no_cons_check
    USER sy-uname
    VIA JOB lv_job_name NUMBER lv_jobcount
    AND RETURN.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'W' NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    RETURN.
  ENDIF.

  "Close the job
  CALL FUNCTION 'JOB_CLOSE'
    EXPORTING
      jobcount  = lv_jobcount
      jobname   = lv_job_name
      strtimmed = 'X'
    EXCEPTIONS
      OTHERS    = 1.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'W' NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    RETURN.
  ENDIF.

  MESSAGE 'Job RC_NEW_CHECK_IN_JOB scheduled; check the execution status in transaction SM37'(M00) TYPE 'I'. "#EC NOTEXT

ENDFUNCTION.