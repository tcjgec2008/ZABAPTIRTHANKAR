METHOD fill_task.

  DATA lv_qn8d_effectperc(60)    TYPE c VALUE 'EFFECTPERC'.
  DATA lv_qn8d_effecttext(60)    TYPE c VALUE 'EFFECTTEXT'.
  DATA lv_langu             TYPE sy-langu.
  DATA ls_message           TYPE bapiret2.
  DATA:
        ls_task       TYPE arbcig_qltyiss_notif_tsk,
        ls_task_i     TYPE arbcig_qltyiss_notif_itm_tsk,
        ls_item       TYPE arbcig_qltyiss_notif_itm,
        ls_notiftask  TYPE bapi2078_nottaski,
        ls_qin_task   TYPE rfc_viqmsm.
  DATA lo_cx_gdt_conversion      TYPE REF TO cx_gdt_conversion.

  FIELD-SYMBOLS <qn8d_effectperc> TYPE ANY.
  FIELD-SYMBOLS <qn8d_effecttext> TYPE ANY.

  DATA: BEGIN OF ls_objkey,
          posnr  TYPE qlfdpos,
          qsmnum LIKE ls_qin_task-qsmnum,
        END OF ls_objkey.

  CONSTANTS: lc_qmsm        TYPE swo_objtyp VALUE 'QMSM'.

****************************************************
*             Header Task
****************************************************

  LOOP AT i_quality_notification-task INTO ls_task.
    CLEAR ls_qin_task. " SAP Note 2939603
* QualityIssueCatalogue
    MOVE ls_task-quality_issue_catgry_catalg_id-content TO ls_qin_task-mnkat.
    MOVE ls_task-parent_quality_issue_catgry_id-content  TO ls_qin_task-mngrp.
    MOVE ls_task-quality_issue_category_id-content      TO ls_qin_task-mncod.

*   PlannedProcessingPeriod
    IF NOT ls_task-planned_processing_period-start_date_time IS INITIAL.
      CONVERT TIME STAMP ls_task-planned_processing_period-start_date_time
      TIME ZONE sy-zonlo INTO DATE ls_qin_task-pster TIME ls_qin_task-pstur.
    ENDIF.
    IF NOT ls_task-planned_processing_period-end_date_time IS INITIAL.
      CONVERT TIME STAMP ls_task-planned_processing_period-end_date_time
      TIME ZONE sy-zonlo INTO DATE ls_qin_task-peter TIME ls_qin_task-petur.
    ENDIF.

* AssigendToInternalID
    IF NOT ls_task-assigned_to_internal_id-content IS INITIAL AND gv_enb_masd_ext_format EQ 'X'. "Defect fix 4676
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = ls_task-assigned_to_internal_id-content
        IMPORTING
          output = ls_qin_task-parnr.
    ELSE.
      ls_qin_task-parnr = ls_task-assigned_to_internal_id-content.
    ENDIF.

* AssignedToTypeCode
*** In XSLT external format is maintained, hence always this conversion is required.
    IF NOT ls_task-assigned_to_type_code IS INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_PARVW_INPUT'
        EXPORTING
          input  = ls_task-assigned_to_type_code
        IMPORTING
          output = ls_qin_task-parvw.
    ELSE.
      ls_qin_task-parvw = ls_task-assigned_to_type_code.
    ENDIF.

* CompleterInternalID
    MOVE ls_task-completer_internal_id-content TO ls_qin_task-erlnam.

* CompletionDateTime
    IF NOT ls_task-completion_date_time IS INITIAL.
      CONVERT TIME STAMP ls_task-planned_processing_period-start_date_time
      TIME ZONE sy-zonlo INTO DATE ls_qin_task-erldat TIME ls_qin_task-erlzeit.
    ENDIF.

* OrdinalNumberValue
    MOVE ls_task-ordinal_number_value TO ls_qin_task-qsmnum.

*   Description
    MOVE ls_task-description-content TO ls_qin_task-matxt.
*   Populate Language code as well
    IF ls_task-description-content IS NOT INITIAL.
      TRY.
          CALL METHOD cl_gdt_conversion=>language_code_inbound
            EXPORTING
              im_value = ls_task-description-language_code
            IMPORTING
              ex_value = ls_qin_task-kzmla.
        CATCH cx_gdt_conversion INTO lo_cx_gdt_conversion.
          CALL FUNCTION 'BALW_BAPIRETURN_GET2'
            EXPORTING
              type   = lo_cx_gdt_conversion->message-type
              cl     = lo_cx_gdt_conversion->message-id
              number = lo_cx_gdt_conversion->message-number
              par1   = lo_cx_gdt_conversion->message-message_v1
            IMPORTING
              return = ls_message.
          APPEND ls_message TO c_message.
          CLEAR: ls_message.
      ENDTRY.
    ENDIF.
*   DetailedText
    IF NOT ls_task-detailed_text-content IS INITIAL.
      CALL METHOD cl_gdt_conversion=>language_code_inbound
        EXPORTING
          im_value = ls_task-detailed_text-language_code
        IMPORTING
          ex_value = lv_langu.
    ENDIF.
*{ SAP Note 2939603
    IF ls_qin_task-kzmla IS INITIAL.
      ls_qin_task-kzmla = lv_langu.
    ENDIF.
*} SAP Note 2939603
    ls_objkey-qsmnum = ls_qin_task-qsmnum.

    CALL METHOD me->fill_longtexts
      EXPORTING
        i_text        = ls_task-detailed_text
        i_object      = lc_qmsm
        i_langu       = lv_langu
        i_objkey      = ls_objkey
        i_action_code = gv_operation
      IMPORTING
        e_text_exists = ls_qin_task-indtx
      CHANGING
        c_messages    = c_message
        c_tline       = t_longtexts.

    APPEND ls_qin_task TO e_qin_task.
  ENDLOOP.

****************************************************
*             Item Task
****************************************************
  LOOP AT i_item INTO ls_item.
    LOOP AT ls_item-task INTO ls_task_i.
      CLEAR ls_qin_task. " SAP Note 2939603
* itemordinalnumbervalue (internal required field)
      MOVE ls_item-ordinal_number_value TO ls_qin_task-posnr.

*     QualityIssueCatalogue
      MOVE ls_task_i-quality_issue_catgry_catalg_id-content TO ls_qin_task-mnkat.
      MOVE ls_task_i-parent_quality_issue_catgry_id-content TO ls_qin_task-mngrp.
      MOVE ls_task_i-quality_issue_category_id-content     TO ls_qin_task-mncod.

*     PlannedProcessingPeriod
      IF NOT ls_task_i-planned_processing_period-start_date_time IS INITIAL.
        CONVERT TIME STAMP ls_task_i-planned_processing_period-start_date_time TIME ZONE sy-zonlo INTO DATE ls_qin_task-pster TIME ls_qin_task-pstur.
      ENDIF.
      IF NOT ls_task_i-planned_processing_period-end_date_time IS INITIAL.
        CONVERT TIME STAMP ls_task_i-planned_processing_period-end_date_time TIME ZONE sy-zonlo INTO DATE ls_qin_task-peter TIME ls_qin_task-petur.
      ENDIF.

*     EmployeeResponsibleInternalID
      IF NOT ls_task_i-assigned_to_internal_id-content IS INITIAL AND gv_enb_masd_ext_format EQ 'X'. "Defect fix 4676
        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING
            input  = ls_task_i-assigned_to_internal_id-content
          IMPORTING
            output = ls_qin_task-parnr.
      ELSE.
        ls_qin_task-parnr = ls_task_i-assigned_to_internal_id-content.
      ENDIF.

*     EmployeeResponsibleInternalTypeCode
      IF NOT ls_task_i-assigned_to_type_code IS INITIAL AND gv_enb_masd_ext_format EQ 'X'. "Defect fix 4676
        CALL FUNCTION 'CONVERSION_EXIT_PARVW_INPUT'
          EXPORTING
            input  = ls_task_i-assigned_to_type_code
          IMPORTING
            output = ls_qin_task-parvw.
      ELSE.
        ls_qin_task-parvw = ls_task_i-assigned_to_type_code.
      ENDIF.

*     CompleterInternalID
      MOVE ls_task_i-completer_internal_id-content TO ls_qin_task-erlnam.

*     CompletionDateTime
      IF NOT ls_task_i-completion_date_time IS INITIAL.
        CONVERT TIME STAMP ls_task_i-planned_processing_period-end_date_time
        TIME ZONE sy-zonlo INTO DATE ls_qin_task-erldat TIME ls_qin_task-erlzeit.
      ENDIF.

*     Description
      MOVE ls_task_i-description-content TO ls_qin_task-matxt.
*     Populate langugage code as well
      IF ls_task_i-description-content IS NOT INITIAL.
        TRY.
            CALL METHOD cl_gdt_conversion=>language_code_inbound
              EXPORTING
                im_value = ls_task_i-description-language_code
              IMPORTING
                ex_value = ls_qin_task-kzmla.
          CATCH cx_gdt_conversion INTO lo_cx_gdt_conversion.
            CALL FUNCTION 'BALW_BAPIRETURN_GET2'
              EXPORTING
                type   = lo_cx_gdt_conversion->message-type
                cl     = lo_cx_gdt_conversion->message-id
                number = lo_cx_gdt_conversion->message-number
                par1   = lo_cx_gdt_conversion->message-message_v1
              IMPORTING
                return = ls_message.
            APPEND ls_message TO c_message.
            CLEAR: ls_message.
        ENDTRY.
      ENDIF.
*     OrdinalNumberValue
      MOVE ls_task_i-ordinal_number_value TO ls_qin_task-qsmnum.

*     Detailed text
      IF NOT ls_task_i-detailed_text-content IS INITIAL.
        MOVE ls_task_i-detailed_text-language_code TO lv_langu.
      ENDIF.

      ls_objkey-posnr = ls_qin_task-posnr.
      ls_objkey-qsmnum = ls_qin_task-qsmnum.

      CALL METHOD me->fill_longtexts
        EXPORTING
          i_text        = ls_task_i-detailed_text
          i_object      = lc_qmsm
          i_langu       = lv_langu
          i_objkey      = ls_objkey
          i_action_code = gv_operation
        IMPORTING
          e_text_exists = ls_qin_task-indtx
        CHANGING
          c_messages    = c_message
          c_tline       = t_longtexts.

*     EffectivenessPercent
      ASSIGN COMPONENT lv_qn8d_effectperc OF STRUCTURE ls_qin_task TO <qn8d_effectperc>.
      IF sy-subrc = 0.
        MOVE ls_task_i-effectiveness_percent TO <qn8d_effectperc>.
      ENDIF.

*     EffectivenessComment
      ASSIGN COMPONENT lv_qn8d_effecttext OF STRUCTURE ls_qin_task TO <qn8d_effecttext>.
      IF sy-subrc = 0.
        MOVE ls_task_i-effectiveness_comment TO <qn8d_effecttext>.
      ENDIF.

**     QualityIssueNotificationCauseID
*  ASSIGN COMPONENT lv_urnum OF STRUCTURE ls_qin_task TO <urnum>.
*  IF sy-subrc = 0.
*    MOVE ls_task_i-quality_issue_notification_cau TO <urnum>.
*  ENDIF.
      APPEND ls_qin_task TO e_qin_task.
    ENDLOOP.
  ENDLOOP.

ENDMETHOD.