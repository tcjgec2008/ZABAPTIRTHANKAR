class /SDF/CL_RC_CHK_UTILITY definition
  public
  final
  create public .

public section.
  type-pools BCWBN .
  type-pools ICON .

  types TY_RETURN_CODE type I .
  types:
    BEGIN OF ty_name_value_pair_str,
        name   TYPE string,
        value  TYPE string,
      END OF ty_name_value_pair_str .
  types:
    ty_name_value_pair_tab TYPE STANDARD TABLE OF ty_name_value_pair_str .
  types TY_OPTION type CHAR2 .
  types TY_BORMNR type CHAR20 .
  types:
    ty_bormnr_desc    TYPE c LENGTH 255 .
  types TY_CHECK_CONDITION type CHAR3 .
  types:
    ty_check_type     TYPE c LENGTH 30 .
  types TY_ENTRY_POINT_TY type CHAR1 .
  types:
    ty_check_id       TYPE c LENGTH 80 .
  types:
    ty_check_sub_id   TYPE c LENGTH 80 .
  types:
    ty_si_title_en    TYPE c LENGTH 255 .
  types:
    ty_si_note_type   TYPE c LENGTH 30 .
  types:
    ty_status_text    TYPE c LENGTH 50 .
  types:
    ty_sortseq        TYPE n LENGTH 10 .
  types:
    ty_status         TYPE c LENGTH 4 .
  types:
    ty_status_disp    TYPE c LENGTH 45 .
  types:
    ty_smdb_title     TYPE c LENGTH 80 .
  types TY_SMDB_DESC type STRING .
  types:
    ty_smdb_key       TYPE c LENGTH 30 .
  types:
    ty_note_num_tab   TYPE TABLE OF cwbntnumm .
  types:
    ty_piece_list_type TYPE c LENGTH 30 .
  types:
    ty_piece_list      TYPE c LENGTH 80 .
  types:
    BEGIN OF ty_note_stat_str,
        number                 TYPE cwbntnumm,
        action                 TYPE string,
        target_stack           TYPE ty_bormnr,
        current_version        TYPE cwbntvers,
        current_version_str    TYPE string,
        implemented            TYPE flag,
        status                 TYPE char1,
        min_required_ver       TYPE cwbntvers,
        min_required_ver_str   TYPE string,
        min_ver_implmented     TYPE char1,
        latest_ver_implemented TYPE char1,
      END OF ty_note_stat_str .
  types:
    ty_note_stat_tab TYPE TABLE OF ty_note_stat_str .
  types:
    BEGIN OF ty_sitem_guid,
        sitem_guid TYPE guid_32,
      END OF ty_sitem_guid .
  types:
    ty_sitem_guid_tab TYPE TABLE OF ty_sitem_guid .
  types:
    BEGIN OF ty_tmw_adm_str,
        mandt   TYPE mandt,
        cid     TYPE char3,
        at_date TYPE as4date,
        rfcdest TYPE rfcdest,
      END OF ty_tmw_adm_str .
  types:
    ty_tmw_adm_tab TYPE TABLE OF ty_tmw_adm_str .
  types:
    ty_cvers_tab TYPE TABLE OF cvers .
  types:
    BEGIN OF ty_smdb_item_str,
        guid                         TYPE guid_32,
        seq_area                     TYPE char10,
        sitem_id                     TYPE ty_smdb_title,
        app_area                     TYPE ty_smdb_title,
        lob_technology               TYPE string,
        business_area                TYPE string,
        proc_status                  TYPE ty_smdb_key,
        proc_status_text_en          TYPE ty_bormnr_desc,
        title_en                     TYPE ty_smdb_desc,
        check_condition              TYPE ty_check_condition,
        expected_relev_stat          TYPE char30,"this is only for test purpose
        refer_guid                   TYPE guid_32,
        copy_guid                    TYPE guid_32,
        copy_status                  TYPE char1,
      END OF ty_smdb_item_str .
  types:
    ty_smdb_item_tab TYPE TABLE OF ty_smdb_item_str .
  types:
    BEGIN OF ty_smdb_lob_str,
        id                           TYPE guid_32,
        name                         TYPE string,
        type                         TYPE char2,
        parent                       TYPE guid_32,
      END OF ty_smdb_lob_str .
  types:
    ty_smdb_lob_tab TYPE TABLE OF ty_smdb_lob_str .
  types:
    BEGIN OF ty_smdb_source_str,
        guid                          TYPE guid_32,
        source_rel_valid_from_prd_ver TYPE ty_bormnr, "pv_releasenr,
        source_rel_valid_from_stack   TYPE ty_bormnr, "stck_releasenr,
        source_rel_valid_to_prd_ver   TYPE ty_bormnr, "pv_releasenr,
        source_rel_valid_to_stack     TYPE ty_bormnr, "stck_releasenr,
      END OF ty_smdb_source_str .
  types:
    ty_smdb_source_tab TYPE TABLE OF ty_smdb_source_str .
  types:
    BEGIN OF ty_smdb_target_str,
        guid                          TYPE guid_32,
        target_rel_valid_from_prd_ver TYPE ty_bormnr, "pv_releasenr,
        target_rel_valid_from_stack   TYPE ty_bormnr, "stck_releasenr,
        target_rel_valid_to_prd_ver   TYPE ty_bormnr, "pv_releasenr,
        target_rel_valid_to_stack     TYPE ty_bormnr, "stck_releasenr,
        category                      TYPE char30,
        category_text_en              TYPE string,
      END OF ty_smdb_target_str .
  types:
    ty_smdb_target_tab TYPE TABLE OF ty_smdb_target_str .
  types:
    BEGIN OF ty_smdb_note_str,
        guid              TYPE guid_32,
        note_type         TYPE ty_si_note_type,
        sap_note          TYPE cwbntnumm,
        sap_note_desc     TYPE string,
        note_type_text_en TYPE string,
      END OF ty_smdb_note_str .
  types:
    ty_smdb_note_tab TYPE TABLE OF ty_smdb_note_str .
  types:
    BEGIN OF ty_smdb_check_str,
        sitem_guid           TYPE guid_32,
        check_guid           TYPE guid_32,
        check_type           TYPE ty_check_type,
        check_identifier     TYPE ty_check_id,
        check_sub_identifier TYPE ty_check_sub_id,"check_sub_identifier is used as entry point type
        sap_note             TYPE cwbntnumm,
        bf_chk_state         TYPE sfw_r3state,"buz_func_chk_state
        check_count          TYPE i,
        check_count_option   TYPE ty_option,
        check_condition      TYPE ty_check_condition,
        check_class_usage    TYPE char10,
      END OF ty_smdb_check_str .
  types:
    ty_smdb_check_tab TYPE TABLE OF ty_smdb_check_str .
  types:
    BEGIN OF ty_smdb_check_db_str,
        sitem_guid           TYPE guid_32,
        check_guid           TYPE guid_32,
        "check_identifier     TYPE ty_check_id,
        field_number         TYPE i,
        field_name           TYPE char30,
        sel_option           TYPE ty_option,
        sel_value_low        TYPE char100,
        sel_value_high       TYPE char100,
      END OF ty_smdb_check_db_str .
  types:
    ty_smdb_check_db_tab TYPE TABLE OF ty_smdb_check_db_str .
  types:
    BEGIN OF ty_conv_target_stack_str,
        prod_number        TYPE ty_bormnr,
        prod_desc          TYPE char100,
        prod_ver_number    TYPE ty_bormnr,
        prod_ver_name      TYPE char100,
        stack_number       TYPE ty_bormnr,
        stack_name         TYPE char100,
        stack_sort_seq     TYPE numc10,
        stack_release_date TYPE bapisdate,
      END OF ty_conv_target_stack_str .
  types:
    ty_conv_target_stack_tab TYPE TABLE OF ty_conv_target_stack_str .
  types:
    BEGIN OF ty_smdb_scv_str,
        sitem_guid   TYPE guid_32,
        tech_name    TYPE dlvunit,
        tech_release TYPE saprelease,
      END OF ty_smdb_scv_str .
  types:
    ty_smdb_scv_tab TYPE TABLE OF ty_smdb_scv_str .
  types:
    BEGIN OF ty_piece_list_str,
        guid                         TYPE guid_32,
        piece_list_type              TYPE ty_piece_list_type,
        piece_list                   TYPE ty_piece_list,
        sap_note                     TYPE cwbntnumm,
      END OF ty_piece_list_str .
  types:
    ty_piece_list_tab TYPE TABLE OF ty_piece_list_str .
  types:
    BEGIN OF ty_rc_rele_chk_result_str,
        "Below fields are from SDB
        sitem_guid                TYPE guid_32,
        "Below fields are based on calculation
        applicable                TYPE ty_status_text,
        applicable_stat           TYPE ty_status,
        match_target_rel_category TYPE char30,
        relevant_stat             TYPE ty_status,
        relevant_stat_int         TYPE char10,
        summary                   TYPE string,
        summary_int               TYPE string,
        sql_str_int               TYPE string,
      END OF ty_rc_rele_chk_result_str .
  types:
    ty_rc_rele_chk_result_tab TYPE STANDARD TABLE OF ty_rc_rele_chk_result_str .
  types:
    BEGIN OF ty_check_result_str,
        "Below fields are from SDB
        sitem_guid                TYPE guid_32,
        sitem_id                  TYPE ty_smdb_title,
        seq_area                  TYPE char2,
        title_en                  TYPE ty_smdb_desc,
        app_area                  TYPE ty_smdb_title,
        lob_technology_des        TYPE string,
        business_area_des         TYPE string,
        proc_status               TYPE ty_smdb_key,
        proc_stat_disp            TYPE ty_status_disp,
        buz_imp_note              TYPE string,
        note_descr                TYPE string,
        check_condition           TYPE ty_check_condition,
        app_components            TYPE string,
        category_text             TYPE string,"category (for the specified target release)
        check_class_note          TYPE string,
        "Below fields are based on calculation
        applicable                TYPE ty_status_text,
        applicable_stat           TYPE ty_status,
        applicable_stat_disp      TYPE ty_status_disp,
        match_target_rel_category TYPE char30,
        relevant_stat_int         TYPE char30,
        relevant_stat             TYPE ty_status,
        relevant_tooltip          TYPE ty_status_text,
        relevant_stat_disp        TYPE ty_status_disp,
        consistency_return_code   TYPE ty_return_code,
        consistency_stat_disp     TYPE ty_status_disp,
        consistency_stat_tooltip  TYPE ty_status_text,
        exemption_stat_disp       TYPE ty_status_disp,
        exemption_stat_tooltip    TYPE ty_status_text,
        summary                   TYPE string,
        summary_int               TYPE string,
        sql_str_int               TYPE string,
        "Below fields for unit test purpose
        expected_relev_stat       TYPE char30,
        test_result_stat          TYPE ty_status,
      END OF ty_check_result_str .
  types:
    ty_check_result_tab TYPE STANDARD TABLE OF ty_check_result_str .
  types:
    BEGIN OF ty_check_result_persist_str,
        target_stack  TYPE ty_bormnr,
        result_xstr   TYPE xstring,
      END OF ty_check_result_persist_str .
  types:
    ty_check_result_persist_tab TYPE STANDARD TABLE OF ty_check_result_persist_str .
  types:
    BEGIN OF ty_pre_cons_chk_result_str,
        return_code   TYPE ty_return_code,
        descriptions  TYPE salv_wd_t_string,"table of string
        "check_id     TYPE c LENGTH 80,     "SI check_identifier; not used since it's always the class name
        check_sub_id  TYPE c LENGTH 80,     "SI check_sub_identifier; used if same class for different SI
      END OF ty_pre_cons_chk_result_str .
  types:
    ty_pre_cons_chk_result_tab TYPE STANDARD TABLE OF ty_pre_cons_chk_result_str .
  types:
    BEGIN OF ty_consis_chk_result_str,
        "Below fields are from SDB
        sitem_guid              TYPE guid_32,
        sitem_id                TYPE ty_smdb_title,
        check_class             TYPE ty_check_id,
        sap_note                TYPE string,
        "Below fields are based on calculation
        return_code             TYPE ty_return_code,
        skippable_error         TYPE flag,
        skip_status             TYPE ty_status,
        start_time              TYPE timestamp,
        start_time_wh_timezone  TYPE string,
        end_time                TYPE timestamp,
        end_time_wh_timezone    TYPE string,
        running_time_in_seconds TYPE i,
        header_info_table       TYPE tihttpnvp,"salv_wd_t_string,
        chk_clas_result_xstr    TYPE xstring,
      END OF ty_consis_chk_result_str .
  types:
    ty_consis_chk_result_tab TYPE STANDARD TABLE OF ty_consis_chk_result_str .
  types:
    BEGIN OF ty_relev_chk_header_str,
        start_time_utc          TYPE timestamp,
        start_time_wh_timezone  TYPE string,
        end_time_utc            TYPE timestamp,
        end_time_wh_timezone    TYPE string,
        running_time_in_seconds TYPE i,
        system_name             TYPE sy-sysid,
        system_client           TYPE sy-mandt,
        check_user              TYPE sy-uname,
        simp_item_cat_ver_utc   TYPE timestamp,
        no_enough_st03_data     TYPE flag,
        fwk_note_number         TYPE cwbntnumm,
        fwk_note_current_ver    TYPE cwbntvers,
        fwk_note_min_req_ver    TYPE cwbntvers,
        fwk_note_latest_impled  TYPE char1,
      END OF ty_relev_chk_header_str .
  types:
    BEGIN OF ty_consis_chk_header_str,
        start_time_utc          TYPE timestamp,
        end_time_utc            TYPE timestamp,
        running_time_in_seconds TYPE i,
        system_name             TYPE sy-sysid,
        system_client           TYPE sy-mandt,
        fwk_note_number         TYPE cwbntnumm,
        fwk_note_current_ver    TYPE cwbntvers,
        fwk_note_min_req_ver    TYPE cwbntvers,
        fwk_note_latest_impled  TYPE char1,
      END OF ty_consis_chk_header_str .
  types:
    BEGIN OF ty_entry_str,
        object_name     TYPE string,
        object_type     TYPE char1,
        account         TYPE string,
      END OF ty_entry_str .
  types:
    ty_entry_hash_tab TYPE HASHED TABLE OF ty_entry_str WITH UNIQUE KEY table_line .
  types:
    BEGIN OF ty_usage_str,
        object_name     TYPE string,
        object_type     TYPE char1,
        usage_counter   TYPE int4,
      END OF ty_usage_str .
  types:
    ty_usage_hash_tab TYPE HASHED TABLE OF ty_usage_str WITH UNIQUE KEY object_name object_type .
  types:
    ty_usage_tab TYPE STANDARD TABLE OF ty_usage_str .
  types:
    BEGIN OF ty_smdb_app_comp_str,
        guid                 TYPE guid_32,
        app_comp             TYPE char20,
      END OF ty_smdb_app_comp_str .
  types:
    ty_smdb_app_comp_tab TYPE STANDARD TABLE OF ty_smdb_app_comp_str .
  types:
    BEGIN OF ty_key_value_str,
        key   TYPE string,
        value TYPE string,
      END OF ty_key_value_str .
  types:
    ty_key_value_tab TYPE STANDARD TABLE OF ty_key_value_str .
  types:
    ty_message_120 TYPE c LENGTH 120 .
  types:
    ty_message_120_tab TYPE STANDARD TABLE OF ty_message_120 .
  types:
    BEGIN OF ty_cons_chk_map_str,
        sitem_guid           TYPE guid_32,
        check_guid           TYPE guid_32,
        calculation_guid     TYPE guid_16,
        check_identifier     TYPE string,"ty_check_id,
        check_sub_identifier TYPE string,"ty_check_sub_id,
        sap_note             TYPE cwbntnumm,
      END OF ty_cons_chk_map_str .
  types:
    ty_cons_chk_map_tab TYPE TABLE OF ty_cons_chk_map_str .
  types:
    ty_where_clause_line    TYPE c LENGTH 500 .
  types:
    BEGIN OF ty_where_clause_str,
        line TYPE ty_where_clause_line,
      END OF ty_where_clause_str .
  types:
    ty_where_clause_tab TYPE TABLE OF ty_where_clause_str .
  types:
    BEGIN OF ty_sql_condition_str,
        field      TYPE char30,
        opera      TYPE ty_option,
        low        TYPE string,
        high       TYPE string,
      END OF ty_sql_condition_str .
  types:
    ty_sql_condition_tab TYPE TABLE OF ty_sql_condition_str .
  types:
    BEGIN OF ty_ppms_product_str,
        product_ppms_id       TYPE ty_bormnr,
        product_desc          TYPE string,
      END OF ty_ppms_product_str .
  types:
    ty_ppms_product_tab TYPE TABLE OF ty_ppms_product_str .
  types:
    BEGIN OF ty_ppms_prod_version_str,
        product_ppms_id       TYPE ty_bormnr,
        prd_version_ppms_id   TYPE ty_bormnr,
        prd_version_sequence  TYPE int1,
        sw_comp_tech_name     TYPE char30,
        sw_comp_release       TYPE char30,
        prd_version_desc      TYPE string,
      END OF ty_ppms_prod_version_str .
  types:
    ty_ppms_prod_version_tab TYPE TABLE OF ty_ppms_prod_version_str .
  types:
    BEGIN OF ty_ppms_stack_str,
        product_ppms_id       TYPE ty_bormnr,
        prd_version_ppms_id   TYPE ty_bormnr,
        stack_ppms_id         TYPE ty_bormnr,
        stack_sequence        TYPE int1,
        stack_sp_name         TYPE char6,
        stack_desc            TYPE string,
        stack_status          TYPE string,
      END OF ty_ppms_stack_str .
  types:
    ty_ppms_stack_tab TYPE TABLE OF ty_ppms_stack_str .
  types:
    BEGIN OF ty_sitem_skip_str,
        sitem_guid        TYPE guid_32,
        skip_status       TYPE ty_status,
        last_changed_at   TYPE timestamp,
        last_changed_by   TYPE syuname,
        last_checked_at   TYPE timestamp,
        last_checked_by   TYPE syuname,
      END OF ty_sitem_skip_str .
  types:
    ty_sitem_skip_tab TYPE TABLE OF ty_sitem_skip_str .
  types:
    BEGIN OF ty_smdb_note_req_str,
        stack_ppms_id     TYPE ty_bormnr,
        sap_note          TYPE cwbntnumm,
        min_note_version  TYPE cwbntvers,
        chk_clas_tci_note TYPE flag,
      END OF ty_smdb_note_req_str .
  types:
    ty_smdb_note_req_tab TYPE TABLE OF ty_smdb_note_req_str .
  types:
    BEGIN OF ty_rc_note_req_str,
        application      TYPE string,
        appl_action      TYPE string,
        sap_note         TYPE cwbntnumm,
        min_note_version TYPE cwbntvers,
      END OF ty_rc_note_req_str .
  types:
    ty_rc_note_req_tab TYPE TABLE OF ty_rc_note_req_str .
  types:
    BEGIN OF ty_note_req_str,
      sap_note            TYPE cwbntnumm,
      min_note_version    TYPE cwbntvers,
      latest_note_version TYPE cwbntvers,
    END OF ty_note_req_str .
  types:
    BEGIN OF ty_note_req_buf_str,
      action              TYPE string,
      target_stack        TYPE ty_bormnr,
      sap_note            TYPE cwbntnumm,
      min_note_version    TYPE cwbntvers,
      latest_note_version TYPE cwbntvers,
    END OF ty_note_req_buf_str .
  types:
    ty_note_req_buf_tab TYPE TABLE OF ty_note_req_buf_str .
  types:
    BEGIN OF ty_message_str,
        mesg_type   TYPE symsgty,
        mesg_str    TYPE string,
      END OF ty_message_str .
  types:
    ty_message_tab TYPE STANDARD TABLE OF ty_message_str .
  types:
    ty_cwbntnumm_tab TYPE STANDARD TABLE OF cwbntnumm .

  class-data SV_IS_DS_USED type BOOLEAN .
  constants:
    BEGIN OF c_applicable_status,
        yes TYPE ty_status VALUE icon_checked,"Applicable                   "#EC NOTEXT
        no  TYPE ty_status VALUE icon_dummy,  "No Applicable                "#EC NOTEXT
      END OF c_applicable_status .
  constants:
    BEGIN OF c_app_log,
        object                   TYPE balobj_d   VALUE 'RC_S4HANA',                                "#EC NOTEXT
        sub_obj_cons_check       TYPE balsubobj  VALUE 'RC_S4HANA_CONS',                           "#EC NOTEXT
        "sub_obj_cons_check_sub   TYPE balsubobj  VALUE 'RC_S4HANA_CONS_SUB',                      "#EC NOTEXT
        sub_obj_cons_check_skip  TYPE balsubobj  VALUE 'RC_S4HANA_CONS_SKIP',                      "#EC NOTEXT
        sub_obj_relevancy_check  TYPE balsubobj  VALUE 'RC_S4HANA_RELEVANCY',                      "#EC NOTEXT
        sub_obj_smdb_source_chng TYPE balsubobj  VALUE 'RC_SCI_SRC_CHNG',                          "#EC NOTEXT
        ext_num_cons_check_all   TYPE balnrext   VALUE 'Simplification Item Check',                "#EC NOTEXT
        ext_num_cons_check_sel   TYPE balnrext   VALUE 'Simplification Item Detailed Check',       "#EC NOTEXT
        ext_num_cons_check_skip  TYPE balnrext   VALUE 'Simplification Item Exemption',            "#EC NOTEXT
        ext_num_relevancy_check  TYPE balnrext   VALUE 'Simplification Item Relevance Check',      "#EC NOTEXT
        ext_num_smdb_source_chng TYPE balnrext   VALUE 'Simplification Item Catalog Source Change',"#EC NOTEXT
        alsort_init              TYPE balsort    VALUE '000',                                      "#EC NOTEXT
        txt_length               TYPE i          VALUE 90,"120                                     "#EC *
        log_keep_period          TYPE i          VALUE 180, "#EC *
        free_text_msgid          TYPE symsgid    VALUE 'BL',
        free_text_msgno          TYPE symsgno    VALUE '001',
        update(1)                TYPE c          VALUE 'U',
        insert(1)                TYPE c          VALUE 'I',
        replace(1)               TYPE c          VALUE 'R',
        level_1                  TYPE ballevel   VALUE 1,
        level_2                  TYPE ballevel   VALUE 2,
        level_3                  TYPE ballevel   VALUE 3,
        level_4                  TYPE ballevel   VALUE 4,
        sum_logger_class_name    TYPE seoclsname VALUE 'CL_UPG_LOGGER_620',
        sum_log_file_name        TYPE trfilename VALUE 'S4_SIF_TRANSITION_CHECKS',
        sum_module_id            TYPE syrepid    VALUE 'R_S4_SIF_TRANSITION_CHECKS',
        sum_log_type_p           TYPE char_lg_01 VALUE 'P',
        sum_log_txt_length       TYPE i          VALUE 50,
      END OF c_app_log .
  constants:
    BEGIN OF c_bf_status,
        active     TYPE sfw_r3state VALUE 'A', "Active
        inactive   TYPE sfw_r3state VALUE 'I', "Inactive
        pre_active TYPE sfw_r3state VALUE 'P', "Pre-Active After Import-->not used so far
      END OF c_bf_status .
  constants:
    BEGIN OF c_check_condition,
        and TYPE ty_check_condition VALUE 'AND',  "All checks must pass
        or  TYPE ty_check_condition VALUE 'OR',  "At least one check must pass
      END OF c_check_condition .
  constants:
    BEGIN OF c_check_type,
        buz_func      TYPE ty_check_type VALUE 'BF',          "Business Function
        entry_point   TYPE ty_check_type VALUE 'ENTRY_POINT', "Entry Point
        idoc          TYPE ty_check_type VALUE 'IDOC',        "IDoc
        pre_check_old TYPE ty_check_type VALUE 'PC',          "Old Pre Check
        pre_check_new TYPE ty_check_type VALUE 'NPC',         "New Pre Check
        table         TYPE ty_check_type VALUE 'TABLE',       "Table
        manual        TYPE ty_check_type VALUE 'MANUAL',      "Manual
      END OF c_check_type .
  constants C_CHK_CLAS_TCI_NOTE type STRING value '2502552' ##NO_TEXT.
  constants:
    BEGIN OF c_chk_clas_usage,
        relevance      TYPE char10 VALUE 'RELEVANCE',  "Relevance
        consistency    TYPE char10 VALUE 'CONSISTNCY', "Consistency
        rel_and_consis TYPE char10 VALUE 'REL_CONSIS', "Relevance & Consistency
      END OF c_chk_clas_usage .
  constants:
    BEGIN OF c_data_key_new,
        data_trigid                   TYPE int4 VALUE 999999999,"#EC NOTEXT "max possible 2147483647
        data_trigoffset               TYPE int4 VALUE 999999999,"#EC NOTEXT
        subid_smdb_content_latest_sap TYPE int4 VALUE       100,"#EC NOTEXT
        subid_smdb_content_upload     TYPE int4 VALUE       200,"#EC NOTEXT
        "subid_item_status             TYPE int4 VALUE       300,"#EC NOTEXT
        subid_calculation_key         TYPE int4 VALUE       400,"#EC NOTEXT
        subid_cons_skip_sitem         TYPE int4 VALUE       500,"#EC NOTEXT
        subid_cons_result_last        TYPE int4 VALUE       600,"#EC NOTEXT
        subid_relv_result_last        TYPE int4 VALUE       700,"#EC NOTEXT
        subid_simpl_item_catalog_src  TYPE int4 VALUE       800,"#EC NOTEXT
        subid_st03n_data              TYPE int4 VALUE       900, "#EC NOTEXT
      END OF c_data_key_new .
  constants:
    BEGIN OF c_entry_option,
        equal_to      TYPE ty_option VALUE 'EQ', "Equal to
        not_more_than TYPE ty_option VALUE 'LE', "Less than or Equal to
        not_less_than TYPE ty_option VALUE 'GE', "Greater than or Equal to
        not_equal_to  TYPE ty_option VALUE 'NE', "Not Equal to
        more_than     TYPE ty_option VALUE 'GT', "Greater than
        less_than     TYPE ty_option VALUE 'LT', "Less than
      END OF c_entry_option .
  constants:
    BEGIN OF c_entry_point_type,
        transaction TYPE char1 VALUE 'T', "Transaction
        rfc         TYPE char1 VALUE 'C', "Remote Function Call
        url         TYPE char1 VALUE 'U', "URL
        report      TYPE char1 VALUE 'S', "Submit Report
        job         TYPE char1 VALUE 'B', "Batch Job
      END OF c_entry_point_type .
  constants:
    BEGIN OF c_field_option,
        equal_to      TYPE ty_option VALUE 'EQ', "Equal to
        between       TYPE ty_option VALUE 'BT', "BeTween ... and ...
        contains      TYPE ty_option VALUE 'CP', "Contains pattern
        not_more_than TYPE ty_option VALUE 'LE', "Less than or Equal to
        not_less_than TYPE ty_option VALUE 'GE', "Greater than or Equal to
        not_equal_to  TYPE ty_option VALUE 'NE', "Not Equal to
        not_between   TYPE ty_option VALUE 'NB', "Not Between ... and ...
        not_contains  TYPE ty_option VALUE 'NP', "Not Contains pattern
        more_than     TYPE ty_option VALUE 'GT', "Greater than
        less_than     TYPE ty_option VALUE 'LT', "Less than
        is_empty      TYPE ty_option VALUE 'EP', "Is Empty
        is_not_empty  TYPE ty_option VALUE 'NM', "Is Not Empty
      END OF c_field_option .
  constants:
    BEGIN OF c_file_name,
        header                TYPE string VALUE 'header.xml',                      "#EC NOTEXT
        conv_start_stack      TYPE string VALUE 'conv_start_stack.xml',            "#EC NOTEXT
        conv_target_stack     TYPE string VALUE 'conv_target_stack.xml',           "#EC NOTEXT
        bw_conv_target_stack  TYPE string VALUE 'bw_conv_target_stack.xml',        "#EC NOTEXT
        transition_db_item    TYPE string VALUE 'sdb_transition_db_item.xml',      "#EC NOTEXT
        source_release        TYPE string VALUE 'sdb_source_release.xml',          "#EC NOTEXT
        target_release        TYPE string VALUE 'sdb_target_release.xml',          "#EC NOTEXT
        application_area      TYPE string VALUE 'sdb_application_area.xml',        "#EC NOTEXT
        check                 TYPE string VALUE 'sdb_check.xml',                   "#EC NOTEXT
        check_new             TYPE string VALUE 'sdb_check_new.xml',               "#EC NOTEXT
        check_db              TYPE string VALUE 'sdb_check_db.xml',                "#EC NOTEXT
        check_db_new          TYPE string VALUE 'sdb_check_db_new.xml',            "#EC NOTEXT
        note                  TYPE string VALUE 'sdb_note.xml',                    "#EC NOTEXT
        piece_list            TYPE string VALUE 'sdb_piece_list.xml',              "#EC NOTEXT
        software_component    TYPE string VALUE 'sdb_software_component.xml',      "#EC NOTEXT
        application_component TYPE string VALUE 'sdb_application_component.xml',   "#EC NOTEXT
        ppms_product          TYPE string VALUE 'ppms_product.xml',                "#EC NOTEXT
        ppms_prod_version     TYPE string VALUE 'ppms_prod_version.xml',           "#EC NOTEXT
        ppms_stack            TYPE string VALUE 'ppms_stack.xml',                  "#EC NOTEXT
        note_requirement      TYPE string VALUE 'note_requirement.xml',            "#EC NOTEXT
        hdr_time_utc          TYPE string VALUE 'TransitionDBDownloadedTimeUTC',   "#EC NOTEXT
        lob_ba                TYPE string VALUE 'sdb_lob.xml',                     "#EC NOTEXT
      END OF c_file_name .
  constants C_FRAMEWORK_NOTE type STRING value '2399707' ##NO_TEXT.
  constants C_FRAMEWORK_TEST_NOTE type STRING value '2593207' ##NO_TEXT.
  constants C_LANGU_ENGLISH type LANGU value 'E' ##NO_TEXT.
  constants:
    BEGIN OF c_message_severity,
        success TYPE symsgty VALUE 'S',
        info    TYPE symsgty VALUE 'I',
        warning TYPE symsgty VALUE 'W',
        error   TYPE symsgty VALUE 'E',
      END OF c_message_severity .
  constants:
    BEGIN OF c_method,
        check_relevance    TYPE abap_methname VALUE 'CHECK_RELEVANCE',    "#EC NOTEXT
        check_consistency  TYPE abap_methname VALUE 'CHECK_CONSISTENCY',  "#EC NOTEXT
      END OF c_method .
  class-data C_NOTE_SEPERATOR type CHAR1 value ';' ##NO_TEXT.
  constants:
    BEGIN OF c_note_type,
        buz_impact TYPE ty_si_note_type VALUE 'BI',  "#EC NOTEXT
        technical  TYPE ty_si_note_type VALUE 'TC',  "#EC NOTEXT
        others     TYPE ty_si_note_type VALUE 'OT',  "#EC NOTEXT
      END OF c_note_type .
  constants:
    BEGIN OF c_parameter,
        sys_type_key           TYPE string VALUE 'SYSTEM_TYPE',
        sys_type_sap           TYPE string VALUE 'SAP',
        sys_type_custom        TYPE string VALUE 'CUS',
        sys_type_sap_test      TYPE string VALUE 'SAP_TEST',
        sys_type_key_local     TYPE string VALUE 'RC_SYS_TYPE',
        note_req_applition     TYPE string VALUE 'NOTE_REQ_APPLITION',
        note_req_appl_action   TYPE string VALUE 'NOTE_REQ_APPL_ACTION',
        note_req_note_number   TYPE string VALUE 'NOTE_REQ_NOTE_NUMBER',
        note_req_ppms_stack    TYPE string VALUE 'NOTE_REQ_PPMS_STACK',
        note_req_system_id     TYPE string VALUE 'NOTE_REQ_SYSTEM_ID',
        note_req_sys_inst_no   TYPE string VALUE 'NOTE_REQ_SYS_INST_NO',
        note_req_curr_note_ver TYPE string VALUE 'NOTE_REQ_CURRENT_NOTE_VER',
        smdb_source_sap        TYPE string VALUE 'SMDB_SOURCE_SAP',
        smdb_source_manual     TYPE string VALUE 'SMDB_SOURCE_MANUAL',
      END OF c_parameter .
  constants:
    BEGIN OF c_sap_note,"Refer to INCLUDE cwbntcns & FM SCWN_NOTES_DOWNLOAD
         "Implementation status of a note (set by system)
         prstat_initial            TYPE cwbprstat  VALUE ' ',
         prstat_implemented        TYPE cwbprstat  VALUE 'E',
         prstat_old_vrs_impl       TYPE cwbprstat  VALUE 'V',
         prstat_incompl_impl       TYPE cwbprstat  VALUE 'U',
         prstat_not_implemented    TYPE cwbprstat  VALUE 'N',
         prstat_obsolete           TYPE cwbprstat  VALUE 'O',
         prstat_no_valid_cinst     TYPE cwbprstat  VALUE '-',
         "Values for the OSS status of a note
         sap_status_rel_for_cust   TYPE cwbattrval VALUE '00',
         sap_status_rel_int        TYPE cwbattrval VALUE '04',
         sap_status_rel_pilot      TYPE cwbattrval VALUE '22',
         sap_status_for_checking   TYPE cwbattrval VALUE '01',
         sap_status_in_process     TYPE cwbattrval VALUE '03',
         "RFC destination to get note information
         cwbadm_cs_nt              TYPE rfcdest    VALUE 'SAPOSS',
         cwbadm_cs_nt_new          TYPE rfcdest    VALUE 'SAPSNOTE',
         "SAP note status
         not_downloaded            TYPE char1      VALUE '0',
         implemented_upto_date     TYPE char1      VALUE '1',
         implemented_outof_date    TYPE char1      VALUE '2',
         implemented_stat_unknown  TYPE char1      VALUE '3',
         not_implemen_upto_date    TYPE char1      VALUE '4',
         not_implemen_outof_date   TYPE char1      VALUE '5',
         not_implemen_stat_unknown TYPE char1      VALUE '6',
         "Note requirement check
         application_read_chk      TYPE string VALUE 'RC4S4HANA',   "RC4S4HANA  Readiness Check
         action_manual_upload      TYPE string VALUE 'RC_MAN_UPL',  "RC: Manual Upload Analysis
         action_solman_upload      TYPE string VALUE 'RC_SM_ANA  ', "RC: Created Analysis in SolMan
         action_prepare_data       TYPE string VALUE 'RC_PR_DATA',  "RC: Prepare Data in Managed System
         action_rc_relev_chk       TYPE string VALUE 'RC_SITM_CK',  "RC: Simplification Item Check
         action_rc_sitm_sum_chk    TYPE string VALUE 'RC_SUM1709',  "RC: SUM Consistency Check for S/4 1709
      END OF c_sap_note .
  constants C_SDB_FILE_MIME_PATH type RSZWMIMEPATH value '/SAP/PUBLIC/SIMPLIFICATION_ITEM_DB.ZIP' ##NO_TEXT.
  constants:
    BEGIN OF c_sitem_skip_status,
        yes            TYPE ty_status VALUE icon_checked,    "Skipped                             "#EC NOTEXT
        no             TYPE ty_status VALUE icon_led_yellow, "Not skipped                         "#EC NOTEXT
        not_applicalbe TYPE ty_status VALUE icon_dummy,      "Not applicalbe                      "#EC NOTEXT
        "no_skippable TYPE ty_status VALUE icon_led_green,   "Not skippable anymore after recheck "#EC NOTEXT
      END OF c_sitem_skip_status .
  constants:
    BEGIN OF c_si_cons_stat,"Simplification Item consistency Status - external
        success          TYPE ty_status VALUE icon_led_green,
        warning          TYPE ty_status VALUE icon_led_yellow,
        error            TYPE ty_status VALUE icon_led_red,
        abortion         TYPE ty_status VALUE icon_breakpoint,
        not_applicalbe   TYPE ty_status VALUE icon_dummy,     "Not applicalbe                 "#EC NOTEXT
      END OF c_si_cons_stat .
  constants:
    BEGIN OF c_si_rele_int_stat,"Simplification Item Relevance Status - external
        "The constants is defined as /SPN/SMRC_SITEM_RELAVANCE in backend
        yes           TYPE char10 VALUE 'RELEVANT',    "Relevant
        no            TYPE char10 VALUE 'NOT_RELEVT',  "Irrelevant
        manual_check  TYPE char10 VALUE 'MANUAL_CHK',  "Need manual check -> ingnore simple check and check class
        chk_cls_issue TYPE char10 VALUE 'CLS_MISSNG',  "Check class defined but not exists or note out-of-date
        rule_issue    TYPE char10 VALUE 'RULE_ISSUE',  "Check rule not defined or defined incorrectly
        miss_usg_data TYPE char10 VALUE 'MISS_ST03N',  "Missing usage (ST03N) data for entry point
      END OF c_si_rele_int_stat .
  constants:
    BEGIN OF c_si_rele_stat,"Simplification Item Relevance Status - external
        yes           TYPE ty_status VALUE icon_led_yellow,
        no            TYPE ty_status VALUE icon_checked,
        manual_check  TYPE ty_status VALUE icon_led_yellow,
        chk_cls_issue TYPE ty_status VALUE icon_led_yellow,
        rule_issue    TYPE ty_status VALUE icon_led_yellow,
        miss_usg_data TYPE ty_status VALUE icon_led_yellow,
      END OF c_si_rele_stat .
  constants:
    BEGIN OF c_status,
        yes      TYPE char1 VALUE 'Y',   "#EC NOTEXT
        no       TYPE char1 VALUE 'N',   "#EC NOTEXT
        unknown  TYPE char1 VALUE space, "#EC NOTEXT
        error    TYPE char1 VALUE 'E',   "#EC NOTEXT
      END OF c_status .
  constants:
    BEGIN OF c_sum_phase,
        first    TYPE char1 VALUE '1', "#EC NOTEXT
        second   TYPE char1 VALUE '2', "#EC NOTEXT
        unknown  TYPE char1 VALUE '9', "#EC NOTEXT
      END OF c_sum_phase .
  constants C_TEST_DATA_SEQ_AREA type CHAR2 value '00' ##NO_TEXT.
  constants C_TEST_FUNCTION type RS38L_FNAM value '/SDF/RC_CHK_ADD_TEST_DATA' ##NO_TEXT.
  constants C_TIME_ZONE_UTC type SYSTZONLO value 'UTC' ##NO_TEXT.
  class-data SV_CONDITIONAL_STOP type FLAG .
  class-data SV_NO_ENOUGH_ST03_DATA type FLAG .
  class-data SV_SMDB_FETCHED_FROM_SAP type FLAG .
  class-data SV_DB_TYPE type STRING .
  class-data SV_SYSTEM_TYPE type STRING .
  class-data SV_TEST_FUNCTION type RS38L_FNAM value '/SDF/S4_CONDITIONAL_STOP' ##NO_TEXT.
  class-data SV_TEST_SYSTEM type FLAG .
  class-data SV_UPD_SMDB_CONT_DISP1 type FLAG value 'X' ##NO_TEXT.
  constants C_RC_SYS_TYPE type STRING value 'RC_SYS_TYPE' ##NO_TEXT.
  constants C_SAP_TEST type STRING value 'SAP_TEST' ##NO_TEXT.
  class-data SV_CONTENT_SOURCE type STRING .

  class-methods SMDB_CONTENT_FETCH_FROM_SAP_DS
    importing
      !IV_URL type STRING
    exporting
      !EV_CONTENT type XSTRING
      !EV_MSG type STRING .
  class-methods GET_DOWNLOAD_SERVICE_INFO
    exporting
      !EV_DWLD_SERV_DEST type RFCDEST
      !EV_IS_DS_USED type BOOLEAN .
  class-methods APP_LOG_ADD_FREE_TEXT
    importing
      !IV_MESG_TEXT type STRING
      !IV_MESG_TYPE type SYMSGTY default 'I'
      !IV_MESG_LEVEL type BALLEVEL
      !IV_MESG_TYPE_SUM type SYMSGTY optional
      !IV_MESG_TEXT_SUM type STRING optional .
  class-methods GET_SAPNOTE_REQUIRE_AND_LATEST
    importing
      !IV_NOTE_NUMBER type CWBNTNUMM
      !IV_ACTION type STRING
      !IV_TARGET_STACK type TY_BORMNR optional
    exporting
      !ES_NOTE_REQ type TY_NOTE_REQ_STR
      !EV_MSG type STRING .
  class-methods APP_LOG_CHK_EXEMPTION_INIT .
  class-methods APP_LOG_SMDB_SRC_CHANGE_INIT .
  class-methods SMDB_CONTENT_LOAD
    exporting
      !EV_SMDB_ZIP_XTR type XSTRING
      !ET_HEADER type TY_NAME_VALUE_PAIR_TAB
      !ET_SITEM type TY_SMDB_ITEM_TAB
      !ET_SOURCE_RELEASE type TY_SMDB_SOURCE_TAB
      !ET_TARGET_RELEASE type TY_SMDB_TARGET_TAB
      !ET_CHECK type TY_SMDB_CHECK_TAB
      !ET_CHECK_DB type TY_SMDB_CHECK_DB_TAB
      !ET_CONV_TARGET_STACK type TY_CONV_TARGET_STACK_TAB
      !ET_BW_CONV_TARGET_STACK type TY_CONV_TARGET_STACK_TAB
      !ET_NOTE type TY_SMDB_NOTE_TAB
      !ET_APP_COMP type TY_SMDB_APP_COMP_TAB
      !ET_PPMS_PRODUCT type TY_PPMS_PRODUCT_TAB
      !ET_PPMS_PROD_VERSION type TY_PPMS_PROD_VERSION_TAB
      !ET_PPMS_STACK type TY_PPMS_STACK_TAB
      !ET_PIECE_LIST type TY_PIECE_LIST_TAB
      !EV_TIME_UTC type TIMESTAMP
      !EV_TIME_UTC_STR type STRING
      !ET_SMDB_NOTE_REQ type TY_SMDB_NOTE_REQ_TAB
      !ET_RC_NOTE_REQ type TY_RC_NOTE_REQ_TAB
      !ET_LOB type TY_SMDB_LOB_TAB
    exceptions
      ERROR .
  class-methods APP_LOG_CONS_CHK_INIT
    importing
      !IV_SUM_MODE type FLAG default SPACE
      !IV_SUB_OBJECT type BALSUBOBJ default /SDF/CL_RC_CHK_UTILITY=>C_APP_LOG-SUB_OBJ_CONS_CHECK
      !IV_DETAILED_CHK type FLAG optional .
  class-methods APP_LOG_RELVENCE_CHK_INIT .
  class-methods APP_LOG_DISP
    importing
      !IS_LOG_FILTER type BAL_S_LFIL
      !IV_TITLE type BALTITLE optional .
  class-methods APP_LOG_EXISTS
    returning
      value(RV_LOG_EXISTS) type FLAG .
  class-methods APP_LOG_DISP_CONS_CHK .
  class-methods APP_LOG_SUM_LOG_INIT
    exceptions
      SUM_LOG_ERR .
  class-methods APP_LOG_SUM_LOG_WRITE .
  class-methods CHECK_NOTE_STATUS
    importing
      !IV_NOTE_NUMBER type CWBNTNUMM
      !IV_ACTION type STRING
      !IV_TARGET_STACK type TY_BORMNR optional
    returning
      value(RS_NOTE_STATUS) type TY_NOTE_STAT_STR .
  class-methods CHECK_IS_TEST_MODE
    returning
      value(RV_TEST_MODE) type FLAG
    exceptions
      ERROR .
  class-methods CLASS_CONSTRUCTOR .
  class-methods GET_SMDB_CONTENT
    importing
      !IV_RELOAD type FLAG default SPACE
    exporting
      !EV_SMDB_ZIP_XTR type XSTRING
      !ET_HEADER type TY_NAME_VALUE_PAIR_TAB
      !ET_SITEM type TY_SMDB_ITEM_TAB
      !ET_SOURCE_RELEASE type TY_SMDB_SOURCE_TAB
      !ET_TARGET_RELEASE type TY_SMDB_TARGET_TAB
      !ET_CHECK type TY_SMDB_CHECK_TAB
      !ET_CHECK_DB type TY_SMDB_CHECK_DB_TAB
      !ET_CONV_TARGET_STACK type TY_CONV_TARGET_STACK_TAB
      !ET_BW_CONV_TARGET_STACK type TY_CONV_TARGET_STACK_TAB
      !ET_NOTE type TY_SMDB_NOTE_TAB
      !ET_APP_COMP type TY_SMDB_APP_COMP_TAB
      !ET_PPMS_PRODUCT type TY_PPMS_PRODUCT_TAB
      !ET_PPMS_PROD_VERSION type TY_PPMS_PROD_VERSION_TAB
      !ET_PPMS_STACK type TY_PPMS_STACK_TAB
      !ET_PIECE_LIST type TY_PIECE_LIST_TAB
      !EV_TIME_UTC type TIMESTAMP
      !EV_TIME_UTC_STR type STRING
      !ET_SMDB_NOTE_REQ type TY_SMDB_NOTE_REQ_TAB
      !ET_RC_NOTE_REQ type TY_RC_NOTE_REQ_TAB
      !ET_LOB type TY_SMDB_LOB_TAB
    exceptions
      ERROR
      SMDB_CONTNET_NOT_FOUND .
  class-methods GET_UPLOADED_ST03N_DATA
    exporting
      !ET_USAGE_REPORT type TY_USAGE_TAB
      !ET_USAGE_TRANS type TY_USAGE_TAB
      !ET_USAGE_RFC type TY_USAGE_TAB
      !ET_USAGE_URL type TY_USAGE_TAB
      !EV_INFO_STR type STRING
      !EV_MONTH_OF_USG type I .
  class-methods GET_TEXT_STR
    importing
      !IV_TXT_KEY type CHAR3
      !IV_PARA1 type STRING optional
      !IV_PARA2 type STRING optional
      !IV_PARA3 type STRING optional
      !IV_PARA4 type STRING optional
    returning
      value(RV_TEXT) type STRING .
  class-methods GET_TIMESTAMP
    exporting
      !EV_TIMESTAMP_UTC type TIMESTAMP
      !EV_TIMESTAMP_WH_TIMEZONE type STRING
      !EV_TIMESTAMP_UTC_STR type STRING .
  class-methods GET_SUM_PHASE
    returning
      value(RV_SUM_PHASE) type CHAR1 .
  class-methods IS_CLASS_EXIST
    importing
      !IV_CLASS_NAME type TY_CHECK_ID
    returning
      value(RV_EXIST) type FLAG .
  class-methods IS_METHOD_EXIST
    importing
      !IV_CLASS_NAME type TY_CHECK_ID
      !IV_METHOD_NAME type ABAP_METHNAME
    returning
      value(RV_EXIST) type FLAG .
  class-methods IS_SITEM_SAP_EXIST
    returning
      value(RV_RESULT) type BOOLEAN .
  class-methods PREPARE_CHECK_CLASS_PARAMETER
    importing
      !IV_SITEM_GUID type GUID_32
      !IV_TARGET_STACK type /SDF/CL_RC_CHK_UTILITY=>TY_BORMNR
      !IV_DETAILED_CHK type FLAG optional
    returning
      value(RT_PARAMETER) type TIHTTPNVP .
  class-methods SITEM_CONSISTENCY_RESULT_GET
    importing
      !IV_TARGET_STACK type TY_BORMNR
    exporting
      !ET_CONS_CHK_RESULT type TY_CONSIS_CHK_RESULT_TAB
      !ET_CONS_HEADER_INFO type SALV_WD_T_STRING
      !ES_HEADER_INFO type TY_CONSIS_CHK_HEADER_STR .
  class-methods SITEM_RELEVANCE_RESULT_GET
    importing
      !IV_TARGET_STACK type TY_BORMNR
    exporting
      !ET_REL_CHK_RESULT type TY_CHECK_RESULT_TAB
      !ES_HEADER_INFO type /SDF/CL_RC_CHK_UTILITY=>TY_RELEV_CHK_HEADER_STR .
  class-methods SITEM_RELEVANCE_RESULT_SAVE
    importing
      !IV_TARGET_STACK type TY_BORMNR
      !IT_REL_CHK_RESULT type TY_CHECK_RESULT_TAB
      !IS_HEADER_INFO type /SDF/CL_RC_CHK_UTILITY=>TY_RELEV_CHK_HEADER_STR .
  class-methods GET_CONVERSION_TARGET_STR
    importing
      !IV_TARGET_STACK type TY_BORMNR
    returning
      value(RV_TARGET_STR) type STRING .
  class-methods SITEM_SKIP_STAT_GET
    importing
      !IV_TARGET_STACK type TY_BORMNR
    exporting
      !ET_SITEM_SKIP type TY_SITEM_SKIP_TAB .
  class-methods SITEM_RELEVANCE_RESULT_DEL
    importing
      !IV_TARGET_STACK type CHAR20 .
  class-methods SITEM_CONSISTENCY_RESULT_SAVE
    importing
      !IV_TARGET_STACK type TY_BORMNR
      !IT_CONS_CHK_RESULT type TY_CONSIS_CHK_RESULT_TAB
      !IT_CONS_HEADER_INFO type SALV_WD_T_STRING
      !IS_HEADER_INFO type TY_CONSIS_CHK_HEADER_STR .
  class-methods SITEM_SKIP_STAT_UPDATE_MASS
    importing
      !IV_TARGET_STACK type TY_BORMNR
      !IT_SITEM_SKIP type TY_SITEM_SKIP_TAB .
  class-methods SITEM_CONSISTENCY_RESULT_DEL
    importing
      !IV_TARGET_STACK type CHAR20 .
  class-methods SITEM_SKIP_STAT_UPDATE_SINGLE
    importing
      !IV_TARGET_STACK type TY_BORMNR
      !IS_SITEM_SKIP type TY_SITEM_SKIP_STR
      !IV_EXEMP_ACTION type BOOLEAN optional .
  class-methods SMDB_CONTENT_SOURCE_GET
    returning
      value(RV_SMDB_SOURCE) type STRING .
  class-methods SMDB_CONTENT_SOURCE_SAVE
    importing
      value(IV_SMDB_SOURCE) type STRING .
  class-methods SMDB_CONTENT_USE_MANUAL_4_SAP
    returning
      value(RV_SMDB_SOURCE) type STRING .
  class-methods SMDB_CONTENT_TIME_GET
    exporting
      !EV_TIME_UTC_SAP type TIMESTAMP
      !EV_TIME_UTC_SAP_STR type STRING
      !EV_TIME_UTC_MANUAL type TIMESTAMP
      !EV_TIME_UTC_MANUAL_STR type STRING .
  class-methods SMDB_CONTENT_UPLOAD
    returning
      value(RV_ERR_MESG_STR) type STRING .
  class-methods IS_TEST_MODE
    returning
      value(RV_RESULT) type BOOLEAN .
  class-methods SMDB_CONTENT_FETCH_FROM_SAP
    importing
      !IV_SYSTEM_TYPE type STRING optional
    returning
      value(RV_SUCCESS) type FLAG .
  class-methods GET_TARGET_S4_VERSION
    exporting
      value(ET_VERSION) type TY_CONV_TARGET_STACK_TAB
      value(ET_STACK) type TY_PPMS_STACK_TAB
    exceptions
      SMDB_CONTNET_NOT_FOUND
      ERROR .
  class-methods GET_LED_ICON_FROM_TIMESTAMP
    importing
      !IV_TIME type TIMESTAMP
    returning
      value(RV_ICON) type STRING .