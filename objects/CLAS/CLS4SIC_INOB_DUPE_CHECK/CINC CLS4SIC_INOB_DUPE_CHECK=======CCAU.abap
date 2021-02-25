CLASS ltc_s4sic_inob_dupe_check DEFINITION DEFERRED.
CLASS cls4sic_inob_dupe_check DEFINITION LOCAL FRIENDS ltc_s4sic_inob_dupe_check.

CLASS ltc_s4sic_inob_dupe_check DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS
  FINAL.
  PUBLIC SECTION.

  PRIVATE SECTION.
    CLASS-DATA:
      go_osql_env           TYPE REF TO if_osql_test_environment,
      gt_parameter_simple   TYPE tihttpnvp,
      gt_parameter_detailed TYPE tihttpnvp.

    CLASS-METHODS: class_setup.
    CLASS-METHODS: class_teardown.

    DATA:
      mo_cut                TYPE REF TO cls4sic_inob_dupe_check.

    METHODS: setup.
    METHODS: check_relevance FOR TESTING.
    METHODS: check_consistency_normal_empty FOR TESTING.
    METHODS: check_consistency_normal_inc FOR TESTING.
    METHODS: check_consistency_normal_cons FOR TESTING.
    METHODS: check_consistency_details_emp FOR TESTING.
    METHODS: check_consistency_details_inc FOR TESTING.
    METHODS: check_consistency_details_cons FOR TESTING.
ENDCLASS.

CLASS ltc_s4sic_inob_dupe_check IMPLEMENTATION.
  METHOD class_setup.

    go_osql_env = cl_osql_test_environment=>create(
      VALUE #(
        ( 'INOB' ) ) ).

    gt_parameter_simple   = VALUE #( ( name = 'DETAILED_CHECK'  value = abap_false ) ).
    gt_parameter_detailed = VALUE #( ( name = 'DETAILED_CHECK'  value = abap_true ) ).

  ENDMETHOD.

  METHOD class_teardown.

    go_osql_env->destroy( ).

  ENDMETHOD.

  METHOD setup.

    go_osql_env->clear_doubles( ).

    mo_cut = NEW #( ).

  ENDMETHOD.

  METHOD check_relevance.

    " When: I ask for the relevance.
    mo_cut->check_relevance(
      EXPORTING
        it_parameter   = VALUE #( )
      IMPORTING
        ev_relevance   = DATA(lv_relevance)
        ev_description = DATA(lv_description) ).

    " Then: It should return yes.
    cl_abap_unit_assert=>assert_equals(
      exp = 'Y'
      act = lv_relevance ).

    " And: It should return the proper description.
    cl_abap_unit_assert=>assert_equals(
      exp = 'INOB duplicate check is required.'
      act = lv_description ).

  ENDMETHOD.

  METHOD check_consistency_normal_empty.

    DATA:
      lt_chk_result_exp TYPE cls4sic_inob_dupe_check=>ty_pre_cons_chk_result_tab.

    " Given: There is no INOB entries in the system.

    " And: We expect the following return value.
    lt_chk_result_exp = VALUE #(
      (
        check_sub_id = 'CHK_INOB_DUPE'
        return_code = 0
        descriptions = VALUE #( ( `No INOB duplicates (inconsistency) found.` ) ) ) ).

    " When: I execute check_consistency with empty input.
    mo_cut->check_consistency(
      EXPORTING
        it_parameter   = gt_parameter_simple
      IMPORTING
        et_chk_result = DATA(lt_chk_result_act) ).

    " Then: It should return the proper values.
    cl_abap_unit_assert=>assert_equals(
      exp = lt_chk_result_exp
      act = lt_chk_result_act ).

  ENDMETHOD.

  METHOD check_consistency_normal_inc.

    DATA:
      lt_chk_result_exp TYPE cls4sic_inob_dupe_check=>ty_pre_cons_chk_result_tab.

    " Given: There is an INOB duplicate in the system.
    DATA(lt_inob) = VALUE tt_inob(
      (
        mandt = '003'
        cuobj = 1
        obtab = 'MCH1'
        objek = 'OBJ1'
        klart = '023' )
      (
        mandt = '003'
        cuobj = 2
        obtab = 'MCH1'
        objek = 'OBJ2'
        klart = '023' )
      (
        mandt = '003'
        cuobj = 3
        obtab = 'MCH1'
        objek = 'OBJ2'
        klart = '023' )
      (
        mandt = '003'
        cuobj = 4
        obtab = 'MARA'
        objek = 'OBJ2'
        klart = '023' ) ).
    go_osql_env->insert_test_data( lt_inob ).

    " And: We expect the following return value.
    lt_chk_result_exp = VALUE #(
      (
        check_sub_id = 'CHK_INOB_DUPE'
        return_code = 12
        descriptions = VALUE #( ( `Inconsistency: Several INOB entry found for a Business Object! Please do a run with detailed check turned on.` ) ) ) ).

    " When: I execute check_consistency with empty input.
    mo_cut->check_consistency(
      EXPORTING
        it_parameter   = gt_parameter_simple
      IMPORTING
        et_chk_result = DATA(lt_chk_result_act) ).

    " Then: It should return the proper values.
    cl_abap_unit_assert=>assert_equals(
      exp = lt_chk_result_exp
      act = lt_chk_result_act ).

  ENDMETHOD.

  METHOD check_consistency_normal_cons.

    DATA:
      lt_chk_result_exp TYPE cls4sic_inob_dupe_check=>ty_pre_cons_chk_result_tab.

    " Given: There is no INOB duplicate in the system.
    DATA(lt_inob) = VALUE tt_inob(
      (
        mandt = '003'
        cuobj = 1
        obtab = 'MCH1'
        objek = 'OBJ1'
        klart = '023' )
      (
        mandt = '003'
        cuobj = 2
        obtab = 'MCH1'
        objek = 'OBJ2'
        klart = '023' )
      (
        mandt = '003'
        cuobj = 4
        obtab = 'MARA'
        objek = 'OBJ2'
        klart = '023' ) ).
    go_osql_env->insert_test_data( lt_inob ).

    " And: We expect the following return value.
    lt_chk_result_exp = VALUE #(
      (
        check_sub_id = 'CHK_INOB_DUPE'
        return_code = 0
        descriptions = VALUE #( ( `No INOB duplicates (inconsistency) found.` ) ) ) ).

    " When: I execute check_consistency with empty input.
    mo_cut->check_consistency(
      EXPORTING
        it_parameter   = gt_parameter_simple
      IMPORTING
        et_chk_result = DATA(lt_chk_result_act) ).

    " Then: It should return the proper values.
    cl_abap_unit_assert=>assert_equals(
      exp = lt_chk_result_exp
      act = lt_chk_result_act ).

  ENDMETHOD.

  METHOD check_consistency_details_emp.

    DATA:
      lt_chk_result_exp TYPE cls4sic_inob_dupe_check=>ty_pre_cons_chk_result_tab.

    " Given: There is no INOB entry in the system.

    " And: We expect the following return value.
    lt_chk_result_exp = VALUE #(
      (
        check_sub_id = 'CHK_INOB_DUPE'
        return_code = 0
        descriptions = VALUE #( ( `No INOB duplicates (inconsistency) found.` ) ) ) ).

    " When: I execute check_consistency with empty input.
    mo_cut->check_consistency(
      EXPORTING
        it_parameter   = gt_parameter_detailed
      IMPORTING
        et_chk_result = DATA(lt_chk_result_act) ).

    " Then: It should return the proper values.
    cl_abap_unit_assert=>assert_equals(
      exp = lt_chk_result_exp
      act = lt_chk_result_act ).

  ENDMETHOD.

  METHOD check_consistency_details_inc.

    DATA:
      lt_chk_result_exp TYPE cls4sic_inob_dupe_check=>ty_pre_cons_chk_result_tab.

    " Given: There is an INOB duplicate in the system.
    DATA(lt_inob) = VALUE tt_inob(
      (
        mandt = '003'
        cuobj = 1
        obtab = 'MCH1'
        objek = 'OBJ1'
        klart = '023' )
      (
        mandt = '003'
        cuobj = 2
        obtab = 'MCH1'
        objek = 'OBJ2'
        klart = '023' )
      (
        mandt = '003'
        cuobj = 3
        obtab = 'MCH1'
        objek = 'OBJ2'
        klart = '023' )
      (
        mandt = '003'
        cuobj = 4
        obtab = 'MARA'
        objek = 'OBJ2'
        klart = '023' ) ).
    go_osql_env->insert_test_data( lt_inob ).

    " And: We expect the following return value.
    lt_chk_result_exp = VALUE #(
      (
        check_sub_id = 'CHK_INOB_DUPE'
        return_code = 12
        descriptions = VALUE #( ( `Inconsistency: Several INOB entries found for Business Object: MANDT=003 KLART='023' OBTAB='MCH1' OBJEK='OBJ2' Please eliminate INOB duplicates. For more information, see SAP Note 2948953!` ) ) ) ).

    " When: I execute check_consistency.
    mo_cut->check_consistency(
      EXPORTING
        it_parameter   = gt_parameter_detailed
      IMPORTING
        et_chk_result = DATA(lt_chk_result_act) ).

    " Then: It should return the proper values.
    cl_abap_unit_assert=>assert_equals(
      exp = lt_chk_result_exp
      act = lt_chk_result_act ).

  ENDMETHOD.

  METHOD check_consistency_details_cons.

    DATA:
      lt_chk_result_exp TYPE cls4sic_inob_dupe_check=>ty_pre_cons_chk_result_tab.

    " Given: There is no INOB duplicate in the system.
    DATA(lt_inob) = VALUE tt_inob(
      (
        mandt = '003'
        cuobj = 1
        obtab = 'MCH1'
        objek = 'OBJ1'
        klart = '023' )
      (
        mandt = '003'
        cuobj = 2
        obtab = 'MCH1'
        objek = 'OBJ2'
        klart = '023' )
      (
        mandt = '003'
        cuobj = 4
        obtab = 'MARA'
        objek = 'OBJ2'
        klart = '023' ) ).
    go_osql_env->insert_test_data( lt_inob ).

    " And: We expect the following return value.
    lt_chk_result_exp = VALUE #(
      (
        check_sub_id = 'CHK_INOB_DUPE'
        return_code = 0
        descriptions = VALUE #( ( `No INOB duplicates (inconsistency) found.` ) ) ) ).

    " When: I execute check_consistency with empty input.
    mo_cut->check_consistency(
      EXPORTING
        it_parameter   = gt_parameter_detailed
      IMPORTING
        et_chk_result = DATA(lt_chk_result_act) ).

    " Then: It should return the proper values.
    cl_abap_unit_assert=>assert_equals(
      exp = lt_chk_result_exp
      act = lt_chk_result_act ).

  ENDMETHOD.
ENDCLASS.