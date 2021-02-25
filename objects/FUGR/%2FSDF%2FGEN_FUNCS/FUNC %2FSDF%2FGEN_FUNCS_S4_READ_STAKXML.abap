FUNCTION /sdf/gen_funcs_s4_read_stakxml.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(EV_TARGET_STACK) TYPE  BORM_ID
*"----------------------------------------------------------------------

  DATA: lv_queue_id       TYPE queue_id,
        lt_stackheadr     TYPE TABLE OF stackheadr,
        ls_stackheadr     TYPE stackheadr,
        lt_target_stack   TYPE /sdf/cl_rc_chk_utility=>ty_conv_target_stack_tab,
        ls_target_stack   TYPE /sdf/cl_rc_chk_utility=>ty_conv_target_stack_str,
        lv_mesg_text      TYPE string,
        lt_uvers          TYPE TABLE OF uvers,
        ls_uvers          TYPE uvers.

*--------------------------------------------------------------------*
* Get S/4HANA conversion target

  /sdf/cl_rc_chk_utility=>get_smdb_content(
    IMPORTING
      et_conv_target_stack = lt_target_stack
    EXCEPTIONS
      OTHERS               = 1 ).
  CHECK sy-subrc = 0."Check before; no error expected


*--------------------------------------------------------------------*
* In SUM mode; the target stack can be read from stack.xml
* We want to know the target S/4HANA SP stack described in the stack.xml.
* The information is available but only after the stack.xml was evaluated
* (by FM SPDA_GET_STACK_INFO) after the SUM prepare phase SEL_STACK_XML_READ.
* The SP stack information is written into table STACKHEADR.
* Since pre-check is executed (in phase RUN_S4H_PRE_CHECK_INIT ) after
* "prepare phase SEL_STACK_XML_READ", we can use below code to read the target stack

  lv_mesg_text = 'Try to read S/4HANA conversion target from stack.xml.'(M01). "#EC NOTEXT
  MESSAGE lv_mesg_text TYPE 'I'.

  CALL FUNCTION 'OCS_GENERATE_QUEUE_ID'
    EXPORTING
      iv_ocs_tool = 'SUM'
    IMPORTING
      ev_queue_id = lv_queue_id.
  IF lv_queue_id IS NOT INITIAL.
    lv_mesg_text = lv_queue_id.
    CONCATENATE 'Queue ID found:'(M02) lv_mesg_text INTO lv_mesg_text. "#EC NOTEXT
    MESSAGE lv_mesg_text TYPE 'I'.
  ELSE.
    lv_mesg_text = 'No queue ID is found from OCS_GENERATE_QUEUE_ID'(M03). "#EC NOTEXT
    MESSAGE lv_mesg_text TYPE 'I'.
    RETURN.
  ENDIF.

  SELECT * FROM stackheadr INTO TABLE lt_stackheadr
    WHERE queue_id = lv_queue_id.
  LOOP AT lt_stackheadr INTO ls_stackheadr.
    READ TABLE lt_target_stack INTO ls_target_stack
      WITH KEY stack_number = ls_stackheadr-id.
    IF sy-subrc = 0.
      ev_target_stack = ls_stackheadr-id.
      RETURN.
    ENDIF.
  ENDLOOP.


*--------------------------------------------------------------------*
* Print more informatin for trouble shooting purpose

  IF lt_stackheadr IS INITIAL.
    lv_mesg_text = 'Target release from the stack file could not be read for the queue ID.'(M04). "#EC NOTEXT
    MESSAGE lv_mesg_text TYPE 'I'.
    RETURN.
  ENDIF.

  lv_mesg_text = 'Target release is not valid or not yet released. Check the selected target release below'(M05). "#EC NOTEXT
  MESSAGE lv_mesg_text TYPE 'I'.

  CLEAR lt_stackheadr.
  SELECT * FROM stackheadr INTO TABLE lt_stackheadr.
  LOOP AT lt_stackheadr INTO ls_stackheadr.
    CONCATENATE ls_stackheadr-id
            '/' ls_stackheadr-queue_id
            '/' ls_stackheadr-type
            '/' ls_stackheadr-prod_id
            '/' ls_stackheadr-descript
            '/' ls_stackheadr-inststatus
            '/' ls_stackheadr-inst_date
            '/' ls_stackheadr-inst_time
            '/' ls_stackheadr-responsibl
            '/' ls_stackheadr-gen_vers
            '/' ls_stackheadr-gen_date
            '/' ls_stackheadr-gen_time
            INTO lv_mesg_text.
    MESSAGE lv_mesg_text TYPE 'I'.
  ENDLOOP.

*  SELECT * FROM uvers INTO TABLE lt_uvers.
*  LOOP AT lt_uvers INTO ls_uvers.
*    CONCATENATE ls_uvers-component
*            '/' ls_uvers-newrelease
*            '/' ls_uvers-startdate
*            '/' ls_uvers-starttime
*            '/' ls_uvers-enddate
*            '/' ls_uvers-endtime
*            '/' ls_uvers-putstatus
*            '/' ls_uvers-puttype
*            '/' ls_uvers-putmaster
*            '/' ls_uvers-oldrelease
*            '/' ls_uvers-modea01
*            '/' ls_uvers-modeb01
*            '/' ls_uvers-modea10
*            INTO lv_mesg_text.
*    MESSAGE lv_mesg_text TYPE 'I'.
*  ENDLOOP.

ENDFUNCTION.