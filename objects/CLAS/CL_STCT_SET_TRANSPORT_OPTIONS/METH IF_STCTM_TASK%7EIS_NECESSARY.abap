  METHOD if_stctm_task~is_necessary.

    DATA lr_rt_info TYPE REF TO cl_stctm_tasklist_rt_info.

    DATA ls_task TYPE cl_stctm_tasklist=>ts_task.
    DATA lr_task_object TYPE REF TO if_stctm_task.

    " get runtime info
    lr_rt_info = ir_tasklist->get_runtime_info( ).

    r_necessary = if_stctm_task=>c_necessary-necessary.

    " Special handling for 'SAP_FIORI_FCM_CONTENT_ACTIVATION' task list to set task 'CL_STCT_FCM_UPDATE_ROLE_MENU' out of scope
    " when de-selecting -> PROD env: update role menu should not be executed by default
    IF lr_rt_info->p_scenario_id CP 'SAP_FIORI_FCM_CONTENT_ACTIVATION'.

      DATA(lv_status) = me->if_stctm_task~p_status.

      " this task is not in scope
      IF lv_status = '02'.

        " but only for the initial set
        IF mv_initial = abap_true.

          " set task 'Update role menu" not in scope
          LOOP AT ir_tasklist->ptx_task INTO ls_task.

            IF ls_task-taskname = 'CL_STCT_FCM_UPDATE_ROLE_MENU'.

              IF sy-subrc = 0.

                TRY.
                    lr_task_object = ls_task-r_task.

                    IF ( lr_task_object->p_check_status <> cl_stc_task_utilities=>c_check_status-needless AND
                         lr_task_object->p_status <> cl_stc_task_utilities=>c_status-skipped ) OR
                       ( lr_task_object->p_check_status = cl_stc_task_utilities=>c_check_status-needless AND  " Task without Checkmode
                         lr_task_object->p_status = cl_stc_task_utilities=>c_status-initial ) .

                      lr_task_object->p_check_status = cl_stc_task_utilities=>c_check_status-needless.
                      lr_task_object->p_status       = cl_stc_task_utilities=>c_status-skipped.

                      mv_initial = abap_false.

                      MESSAGE i000 WITH 'Task should not be executed' 'by default in productive environment' INTO if_stctm_task~pr_log->dummy ##NO_TEXT.
                      ls_task-r_task->pr_log->add_syst( ).

                    ENDIF.

                  CATCH cx_sy_move_cast_error INTO DATA(lx_cast_exc) ##NO_HANDLER.
                    "error handling
                ENDTRY.

              ENDIF.
            ENDIF.

          ENDLOOP.

        ENDIF.

        " this task in scope
      ELSE.

        IF mv_initial = abap_true.

          " set task 'Update role menu" in scope
          LOOP AT ir_tasklist->ptx_task INTO ls_task.

            IF ls_task-taskname = 'CL_STCT_FCM_UPDATE_ROLE_MENU'.

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

                          " set to initial status
                          lr_task_object->p_check_status = cl_stc_task_utilities=>c_check_status-initial.
                          lr_task_object->p_status       = cl_stc_task_utilities=>c_status-initial.

                        ENDIF.

                      ENDIF.

                    ENDIF.

                  CATCH cx_sy_move_cast_error INTO lx_cast_exc ##NO_HANDLER.
                    " error handling
                ENDTRY.
              ENDIF.

            ENDIF.

          ENDLOOP.

        ENDIF.

      ENDIF.

    ENDIF.

  ENDMETHOD.