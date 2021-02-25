*&---------------------------------------------------------------------*
*& Report RACORR_DELETE_DOUBLED_DOC_IT
*&---------------------------------------------------------------------*
*& This report selects DB entries in FI-AA posting table FAAT_DOC_IT that fulfil following conditions:
*& - The same DB key occurs at least twice
*&   Hint: FAAT_DOC_IT has no primary key at DB level (only in the data dictionary structure)
*&
*& Following error situation for duplicate entries is corrected by this report:
*& -  Duplicate entries created by AFAR with following conditions:
*&       FAAT_DOC_IT-BWASL      =  999
*&       FAAT_DOC_IT-MOVCAT     =  00
*&       FAAT_DOC_IT-POPER      =  000
*&       FAAT_DOC_IT-MIG_SOURCE <> V
*&       FAAT_DOC_IT-MIG_SOURCE <> A
*&       It is checked that ALL other fields are identical within the duplicate entries for the same key
*& - The amount fields of above duplicate entries are not necessarily identical
*&    a) In test run duplicate entries of above type are listed with yellow traffic light.
*&    b) In productive run these duplicate entries are listed with green traffic light if no error occurs:
*&       The duplicate DB entries are deleted and a single new DB entry is inserted per key field combination.
*&       The inserted DB entry contains the sum of amounts of the corresponding deleted duplicate DB entries.
*&       This ensures that the balances on asset master data and on company code level stay unchanged.
*& - Other types of duplicate entries in FAAT_DOC_IT are listed with red treffic light and STOP the correction.
*&       Red traffic lights require a manual analysis to be executed by SAP Support
*&
*& Additional Remarks:
*&   This report corrects duplicate entries in FAAT_DOC_IT only in productive run.
*&   This report works cross-client and can be executed out of client 000.
*&   Changed data is written to application log under object = 'FINS', subobject = 'FINS_MIG' and extnum = report name
*&   The application log can be accessed after report execution with transaction SLG1.
*&---------------------------------------------------------------------*
*& List of changes:
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT faa_delete_duplicate_doc_it.

*--------------------------------------------------------------------*
* DATA DEFINITION FOR CORRECTION REPORT
*--------------------------------------------------------------------*
" Definitions specific for select-options only
DATA:
  gv_client             LIKE sy-mandt,
  gv_string             TYPE string,
  gv_mode_str           TYPE string,
  gv_msg                TYPE string,
  gv_bukrs              TYPE faat_doc_it-bukrs,
  gv_gjahr              TYPE faat_doc_it-gjahr,
  gv_anln1              TYPE faat_doc_it-anln1,
  gv_timestamp          TYPE timestamp,
  gv_date_time_conv     TYPE char20,
  gb_error_occurred     TYPE abap_bool,
  gb_no_data            TYPE abap_bool,
  gv_ins_total_expected TYPE i VALUE 0,
  gv_del_total_expected TYPE i VALUE 0,
  gv_del_records_ok     TYPE i VALUE 0,
  gv_ins_records_ok     TYPE i VALUE 0,
  gv_del_records_err    TYPE i VALUE 0,
  gv_ins_records_err    TYPE i VALUE 0,
  gt_faat_doc_it        TYPE STANDARD TABLE OF faat_doc_it, " only for comparison in unit test
  lb_l1_error_occurred  TYPE abap_bool,
  lv_l1_del_records_ok  TYPE i VALUE 0,
  lv_l1_ins_records_ok  TYPE i VALUE 0,
  lv_l1_del_records_err TYPE i VALUE 0,
  lv_l1_ins_records_err TYPE i VALUE 0,
  go_log                TYPE REF TO cl_fins_fi_log.

*--------------------------------------------------------------------*
* Selection-Screen
*--------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK 1 WITH FRAME TITLE scrtit.

  PARAMETERS:
    p_client TYPE faat_doc_it-mandt DEFAULT sy-mandt.
  SELECTION-SCREEN SKIP 1.

  SELECT-OPTIONS:
    so_bukrs FOR gv_bukrs,
    so_anln1 FOR gv_anln1,
    so_gjahr FOR gv_gjahr.
  SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN END OF BLOCK 1.

SELECTION-SCREEN BEGIN OF BLOCK 2 WITH FRAME TITLE subscr3.
  PARAMETERS: p_test  TYPE rarep-xtest DEFAULT abap_on.
SELECTION-SCREEN END OF BLOCK 2.

*--------------------------------------------------------------------*
* DEFERRED CLASS DEFINITION
*--------------------------------------------------------------------*
" Class definition deferred necessary for data declaration of objects
CLASS lcl_handle_events DEFINITION DEFERRED.

*---------------------------------------------------------------------*
* INTERFACE       lif_corr_doc_it_del_duplicates
*---------------------------------------------------------------------*

INTERFACE lif_corr_doc_it_del_duplicates.

  " Types
  TYPES:
    BEGIN OF ty_s_faat_doc_it_analyze,
      icon                 TYPE aa_icon,
      flg_auto_corr        TYPE abap_bool,
      flg_man_corr         TYPE abap_bool,
      flg_corr_done        TYPE abap_bool,
      flg_ident_attibutes  TYPE abap_bool,
      flg_depr_amount      TYPE abap_bool,
      flg_diff_group_asset TYPE abap_bool,
      count_multiple       TYPE int4,       " lower releases: instead of internal type int8
    END OF ty_s_faat_doc_it_analyze.
  TYPES BEGIN OF ty_s_faat_doc_it_err.
  INCLUDE TYPE ty_s_faat_doc_it_analyze.
  INCLUDE TYPE faat_doc_it.
  TYPES END OF ty_s_faat_doc_it_err.
  TYPES: ty_t_faat_doc_it_err TYPE TABLE OF ty_s_faat_doc_it_err.
  TYPES: ty_t_x031l_tab TYPE STANDARD TABLE OF x031l.
  TYPES: ty_t_t000_tab TYPE STANDARD TABLE OF t000.

* List of asset keys per ledger group (that require manual correction)
  TYPES: BEGIN OF ty_s_asset_per_client,
           mandt TYPE sy-mandt,
           bukrs TYPE faat_doc_it-bukrs,
           anln1 TYPE anln1,
           anln2 TYPE anln2,
         END   OF ty_s_asset_per_client,
         ty_t_asset_per_client TYPE TABLE OF ty_s_asset_per_client.

  " Constants from cl_faa_bcf_services
  CONSTANTS:
    gc_poper_bcf TYPE poper VALUE '000'                              ##NO_TEXT.

  " Support lower releases: copy of Constants from if_faa_posting_constants
  CONSTANTS:
    BEGIN OF gc_mig_source,
      asset_migration TYPE acdoca-mig_source  VALUE 'A'              ##NO_TEXT,
      new_depr_area   TYPE acdoca-mig_source  VALUE 'V'              ##NO_TEXT,
    END OF gc_mig_source.
  CONSTANTS:
    BEGIN OF gc_movcat,
      bcf TYPE faa_movcat VALUE '00'                                 ##NO_TEXT,
    END OF gc_movcat .
  CONSTANTS:
    BEGIN OF gc_awtyp,
      afar TYPE rlambu-awtyp VALUE '!AFA!',                         "##NOTEXT,
      bcf  TYPE rlambu-awtyp VALUE '!BCF!',                         "##NOTEXT,
    END OF gc_awtyp .
  CONSTANTS:
    BEGIN OF gc_tty,
      bcf TYPE bwasl VALUE '999',                           "##NOTEXT,
    END OF gc_tty .

  " local
  CONSTANTS:
    BEGIN OF gc_component,
      sapscore TYPE dlvunit VALUE 'SAPSCORE'                            ##NO_TEXT,
      s4core   TYPE dlvunit VALUE 'S4CORE'                              ##NO_TEXT,
      sap_fin TYPE dlvunit VALUE 'SAP_FIN'                             ##NO_TEXT,
    END OF gc_component.

ENDINTERFACE. " lif_corr_doc_it_del_duplicates


*--------------------------------------------------------------------*
* DATA DEFINITION FOR CORRECTION REPORT (here typing depends on loval definitions)
*--------------------------------------------------------------------*

DATA:
  gr_events          TYPE REF TO lcl_handle_events,
  gt_faat_doc_it_err TYPE lif_corr_doc_it_del_duplicates=>ty_t_faat_doc_it_err.   " output table is not allowed to be sorted

*---------------------------------------------------------------------*
*       CLASS lcl_handle_events DEFINITION
*---------------------------------------------------------------------*
* Define a local class for handling events of cl_salv_table
*---------------------------------------------------------------------*
CLASS lcl_handle_events DEFINITION.

*----------------------------------------------------------------------
  PUBLIC SECTION.
*----------------------------------------------------------------------

    INTERFACES  lif_corr_doc_it_del_duplicates.

    METHODS:
      on_user_command FOR EVENT added_function OF cl_salv_events
        IMPORTING e_salv_function,

      on_link_click FOR EVENT link_click OF cl_salv_events_table
        IMPORTING row column.

*----------------------------------------------------------------------
  PRIVATE SECTION.
*----------------------------------------------------------------------
    CLASS-METHODS:
      _show_asset
        IMPORTING
          is_row TYPE lif_corr_doc_it_del_duplicates=>ty_s_faat_doc_it_err.

ENDCLASS. "lcl_handle_events DEFINITION

*---------------------------------------------------------------------*
*       CLASS lcl_handle_log DEFINITION
*---------------------------------------------------------------------*
* Define a local class for handling events of cl_salv_table
*---------------------------------------------------------------------*
CLASS lcl_handle_log DEFINITION CREATE PRIVATE.
*----------------------------------------------------------------------
  PUBLIC SECTION.
*----------------------------------------------------------------------

    INTERFACES  lif_corr_doc_it_del_duplicates.

    CLASS-METHODS:

      get_instance
        RETURNING VALUE(ro_instance) TYPE REF TO lcl_handle_log,

      show_output.

    CLASS-DATA:
      gv_icon_red    TYPE char50,
      gv_icon_yellow TYPE char50,
      gv_icon_green  TYPE char50.

*----------------------------------------------------------------------
  PRIVATE SECTION.
*----------------------------------------------------------------------
    CLASS-METHODS:

      _set_columns
        IMPORTING
          io_table TYPE REF TO cl_salv_table,

      _set_functions
        IMPORTING
          io_table TYPE REF TO cl_salv_table,

      _set_header
        IMPORTING
          io_table TYPE REF TO cl_salv_table,

      _set_sort
        IMPORTING
          io_table TYPE REF TO cl_salv_table,

      _initialize,

      _create_icon.

ENDCLASS. "lcl_handle_log DEFINITION

*---------------------------------------------------------------------*
* Define a local class for execution of the correction functionality
*---------------------------------------------------------------------*
CLASS lcl_execute DEFINITION CREATE PRIVATE.

*----------------------------------------------------------------------
  PUBLIC SECTION.
*----------------------------------------------------------------------

    INTERFACES  lif_corr_doc_it_del_duplicates.

    CLASS-METHODS:
      get_instance
        IMPORTING
          io_log             TYPE REF TO cl_fins_fi_log
        RETURNING
          VALUE(ro_instance) TYPE REF TO lcl_execute.

    METHODS:
      is_suitable_release
        RETURNING
          VALUE(rb_is_suitable_release) TYPE abap_bool,

      check_authority_for_bukrs
        IMPORTING
          iv_bukrs       TYPE bukrs
          ib_test        TYPE abap_bool
        RETURNING
          VALUE(rv_stop) TYPE abap_bool,

      get_amount_curr_fld_for_select
        IMPORTING
          io_log            TYPE REF TO cl_fins_fi_log
        EXPORTING
          eb_error_occurred TYPE abap_bool,

      get_key_fld_for_select
        IMPORTING
          io_log            TYPE REF TO cl_fins_fi_log
        EXPORTING
          eb_error_occurred TYPE abap_bool,

      get_data_fld_for_select
        IMPORTING
          io_log            TYPE REF TO cl_fins_fi_log
        EXPORTING
          eb_error_occurred TYPE abap_bool,

      get_clients_to_be_processed
        IMPORTING
          iv_client         TYPE       t093c-mandt OPTIONAL
          io_log            TYPE REF TO cl_fins_fi_log
        EXPORTING
          et_t000           TYPE       lif_corr_doc_it_del_duplicates=>ty_t_t000_tab
          eb_error_occurred TYPE       abap_bool,

      process_data
        IMPORTING
          VALUE(iv_client)      TYPE sy-mandt
          ib_test               TYPE abap_bool
          io_log                TYPE REF TO cl_fins_fi_log
        EXPORTING
          et_faat_doc_it_err    TYPE lif_corr_doc_it_del_duplicates=>ty_t_faat_doc_it_err
          eb_no_data            TYPE abap_bool
          eb_error_occurred     TYPE abap_bool
          ev_l1_del_records_ok  TYPE i
          ev_l1_ins_records_ok  TYPE i
          ev_l1_del_records_err TYPE i
          ev_l1_ins_records_err TYPE i,

      analyze_data_for_correction
        IMPORTING
          iv_client          TYPE sy-mandt
          ib_test            TYPE abap_bool
        EXPORTING
          eb_error_occurred  TYPE abap_bool
        CHANGING
          ct_faat_doc_it_err TYPE lif_corr_doc_it_del_duplicates=>ty_t_faat_doc_it_err,

      analyze_single_db_entry
        IMPORTING
          VALUE(iv_client)           TYPE sy-mandt
          ib_test                    TYPE abap_bool
        EXPORTING
          eb_error_occurred          TYPE abap_bool
        CHANGING
          cs_faat_doc_it_err         TYPE lif_corr_doc_it_del_duplicates=>ty_s_faat_doc_it_err
          cb_autocorrection_possible TYPE abap_bool,

      ddif_nametab_get
        IMPORTING
          iv_tabname        TYPE        ddobjname
          io_log            TYPE REF TO cl_fins_fi_log
        EXPORTING
          eb_error_occurred TYPE abap_bool
        CHANGING
          ct_x031l_tab      TYPE        lif_corr_doc_it_del_duplicates~ty_t_x031l_tab
        RAISING
          cm_faa_t100,

      process_update_operation
        IMPORTING
          iv_client          TYPE sy-mandt
          ib_test            TYPE abap_bool
          iv_package         TYPE n
        EXPORTING
          eb_error_occurred  TYPE abap_bool
          ev_del_records_ok  TYPE i
          ev_ins_records_ok  TYPE i
          ev_del_records_err TYPE i
          ev_ins_records_err TYPE i
        CHANGING
          ct_faat_doc_it_err TYPE lif_corr_doc_it_del_duplicates=>ty_t_faat_doc_it_err.

    CONSTANTS:
      gc_package_size        TYPE i VALUE 500.

    DATA:
      mv_bukrs            TYPE          bukrs,
      mt_item_key_column  TYPE TABLE OF string,
      mt_item_data_column TYPE TABLE OF string,
      mt_amount_columns   TYPE TABLE OF string,
      mo_log              TYPE REF TO cl_fins_fi_log.

ENDCLASS. " lcl_execute

*&---------------------------------------------------------------------*
*& Report RACORR_ANALYZE_FAAT_DOC_IT
*& Implementation of the report logic
*&---------------------------------------------------------------------*

"--------------------------------------------------------------------"
" BODY
"--------------------------------------------------------------------"

****************** Define texts for selection-screen ***************
*--------------------------------------------------------------------*
INITIALIZATION.
*--------------------------------------------------------------------*
  MOVE 'Parameters'                                                   TO scrtit          ##NO_TEXT.
  MOVE 'Test Run Parameters'                                          TO subscr3         ##NO_TEXT.

*--------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
*--------------------------------------------------------------------*

  " DEFAULT is that in client 000 always all cients are executed
  IF sy-mandt EQ '000'.
    CLEAR p_client.
  ENDIF.

****************** Start selecting data ****************************
*--------------------------------------------------------------------*
START-OF-SELECTION.
*--------------------------------------------------------------------*

  "------------------------------------------------------------------------------
  " Create instances for processing
  "------------------------------------------------------------------------------
  " Create local log (ALV List)
  DATA(go_handle_log)    = lcl_handle_log=>get_instance( ).


  " Create SLG1 application log and add test/production run message
  DATA(lv_extnum) = CONV balnrext( sy-repid ).
  go_log          = cl_fins_fi_log=>get_log(
                   iv_subobject = 'FINS_MIG'
                   iv_extnum    = lv_extnum ).

  " Create instance of correction class
  DATA(go_execute) = lcl_execute=>get_instance( io_log = go_log ).

  IF NOT go_execute IS BOUND.
    " Error at creation of instance
    gb_error_occurred = abap_true.
    gb_no_data        = abap_true.
  ENDIF.

  "------------------------------------------------------------------------------
  " Set processing mode
  "------------------------------------------------------------------------------
  IF p_test = abap_true.
    MESSAGE w047(fins_fi_mig) INTO DATA(lv_msg). "***** Test Run ******
  ELSE.
    MESSAGE w048(fins_fi_mig) INTO lv_msg. "***** Productive Run ******
  ENDIF.
  go_log->add_current_sy_message( iv_probclass = '1' ).

  "--------------------------------------------------------------------"
  " Write start time stamp
  "--------------------------------------------------------------------"

  GET TIME STAMP FIELD gv_timestamp.
  CALL FUNCTION 'CONVERSION_EXIT_TSTLC_OUTPUT'
    EXPORTING
      input  = gv_timestamp
    IMPORTING
      output = gv_date_time_conv.

  "------------------------------------------------------------------------------
  " Add message to report protocol:
  "------------------------------------------------------------------------------
  " End of conversion report &1 at &2
  CONCATENATE 'Start of report: ' sy-repid INTO gv_string SEPARATED BY space             ##NO_TEXT.
  MESSAGE i900(ac) WITH gv_string INTO lv_msg.
  go_log->add_current_sy_message( iv_probclass = '1' ).

  CONCATENATE  'Start timestamp: ' gv_date_time_conv INTO gv_string SEPARATED BY space   ##NO_TEXT.
  MESSAGE i900(ac) WITH gv_string INTO lv_msg.
  go_log->add_current_sy_message( iv_probclass = '1' ).

  "--------------------------------------------------------------------"
  " Execute table conversion only if current system is a SAP_FIN or S4CORE release
  "--------------------------------------------------------------------"
  IF go_execute IS BOUND.
    IF go_execute->is_suitable_release( ) EQ abap_false.
      " Abort processsing: System precondition not fulfilled
      gv_string = 'Correction report requires releases SAP_FIN or S4CORE'                          ##NO_TEXT.
      gv_string = gv_string && ' '.
      MESSAGE gv_string TYPE 'A'.
      gb_error_occurred = abap_true.
    ENDIF.
  ENDIF.

  "--------------------------------------
  " Get clients for analysis/correction
  "--------------------------------------
  IF go_execute IS BOUND.
    go_execute->get_clients_to_be_processed(
      EXPORTING
        iv_client         = p_client
        io_log            = go_log
      IMPORTING
        et_t000           = DATA(lt_t000)
        eb_error_occurred = lb_l1_error_occurred ).

    " Errors handling
    IF lb_l1_error_occurred EQ abap_true.
      gb_error_occurred = abap_true.
      gb_no_data        = abap_true.
    ENDIF.
  ENDIF.

  "------------------------------------------------------------------------------
  " Start of Client Loop: execute final actions
  "------------------------------------------------------------------------------

  " No errors allowed in above preparation including client selection
  IF gb_error_occurred EQ abap_false AND
     go_execute        IS BOUND.

    " Any client with processed data has to reset the flag 'no data'
    gb_no_data           = abap_true.

    " Process all clients one after the other (in higher releases processing with range of clients would be better)
    LOOP AT lt_t000 ASSIGNING FIELD-SYMBOL(<ls_t000>).
      gv_client = <ls_t000>-mandt.

      "------------------------------------------------------------------------------
      " Add message to report protocol:
      "------------------------------------------------------------------------------
      " End of client &1
      CONCATENATE 'Start processing of client: ' gv_client INTO gv_string SEPARATED BY space       ##NO_TEXT.
      MESSAGE i900(ac) WITH gv_string INTO lv_msg.
      go_log->add_current_sy_message( iv_probclass = '1' ).

      "------------------------------------------------------------------------------
      " Select, analyze and correct duplicate entries in DB table FAAT_DOC_IT for a single client
      "------------------------------------------------------------------------------
      lb_l1_error_occurred = abap_false.

      go_execute->process_data(
                EXPORTING
                  iv_client             = gv_client
                  ib_test               = p_test
                  io_log                = go_log
                IMPORTING
                  eb_no_data            = DATA(lb_no_data)
                  et_faat_doc_it_err    = DATA(lt_faat_doc_it_err)
                  eb_error_occurred     = lb_l1_error_occurred
                  ev_l1_del_records_ok  = lv_l1_del_records_ok
                  ev_l1_ins_records_ok  = lv_l1_ins_records_ok
                  ev_l1_del_records_err = lv_l1_del_records_err
                  ev_l1_ins_records_err = lv_l1_ins_records_err ).

      "Error Handling:
      IF lb_l1_error_occurred = abap_true.
        gb_error_occurred = abap_true.
      ENDIF.
      " The first one clears the flag 'no data'
      IF lb_no_data = abap_false.
        gb_no_data = abap_false.
      ENDIF.
      " Export no. records (independent of error or not)
      gv_del_records_ok  = gv_del_records_ok  + lv_l1_del_records_ok.
      gv_ins_records_ok  = gv_ins_records_ok  + lv_l1_ins_records_ok.
      gv_del_records_err = gv_del_records_err + lv_l1_del_records_err.
      gv_ins_records_err = gv_ins_records_err + lv_l1_ins_records_err.

      "------------------------------------------------------------------------------
      " End of Cient Loop: execute final actions
      "------------------------------------------------------------------------------
      APPEND LINES OF lt_faat_doc_it_err TO gt_faat_doc_it_err.       " keep result for protocol
      CLEAR:
        lb_l1_error_occurred,
        lb_no_data,
        lt_faat_doc_it_err,
        lv_l1_del_records_ok,
        lv_l1_ins_records_ok,
        lv_l1_del_records_err,
        lv_l1_ins_records_err.

      "------------------------------------------------------------------------------
      " End of Client loop
      "------------------------------------------------------------------------------
      " End of client &1
      CONCATENATE 'End processing of client: ' gv_client INTO gv_string SEPARATED BY space                   ##NO_TEXT.
      MESSAGE i900(ac) WITH gv_string INTO lv_msg.
      go_log->add_current_sy_message( iv_probclass = '1' ).

    ENDLOOP. " at lt_t000

    "------------------------------------------------------------------------------
    " Protocol header for whole report execution in all clients:
    "------------------------------------------------------------------------------
    "-- Preparation test/productive run
    IF p_test EQ abap_true.
      gv_mode_str = ' test '                                                                                 ##NO_TEXT.
    ELSE.
      gv_mode_str = ' productive '                                                                           ##NO_TEXT.
    ENDIF.  "p_test

    " Total DB Changes in test run in client
    MESSAGE i900(ac) WITH 'Total DB Changes: ' && gv_mode_str && ' run in all clients: ' INTO lv_msg         ##NO_TEXT.
    go_log->add_current_sy_message( iv_probclass = '1' ).
    "------------------------------------------------------------------------------
    " Add Successful run message to report protocol:
    "------------------------------------------------------------------------------
    " Total Successful DB deletions in test run
    MESSAGE i900(ac) WITH 'Total succ. DB deletions in ' && gv_mode_str && ' run: ' && gv_del_records_ok INTO lv_msg   ##NO_TEXT.
    go_log->add_current_sy_message( iv_probclass = '1' ).
    " Total Successful DB inserts in test run
    MESSAGE i900(ac) WITH 'Total succ. DB inserts in ' && gv_mode_str && ' run: '   && gv_ins_records_ok INTO lv_msg   ##NO_TEXT.
    go_log->add_current_sy_message( iv_probclass = '1' ).

    "------------------------------------------------------------------------------
    " Add Failing run message to report protocol:
    "------------------------------------------------------------------------------
    " Total Failing DB deletions in test run
    MESSAGE i900(ac) WITH 'Total Failing DB deletions in ' && gv_mode_str && ' run: ' && gv_del_records_err INTO lv_msg   ##NO_TEXT.
    go_log->add_current_sy_message( iv_probclass = '1' ).
    " Total Failing DB inserts in test run
    MESSAGE i900(ac) WITH 'Total Failing DB inserts in ' && gv_mode_str && ' run: '   && gv_ins_records_err INTO lv_msg   ##NO_TEXT.
    go_log->add_current_sy_message( iv_probclass = '1' ).

  ENDIF. " gb_error_occurred

END-OF-SELECTION.

  IF p_test = abap_true.
    MESSAGE w047(fins_fi_mig) INTO lv_msg. "***** Test Run ******
  ELSE.
    MESSAGE w048(fins_fi_mig) INTO lv_msg. "***** Productive Run ******
  ENDIF.
  go_log->add_current_sy_message( iv_probclass = '1' ).

  "--------------------------------------------------------------------"
  " Write start time stamp
  "--------------------------------------------------------------------"

  GET TIME STAMP FIELD gv_timestamp.
  CALL FUNCTION 'CONVERSION_EXIT_TSTLC_OUTPUT'
    EXPORTING
      input  = gv_timestamp
    IMPORTING
      output = gv_date_time_conv.

  "------------------------------------------------------------------------------
  " Add message to report protocol:
  "------------------------------------------------------------------------------
  " End of conversion report &1 at &2
  CONCATENATE 'End of report: ' sy-repid INTO gv_string SEPARATED BY space                                   ##NO_TEXT.
  MESSAGE i900(ac) WITH gv_string INTO lv_msg.
  go_log->add_current_sy_message( iv_probclass = '1' ).

  CONCATENATE  'End timestamp: ' gv_date_time_conv INTO gv_string SEPARATED BY space                         ##NO_TEXT.
  MESSAGE i900(ac) WITH gv_string INTO lv_msg.
  go_log->add_current_sy_message( iv_probclass = '1' ).

  "------------------------------------------------------------------------------
  " <<<<<<<<<<<<<<<<<< FAAT_DOC_IT DB Commit Handling    >>>>>>>>>>>>>>>>>>>>>>>>
  "------------------------------------------------------------------------------

  IF gb_error_occurred EQ abap_false AND
     p_test            EQ abap_false.

    COMMIT WORK AND WAIT.

    "------------------------------------------------------------------------------
    " Add success message to report protocol:
    "------------------------------------------------------------------------------
    " MESSAGE w742(fins_fi_mig) INTO lv_msg. "***** Data Saved Succesfully ******
    MESSAGE i900(ac) WITH 'Data Saved Succesfully' INTO lv_msg                                               ##NO_TEXT.
    go_log->add_current_sy_message( iv_probclass = '1' ).

  ELSE.

    ROLLBACK WORK.

    "------------------------------------------------------------------------------
    " Add failure message to report protocol:
    "------------------------------------------------------------------------------
    " MESSAGE w743(fins_fi_mig) INTO lv_msg. "***** No Data Saved ******
    MESSAGE i900(ac) WITH 'No Data Saved' INTO lv_msg                                                        ##NO_TEXT.
    go_log->add_current_sy_message( iv_probclass = '1' ).

  ENDIF.

  "------------------------------------------------------------------------------
  " Set traffic light for successful correction only after commit
  " Other display flags were already set in METHOD analyze_data_for_correction of LCL_EXECUTE
  "------------------------------------------------------------------------------
  " Graphical output of check algorithm: use icons

  LOOP AT gt_faat_doc_it_err ASSIGNING FIELD-SYMBOL(<ls_faat_doc_it_err>).
    DATA(lv_icon_before_change) = <ls_faat_doc_it_err>-icon.
    <ls_faat_doc_it_err>-icon = SWITCH #( <ls_faat_doc_it_err>-flg_corr_done
                          WHEN abap_true THEN lcl_handle_log=>gv_icon_green
                          ELSE lv_icon_before_change ).
  ENDLOOP. " at lt_faat_doc_it_err


  "------------------------------------------------------------------------------
  " Determine total number of expected changes
  "------------------------------------------------------------------------------
  CLEAR:
    gv_del_total_expected,
    gv_ins_total_expected,
    gt_faat_doc_it.

  LOOP AT gt_faat_doc_it_err ASSIGNING <ls_faat_doc_it_err>.
    ADD <ls_faat_doc_it_err>-count_multiple TO gv_del_total_expected.
    ADD 1 TO gv_ins_total_expected.
    " For comparison only:
    APPEND INITIAL LINE TO gt_faat_doc_it ASSIGNING FIELD-SYMBOL(<ls_faat_doc_it>).
    IF <ls_faat_doc_it>     IS ASSIGNED AND
       <ls_faat_doc_it_err> IS ASSIGNED.
      MOVE-CORRESPONDING <ls_faat_doc_it_err> TO <ls_faat_doc_it>.
    ENDIF.
  ENDLOOP. " at lt_faat_doc_it_err

  " Sort result in FAAT_DOC_IT table format (result identical for both test and productive mode)
  " Sort by primary key is not sufficient due to duplicate entries with different amounts
  " Use amount fields that are valid since release SAP_FIN 720
  SORT gt_faat_doc_it BY
    bukrs
    anln1
    anln2
    gjahr
    awtyp
    awref
    aworg
    awsys
    subta
    afabe
    slalittype
    drcrk
    hsl
    ksl
    osl
    vsl.

  "------------------------------------------------------------------------------
  " <<<<<<<<<<<<<<<< Save report protocol in productive run >>>>>>>>>>>>>>>>>>>>>>>
  "------------------------------------------------------------------------------
  IF p_test EQ abap_false.
    go_log->save_log( ).

    COMMIT WORK AND WAIT.

  ENDIF.

  "------------------------------------------------------------------------------
  " Creation of ALV output list
  "------------------------------------------------------------------------------
  go_handle_log->show_output( ).

  "------------------------------------------------------------------------------
  " For report restart: switch back again to test mode in User Interface
  "------------------------------------------------------------------------------
  p_test = abap_true.

*---------------------------------------------------------------------*
* End of report
*---------------------------------------------------------------------*



*---------------------------------------------------------------------*
*       CLASS lcl_handle_events IMPLEMENTATION
*---------------------------------------------------------------------*
* Implement the events for handling the events of cl_salv_table
*---------------------------------------------------------------------*
CLASS lcl_handle_events IMPLEMENTATION.
*----------------------------------------------------------------------
* P U B L I C   M E T H O D S
*----------------------------------------------------------------------
  METHOD on_user_command.
* PRECONDITION

* DEFINITIONS

* BODY
    CASE e_salv_function.
      WHEN '&F03'   OR
           '&F15'   OR
           '&F12'.
        SET SCREEN 0.
        LEAVE SCREEN.

      WHEN 'MESS_LIST'.
        " Show log messages
        go_log->show_current_log( i_xpopup = abap_false ).

    ENDCASE.

* POSTCONDITION
  ENDMETHOD.

  METHOD on_link_click.
* PRECONDITION

* DEFINITIONS

* BODY
    TRY.
        "      Determine Output record
        DATA(ls_row) = gt_faat_doc_it_err[ row ].

      CATCH cx_sy_itab_line_not_found.
        RETURN.
    ENDTRY.

    CASE column.
      WHEN 'ANLN1' OR 'ANLN2'.

        _show_asset( ls_row ).

    ENDCASE.

* POSTCONDITION

  ENDMETHOD.
*----------------------------------------------------------------------
* P R I V A T E   M E T H O D S
*----------------------------------------------------------------------
  METHOD _show_asset.
* PRECONDITION
    CHECK sy-mandt EQ is_row-mandt. " Show asset only possible in logon client

* DEFINITIONS

* BODY
    SET PARAMETER ID 'BUK' FIELD is_row-bukrs.
    SET PARAMETER ID 'AN1' FIELD is_row-anln1.
    SET PARAMETER ID 'AN2' FIELD is_row-anln2.

    CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
      EXPORTING
        tcode  = 'AW01N'
      EXCEPTIONS
        ok     = 1
        not_ok = 2
        OTHERS = 3.

    IF sy-subrc = 1.
      CALL TRANSACTION 'AW01N' AND SKIP FIRST SCREEN.    "#EC CI_CALLTA
    ENDIF.

* POSTCONDITION
  ENDMETHOD.

ENDCLASS. " lcl_handle_events

*---------------------------------------------------------------------*
*       CLASS lcl_handle_log IMPLEMENTATION
*---------------------------------------------------------------------*
* Implement the output list
*---------------------------------------------------------------------*
CLASS lcl_handle_log IMPLEMENTATION.
*----------------------------------------------------------------------
* P U B L I C   M E T H O D S
*----------------------------------------------------------------------

  METHOD get_instance.
    CREATE OBJECT ro_instance.
    ro_instance->_initialize( ).
  ENDMETHOD.


  METHOD show_output.
* PRECONDITION

* DEFINITIONS
    DATA:
    lo_table         TYPE REF TO cl_salv_table.

    CONSTANTS:
      lc_pfstatus      TYPE sypfkey       VALUE 'ALV_STANDARD',
      lc_pfstat_rep_id TYPE syst_cprog    VALUE 'FAA_DEPRECIATION_POST'.

* BODY
    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lo_table
          CHANGING
            t_table      = gt_faat_doc_it_err[] ).

        lo_table->set_screen_status( pfstatus      = lc_pfstatus
                                     report        = lc_pfstat_rep_id
                                     set_functions = lo_table->c_functions_all        ).

        _set_header( io_table   = lo_table  ).

        _set_columns( io_table   = lo_table  ).

        _set_sort( io_table = lo_table ).

        _set_functions( io_table = lo_table ).

        " Register Events
        CREATE OBJECT gr_events.
        DATA(lo_events) = lo_table->get_event( ).
        SET HANDLER gr_events->on_user_command FOR lo_events.
        SET HANDLER gr_events->on_link_click   FOR lo_events .

      CATCH cx_salv_wrong_call cx_salv_msg cx_salv_object_not_found. "#EC NO_HANDLER
        RETURN.

    ENDTRY.

    lo_table->display( ).

* POSTCONDITION

  ENDMETHOD.

*----------------------------------------------------------------------
* P R I V A T E   M E T H O D S
*----------------------------------------------------------------------

  METHOD _set_columns.
* PRECONDITION

* DEFINITIONS
    DATA:
      lo_column   TYPE REF TO cl_salv_column_list,
      lv_position TYPE i,
      ls_color    TYPE lvc_s_colo.

* BODY
    " Get column information
    DATA(lo_columns) = io_table->get_columns( ).

    TRY.

        lo_column ?= lo_columns->get_column( 'ICON' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_key( abap_true ).
        lo_column->set_alignment( if_salv_c_alignment=>centered ).
        lo_column->set_icon( ).
        lo_columns->set_column_position( columnname = 'ICON'                   position   = 1 ).

        lo_column ?= lo_columns->get_column( 'FLG_AUTO_CORR' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        lo_column->set_key( abap_true ).
        lo_column->set_short_text( 'Auto').
        lo_column->set_long_text( 'Flag: Automatic Correction').
        lo_columns->set_column_position( columnname = 'FLG_MAN_CORR'           position   = 2 ).

        lo_column ?= lo_columns->get_column( 'FLG_MAN_CORR' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        lo_column->set_key( abap_true ).
        lo_column->set_short_text( 'Manual').
        lo_column->set_long_text( 'Flag: Manual Correction').
        lo_columns->set_column_position( columnname = 'FLG_AUTO_CORR'          position   = 3 ).

        lo_column ?= lo_columns->get_column( 'FLG_CORR_DONE' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        lo_column->set_key( abap_true ).
        lo_column->set_short_text( 'Corrected').
        lo_column->set_long_text( 'Flag: Correction Successfully Done').
        lo_columns->set_column_position( columnname = 'FLG_CORR_DONE'          position   = 4 ).

        lo_column ?= lo_columns->get_column( 'FLG_IDENT_ATTIBUTES' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        lo_column->set_key( abap_true ).
        lo_column->set_short_text( 'IdentAttr').
        lo_column->set_long_text( 'Flag: Identical attribute fields').
        lo_columns->set_column_position( columnname = 'FLG_IDENT_ATTIBUTES'    position   = 5 ).

        lo_column ?= lo_columns->get_column( 'FLG_DEPR_AMOUNT' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        lo_column->set_key( abap_true ).
        lo_column->set_short_text( 'DeprAmount' ).
        lo_column->set_long_text( 'Flag: Depreciation amount' ).
        lo_columns->set_column_position( columnname = 'FLG_DEPR_AMOUNT'        position   = 6 ).

        lo_column ?= lo_columns->get_column( 'FLG_DIFF_GROUP_ASSET' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        lo_column->set_key( abap_true ).
        lo_column->set_short_text( 'GroupAsset').
        lo_column->set_long_text( 'Flag: Group asset field differs').
        lo_columns->set_column_position( columnname = 'FLG_DIFF_GROUP_ASSET'   position   = 7 ).

        lo_column ?= lo_columns->get_column( 'COUNT_MULTIPLE' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        lo_column->set_key( abap_true ).
        lo_column->set_short_text( 'Occurrence').
        lo_column->set_long_text( 'Number of Multiples').
        lo_columns->set_column_position( columnname = 'COUNT_MULTIPLE'         position   = 8 ).


        lo_column ?= lo_columns->get_column( 'MANDT' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_key( abap_true ).
        lo_columns->set_column_position( columnname = 'MANDT'                  position   = 9 ).

        lo_column ?= lo_columns->get_column( 'BUKRS' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_key( abap_true ).
        lo_columns->set_column_position( columnname = 'BUKRS'                  position   = 10 ).

        lo_column ?= lo_columns->get_column( 'ANLN1' ).
        lo_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
        lo_column->set_alignment( if_salv_c_alignment=>right ).
        lo_columns->set_column_position( columnname = 'ANLN1'                  position   = 11 ).

        lo_column ?= lo_columns->get_column( 'ANLN2' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
        lo_column->set_alignment( if_salv_c_alignment=>right ).
        lo_columns->set_column_position( columnname = 'ANLN2'                  position   = 12 ).

        lo_column ?= lo_columns->get_column( 'GJAHR' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_key( abap_true ).
        lo_columns->set_column_position( columnname = 'GJAHR'                  position   = 13 ).

        lo_column ?= lo_columns->get_column( 'AFABE' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_alignment( if_salv_c_alignment=>centered ).
        ls_color-col = col_positive.
        lo_column->set_color( ls_color  ).
        lo_columns->set_column_position( columnname = 'AFABE'                  position   = 14 ).

        lo_column ?= lo_columns->get_column( 'AWREF' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_alignment( if_salv_c_alignment=>centered ).
        ls_color-col = col_positive.
        lo_column->set_color( ls_color  ).
        lo_columns->set_column_position( columnname = 'AWREF'                  position   = 15 ).

        lo_column ?= lo_columns->get_column( 'AWORG' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_key( abap_true ).
        lo_columns->set_column_position( columnname = 'AWORG'                  position   = 16 ).

        lo_column ?= lo_columns->get_column( 'AWSYS' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_alignment( if_salv_c_alignment=>centered ).
        ls_color-col = col_positive.
        lo_column->set_color( ls_color  ).
        lo_column->set_key( abap_true ).
        lo_columns->set_column_position( columnname = 'AWSYS'                  position   = 17 ).

        lo_column ?= lo_columns->get_column( 'SUBTA' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_key( abap_true ).
        lo_columns->set_column_position( columnname = 'SUBTA'                  position   = 18 ).

        lo_column ?= lo_columns->get_column( 'AWTYP' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        ls_color-col = col_positive.
        lo_column->set_color( ls_color  ).
        lo_columns->set_column_position( columnname = 'AWTYP'                  position   = 19 ).

        lo_column ?= lo_columns->get_column( 'SLALITTYPE' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_alignment( if_salv_c_alignment=>centered ).
        lo_columns->set_column_position( columnname = 'SLALITTYPE'             position   = 20 ).

        lo_column ?= lo_columns->get_column( 'DRCRK' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_alignment( if_salv_c_alignment=>centered ).
        ls_color-col = col_positive.
        lo_column->set_color( ls_color  ).
        lo_columns->set_column_position( columnname = 'DRCRK'                  position   = 21 ).

        lo_column ?= lo_columns->get_column( 'PREC_AWTYP' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        ls_color-col = col_negative.
        lo_column->set_color( ls_color  ).
        lo_columns->set_column_position( columnname = 'PREC_AWTYP'             position   = 22 ).

        lo_column ?= lo_columns->get_column( 'BWASL' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        ls_color-col = col_negative.
        lo_column->set_color( ls_color  ).
        lo_columns->set_column_position( columnname = 'BWASL'                  position   = 23 ).

        lo_column ?= lo_columns->get_column( 'MIG_SOURCE' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        ls_color-col = col_negative.
        lo_column->set_color( ls_color  ).
        lo_columns->set_column_position( columnname = 'MIG_SOURCE'             position   = 24 ).

        lo_column ?= lo_columns->get_column( 'AWITEM' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        ls_color-col = col_positive.
        lo_column->set_color( ls_color  ).
        lo_columns->set_column_position( columnname = 'AWITEM'                 position   = 25 ).

        lo_column ?= lo_columns->get_column( 'LDGRP' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        lo_columns->set_column_position( columnname = 'LDGRP'                  position   = 26 ).

        lo_column ?= lo_columns->get_column( 'VORGN' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        lo_columns->set_column_position( columnname = 'VORGN'                  position   = 27 ).

        lo_column ?= lo_columns->get_column( 'BUDAT' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        lo_columns->set_column_position( columnname = 'BUDAT'                  position   = 28 ).

        lo_column ?= lo_columns->get_column( 'BZDAT' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        ls_color-col = col_positive.
        lo_column->set_color( ls_color  ).
        lo_columns->set_column_position( columnname = 'BZDAT'                  position   = 29 ).

        lo_column ?= lo_columns->get_column( 'POPER' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_alignment( if_salv_c_alignment=>centered ).
        ls_color-col = col_positive.
        lo_column->set_color( ls_color  ).
        lo_columns->set_column_position( columnname = 'POPER'                  position   = 30 ).

        lo_column ?= lo_columns->get_column( 'MOVCAT' ).
        lo_column->set_output_length( 10 ).
        lo_column->set_visible( abap_true ).
        ls_color-col = col_positive.
        lo_column->set_color( ls_color  ).
        lo_columns->set_column_position( columnname = 'MOVCAT'                 position   = 31 ).

      CATCH cx_salv_not_found cx_sy_dyn_call_illegal_type cx_salv_data_error.
        RETURN.

    ENDTRY.

* POSTCONDITION

  ENDMETHOD.

  METHOD _set_functions.
* PRECONDITION

* DEFINITIONS

* BODY
    DATA(lo_functions) = io_table->get_functions( ).

    TRY.
        lo_functions->set_function( name    =  'ACC_LIST'
                                    boolean = abap_false ).

        lo_functions->set_function( name    =  'SCHEDMON'
                                    boolean = abap_false ).

        lo_functions->set_function( name    =  'TRACE'
                                    boolean = abap_false ).

      CATCH cx_salv_not_found cx_salv_wrong_call.
        RETURN.

    ENDTRY.

* POSTCONDITION
  ENDMETHOD.

  METHOD _set_header.
* PRECONDITION

* DEFINITIONS
    DATA:
      lv_date        TYPE char10,
      lv_icon        TYPE icon_d,
      lv_string1     TYPE string,
      lv_string2     TYPE string,
      lv_string3     TYPE string,
      lv_string4     TYPE string,
      lo_flow        TYPE REF TO cl_salv_form_layout_flow,
      lo_icon        TYPE REF TO cl_salv_form_icon,
      lo_top_element TYPE REF TO cl_salv_form_layout_grid.

* BODY
    " T O P    O F    L I S T
    CREATE OBJECT lo_top_element
      EXPORTING
        columns = 1.

    " Header
    IF p_test = abap_true.
      MESSAGE i900(ac) WITH 'Correct FAAT_DOC_IT Duplicate Entries - Test Run' INTO lv_string1                                          ##NO_TEXT.
    ELSE.
      MESSAGE i900(ac) WITH 'Correct FAAT_DOC_IT Duplicate Entries - Productive Run' INTO lv_string1                                    ##NO_TEXT.
    ENDIF.

    lo_top_element->create_header_information( row  = 1           column  = 1
                                               text = lv_string1  tooltip = lv_string1 ).

    " Overall messsage: errors or not
    IF gb_error_occurred = abap_true.
      lv_icon         = icon_led_red.
      MESSAGE i900(ac) WITH 'Errors Occurred -> Button Message Log (F7)' INTO lv_string1                                         ##NO_TEXT.
    ELSE.
      lv_icon         = icon_led_green.
      MESSAGE i900(ac) WITH 'No Errors occurred -> Button Message Log (F7)' INTO lv_string1                                      ##NO_TEXT.
    ENDIF.

    CREATE OBJECT lo_icon EXPORTING icon = lv_icon tooltip = lv_string1.
    lo_flow = lo_top_element->create_flow( row = 2  column = 1 ).
    lo_flow->set_element( lo_icon ).
    lo_flow->create_text( text = lv_string1 ).

    " Distinguish output for no data / data found situation
    IF gb_no_data EQ abap_true.

      IF gb_error_occurred EQ abap_true.
        lv_icon         = icon_led_red.
        MESSAGE i900(ac) WITH 'Error reading duplicate entries in FAAT_DOC_IT' INTO lv_string1                                   ##NO_TEXT.
      ELSE.
        lv_icon         = icon_led_green.
        MESSAGE i900(ac) WITH 'No duplicate entries found in FAAT_DOC_IT' INTO lv_string1                                        ##NO_TEXT.
      ENDIF.

      CREATE OBJECT lo_icon EXPORTING icon = lv_icon tooltip = lv_string1.
      lo_flow = lo_top_element->create_flow( row = 3  column = 1 ).
      lo_flow->set_element( lo_icon ).
      lo_flow->create_text( text = lv_string1 ).

    ELSE. " gb_no_data

      " Total number of expected DB deletions
      MOVE gv_del_total_expected TO lv_string1.
      CONCATENATE 'Expected total number of DB deletions: ' lv_string1 INTO lv_string1 RESPECTING BLANKS   ##NO_TEXT.

      CREATE OBJECT lo_icon EXPORTING icon = lv_icon tooltip = lv_string1.
      lo_flow = lo_top_element->create_flow( row = 3  column = 1 ).
      lo_flow->set_element( lo_icon ).
      lo_flow->create_text( text = lv_string1 ).

      " Total number of expected DB inserts
      MOVE gv_ins_total_expected TO lv_string1.
      CONCATENATE 'Expected total number of DB inserts: ' lv_string1 INTO lv_string1  RESPECTING BLANKS                ##NO_TEXT.

      CREATE OBJECT lo_icon EXPORTING icon = lv_icon tooltip = lv_string1.
      lo_flow = lo_top_element->create_flow( row = 4  column = 1 ).
      lo_flow->set_element( lo_icon ).
      lo_flow->create_text( text = lv_string1 ).

      " set result icon
      IF gb_error_occurred = abap_true.
        lv_icon         = icon_led_red.
      ELSE.
        lv_icon         = icon_led_green.
      ENDIF.

      " Prefill test/productive helper string
      IF p_test EQ abap_true.
        gv_mode_str = ' test '                                                                                                   ##NO_TEXT.
      ELSE.
        gv_mode_str = ' productive '                                                                                             ##NO_TEXT.
      ENDIF. "p_test

      " Actual number of successful DB operations
      MOVE gv_del_records_ok  TO lv_string1.
      CONCATENATE 'Successful deletions in ' gv_mode_str  ' run: ' lv_string1 INTO lv_string1 RESPECTING BLANKS                  ##NO_TEXT.
      MOVE gv_ins_records_ok TO lv_string2.
      CONCATENATE 'Successful inserts in '   gv_mode_str  ' run: ' lv_string2 INTO lv_string2 RESPECTING BLANKS                  ##NO_TEXT.

      " Actual number of failing DB operations
      MOVE gv_del_records_err TO lv_string3.
      CONCATENATE 'Failed    deletions in ' gv_mode_str ' run: '  lv_string3 INTO lv_string3 RESPECTING BLANKS                   ##NO_TEXT.

      move gv_ins_records_err TO lv_string4.
      CONCATENATE 'Failed    inserts in '   gv_mode_str ' run: '  lv_string4 INTO lv_string4 RESPECTING BLANKS                   ##NO_TEXT.

      CREATE OBJECT lo_icon EXPORTING icon = lv_icon tooltip = lv_string1.
      lo_flow = lo_top_element->create_flow( row = 5  column = 1 ).
      lo_flow->set_element( lo_icon ).
      lo_flow->create_text( text = lv_string1 ).

      CREATE OBJECT lo_icon EXPORTING icon = lv_icon tooltip = lv_string2.
      lo_flow = lo_top_element->create_flow( row = 6  column = 1 ).
      lo_flow->set_element( lo_icon ).
      lo_flow->create_text( text = lv_string2 ).

      CREATE OBJECT lo_icon EXPORTING icon = lv_icon tooltip = lv_string3.
      lo_flow = lo_top_element->create_flow( row = 7  column = 1 ).
      lo_flow->set_element( lo_icon ).
      lo_flow->create_text( text = lv_string3 ).

      CREATE OBJECT lo_icon EXPORTING icon = lv_icon tooltip = lv_string4.
      lo_flow = lo_top_element->create_flow( row = 8  column = 1 ).
      lo_flow->set_element( lo_icon ).
      lo_flow->create_text( text = lv_string4 ).

    ENDIF. " gb_no_data EQ abap_true.

    io_table->set_top_of_list( lo_top_element ).

* POSTCONDITION

  ENDMETHOD.

  METHOD _set_sort.
* PRECONDITION

* DEFINITIONS

* BODY
    TRY.
        " Get sort information
        DATA(lo_sort) = io_table->get_sorts( ).
        lo_sort->set_group_active( ).

        lo_sort->add_sort(
            columnname = 'MANDT'
            position   = 1
            sequence   = if_salv_c_sort=>sort_up
            subtotal   = abap_true
            group      = if_salv_c_sort=>group_none
            obligatory = abap_false ).

        lo_sort->add_sort(
            columnname = 'BUKRS'
            position   = 2
            sequence   = if_salv_c_sort=>sort_up
            subtotal   = abap_true
            group      = if_salv_c_sort=>group_none
            obligatory = abap_false ).

        lo_sort->add_sort(
            columnname = 'ANLN1'
            position   = 3
            sequence   = if_salv_c_sort=>sort_up
            subtotal   = abap_true
            group      = if_salv_c_sort=>group_none
            obligatory = abap_false ).

        lo_sort->add_sort(
            columnname = 'ANLN2'
            position   = 4
            sequence   = if_salv_c_sort=>sort_up
            subtotal   = abap_true
            group      = if_salv_c_sort=>group_none
            obligatory = abap_false ).

        lo_sort->add_sort(
            columnname = 'GJAHR'
            position   = 5
            sequence   = if_salv_c_sort=>sort_up
            subtotal   = abap_true
            group      = if_salv_c_sort=>group_none
            obligatory = abap_false ).

        lo_sort->add_sort(
            columnname = 'AFABE'
            position   = 6
            sequence   = if_salv_c_sort=>sort_up
            subtotal   = abap_true
            group      = if_salv_c_sort=>group_none
            obligatory = abap_false ).

        lo_sort->add_sort(
            columnname = 'AWREF'
            position   = 7
            sequence   = if_salv_c_sort=>sort_up
            subtotal   = abap_true
            group      = if_salv_c_sort=>group_none
            obligatory = abap_false ).

      CATCH cx_salv_not_found cx_salv_existing cx_salv_data_error.
        RETURN.

    ENDTRY.

* POSTCONDITION

  ENDMETHOD.

  METHOD _initialize.

    _create_icon( ).

  ENDMETHOD.

  METHOD _create_icon.
* PRECONDITION

* DEFINITIONS
    DATA:
    lv_function_icon TYPE smp_dyntxt. " Individual function code push buttons FC01, FC02

* BODY
    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        name   = icon_led_red
        info   = TEXT-err
      IMPORTING
        result = gv_icon_red.


    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        name   = icon_led_yellow
        info   = TEXT-aut
      IMPORTING
        result = gv_icon_yellow.


    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        name   = icon_led_green
        info   = TEXT-cor
      IMPORTING
        result = gv_icon_green.

* POSTCONDITION

  ENDMETHOD.

ENDCLASS. " lcl_handle_log


CLASS lcl_execute IMPLEMENTATION.
*----------------------------------------------------------------------
* P U B L I C   M E T H O D S
*----------------------------------------------------------------------
*--------------------------------------------------------------------*
  METHOD get_instance.
* PRECONDITION
    CLEAR ro_instance.

* DEFINITIONS
    DATA:
      lb_error_occurred_tmp      TYPE abap_bool,
      lb_error_occurred_instance TYPE abap_bool.


* BOD>
    "--------------------------------------
    " Create instance of correction class
    "--------------------------------------
    CREATE OBJECT ro_instance.

    ro_instance->get_key_fld_for_select( EXPORTING io_log = go_log IMPORTING eb_error_occurred = lb_error_occurred_tmp ).
    IF lb_error_occurred_tmp EQ abap_true. lb_error_occurred_instance = abap_true. CLEAR lb_error_occurred_tmp. ENDIF.

    ro_instance->get_data_fld_for_select( EXPORTING io_log = go_log IMPORTING eb_error_occurred = lb_error_occurred_tmp ).
    IF lb_error_occurred_tmp EQ abap_true. lb_error_occurred_instance = abap_true. CLEAR lb_error_occurred_tmp. ENDIF.

    ro_instance->get_amount_curr_fld_for_select( EXPORTING io_log = go_log IMPORTING eb_error_occurred = lb_error_occurred_tmp ).
    IF lb_error_occurred_tmp EQ abap_true. lb_error_occurred_instance = abap_true. CLEAR lb_error_occurred_tmp. ENDIF.

    IF lb_error_occurred_instance EQ abap_true.
      CLEAR ro_instance.
      " No instace of correction class could be created
      MESSAGE i900(ac) WITH 'No instace of correction class could be created' INTO lv_msg                                        ##NO_TEXT.
      io_log->add_current_sy_message( iv_probclass = '1' ).
      EXIT.
    ENDIF.

  ENDMETHOD. " get_instance


  METHOD is_suitable_release.
*&---------------------------------------------------------------------*
*& for correct configuration access we need to know analyze the software components
*&---------------------------------------------------------------------*
* PRECONDITION
    CLEAR rb_is_suitable_release.

* DEFINITIONS
    DATA:
      ls_component             TYPE cvers,
      lt_component             TYPE STANDARD TABLE OF cvers,
      lv_release               TYPE i,
      lb_is_suitable_release   TYPE abap_bool      VALUE abap_false,
      lv_cfg_access_class_name TYPE faa_pc_method,
      lv_msg_text              TYPE string.

* BODY
    SELECT * FROM cvers INTO ls_component
             WHERE component = lif_corr_doc_it_del_duplicates=>gc_component-s4core
                OR component = lif_corr_doc_it_del_duplicates=>gc_component-sap_fin.

      IF sy-subrc = 0.

        APPEND ls_component TO lt_component.
        lv_release = ls_component-release."Cast from Char to i

        CASE ls_component-component.

          WHEN lif_corr_doc_it_del_duplicates=>gc_component-sapscore.
            lb_is_suitable_release = abap_true.

          WHEN lif_corr_doc_it_del_duplicates=>gc_component-s4core.
            lb_is_suitable_release = abap_true.

          WHEN lif_corr_doc_it_del_duplicates=>gc_component-sap_fin.
            IF lv_release = 700.
              lb_is_suitable_release = abap_false.
              " Abort processsing: System precondition not fulfilled
              lv_msg_text = 'Correction report requires releases SAP_FIN or S4CORE'                    ##NO_TEXT.
              lv_msg_text = lv_msg_text && ' '.
              MESSAGE lv_msg_text TYPE 'A'.
              EXIT.                                                            " >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            ELSE.
              lb_is_suitable_release = abap_true.
            ENDIF.

          WHEN OTHERS.
            " S4CORE ore SAP_FIN not installed.
            " release not suitable for correction report
            lb_is_suitable_release = abap_false.
            " Abort processsing: System precondition not fulfilled
            lv_msg_text = 'Correction report requires releases SAP_FIN or S4CORE'                     ##NO_TEXT.
            lv_msg_text = lv_msg_text && ' '.
            MESSAGE lv_msg_text TYPE 'A'.
            EXIT.                                                              " >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

        ENDCASE.

      ENDIF. " sy-subrc

    ENDSELECT.

    " Check that necessary software components exist in the system:
    IF lt_component IS INITIAL.
      " Abort processsing: System precondition not fulfilled
      lv_msg_text = 'Correction report requires releases SAP_FIN or S4CORE'                            ##NO_TEXT.
      lv_msg_text = lv_msg_text && ' '.
      MESSAGE lv_msg_text TYPE 'A'.
      EXIT.                                                                    " >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ENDIF.

* POSTCONDITION
    rb_is_suitable_release =  lb_is_suitable_release.

  ENDMETHOD. " is_suitable_release

  METHOD get_key_fld_for_select.
* PRECONDITION
    CLEAR:
      eb_error_occurred,
      mt_item_key_column.

* DEFINITIONS

* BODY
    DATA:
      lt_x031l            TYPE TABLE OF x031l.

    TRY.
        ddif_nametab_get(
          EXPORTING
            iv_tabname     = 'FAA_S_DOC_ITEM_KEY'
            io_log         = go_log
          IMPORTING
            eb_error_occurred = eb_error_occurred
          CHANGING
            ct_x031l_tab   = lt_x031l ).

        IF eb_error_occurred EQ abap_true.
          EXIT.
        ENDIF.

        LOOP AT lt_x031l ASSIGNING FIELD-SYMBOL(<ls_x031l>).
          DATA(lv_whitelist) = <ls_x031l>-fieldname.
          DATA(lv_fieldname) = cl_abap_dyn_prg=>check_whitelist_str( val       = <ls_x031l>-fieldname
                                                                     whitelist = lv_whitelist ).
          lv_fieldname = to_lower( lv_fieldname ).
          APPEND lv_fieldname TO mt_item_key_column.
        ENDLOOP.

      CATCH cm_faa_t100.
        "just catch the exception and allow for continuation of the processing.
      CATCH  cx_abap_not_in_whitelist.
        ASSERT 1 = 0.
    ENDTRY.

* POSTCONDITION
    " none

  ENDMETHOD. " get_key_fld_for_select

  METHOD get_data_fld_for_select.
* PRECONDITION
    CLEAR:
      eb_error_occurred,
      mt_item_data_column.

* DEFINITIONS

* BODY
    DATA:
      lt_x031l            TYPE TABLE OF x031l.

    TRY.
        ddif_nametab_get(
          EXPORTING
            iv_tabname        = 'FAA_S_DOC_ITEM_DATA'
            io_log            = io_log
          IMPORTING
            eb_error_occurred = eb_error_occurred
          CHANGING
            ct_x031l_tab      = lt_x031l ).

        IF eb_error_occurred EQ abap_true.
          EXIT.
        ENDIF.

        LOOP AT lt_x031l ASSIGNING FIELD-SYMBOL(<ls_x031l>).
          DATA(lv_whitelist) = <ls_x031l>-fieldname.
          DATA(lv_fieldname) = cl_abap_dyn_prg=>check_whitelist_str( val       = <ls_x031l>-fieldname
                                                                     whitelist = lv_whitelist ).
          lv_fieldname = to_lower( lv_fieldname ).
          APPEND lv_fieldname TO mt_item_data_column.
        ENDLOOP.

      CATCH cm_faa_t100.
        "just catch the exception and allow for continuation of the processing.
      CATCH  cx_abap_not_in_whitelist.
        ASSERT 1 = 0.
    ENDTRY.

* POSTCONDITION
    " none

  ENDMETHOD. " get_data_fld_for_select

  METHOD get_amount_curr_fld_for_select.
* PRECONDITION
    CLEAR:
      eb_error_occurred,
      mt_amount_columns.

* DEFINITIONS
    DATA:
      lt_x031l            TYPE TABLE OF x031l.

* BODY
    TRY.

        " Support lower releases: don't use FAAS_AMOUNT or FAAS_CURRENCIES but FAAS_AMOUNT_VECTOR
        CLEAR lt_x031l.

        ddif_nametab_get(
          EXPORTING
            iv_tabname        = 'FAAS_AMOUNT_VECTOR'
            io_log            = io_log
          IMPORTING
            eb_error_occurred = eb_error_occurred
          CHANGING
            ct_x031l_tab      = lt_x031l ).

        IF eb_error_occurred EQ abap_true.
          EXIT.
        ENDIF.

        LOOP AT lt_x031l ASSIGNING FIELD-SYMBOL(<ls_x031l>).
          DATA(lv_whitelist) = <ls_x031l>-fieldname.
          DATA(lv_fieldname) = cl_abap_dyn_prg=>check_whitelist_str( val       = <ls_x031l>-fieldname
                                                                     whitelist = lv_whitelist ).
          lv_fieldname = to_lower( lv_fieldname ).
          APPEND lv_fieldname TO mt_amount_columns.
        ENDLOOP.



      CATCH cm_faa_t100.
        "just catch the exception and allow for continuation of the processing.
      CATCH  cx_abap_not_in_whitelist.
        ASSERT 1 = 0.
    ENDTRY.

* POSTCONDITION
    " none

  ENDMETHOD. "  get_amount_curr_fld_for_select

  METHOD check_authority_for_bukrs.

    rv_stop = abap_false.
    IF ib_test IS INITIAL.
      " Authority check
      AUTHORITY-CHECK   OBJECT 'A_PERI_BUK'
                        ID     'AM_ACT_PER'   FIELD '03'
                        ID     'BUKRS'        FIELD iv_bukrs.
    ELSE.
      AUTHORITY-CHECK   OBJECT 'A_PERI_BUK'
                        ID     'AM_ACT_PER'   FIELD '02'
                        ID     'BUKRS'        FIELD iv_bukrs.
    ENDIF.

    IF sy-subrc <> 0.
      MESSAGE s074(aa) WITH iv_bukrs INTO DATA(lv_dummy).
      mo_log->add_current_sy_message( iv_probclass = '1' ).
      rv_stop = abap_true.
    ENDIF.

  ENDMETHOD. " check_authority_for_bukrs

  METHOD get_clients_to_be_processed.
*    This method creates a list of clients that should be analyzed
*    Option 1: read all clients existing in the customer system
*    Option 2: use user-defined client(s)
*--------------------------------------------------------------------*
* PRECONDITION
    REFRESH et_t000.
    CLEAR   eb_error_occurred.

* DEFINITIONS
    DATA:
      lv_subrc LIKE sy-subrc.

* BODY
    IF NOT iv_client IS INITIAL. "  AND NOT sy-mandt EQ '000'.
      SELECT mandt mtext FROM t000 INTO CORRESPONDING FIELDS OF TABLE et_t000 WHERE mandt = iv_client ##TOO_MANY_ITAB_FIELDS.
      lv_subrc = sy-subrc.
    ELSE.
      SELECT mandt mtext FROM t000 INTO CORRESPONDING FIELDS OF TABLE et_t000 ##TOO_MANY_ITAB_FIELDS.
      lv_subrc = sy-subrc.
    ENDIF.

* POSTCONDITION
    IF lv_subrc NE 0.
      " Errors at client selection
      eb_error_occurred = abap_true.
      MESSAGE e900(ac)  WITH 'Report aborted.' INTO lv_msg                                         ##NO_TEXT.
      io_log->add_current_sy_message( iv_probclass = '1' ).
      MESSAGE e900(ac)  WITH 'Error at client selection' INTO lv_msg                               ##NO_TEXT.
      io_log->add_current_sy_message( iv_probclass = '1' ).
    ENDIF.

  ENDMETHOD. " get_clients_to_be_processed

  METHOD process_data.
    "------------------------------------------------------------------------------
    " Select data from FAAT_DOC_IT with duplicate entries
    "------------------------------------------------------------------------------

    " Preconditions
    CLEAR:
      ev_l1_del_records_ok,
      ev_l1_ins_records_ok,
      ev_l1_del_records_err,
      ev_l1_ins_records_err,
      et_faat_doc_it_err.
    eb_no_data        = abap_false.
    eb_error_occurred = abap_false.

    " Definition
    DATA:
      lt_faat_doc_it_err    TYPE          lif_corr_doc_it_del_duplicates=>ty_t_faat_doc_it_err,
      lb_no_data            TYPE          abap_bool,
      lv_mode_str           TYPE          string,
      lv_msg                TYPE          string,
      lv_del_records        TYPE          i VALUE 0,
      lv_ins_records        TYPE          i VALUE 0,
      lt_column             TYPE TABLE OF string,
      lt_group_column       TYPE TABLE OF string,
      lt_range_client       TYPE RANGE OF sy-mandt,
      lv_package            TYPE          n VALUE 0,
      lb_l2_error_occurred  TYPE          abap_bool,
      lv_l2_del_records_ok  TYPE          i VALUE 0,
      lv_l2_ins_records_ok  TYPE          i VALUE 0,
      lv_l2_del_records_err TYPE          i VALUE 0,
      lv_l2_ins_records_err TYPE          i VALUE 0.

    "--------------------------------------
    " Body
    "--------------------------------------

    "--------------------------------------
    " Transfer imported log reference into memmber attribute
    "--------------------------------------
    mo_log = io_log.

    "--------------------------------------
    " Reset data relevant for select
    "--------------------------------------
    CLEAR:
      lt_faat_doc_it_err,
      lv_package.

    "--------------------------------------
    " Prepare columns for SELECT from table FAAT_DOC_IT
    "--------------------------------------

    " Add key fields to selected fields (depends on support level w.r.t. drcrk indicator)
    LOOP AT mt_item_key_column REFERENCE INTO DATA(lr_key_column).
      APPEND lr_key_column->* && ',' TO lt_column.
      APPEND lr_key_column->* && ',' TO lt_group_column.
    ENDLOOP. " at mt_item_key_column

    " Amount and currency fields(depends on release)
    LOOP AT mt_amount_columns REFERENCE INTO DATA(lr_amount_curr_column).
      IF lr_amount_curr_column->* CS 'cur'.
        " Add currency type fields to selected fields
        APPEND lr_amount_curr_column->* && ',' TO lt_column.
        " Add (only) currency type fields to 'group by' columns
        APPEND lr_amount_curr_column->* && ',' TO lt_group_column.
      ELSE.
        " Add amount fields only to selected fields
        APPEND `SUM( ` && lr_amount_curr_column->* && ` ) AS ` && lr_amount_curr_column->* && ',' TO lt_column                   ##NO_TEXT.
        " Don't add amount fields to 'group by' columns -> gives problems in OSQL mocking for unit test
      ENDIF.
    ENDLOOP. " at mt_amount_columns

    " Remove comma for last grouping field
    ASSIGN lt_group_column[ lines( lt_group_column ) ] TO FIELD-SYMBOL(<ls_last_group_column>).
    REPLACE ',' IN <ls_last_group_column> WITH ''.

    " Count occurrences of duplicate entries
    APPEND 'COUNT(*) AS count_multiple' TO lt_column                                                                             ##NO_TEXT.

    "--------------------------------------
    " Select duplicate entries from FAAT_DOC_IT at DB level
    "--------------------------------------

    TRY.
        SELECT
          (lt_column)
         " mandt,
         " bukrs,
         " anln1,
         " anln2,
         " gjahr,
         " awtyp,
         " awref,
         " aworg,
         " awsys,
         " subta,
         " afabe,
         " slalittype,
         " drcrk,
         " SUM( hsl ) AS hsl,
         " SUM( ksl ) AS ksl,
         " SUM( osl ) AS osl,
         " SUM( vsl ) AS vsl,
         " SUM( bsl ) AS bsl,
         " SUM( csl ) AS csl,
         " SUM( dsl ) AS dsl,
         " SUM( esl ) AS esl,
         " SUM( fsl ) AS fsl,
         " SUM( gsl ) AS gsl,
         " rhcur,
         " rkcur,
         " rocur,
         " rvcur,
         " rbcur,
         " rccur,
         " rdcur,
         " recur,
         " rfcur,
         " rgcur,
         " COUNT(*) AS count_multiple
        FROM faat_doc_it  USING CLIENT @iv_client
        WHERE
          bukrs IN @so_bukrs AND
          gjahr IN @so_gjahr AND
          anln1 IN @so_anln1
        GROUP BY
          (lt_group_column)
         " mandt,
         " bukrs,
         " anln1,
         " anln2,
         " gjahr,
         " awtyp,
         " awref,
         " aworg,
         " awsys,
         " subta,
         " afabe,
         " slalittype,
         " drcrk,
         " rhcur,
         " rkcur,
         " rocur,
         " rvcur,
         " rbcur,
         " rccur,
         " rdcur,
         " recur,
         " rfcur,
         " rgcur
        HAVING COUNT(*) > 1
        ORDER BY count_multiple DESCENDING
        INTO CORRESPONDING FIELDS OF TABLE @lt_faat_doc_it_err
        PACKAGE SIZE @gc_package_size.

          DATA(lv_subrc) = sy-subrc.

          "------------------------------------------------------------------------------
          " Create Package Number for Protocol
          "------------------------------------------------------------------------------
          ADD 1 TO lv_package.

          "------------------------------------------------------------------------------
          " If no records found to be processed in THIS client -> continue with next client
          " Add message to report protocol:
          "------------------------------------------------------------------------------
          IF lv_subrc NE 0 OR
             lt_faat_doc_it_err IS INITIAL.
            eb_no_data = abap_true.
            " No changes in client
            CONCATENATE 'No changes in client: ' iv_client INTO gv_string SEPARATED BY space                                     ##NO_TEXT.
            MESSAGE i900(ac) WITH gv_string INTO lv_msg.
            mo_log->add_current_sy_message( iv_probclass = '1' ).
            EXIT.                                                                    " >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
          ENDIF.

          "------------------------------------------------------------------------------
          " Add message to report protocol:
          "------------------------------------------------------------------------------
          " Start processing new package in client &1
          CONCATENATE 'Start processing new package: ' lv_package  ' - client: ' gv_client INTO gv_string SEPARATED BY space     ##NO_TEXT.
          MESSAGE i900(ac) WITH gv_string INTO lv_msg.
          mo_log->add_current_sy_message( iv_probclass = '1' ).

          "------------------------------------------------------------------------------
          " Analyze which items are automatically correctable in current package
          "------------------------------------------------------------------------------
          me->analyze_data_for_correction(
                      EXPORTING
                        iv_client          = iv_client
                        ib_test            = ib_test
                      IMPORTING
                        eb_error_occurred  = lb_l2_error_occurred
                      CHANGING
                        ct_faat_doc_it_err = lt_faat_doc_it_err ).

          "Error Handling:
          IF lb_l2_error_occurred = abap_true.
            eb_error_occurred = abap_true.
          ENDIF.

          "------------------------------------------------------------------------------
          " Execute Corrections in current package
          "------------------------------------------------------------------------------

          IF lb_l2_error_occurred EQ abap_false.
            me->process_update_operation(
              EXPORTING
                iv_client          = iv_client
                ib_test            = ib_test
                iv_package         = lv_package
              IMPORTING
                eb_error_occurred  = lb_l2_error_occurred
                ev_del_records_ok  = lv_l2_del_records_ok
                ev_ins_records_ok  = lv_l2_ins_records_ok
                ev_del_records_err = lv_l2_del_records_err
                ev_ins_records_err = lv_l2_ins_records_err
              CHANGING
                ct_faat_doc_it_err = lt_faat_doc_it_err ).

            " Export no. records (independent of error or not)
            ev_l1_del_records_ok  = ev_l1_del_records_ok  + lv_l2_del_records_ok.
            ev_l1_ins_records_ok  = ev_l1_ins_records_ok  + lv_l2_ins_records_ok.
            ev_l1_del_records_err = ev_l1_del_records_err + lv_l2_del_records_err.
            ev_l1_ins_records_err = ev_l1_ins_records_err + lv_l2_ins_records_err.

            "Error Handling:
            IF lb_l2_error_occurred = abap_true.
              eb_error_occurred = abap_true.
            ENDIF.

          ENDIF. " lb_l2_error_occurred

          "------------------------------------------------------------------------------
          " End of Package processing: execute final actions
          "------------------------------------------------------------------------------

          IF NOT lt_faat_doc_it_err IS INITIAL.
            " Add inconsistent entries of current ledger group to export table
            APPEND LINES OF lt_faat_doc_it_err TO et_faat_doc_it_err.
            eb_no_data = abap_false.
          ENDIF.

          CLEAR:
            lv_subrc,
            lt_faat_doc_it_err,
            lv_l2_del_records_ok,
            lv_l2_ins_records_ok,
            lv_l2_del_records_err,
            lv_l2_ins_records_err,
            lb_l2_error_occurred.

          "------------------------------------------------------------------------------
          "-- Protocol preparation test/productive run
          "------------------------------------------------------------------------------
          IF ib_test EQ abap_true.
            lv_mode_str = ' test '                                                                 ##NO_TEXT.
          ELSE.
            lv_mode_str = ' productive '                                                           ##NO_TEXT.
          ENDIF.  "ib_test

          "------------------------------------------------------------------------------
          " Add Successful test run message to report protocol:
          "------------------------------------------------------------------------------

          IF NOT ( lv_l2_del_records_ok IS INITIAL AND lv_l2_ins_records_ok IS INITIAL ).
            " Total  Successful DB Changes in test run in client
            CONCATENATE 'Totals: Successful ' lv_mode_str ' package: ' lv_package ' - client: ' gv_client  INTO gv_string SEPARATED BY space    ##NO_TEXT.
            MESSAGE i900(ac) WITH gv_string INTO lv_msg.
            mo_log->add_current_sy_message( iv_probclass = '1' ).
            " Total Successful DB deletions in test run
            MESSAGE i900(ac) WITH 'Total Successful DB deletions in ' && lv_mode_str && ' run: ' && lv_l2_del_records_ok INTO lv_msg            ##NO_TEXT.
            mo_log->add_current_sy_message( iv_probclass = '1' ).
            " Total Successful DB inserts in test run
            MESSAGE i900(ac) WITH 'Total Successful DB inserts in ' && lv_mode_str && ' run: '   && lv_l2_ins_records_ok INTO lv_msg            ##NO_TEXT.
            mo_log->add_current_sy_message( iv_probclass = '1' ).
          ENDIF.

          "------------------------------------------------------------------------------
          " Add Failing test run message to report protocol:
          "------------------------------------------------------------------------------

          IF NOT ( lv_l2_del_records_err IS INITIAL AND lv_l2_ins_records_err IS INITIAL ).
            " Total Failing DB Changes in test run in client
            CONCATENATE 'Totals: Failing DB Changes in ' lv_mode_str ' run in package: ' lv_package  ' - client: ' gv_client  INTO gv_string SEPARATED BY space ##NO_TEXT.
            MESSAGE i900(ac) WITH gv_string INTO lv_msg.
            mo_log->add_current_sy_message( iv_probclass = '1' ).
            " Total Failing DB deletions in test run
            MESSAGE i900(ac) WITH 'Total Failing DB deletions in ' && lv_mode_str && ' run: ' && lv_l2_del_records_err INTO lv_msg              ##NO_TEXT.
            mo_log->add_current_sy_message( iv_probclass = '1' ).
            " Total Failing DB inserts in test run
            MESSAGE i900(ac) WITH 'Total Failing DB inserts in ' && lv_mode_str && ' run: '   && lv_l2_ins_records_err INTO lv_msg              ##NO_TEXT.
            mo_log->add_current_sy_message( iv_probclass = '1' ).
          ENDIF.

          "------------------------------------------------------------------------------
          " Add message to report protocol:
          "------------------------------------------------------------------------------
          " End processing new package in client &1
          CONCATENATE 'End processing package: ' lv_package  ' - client: ' gv_client INTO gv_string SEPARATED BY space                          ##NO_TEXT.
          MESSAGE i900(ac) WITH gv_string INTO lv_msg.
          mo_log->add_current_sy_message( iv_probclass = '1' ).

          "------------------------------------------------------------------------------
          " Potential Refinement of Commit Handling  <<<<<<<<< Option: here would be the right place for commit at level of a single package >>>>>>>>>>
          "------------------------------------------------------------------------------

          "------------------------------------------------------------------------------
          " Get next package
          "------------------------------------------------------------------------------
        ENDSELECT. " End of current FAAT_DOC_IT package

        " Send 'no data' info back to report
        IF et_faat_doc_it_err IS INITIAL.
          eb_no_data = abap_true.
        ENDIF.

      CATCH cx_sy_dynamic_osql_syntax cx_sy_dynamic_osql_semantics cx_root INTO DATA(lx_root).
        eb_error_occurred = abap_true.
        eb_no_data        = abap_true.
        MESSAGE e900(ac)  WITH 'Report aborted.' INTO lv_msg                                                                                    ##NO_TEXT.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
        MESSAGE e900(ac)  WITH 'CX_SY_DYNAMIC_OSQL error at first dynamic select' INTO lv_msg                                                   ##NO_TEXT.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
        MESSAGE e900(ac)  WITH 'KERNEL_ERRID: ' && lx_root->kernel_errid INTO lv_msg                                                            ##NO_TEXT.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
        MESSAGE e900(ac)  WITH lx_root->get_text( ) INTO lv_msg.
        mo_log->add_current_sy_message( iv_probclass = '1' ).

    ENDTRY.

    " Postconditions
    " none

  ENDMETHOD. "  process_data

  METHOD analyze_data_for_correction.
*&---------------------------------------------------------------------*
*& This method controls the data analysis and ensures that the flags for
*& manual (flg_man_corr) and automatic (flg_auto_corr) correction
*& are correctly set in the output table for ALV display.
*&---------------------------------------------------------------------*
    " Preconditions
    CHECK NOT ct_faat_doc_it_err IS INITIAL.

    " Definition
    DATA:
      lb_autocorrection_possible TYPE abap_bool,
      lb_l3_error_occurred       TYPE abap_bool,
      lt_asset_for_man_corr      TYPE lif_corr_doc_it_del_duplicates=>ty_t_asset_per_client.

    " Body

    "------------------------------------------------------------------------------
    " Separate automatic from manual correction
    " Data was provided by method SELECT_DATA_FOR_CORRECTION
    "------------------------------------------------------------------------------

    LOOP AT ct_faat_doc_it_err ASSIGNING FIELD-SYMBOL(<ls_faat_doc_it_err>).

      " Loop preprocessing
      CLEAR lb_l3_error_occurred.
      lb_autocorrection_possible = abap_false.

      IF iv_client NE <ls_faat_doc_it_err>-mandt.
        eb_error_occurred = abap_true.
        <ls_faat_doc_it_err>-flg_man_corr = abap_true.
      ENDIF.

      IF <ls_faat_doc_it_err>-flg_man_corr EQ abap_true.

        " Flag that manual correction is necessary was already previously set
        " This doesn't need to be analyzed again.
        lb_autocorrection_possible = abap_false.

      ELSE. " <ls_faat_doc_it_err>-flg_man_corr

        analyze_single_db_entry(
          EXPORTING
            iv_client                  = <ls_faat_doc_it_err>-mandt
            ib_test                    = ib_test
          IMPORTING
            eb_error_occurred          = lb_l3_error_occurred
          CHANGING
            cs_faat_doc_it_err         = <ls_faat_doc_it_err>
            cb_autocorrection_possible = lb_autocorrection_possible   ).

        IF lb_l3_error_occurred EQ abap_true.
          eb_error_occurred = abap_true.
        ENDIF.

      ENDIF. " <ls_faat_doc_it_err>-flg_man_corr

      "------------------------------------------------------------------------------
      " Set traffic light and display flags: during analysis identical for test and correction
      " <ls_faat_doc_it_err>-flg_corr_done will be set in METHOD process_update_operation
      "------------------------------------------------------------------------------

      " Graphical output of check/correction algorithm: use icons
      <ls_faat_doc_it_err>-icon = SWITCH #( lb_autocorrection_possible
                            WHEN abap_true THEN lcl_handle_log=>gv_icon_yellow
                            ELSE lcl_handle_log=>gv_icon_red ).

      <ls_faat_doc_it_err>-flg_man_corr  = SWITCH #( lb_autocorrection_possible
                                     WHEN abap_true THEN abap_false
                                     ELSE abap_true ).

      <ls_faat_doc_it_err>-flg_auto_corr = SWITCH #( lb_autocorrection_possible
                                     WHEN abap_true THEN abap_true
                                     ELSE abap_false ).

    ENDLOOP. " AT ct_faat_doc_it_err

    " Postconditions
    IF lb_l3_error_occurred EQ abap_true.
      eb_error_occurred = abap_true.
    ENDIF.

  ENDMETHOD. " analyze_data_for_correction

  METHOD analyze_single_db_entry.

    " Precondition
    CHECK cs_faat_doc_it_err-mandt EQ iv_client.

    " Definition
    DATA:
      lv_string        TYPE                   string,
      lt_where_cond    TYPE STANDARD TABLE OF string,
      lt_amount_vector TYPE STANDARD TABLE OF faas_amount_vector,
      lt_faat_doc_it_1 TYPE STANDARD TABLE OF faat_doc_it,
      lt_faat_doc_it_2 TYPE STANDARD TABLE OF faat_doc_it.

    " Body

    "--------------------------------------
    " Prepare key columns for SELECT from table FAAT_DOC_IT
    " Hint: key fields depend on support level w.r.t. drcrk indicator
    "--------------------------------------

    " Add key fields to where condition
    LOOP AT mt_item_key_column REFERENCE INTO DATA(lr_key_column).
      " skip client key field because client handling is performed by the compiler
      IF to_upper( lr_key_column->* ) EQ 'MANDT'                                                                                 ##NO_TEXT.
        CONTINUE.
      ENDIF.
      CLEAR lv_string.
      CONCATENATE lr_key_column->* ' = ' '@cs_faat_doc_it_err-'  lr_key_column->* ' AND' INTO lv_string RESPECTING BLANKS        ##NO_TEXT.
      APPEND lv_string TO lt_where_cond.
    ENDLOOP. " at mt_item_key_column

    " Remove AND operator for last key field
    ASSIGN lt_where_cond[ lines( lt_where_cond ) ] TO FIELD-SYMBOL(<ls_last_column>).
    REPLACE 'AND' IN <ls_last_column> WITH ''.

    "---------------------------------------------------------------------"
    " DB Detail Selection
    " Select all duplicate entries with same (imported) FAAT_DOC_IT key - client specific
    "---------------------------------------------------------------------"
    TRY.
        SELECT * FROM faat_doc_it USING CLIENT @iv_client
              WHERE
                (lt_where_cond)
                """ mandt    = @cs_faat_doc_it_err-mandt      AND   " Client handling is performed by the compiler
                " bukrs      = @cs_faat_doc_it_err-bukrs      AND
                " anln1      = @cs_faat_doc_it_err-anln1      AND
                " anln2      = @cs_faat_doc_it_err-anln2      AND
                " gjahr      = @cs_faat_doc_it_err-gjahr      AND
                " awtyp      = @cs_faat_doc_it_err-awtyp      AND
                " awref      = @cs_faat_doc_it_err-awref      AND
                " aworg      = @cs_faat_doc_it_err-aworg      AND
                " awsys      = @cs_faat_doc_it_err-awsys      AND
                " subta      = @cs_faat_doc_it_err-subta      AND
                " afabe      = @cs_faat_doc_it_err-afabe      AND
                " slalittype = @cs_faat_doc_it_err-slalittype AND
                " drcrk      = @cs_faat_doc_it_err-drcrk
              APPENDING TABLE @lt_faat_doc_it_1.

      CATCH cx_sy_dynamic_osql_syntax cx_sy_dynamic_osql_semantics cx_root INTO DATA(lx_root).
        eb_error_occurred = abap_true.
        MESSAGE e900(ac)  WITH 'Report aborted.' INTO lv_msg                                                                     ##NO_TEXT.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
        MESSAGE e900(ac)  WITH 'CX_SY_DYNAMIC_OSQL error at detail dynamic select' INTO lv_msg                                   ##NO_TEXT.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
        MESSAGE e900(ac)  WITH 'KERNEL_ERRID: ' && lx_root->kernel_errid INTO lv_msg                                             ##NO_TEXT.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
        MESSAGE e900(ac)  WITH lx_root->get_text( ) INTO lv_msg.
        mo_log->add_current_sy_message( iv_probclass = '1' ).

    ENDTRY.

    "---------------------------------------------------------------------"
    " Analyze correctness of result of above select statement
    "---------------------------------------------------------------------"
    IF sy-subrc NE 0                                            ##SUBRC_OK.
      " This case should not occur:
      " Error at reading db => manual analysis necessary, no automatic correction
      eb_error_occurred          = abap_true.
      cb_autocorrection_possible = abap_false.
      MESSAGE e900(ac) WITH 'No DB entry found in detail selection.' INTO lv_msg                                                 ##NO_TEXT.
      mo_log->add_current_sy_message( iv_probclass = '1' ).
      EXIT.                                                                    " >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ELSE. " " sy-subrc of SELECT * FROM faat_doc_it
      IF lines( lt_faat_doc_it_1 ) EQ 1.
        " This case should not occur:
        " Detail select of db contradicts the top selection of DB => only a single entry found
        " manual analysis necessary, no automatic correction
        eb_error_occurred          = abap_true.
        cb_autocorrection_possible = abap_false.
        MESSAGE e900(ac) WITH 'Only a single DB entry found in detail selection.' INTO lv_msg                                    ##NO_TEXT.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
        EXIT.                                                                  " >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      ENDIF.

      "------------------------------------------------------------------------------
      " Before Analysis: Write FAAT_DOC_IT_KEY and orignial amounts to protocol
      "------------------------------------------------------------------------------

      " Display new content of original amount fiels (will be lost after deletion):
      LOOP AT lt_faat_doc_it_1 ASSIGNING FIELD-SYMBOL(<ls_faat_doc_it>).
        DATA(lv_tabix) = sy-tabix.

*      DATA(lv_asset) = <ls_faat_doc_it_err>-bukrs && '/' && <ls_faat_doc_it_err>-anln1 && '-' && <ls_faat_doc_it_err>-anln2.
*      CONCATENATE 'Asset: ' lv_asset INTO gv_string SEPARATED BY space.
*      MESSAGE s900(ac) WITH gv_string INTO lv_msg.
*      mo_log->add_current_sy_message( iv_probclass = '6' ).

        " Display (unchanged) content of key fields (for deletion and insert)
        IF lv_tabix EQ 1.
          MESSAGE s900(ac) WITH 'Following FAAT_DOC_IT item analyzed : ' INTO lv_msg                                             ##NO_TEXT.
          mo_log->add_current_sy_message( iv_probclass = '6' ).
          LOOP AT mt_item_key_column REFERENCE INTO DATA(lr_item_key_column).
            ASSIGN COMPONENT lr_item_key_column->* OF STRUCTURE <ls_faat_doc_it> TO FIELD-SYMBOL(<lv_column_value>).
            CONCATENATE 'Key Field: ' lr_item_key_column->* ' = ' <lv_column_value> INTO gv_string SEPARATED BY space            ##NO_TEXT.
            MESSAGE i900(ac) WITH gv_string INTO lv_msg.
            mo_log->add_current_sy_message( iv_probclass = '6' ).
          ENDLOOP. " at mt_item_key_column
        ENDIF. " lv_tabix EQ 1.

        MESSAGE s900(ac) WITH 'Original amount fields: Index duplicate key: ' && lv_tabix INTO lv_msg                            ##NO_TEXT.
        mo_log->add_current_sy_message( iv_probclass = '6' ).

        " Display (unchanged) content of amount fields with same key (for deletion)
        LOOP AT mt_amount_columns REFERENCE INTO DATA(lr_amount_column).
          ASSIGN COMPONENT lr_amount_column->* OF STRUCTURE <ls_faat_doc_it> TO <lv_column_value>.
          IF NOT <lv_column_value> IS INITIAL.
            gv_string =  'Index ' && lv_tabix && ' Data Field: ' && lr_amount_column->* && ' = ' && <lv_column_value>            ##NO_TEXT.
            MESSAGE i900(ac) WITH gv_string INTO lv_msg.
            mo_log->add_current_sy_message( iv_probclass = '6' ).
          ENDIF.
        ENDLOOP. " at mt_item_key_column
      ENDLOOP. " at lt_faat_doc_it_1

      "---------------------------------------------------------------------"
      " Analysis 1 - Main Error Situation = Deviating Field Content in Amount Vector
      "---------------------------------------------------------------------"

      " Preset analysis status before loop -> not final!
      cs_faat_doc_it_err-flg_depr_amount = abap_true.

      LOOP AT lt_faat_doc_it_1 REFERENCE INTO DATA(lr_doc_it).

        lv_tabix = sy-tabix.

        "---------------------------------------------------------------------"
        " <<<<<<<<<<<< Filter the expected main error >>>>>>>>>>>>>>>>>>>>>>>>>
        "---------------------------------------------------------------------"
        " First move all entries to a separate internal table that don't fulfil following filter:
        " DB entries can be triggered from AMDP / AFA / BCF. An even stricter filter doesn't make sense.
        "---------------------------------------------------------------------"
        IF   lr_doc_it->poper       EQ lif_corr_doc_it_del_duplicates~gc_poper_bcf                   " 000
         AND lr_doc_it->bwasl       EQ lif_corr_doc_it_del_duplicates~gc_tty-bcf                     " 999
         AND lr_doc_it->movcat      EQ lif_corr_doc_it_del_duplicates~gc_movcat-bcf                  " 00
         AND lr_doc_it->mig_source  NE lif_corr_doc_it_del_duplicates~gc_mig_source-new_depr_area    " V
         AND lr_doc_it->mig_source  NE lif_corr_doc_it_del_duplicates~gc_mig_source-asset_migration. " A

          " Don't change analysis status cs_faat_doc_it_err-FLG_DEPR_AMOUNT
          cb_autocorrection_possible = abap_true.

        ELSE. " First complex filter: prec_awtyp <> !AFA!

          " This is not the main case with prec_awtyp = !AFA! => reset prefilled analysis status cs_faat_doc_it_err-FLG_DEPR_AMOUNT
          cs_faat_doc_it_err-flg_depr_amount = abap_false.

          " Move lines to separate ITAB for additional but separate analysis
          APPEND INITIAL LINE TO lt_faat_doc_it_2 ASSIGNING <ls_faat_doc_it>.
          IF <ls_faat_doc_it> IS ASSIGNED AND
             lr_doc_it        IS BOUND.
            <ls_faat_doc_it> = lr_doc_it->*.
            DELETE lt_faat_doc_it_1 INDEX lv_tabix.
          ELSE.
            " This case should not occur:
            " Failure at detail analysis => error at loop of detail selection
            " manual analysis necessary, no automatic correction
            cb_autocorrection_possible = abap_false.
          ENDIF.
        ENDIF.   " First complex filter: prec_awtyp = !AFA!
      ENDLOOP. " AT lt_faat_doc_it_1
    ENDIF. " sy-subrc of SELECT * FROM faat_doc_it

    "---------------------------------------------------------------------"
    " All-or-nothing validation:
    " Above filter must be valid for all DB lines in above select
    "---------------------------------------------------------------------"
    IF lines( lt_faat_doc_it_1 ) NE cs_faat_doc_it_err-count_multiple.
      cs_faat_doc_it_err-flg_depr_amount = abap_false.
      cb_autocorrection_possible        = abap_false.
      eb_error_occurred                 = abap_true.
      MESSAGE e900(ac)  WITH 'Error occurred for the current DB entry.' INTO lv_msg                                              ##NO_TEXT.
      mo_log->add_current_sy_message( iv_probclass = '1' ).
      MESSAGE e900(ac)  WITH 'Not all DB lines fulfil the main !AFA! filter' INTO lv_msg                                         ##NO_TEXT.
      mo_log->add_current_sy_message( iv_probclass = '1' ).
      EXIT.                                                                    " >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ENDIF.

    "---------------------------------------------------------------------"
    " Prepare Step 1: Sum up amount fields for update
    "---------------------------------------------------------------------"
    CLEAR lt_amount_vector.
    LOOP AT lt_faat_doc_it_1 ASSIGNING <ls_faat_doc_it>.
      COLLECT <ls_faat_doc_it>-amount_vector INTO lt_amount_vector.
    ENDLOOP.

    "---------------------------------------------------------------------"
    " Amount-Vector-Validation:
    " Above calculated sums of the amount vectore (via ABAP)
    " must be equal to the sum calculated at DB level
    "---------------------------------------------------------------------"
    IF lines( lt_amount_vector ) GE 1.
      READ TABLE lt_amount_vector INDEX 1 REFERENCE INTO DATA(lr_amount_vector).
      IF cs_faat_doc_it_err-amount_vector NE lr_amount_vector->*.
        cs_faat_doc_it_err-flg_depr_amount = abap_true.
        cb_autocorrection_possible        = abap_false.
        eb_error_occurred                 = abap_true.
        MESSAGE e900(ac)  WITH 'Error occurred for the current DB entry.' INTO lv_msg                                            ##NO_TEXT.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
        MESSAGE e900(ac)  WITH 'Difference in newly calculated Amount Vector' INTO lv_msg                                        ##NO_TEXT.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
        EXIT.                                                                    " >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      ENDIF.
    ENDIF.

    "---------------------------------------------------------------------"
    " Prepare Step 2: clear amount fields because they can differ
    "---------------------------------------------------------------------"

    LOOP AT lt_faat_doc_it_1 ASSIGNING <ls_faat_doc_it>.
      CLEAR <ls_faat_doc_it>-amount_vector.
    ENDLOOP.

    "--------------------------------------
    " Analysis 1: Ensure that only AMOUNT FIELDS differ
    " Do all entries have identically the same content for ALL other fields
    " IF yes => This is the main symptom => Fill FLG_DEPR_AMOUNT
    "--------------------------------------

    IF lines( lt_faat_doc_it_1 ) GT 0.

      SORT lt_faat_doc_it_1.
      DELETE ADJACENT DUPLICATES FROM lt_faat_doc_it_1
        COMPARING ALL FIELDS.

      IF lines( lt_faat_doc_it_1 ) EQ 1.
        " All fields have the same content - with exception to the amount fields
        " It's allowed to move all attributes back to current db line except for amount fields (currently only key fields are filled)
        READ TABLE lt_faat_doc_it_1 INDEX 1
           ASSIGNING FIELD-SYMBOL(<ls_lt_faat_doc_it>).

        "-------------------------------------
        " Build up the structure for update
        "-------------------------------------

        IF sy-subrc EQ 0 AND <ls_lt_faat_doc_it> IS ASSIGNED.
          MOVE-CORRESPONDING <ls_lt_faat_doc_it> TO cs_faat_doc_it_err.
          IF lines( lt_amount_vector ) = 1.
            READ TABLE lt_amount_vector INDEX 1 REFERENCE INTO lr_amount_vector.
            MOVE-CORRESPONDING lr_amount_vector->* TO cs_faat_doc_it_err.
          ELSE.
            eb_error_occurred = abap_true.
          ENDIF.
        ENDIF. "sy-subrc EQ 0
        " => autocorrection possible
        cs_faat_doc_it_err-flg_depr_amount = abap_true.
        cb_autocorrection_possible        = abap_true.
        EXIT.                                                                    " >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      ELSE.
        cb_autocorrection_possible        = abap_false.
      ENDIF. " lines( lt_faat_doc_it_1 ) EQ 1

    ENDIF. " lines(lt_faat_doc_it_1) GT 0

    "---------------------------------------------------------------------"
    " Analysis 2 - NO ATTRIBUTE DIFFERENCE
    "---------------------------------------------------------------------"
    " Do all entries have identically the same content for ALL fields (key and attribute must be compared)?
    " IF yes => Fill flg_ident_attibutes
    SORT lt_faat_doc_it_2.
    DELETE ADJACENT DUPLICATES FROM lt_faat_doc_it_2
        COMPARING ALL FIELDS.

    IF lines( lt_faat_doc_it_2 ) EQ 1.
      " ALL fields have the same content => allowed to move all attributes back to current db line (currently only key fields are filled)
      READ TABLE lt_faat_doc_it_2 INDEX 1
         ASSIGNING <ls_lt_faat_doc_it>.
      IF sy-subrc EQ 0 AND <ls_lt_faat_doc_it> IS ASSIGNED.
        MOVE-CORRESPONDING <ls_lt_faat_doc_it> TO cs_faat_doc_it_err.
      ENDIF. " sy-subrc EQ 0
      " => currently no autocorrection
      cs_faat_doc_it_err-flg_ident_attibutes = abap_true.
      cb_autocorrection_possible             = abap_false.
      EXIT.                                                                    " >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ELSE.
      cb_autocorrection_possible             = abap_false.
      EXIT.                                                                    " >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ENDIF.

    " Postconditions
    " none

  ENDMETHOD. " analyze_single_db_entry

  METHOD ddif_nametab_get.
*&---------------------------------------------------------------------*
*& This method gives back the definition of DDIC structure.
*& (Copy of method with same method in class CL_FAA_DA_API_CALL_FM)
*&---------------------------------------------------------------------*
    " Preconditions
    CLEAR:
      eb_error_occurred.

    IF iv_tabname IS INITIAL.
      " No structure name imported at reading DDIC definition
      MESSAGE i900(ac) WITH 'No structure name imported at reading DDIC definition' INTO lv_msg                                  ##NO_TEXT.
      io_log->add_current_sy_message( iv_probclass = '1' ).
      eb_error_occurred = abap_true.
      EXIT.
    ENDIF.

    " Definition
    DATA:
      lb_all_types   TYPE ddbool_d,
      lv_lfieldname  TYPE dfies-lfieldname,
      lb_group_names TYPE ddbool_d,
      lv_uclen       TYPE unicodelg,
      lv_status      TYPE as4local.

    " Body
    lb_all_types   =  ' '                                                                                                        ##NO_TEXT.
    lv_lfieldname  =  ' '                                                                                                        ##NO_TEXT.
    lb_group_names =  ' '                                                                                                        ##NO_TEXT.
    lv_status      =  'A'                                                                                                        ##NO_TEXT.

    CALL FUNCTION 'DDIF_NAMETAB_GET'
      EXPORTING
        tabname     = iv_tabname
        all_types   = lb_all_types
        lfieldname  = lv_lfieldname
        group_names = lb_group_names
        uclen       = lv_uclen
        status      = lv_status
      TABLES
        x031l_tab   = ct_x031l_tab
      EXCEPTIONS
        not_found   = 1
        OTHERS      = 2.

    IF sy-subrc NE 0.
      " No structure name imported at reading DDIC definition
      MESSAGE i900(ac) WITH 'Error reading DDIC definition for: ' && iv_tabname INTO lv_msg                                      ##NO_TEXT.
      io_log->add_current_sy_message( iv_probclass = '1' ).
      eb_error_occurred = abap_true.
      EXIT.
    ENDIF.

    " Postconditions
    " none
  ENDMETHOD. "ddif_nametab_get

  METHOD process_update_operation.
*&---------------------------------------------------------------------*
*& This method is responsible to update FAAT_DOC_IT
*& - Remove duplicate DB entries if autocorrection is possible
*&---------------------------------------------------------------------*
    " Preconditions
    CHECK NOT ct_faat_doc_it_err IS INITIAL.
    eb_error_occurred = abap_false.
    CLEAR:
      ev_del_records_ok,
      ev_ins_records_ok,
      ev_del_records_err,
      ev_ins_records_err.

    " Definition
    DATA:
      lt_faat_doc_it_auto_corr TYPE STANDARD TABLE OF faat_doc_it,
      lt_range_bukrs           TYPE RANGE OF          bukrs,
      ls_faat_doc_it_auto_corr TYPE faat_doc_it,
      lv_mode_str              TYPE string,
      lv_del_records_ok        TYPE i VALUE 0,
      lv_ins_records_ok        TYPE i VALUE 0,
      lv_del_records_err       TYPE i VALUE 0,
      lv_ins_records_err       TYPE i VALUE 0,
      lb_error_occurred_update TYPE abap_bool.

    " Body
    "------------------------------------------------------------------------------
    " Header line for package
    "------------------------------------------------------------------------------

    gv_string = '*** New package of FAAT_DOC_IT ***'                                                                             ##NO_TEXT.
    IF ib_test EQ abap_true.
      CONCATENATE gv_string ' Test Run ***' INTO gv_string SEPARATED BY space                                                    ##NO_TEXT.
    ELSE.
      CONCATENATE gv_string ' Productive Run ***' INTO gv_string SEPARATED BY space                                              ##NO_TEXT.
    ENDIF.

    MESSAGE s900(ac) WITH gv_string INTO lv_msg.
    mo_log->add_current_sy_message( iv_probclass = '1' ).

    "------------------------------------------------------------------------------
    " Keep test/productive info for protocol
    "------------------------------------------------------------------------------
    IF ib_test EQ abap_true.
      lv_mode_str = ' test '                                                                                                     ##NO_TEXT.
    ELSE.
      lv_mode_str = ' productive '                                                                                               ##NO_TEXT.
    ENDIF. "p_test

    "------------------------------------------------------------------------------
    " Process requested FAAT_DOC_IT updates
    " Process only if marked as automatically correctable
    "------------------------------------------------------------------------------
    LOOP AT ct_faat_doc_it_err
         ASSIGNING FIELD-SYMBOL(<ls_faat_doc_it_err>)
         WHERE flg_auto_corr EQ abap_true.

      "------------------------------------------------------------------------------
      " Check authorization -> check at company code level is not suitable for conversion tools
      "------------------------------------------------------------------------------

      READ TABLE lt_range_bukrs
      TRANSPORTING NO FIELDS
      WITH KEY low = <ls_faat_doc_it_err>-bukrs.
      IF sy-subrc NE 0.
        lt_range_bukrs = VALUE #( BASE lt_range_bukrs ( sign = 'I' option = 'EQ' low = <ls_faat_doc_it_err>-bukrs ) ).
        IF me->check_authority_for_bukrs( EXPORTING iv_bukrs = <ls_faat_doc_it_err>-bukrs ib_test = ib_test ) = abap_true.
          MESSAGE s900(ac) WITH 'No authorization for company code: ' && <ls_faat_doc_it_err>-bukrs INTO lv_msg                  ##NO_TEXT.
          mo_log->add_current_sy_message( iv_probclass = '1' ).
        ENDIF.
      ENDIF.

      "------------------------------------------------------------------------------
      " Header line for new DB item for protocol
      "------------------------------------------------------------------------------
      gv_string = '*** New item of FAAT_DOC_IT ***'                                                                              ##NO_TEXT.
      IF ib_test EQ abap_true.
        CONCATENATE gv_string ' Test Run ***' INTO gv_string SEPARATED BY space                                                  ##NO_TEXT.
      ELSE.
        CONCATENATE gv_string ' Productive Run ***' INTO gv_string SEPARATED BY space                                            ##NO_TEXT.
      ENDIF.

      MESSAGE s900(ac) WITH gv_string INTO lv_msg.
      mo_log->add_current_sy_message( iv_probclass = '1' ).


      "------------------------------------------------------------------------------
      " Write FAAT_DOC_IT_KEY to protocol
      "------------------------------------------------------------------------------

      DATA(lv_asset) = <ls_faat_doc_it_err>-bukrs && '/' && <ls_faat_doc_it_err>-anln1 && '-' && <ls_faat_doc_it_err>-anln2      ##NO_TEXT.
      CONCATENATE 'Asset: ' lv_asset INTO gv_string SEPARATED BY space                                                           ##NO_TEXT.
      MESSAGE s900(ac) WITH gv_string INTO lv_msg.
      mo_log->add_current_sy_message( iv_probclass = '3' ).

      MESSAGE s900(ac) WITH 'Following FAAT_DOC_IT items processed: ' INTO lv_msg                                                ##NO_TEXT.
      mo_log->add_current_sy_message( iv_probclass = '4' ).

      " Display (unchnaged) content of key fiels (for deletion and insert)
      LOOP AT mt_item_key_column REFERENCE INTO DATA(lr_item_key_column).
        ASSIGN COMPONENT lr_item_key_column->* OF STRUCTURE <ls_faat_doc_it_err> TO FIELD-SYMBOL(<lv_column_value>).
        CONCATENATE 'Key Field: : ' lr_item_key_column->* ' = ' <lv_column_value> INTO gv_string SEPARATED BY space              ##NO_TEXT.
        MESSAGE i900(ac) WITH gv_string INTO lv_msg.
        mo_log->add_current_sy_message( iv_probclass = '4' ).
      ENDLOOP. " at mt_item_key_column

      " Display new content of data fiels (for insert)
      LOOP AT mt_item_data_column REFERENCE INTO DATA(lr_item_data_column).
        ASSIGN COMPONENT lr_item_data_column->* OF STRUCTURE <ls_faat_doc_it_err> TO <lv_column_value>.
        gv_string =  'Data Field: ' && lr_item_data_column->* && ' = ' && <lv_column_value>                                      ##NO_TEXT.
        MESSAGE i900(ac) WITH gv_string INTO lv_msg.
        mo_log->add_current_sy_message( iv_probclass = '4' ).
      ENDLOOP. " at mt_item_key_column

      "------------------------------------------------------------------------------
      " Prepare DB processing with individual lines
      "------------------------------------------------------------------------------
      CLEAR:
        lv_del_records_ok,
        lv_ins_records_ok,
        lv_del_records_err,
        lv_ins_records_err,
        ls_faat_doc_it_auto_corr,
        lt_faat_doc_it_auto_corr.
      MOVE-CORRESPONDING <ls_faat_doc_it_err> TO ls_faat_doc_it_auto_corr.
      ASSERT ls_faat_doc_it_auto_corr-mandt EQ iv_client.
      APPEND ls_faat_doc_it_auto_corr TO lt_faat_doc_it_auto_corr.

      "------------------------------------------------------------------------------
      " Process FAAT_DOC_IT updates in test mode
      "------------------------------------------------------------------------------
      IF ib_test EQ abap_true.

        ADD <ls_faat_doc_it_err>-count_multiple TO lv_del_records_ok.
        lv_ins_records_ok = 1.

        "------------------------------------------------------------------------------
        " Process FAAT_DOC_IT updates in productive mode
        " Execute UPDATE only if marked as automatically correctable
        "------------------------------------------------------------------------------
      ELSE.

        "------------------------------------------------------------------------------
        " Change of DB table FAAT_DOC_IT:
        " Central Part of correction is following (multiple) delete and (single) insert       ##DB_FEATURE_MODE[TABLE_LEN_MAX1]
        "------------------------------------------------------------------------------

        "------------------------------------------------------------------------------
        " <<<<<<<<<<<<<<<<<<<<<<<<<<< DB Delete FAAT_DOC_IT >>>>>>>>>>>>>>>>>>>>>>>>>>>
        "------------------------------------------------------------------------------
        DELETE faat_doc_it
         USING CLIENT @iv_client
         FROM TABLE @lt_faat_doc_it_auto_corr.

        DATA(lv_subrc_del) = sy-subrc. " sy-subr is not suitable for deletions in case of duplicate DB keys
        " Deletion is ok if number of duplicate entries was actually deleted
        IF sy-dbcnt EQ <ls_faat_doc_it_err>-count_multiple.
          lv_del_records_ok  = sy-dbcnt.
        ELSE.
          lv_del_records_err = sy-dbcnt.
        ENDIF.

        "------------------------------------------------------------------------------
        " <<<<<<<<<<<<<<<<<<<<<<<<<<< DB Insert FAAT_DOC_IT >>>>>>>>>>>>>>>>>>>>>>>>>>>
        "------------------------------------------------------------------------------
        INSERT faat_doc_it
         USING CLIENT @iv_client
          FROM TABLE @lt_faat_doc_it_auto_corr.

        DATA(lv_subrc_ins) = sy-subrc.
        IF lv_subrc_ins EQ 0.
          lv_ins_records_ok  = sy-dbcnt.
        ELSE.
          lv_ins_records_err = 1.
        ENDIF.

        " Check result of correction:
        " Especially compare sy-dbcnt with number of known items
        IF   lv_subrc_ins      EQ 0 AND
           " lv_subrc_del      EQ 0 AND " <--- Basis sets ay-aubrc <> 0 for deletion of duplicate FAAT_DOC_IT entries
             lv_ins_records_ok EQ 1 AND
             lv_del_records_ok EQ <ls_faat_doc_it_err>-count_multiple.
          lb_error_occurred_update = abap_false.
        ELSE.
          lb_error_occurred_update = abap_true.
        ENDIF.

        IF lb_error_occurred_update EQ abap_false.

          " Don't change eb_error_occurred at successsful update of this FAAT_DOC_IT item.
          " (Could be that previous items failed).

          " Mark entry as corrected
          <ls_faat_doc_it_err>-flg_corr_done = abap_true.

        ELSE. " lb_error_occurred_update = abap_True

          " Error case
          eb_error_occurred = abap_true.

          " Mark entry as not corrected
          <ls_faat_doc_it_err>-flg_corr_done = abap_false.

          " Error occurred during update &1 &2 &3 &4
          MESSAGE e031(fins_fi_mig) INTO lv_msg                         ##MG_MISSING.
          mo_log->add_current_sy_message( iv_probclass = '1' ).

        ENDIF. " lb_error_occurred_update

      ENDIF.  " ib_test

      "------------------------------------------------------------------------------
      " Protocol FAAT_DOC_IT changes
      "------------------------------------------------------------------------------

      "------------------------------------------------------------------------------
      " Add Successful test run message to report protocol:
      "------------------------------------------------------------------------------

      IF NOT ( lv_del_records_ok IS INITIAL AND lv_ins_records_ok IS INITIAL ).
        " Successful DB Changes for single DB line
        CONCATENATE 'Successful ' lv_mode_str ' run for single DB line' INTO gv_string SEPARATED BY space                        ##NO_TEXT.
        MESSAGE i900(ac) WITH gv_string INTO lv_msg.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
        " Successful DB deletions in test run
        MESSAGE i900(ac) WITH 'Successful DB deletions in ' && lv_mode_str && ' run: ' && lv_del_records_ok INTO lv_msg          ##NO_TEXT.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
        " Successful DB inserts in test run
        MESSAGE i900(ac) WITH 'Successful DB inserts in ' && lv_mode_str && ' run: '   && lv_ins_records_ok INTO lv_msg          ##NO_TEXT.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
      ENDIF.

      "------------------------------------------------------------------------------
      " Add Failing test run message to report protocol:
      "------------------------------------------------------------------------------

      IF NOT ( lv_del_records_err IS INITIAL AND lv_ins_records_err IS INITIAL ).
        " Failing DB Changes for single DB line
        CONCATENATE 'Failed DB Changes in ' lv_mode_str ' run for single DB line' iv_client INTO gv_string SEPARATED BY space   ##NO_TEXT.
        MESSAGE i900(ac) WITH gv_string INTO lv_msg.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
        " Failing DB deletions in test run
        MESSAGE i900(ac) WITH 'Failed DB deletions in ' && lv_mode_str && ' run: ' && lv_del_records_err INTO lv_msg            ##NO_TEXT.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
        " Failing DB inserts in test run
        MESSAGE i900(ac) WITH 'Failed DB inserts in ' && lv_mode_str && ' run: '   && lv_ins_records_err INTO lv_msg            ##NO_TEXT.
        mo_log->add_current_sy_message( iv_probclass = '1' ).
      ENDIF.

      " Export no. records (independent of error or not)
      ev_del_records_ok = ev_del_records_ok + lv_del_records_ok.
      ev_ins_records_ok = ev_ins_records_ok + lv_ins_records_ok.
      ev_del_records_err = ev_del_records_err + lv_del_records_err.
      ev_ins_records_err = ev_ins_records_err + lv_ins_records_err.

      "Postprocessing of loop
      lb_error_occurred_update = abap_false.
      CLEAR:
        lv_subrc_del,
        lv_subrc_ins,
        lv_del_records_ok,
        lv_ins_records_ok,
        lv_del_records_err,
        lv_ins_records_err,
        ls_faat_doc_it_auto_corr,
        lt_faat_doc_it_auto_corr.

      "------------------------------------------------------------------------------
      " Potential Refinement of Commit Handling  <<<<<<<<< Option: here would be the right place for commit at level of single FAAT_DOC_IT keys >>>>>>>>>>
      "------------------------------------------------------------------------------

    ENDLOOP. " at gt_faat_doc_it_err

    "------------------------------------------------------------------------------
    " Add Successful test run message to report protocol:
    "------------------------------------------------------------------------------

    IF NOT ( ev_del_records_ok IS INITIAL AND ev_ins_records_ok IS INITIAL ).
      " Overview Successful DB Changes in this package of client
      CONCATENATE 'Successful ' lv_mode_str ' run in package: ' iv_package ' - client: ' iv_client INTO gv_string SEPARATED BY space       ##NO_TEXT.
      MESSAGE i900(ac) WITH gv_string INTO lv_msg.
      mo_log->add_current_sy_message( iv_probclass = '1' ).
      " Successful DB deletions in test run
      MESSAGE i900(ac) WITH 'Successful DB deletions in ' && lv_mode_str && ' run: ' && ev_del_records_ok INTO lv_msg                      ##NO_TEXT.
      mo_log->add_current_sy_message( iv_probclass = '1' ).
      " Successful DB inserts in test run
      MESSAGE i900(ac) WITH 'Successful DB inserts in ' && lv_mode_str && ' run: '   && ev_ins_records_ok INTO lv_msg                      ##NO_TEXT.
      mo_log->add_current_sy_message( iv_probclass = '1' ).
    ENDIF.

    "------------------------------------------------------------------------------
    " Add Failing test run message to report protocol:
    "------------------------------------------------------------------------------

    IF NOT ( ev_del_records_err IS INITIAL AND ev_ins_records_err IS INITIAL ).
      " Overview Failing DB Changes in this package of client
      CONCATENATE 'Failing DB Changes in ' lv_mode_str ' run in package: ' iv_package ' - client: ' iv_client INTO gv_string SEPARATED BY space      ##NO_TEXT.
      MESSAGE i900(ac) WITH gv_string INTO lv_msg.
      mo_log->add_current_sy_message( iv_probclass = '1' ).
      " Failing DB deletions in test run
      MESSAGE i900(ac) WITH 'Failing DB deletions in ' lv_mode_str ' run: ' && ev_del_records_err INTO lv_msg                                        ##NO_TEXT.
      mo_log->add_current_sy_message( iv_probclass = '1' ).
      " Failing DB inserts in test run
      MESSAGE i900(ac) WITH 'Failing DB inserts in ' lv_mode_str ' run: '   && ev_ins_records_err INTO lv_msg                                        ##NO_TEXT.
      mo_log->add_current_sy_message( iv_probclass = '1' ).
    ENDIF.

    " Postconditions
    IF lb_error_occurred_update EQ abap_true.
      eb_error_occurred = abap_true.
    ENDIF.

  ENDMETHOD.  " process_update_operation

ENDCLASS. " lcl_execute

" Test automation include (not delivered)
INCLUDE faa_lth_tdc_del_double_doc_it IF FOUND.
INCLUDE faa_ltc_del_double_doc_it     IF FOUND.