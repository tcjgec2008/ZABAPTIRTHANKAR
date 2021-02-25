  METHOD if_stctm_ui_task~execute.

    DATA ls_variant TYPE LINE OF tt_variant.

    DATA ls_task TYPE cl_stctm_tasklist=>ts_task.
    DATA lr_task_object TYPE REF TO if_stctm_task.

    " Call UI
    CALL METHOD super->if_stctm_ui_task~execute
      EXPORTING
        ir_tasklist     = ir_tasklist
        i_display_only  = i_display_only
      EXCEPTIONS
        aborted_by_user = 1
        error_occured   = 2
        OTHERS          = 3.

    IF sy-subrc <> 0.
      RAISE aborted_by_user.
    ENDIF.

    " get values for task
    LOOP AT pt_variant INTO ls_variant.
      CASE  ls_variant-selname.
        WHEN 'P_HOST'.
          DATA(lv_host)  = ls_variant-low.
        WHEN 'P_SYSNR'.
          DATA(lv_port) = ls_variant-low.
      ENDCASE.
    ENDLOOP.

    " check if host has changed and set tasks for HTTP allowlisting (ucon_chw)
    IF lv_host <> cl_stct_set_profile_https=>mv_host_https.

      " enable tasks
      LOOP AT ir_tasklist->ptx_task INTO ls_task.

        IF ls_task-taskname = 'CL_STCT_ACTIVATE_HTTP_WHITELIS' OR ls_task-taskname = 'CL_STCT_ADD_HTTP_ALLOWLIST_FLP'.

          IF sy-subrc = 0.
            TRY.
                lr_task_object = ls_task-r_task.

                " do only set something automatically if task is not already executed
                IF lr_task_object->p_status <> cl_stc_task_utilities=>c_status-aborted AND
                   lr_task_object->p_status <> cl_stc_task_utilities=>c_status-running AND
                   lr_task_object->p_status <> cl_stc_task_utilities=>c_status-error AND
                   lr_task_object->p_status <> cl_stc_task_utilities=>c_status-warning AND
                   lr_task_object->p_status <> cl_stc_task_utilities=>c_status-success.


                  IF lr_task_object->p_check_status <> cl_stc_task_utilities=>c_check_status-initial AND
                     lr_task_object->p_status <> cl_stc_task_utilities=>c_status-initial.

                    " check necessary status
                    DATA(lv_necessary) = lr_task_object->is_necessary( ir_tasklist ).

                    IF lv_necessary <> if_stctm_task=>c_necessary-impossible.

                      " set tio initial status
                      lr_task_object->p_check_status = cl_stc_task_utilities=>c_check_status-initial.
                      lr_task_object->p_status       = cl_stc_task_utilities=>c_status-initial.

                      MESSAGE i128(stc_tm) INTO if_stctm_task~pr_log->dummy.
                      ls_task-r_task->pr_log->add_syst( ).
                      MESSAGE i000 WITH 'Using external host:' lv_host INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
                      ls_task-r_task->pr_log->add_syst( ).

                    ENDIF.

                  ENDIF.

                ENDIF.

              CATCH cx_sy_move_cast_error INTO DATA(lx_cast_exc) ##NO_HANDLER.
                " error handling
            ENDTRY.

          ENDIF.
        ENDIF.

      ENDLOOP.

    ELSE.

      " disable tasks
      LOOP AT ir_tasklist->ptx_task INTO ls_task.

        IF ls_task-taskname = 'CL_STCT_ACTIVATE_HTTP_WHITELIS' OR ls_task-taskname = 'CL_STCT_ADD_HTTP_ALLOWLIST_FLP'.

          IF sy-subrc = 0.
            TRY.
                lr_task_object = ls_task-r_task.

                IF ( lr_task_object->p_check_status <> cl_stc_task_utilities=>c_check_status-needless AND
                     lr_task_object->p_status <> cl_stc_task_utilities=>c_status-skipped ) OR
                   ( lr_task_object->p_check_status = cl_stc_task_utilities=>c_check_status-needless AND  " Task without Checkmode
                     lr_task_object->p_status = cl_stc_task_utilities=>c_status-initial ) .

                  lr_task_object->p_check_status = cl_stc_task_utilities=>c_check_status-needless.
                  lr_task_object->p_status       = cl_stc_task_utilities=>c_status-skipped.

                  MESSAGE i128(stc_tm) INTO if_stctm_task~pr_log->dummy.
                  ls_task-r_task->pr_log->add_syst( ).
                  MESSAGE i000 WITH 'Using local host:' lv_host INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
                  ls_task-r_task->pr_log->add_syst( ).

                ENDIF.

              CATCH cx_sy_move_cast_error INTO lx_cast_exc ##NO_HANDLER.
                " error handling
            ENDTRY.

          ENDIF.

        ENDIF.

      ENDLOOP.

    ENDIF.

  ENDMETHOD.